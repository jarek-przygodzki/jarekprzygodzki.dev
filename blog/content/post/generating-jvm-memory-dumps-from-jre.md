---
title: Generating JVM memory dumps from JRE
date: 2018-08-28
draft: false
description: 
tags: [jvm,jre,jattach,docker]
---

# Generating JVM memory dumps from JRE on Linux/Windows/OSX

Generating a JVM heap memory dump with JDK is straightforward as almost every Java developer knows about jmap and jcmd tools that come with the JDK. But what about JRE?

Some people think you [need JDK](https://stackoverflow.com/questions/24213491/how-do-i-produce-a-heap-dump-with-only-a-jre), or at least [part of it](https://medium.com/@chamilad/extracting-memory-and-thread-dumps-from-a-running-jre-based-jvm-26de1e37a080), but that's not true. The answer lies in [jattach](https://github.com/apangin/jattach), a tool to send commands to JVM via Dynamic Attach mechanism created by JVM hacker Andrei Pangin ([@AndreiPangin](https://twitter.com/andreipangin)). It's tiny (24KB), works with just JRE and supports Linux containers. 

## Usage
Most of the time it comes down to downloading a single file 
```
wget -L -O /usr/local/bin/jattach \
    https://github.com/apangin/jattach/releases/download/v1.4/jattach && \
    chmod +x /usr/local/bin/jattach
```

We can then send `dumpheap` command do JVM process
```
jattach PID-OF-JAVA dumpheap <path to heap dump file>
```
 e.g
```
java_pid=$(pidof -s java) && \
    jattach $java_pid dumpheap /tmp/java_pid$java_pid-$(date +%Y-%m-%d_%H-%M-%S).hprof
```
## How does it work?
Built-in JDK utilities like jmap and jstack have two execution modes: cooperative and forced. In normal cooperative mode these tools use Dynamic Attach Mechanism to connect to the target VM. The requested command is then executed by the target VM in it's own process. This mode is used by jattach. 

The forced mode (jmap -F, jstack -F) works differently. The tool suspends the target process and then reads the process memory using Serviceability Agent. See [this](https://stackoverflow.com/questions/26140182/running-jmap-getting-unable-to-open-socket-file/35963059#35963059) for details.
 
## Docker
Prior to  Java 10 jmap, jstack and jcmd could not attach from a process on the host machine to a JVM running inside a Docker container because of how the attach mechanism interacts with pid and mount namespaces. Java 10 [fixes this](https://bugs.openjdk.java.net/browse/JDK-8179498) by the JVM inside the container finding its PID in the root namespace and using this to watch for a JVM attachment.

Jattach supports containers and is compatible with earlier versions of JVM - all we need is process id in host PID namespace. How can we get it?

If JVM is the main process of a container (PID 1), the needed information is included in `docker inspect` output

```
cid=<container name or id>
host_pid=$(docker inspect --format {{.State.Pid}} $cid)
```

If it's not? Then things become more interesting. The easiest way that I know of is to use /proc/PID/sched - kernel scheduling statistics.

```
cid=<container name or id>
docker exec -it $cid bash -c 'cat /proc/$(pidof -s java)/sched'

java (8251, #threads: 127)
-------------------------------------------------------------------
se.exec_start                                :        275669.207074
se.vruntime                                  :            80.606203
se.sum_exec_runtime                          :            57.897264
nr_switches                                  :                  157
nr_voluntary_switches                        :                  149
nr_involuntary_switches                      :                    8
se.load.weight                               :                 1024
se.avg.load_sum                              :              8883079
se.avg.util_sum                              :                 4424
se.avg.load_avg                              :                  181
se.avg.util_avg                              :                   90
se.avg.last_update_time                      :         275669207074
policy                                       :                    0
prio                                         :                  120
clock-delta                                  :                   52
mm->numa_scan_seq                            :                    0
numa_migrations, 0
numa_faults_memory, 0, 0, 1, 0, -1
numa_faults_memory, 1, 0, 0, 0, -1
```

For us interesting is the first line of the output (format defined in [kernel/sched/debug.c#L877](https://github.com/torvalds/linux/blob/v4.18/kernel/sched/debug.c#L877). Desired PID can be extract with a little bit of shell scripting
```
docker exec -it $cid sh -c 'head -1 /proc/$(pidof -s java)/sched | grep -P "(?<=\()\d+" -o'
```

When target container is bare (no shell, no cat, no nothing), nsenter is a possible alternative to `docker exec`

```
host_pid=$(docker inspect --format {{.State.Pid}} <container name or id>)
nsenter --target $host_pid  --pid --mount  sh -c 'cat /proc/$(pidof -s java)/sched'
```

## What can go wrong?
Jattach from project's release page is linked against glibc so it [most likely](https://wiki.alpinelinux.org/wiki/Running_glibc_programs) won't work on Alpine Linux. But it is not too hard to make it work.
