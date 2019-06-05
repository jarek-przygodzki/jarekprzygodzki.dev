---
title: "JVM in Docker and PTRACE_ATTACH"
date: 2016-12-19
tags: [Docker,Linux,ptrace,JVM]
draft: false
---
Docker nowadays (since 1.10, the original pull request is here [docker/docker/#17989](https://github.com/docker/docker/pull/17989)) adds some security to running containers by wrapping them in both AppArmor (or presumably SELinux on RedHat systems) and seccomp eBPF based syscall filters ([here’s a nice article about it](http://www.brendangregg.com/blog/2015-05-15/ebpf-one-small-step.html)). And ptrace is disabled in the [default seccomp profile](https://raw.githubusercontent.com/docker/docker/master/profiles/seccomp/default.json).

```
$ docker run alpine sh -c 'apk add -U strace && strace echo'
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/community/x86_64/APKINDEX.tar.gz
(1/1) Installing strace (4.11-r2)
Executing busybox-1.24.2-r11.trigger
OK: 6 MiB in 12 packages
strace: ptrace(PTRACE_TRACEME, ...): Operation not permitted
+++ exited with 1 +++
```
Why am I writing about this? Because some JDK tools depend on PTRACE_ATTACH on Linux. One of them is  very useful jmap.

```
$ jmap -heap <pid>

Attaching to process ID 142, please wait...
Error attaching to process: sun.jvm.hotspot.debugger.DebuggerException: Can't attach to the process: ptrace(PTRACE_ATTACH, ..) failed for 142: Operation not permitted
sun.jvm.hotspot.debugger.DebuggerException: sun.jvm.hotspot.debugger.DebuggerException: Can't attach to the process: ptrace(PTRACE_ATTACH, ..) failed for 142: Operation not permitted
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$LinuxDebuggerLocalWorkerThread.execute(LinuxDebuggerLocal.java:163)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.attach(LinuxDebuggerLocal.java:278)
        at sun.jvm.hotspot.HotSpotAgent.attachDebugger(HotSpotAgent.java:671)
        at sun.jvm.hotspot.HotSpotAgent.setupDebuggerLinux(HotSpotAgent.java:611)
        at sun.jvm.hotspot.HotSpotAgent.setupDebugger(HotSpotAgent.java:337)
        at sun.jvm.hotspot.HotSpotAgent.go(HotSpotAgent.java:304)
        at sun.jvm.hotspot.HotSpotAgent.attach(HotSpotAgent.java:140)
        at sun.jvm.hotspot.tools.Tool.start(Tool.java:185)
        at sun.jvm.hotspot.tools.Tool.execute(Tool.java:118)
        at sun.jvm.hotspot.tools.HeapSummary.main(HeapSummary.java:49)
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at sun.tools.jmap.JMap.runTool(JMap.java:201)
        at sun.tools.jmap.JMap.main(JMap.java:130)
Caused by: sun.jvm.hotspot.debugger.DebuggerException: Can't attach to the process: ptrace(PTRACE_ATTACH, ..) failed for 142: Operation not permitted
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.attach0(Native Method)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal.access$100(LinuxDebuggerLocal.java:62)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$1AttachTask.doit(LinuxDebuggerLocal.java:269)
        at sun.jvm.hotspot.debugger.linux.LinuxDebuggerLocal$LinuxDebuggerLocalWorkerThread.run(LinuxDebuggerLocal.java:138)
```
Turning seccomp off (`–security-opt seccomp=unconfined`) is not recommended, but we can add just this one explicit [capability](https://docs.docker.com/engine/reference/run/#/runtime-privilege-and-linux-capabilities)  with `--cap-add=SYS_PTRACE`.

```
$ docker run --cap-add=SYS_PTRACE alpine sh -c 'apk add -U strace && strace echo'
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/community/x86_64/APKINDEX.tar.gz
(1/1) Installing strace (4.11-r2)
Executing busybox-1.24.2-r11.trigger
OK: 6 MiB in 12 packages
execve("/bin/echo", ["echo"], [/* 5 vars */]) = 0
arch_prctl(ARCH_SET_FS, 0x7feaca3a8b28) = 0
set_tid_address(0x7feaca3a8b60) = 10
mprotect(0x7feaca3a5000, 4096, PROT_READ) = 0
mprotect(0x558c47ec6000, 16384, PROT_READ) = 0
getuid() = 0
write(1, "\n", 1) = 1
exit_group(0) = ?
+++ exited with 0 +++
```
[Docker Compose](https://docs.docker.com/compose/) supports cap_add since [version 1.1.0 (2015-02-25)](https://github.com/YelpArchive/docker-compose/blob/master/CHANGES.md#110-2015-02-25).

If you run into an issue with the jmap and jstack from OpenJDK failing with exception _java.lang.RuntimeException: unknown CollectedHeap type : class sun.jvm.hotspot.gc_interface.CollectedHeap_ make sure you install openjdk-debuginfo package (or openjdk-8-dbg or something similiar depending on distro).

```
$ jmap -heap 66
Attaching to process ID 66, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.111-b14

using parallel threads in the new generation.
using thread-local object allocation.
Concurrent Mark-Sweep GC

Heap Configuration:
   MinHeapFreeRatio         = 40
   MaxHeapFreeRatio         = 70
   MaxHeapSize              = 268435456 (256.0MB)
   NewSize                  = 87228416 (83.1875MB)
   MaxNewSize               = 87228416 (83.1875MB)
   OldSize                  = 181207040 (172.8125MB)
   NewRatio                 = 2
   SurvivorRatio            = 8
   MetaspaceSize            = 21807104 (20.796875MB)
   CompressedClassSpaceSize = 1073741824 (1024.0MB)
   MaxMetaspaceSize         = 17592186044415 MB
   G1HeapRegionSize         = 0 (0.0MB)

Heap Usage:
Exception in thread "main" java.lang.reflect.InvocationTargetException
        at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
        at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)
        at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
        at java.lang.reflect.Method.invoke(Method.java:498)
        at sun.tools.jmap.JMap.runTool(JMap.java:201)
        at sun.tools.jmap.JMap.main(JMap.java:130)
Caused by: java.lang.RuntimeException: unknown CollectedHeap type : class sun.jvm.hotspot.gc_interface.CollectedHeap
        at sun.jvm.hotspot.tools.HeapSummary.run(HeapSummary.java:144)
        at sun.jvm.hotspot.tools.Tool.startInternal(Tool.java:260)
        at sun.jvm.hotspot.tools.Tool.start(Tool.java:223)
        at sun.jvm.hotspot.tools.Tool.execute(Tool.java:118)
        at sun.jvm.hotspot.tools.HeapSummary.main(HeapSummary.java:49)
        ... 6 more
```