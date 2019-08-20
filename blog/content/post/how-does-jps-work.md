---
title: "How Does Jps Work"
date: 2019-08-04
tags: []
draft: true
---


jps is as part of the JDK, a tool that, according to documentation, 

> lists the instrumented Java Virtual Machines (JVMs) on the target system. 

But what is _instrumened JVM_ and how does jps  work? This post attemps to answer both questions. In depth.



Note: At various points I will refer to JDK 8 source code. There are some changes in newer versions, but thery are pretty minor. Also, some parts are for now Windows-specific.

Let's figure it out. It's to time to dig the source code!

## jps

jps is a small executable. It's just a launcher, which will start a JVM and load the `sun.tools.jps.Jps` java class from tools.jar into it. It's defined in [jdk/make/CompileLaunchers.gmk](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/23c77bdc49fc/make/CompileLaunchers.gmk#l325)

```
$(eval $(call SetupLauncher,jps, \
    -DJAVA_ARGS='{ "-J-ms8m"$(COMMA) "sun.tools.jps.Jps"$(COMMA) }'))
```

Launcher's entry point is defined in [jdk/src/share/bin/main.c](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/23c77bdc49fc/src/share/bin/main.c). There's nothing really intersting there, other than  `_JAVA_LAUNCHER_DEBUG` environment variable that enables debug output. Note that this environment variable's value is not relevant, as long as its set to something.  

```
set _JAVA_LAUNCHER_DEBUG=1
jps

Windows original main args:
wwwd_args[0] = jps
----_JAVA_LAUNCHER_DEBUG----

Much more details. 
See https://gist.github.com/jarek-przygodzki/8988e6f5915b65f20cb3323f5df887f6
```

Jps can be invoked without native launcher

```
java -cp "%JAVA_HOME%\lib\tools.jar" sun.tools.jps.Jps
```

## sun.tools.jps.Jps
The [sun.tools.jps.Jps](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/23c77bdc49fc/src/share/classes/sun/tools/jps/Jps.java) class parses command line arguments and then `MonitoredHost.activeVMs()` method is used to obtain the list of all active VMs on a host. 

Iteresting thing here are [two undocumented system](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/23c77bdc49fc/src/share/classes/sun/tools/jps/Arguments.java#l41) properties `jps.debug` and `jps.printStackTrace` that can aid troubleshooting. We will come back to them later.


Main part of local JVM discovery can be distilled to this code
```
import sun.tools.jps.*
import sun.jvmstat.monitor.*

Arguments arguments = new Arguments(args);
HostIdentifier hostId = arguments.hostId();
// hostId: sun.jvmstat.monitor.HostIdentifier = //localhost
MonitoredHost monitoredHost = MonitoredHost.getMonitoredHost(hostId);
// monitoredHost: sun.jvmstat.monitor.MonitoredHost =
//   sun.jvmstat.perfdata.monitor.protocol.local.MonitoredHostProvider
Set<Integer> jvms = monitoredHost.activeVms()
```

`MonitoredHost` for local host uses `MonitoredHostProvider` which in turn delegates to `LocalVmManager.listVMs()`


```text
sun.jvmstat.monitor.MonitoredHost.activeVms()
    sun.jvmstat.perfdata.monitor.protocol.local.MonitoredHostProvider.activeVms()
        sun.jvmstat.perfdata.monitor.protocol.local.LocalVmManager.activeVms()
```

What does `LocalVmManager.activeVMs()` do? Well, we are finally going somewhere. 

JVM special [temporary directory](http://hg.openjdk.java.net/jdk8u/jdk8u/hotspot/file/c7a3e57fdf4a/src/share/vm/prims/jvm.cpp#l415) (one not affected by configuration variables such as _java.io.tmpdir_) is searched for directories named "hsperfdata_*". Then we iterate over that list to find any files within those directories - each file represents a JVM and it's name is as JVM identifier which is also a OS process identifier: [LocalVmManager.activeVMs()](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/file/23c77bdc49fc/src/share/classes/sun/jvmstat/perfdata/monitor/protocol/local/LocalVmManager.java#l128).

That seems like a lot of effort to find files in directories named _hsperfdata\_*_ in JVM temporary directory.

## PerfData
After that, unless the -q option is used, jps will try to show additional information about JVMs. How? That's the interesting part.


Turns out each file inside hsperfdata_userid directory is a filesystem manifestation of JVM feature called perfdata.  If the VM started with the `-XX:+UsePerfData`  options -- which is on by default, it will create memory mapped file inside hsperfdata_userid directory and store there  performance statistics & other info. This is what jps documentation is refering to when calling JVM _instrumented_: it's a JVM with jvmstat instrumentation turned on. The JVM by default exports statistics by mmap-ing a file, the `-XX:+PerfDisableSharedMem` JVM flag disables this feature - when it is on, performance data is stored in standard memory.  UsePerfData controls whether the JVM collects  performance statistics, PerfDisableSharedMem controls where thery are stored if collected: file or memory.

<!--
hotspot\src\os\aix\vm\perfMemory_aix.cpp
hotspot\src\os\bsd\vm\perfMemory_bsd.cpp
hotspot\src\os\linux\vm\perfMemory_linux.cpp
hotspot\src\os\solaris\vm\perfMemory_solaris.cpp
hotspot\src\os\windows\vm\perfMemory_windows.cpp
-->


The way the program reads perfdata is quite interesting. Instead of accessing perfdata file directly,  it uses `sun.misc.Perf.attach` native method to obtain `ByteBuffer` pointing directly to target process memory. Details of how `PerfMemory::attach` works are platform-specific, but Windows platform stands out. On every platform other than Windows, it calls `mmap_attach_shared` to open the shared memory file for the give vmid and then mmap it. On Windows however, it uses [OpenFileMapping](https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-openfilemappingw) to open a named shared memory object directly, skipping the filesystem.


<!--
hotspot\src\os\aix\vm\perfMemory_aix.cpp
hotspot\src\os\bsd\vm\perfMemory_bsd.cpp
hotspot\src\os\linux\vm\perfMemory_linux.cpp
hotspot\src\os\solaris\vm\perfMemory_solaris.cpp
hotspot\src\os\windows\vm\perfMemory_windows.cpp
-->

<!--
import sun.misc.Perf;
int vmid = 
Perf perf = Perf.getPerf();
ByteBuffer perfdata = perf.attach(vmid, "r");

-->

Buffer content is then parsed to extract necessary information in [PerfDataBuffer](jdk\src\share\classes\sun\jvmstat\perfdata\monitor\v2_0\PerfDataBuffer.java) class.



sun.misc.VMSupport.getVMTemporaryDirectory() is a native method defined in 

jdk/src/share/native/sun/misc/VMSupport.c

```
JNIEXPORT jstring JNICALL
Java_sun_misc_VMSupport_getVMTemporaryDirectory(JNIEnv *env, jclass cls)
{
    return JVM_GetTemporaryDirectory(env);
}

```
hotspot/src/share/vm/prims/jvm.cpp

```
JVM_ENTRY(jstring, JVM_GetTemporaryDirectory(JNIEnv *env))
  JVMWrapper("JVM_GetTemporaryDirectory");
  HandleMark hm(THREAD);
  const char* temp_dir = os::get_temp_directory();
  Handle h = java_lang_String::create_from_platform_dependent_str(temp_dir, CHECK_NULL);
  return (jstring) JNIHandles::make_local(env, h());
JVM_END
```

hotspot/src/os/windows/vm/os_windows.cpp
```
const char* os::get_temp_directory() {
  static char path_buf[MAX_PATH];
  if (GetTempPath(MAX_PATH, path_buf)>0)
    return path_buf;
  else{
    path_buf[0]='\0';
    return path_buf;
  }
}
```

JVM_GetTemporaryDirectory os::get_temp_directory() GetTempPath on Windows


The GetTempPath function checks for the existence of environment variables in the following order and uses the first path found:

- The path specified by the TMP environment variable.
- The path specified by the TEMP environment variable.
- The path specified by the USERPROFILE environment variable.
- The Windows directory.

https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-gettemppathw



