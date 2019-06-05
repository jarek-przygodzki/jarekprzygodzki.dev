---
title: "On why and how to exit JVM on OnOutOfMemoryError
"
date: 2017-10-15
tags: [JVM,OpenJDK]
draft: false
---
For a long time all my JVM-based Docker images were configured to exit on OOM error with `-XX:OnOutOfMemoryError=”kill -9 %p”` (%p is the current JVM process PID placeholder). It works well with `XX:+HeapDumpOnOutOfMemoryError`, because JVM will dump heap first, and then execute OnOutOfMemoryError command (see the relevant code in [vm/utilities/debug.cpp](http://hg.openjdk.java.net/jdk8u/jdk8u/hotspot/file/5755b2aee8e8/src/share/vm/utilities/debug.cpp#l295)). But with version 8u92 there’s now a JVM option in the JDK to make the JVM exit when an OutOfMemoryError occurs:

>**ExitOnOutOfMemoryError**
>
>When you enable this option, the JVM exits on the first occurrence of an out-of-memory error. It can be used if you prefer restarting an instance of the JVM rather than handling out of memory errors.
>
>**CrashOnOutOfMemoryError**
>
> If this option is enabled, when an out-of-memory error occurs, the JVM crashes and produces text and binary crash files.
Enhancement Request: [JDK-8138745](https://bugs.openjdk.java.net/browse/JDK-8138745) (parameter naming is wrong though [JDK-8154713](https://bugs.openjdk.java.net/browse/JDK-8154713), `ExitOnOutOfMemoryErroR` instead of `ExitOnOutOfMemory`)

Why exit on OOM? OutOfMemoryError may seem like any other exception, but if it escapes from Thread.run() it will cause thread to die. When thread dies it is no longer a GC root, and thus all references kept only by this thread are eligible for garbage collection. While it means that JVM has a chance recover from OOME, its not recommended that you try. It may work, but it is generally a bad idea. See [this answer](https://stackoverflow.com/questions/3058198/can-the-jvm-recover-from-an-outofmemoryerror-without-a-restart/3058430#3058430) on SO.