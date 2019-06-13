---
title: "Monitoring new process creation"
date: 2019-06-15
draft: false
tags: [DevOps, Linux, Windows]
---


Monitoring process creation and termination events is a useful skill to have in you toolbox. This article consists of two parts. The first introduces exiting tools for diffrent platforms. The second explains how these tools work internally.


# Introducing tools

## Linux
### forkstat
Forkstat monitors process fork(), exec() and exit() activity. It is mature and it's available in most distribution's repositories. Uses the Linux netlink connector to gather process activity.

{{< highlight plain>}}
# Ubuntu\Debian
sudo apt install forkstat
sudo forkstat -e exec
Time     Event   PID Info   Duration Process
21:20:15 exec   3378                 sleep 10

sudo forkstat -e exec,exit
Time     Event   PID Info   Duration Process
21:21:30 exec   3384                 sleep 10
21:21:40 exit   3384      0  10.003s sleep 10

{{< / highlight >}}
Requires root privilege (CAP_NET_ADMIN capability).


### execsnoop  (eBPF)
execsnoop traces process execution. It works by dynamic tracing an execve kernel function. 
See the bcc [installation instructions](https://github.com/iovisor/bcc/blob/master/INSTALL.md) for your OS. On Ubuntu, versions of bcc are available in the standard Ubuntu repository as of Ubuntu Bionic (18.04). The tools are installed in `/sbin` (`/usr/sbin` in Ubuntu 18.04) with a -bpfcc extension.

{{< highlight plain>}}
sudo apt-get install bpfcc-tools linux-headers-$(uname -r)

sudo execsnoop-bpfcc 
PCOMM            PID    PPID   RET ARGS
sleep            5380   5379     0 /usr/bin/sleep 10

{{< / highlight >}}


### execsnoop
Precedessor of eBPF based execsnoop. Still relevant because it has no dependecies other that awk and works on older Linux kernel versions (3.2+).
{{< highlight plain>}}
wget https://raw.githubusercontent.com/brendangregg/perf-tools/master/execsnoop \
    -O /usr/local/bin/execsnoop  && chmod +x /usr/local/bin/execsnoop

execsnoop
{{< / highlight >}}
Does not work on many newer systems, try execsnoop (eBPF) first.
## Windows

### Process Monitor
[_Process Monitor_](https://docs.microsoft.com/en-us/sysinternals/downloads/procmon), part of _Sysinternals Suite_ is an advanced monitoring tool for Windows that can be used to keep track of process creation events.  Can be downloaded as standalone executable from project's website or installed with chocolatey package manager: `choco install procmon`. Also part of [Sysinternals Suite](https://chocolatey.org/packages/sysinternals) package.

![Process Monitor Process ](/post/images/procmon-process-create-operation.png)

### PowerShell
Microsoft Scripting Guy, Ed Wilson shown that PowerShell can be used to monitor process creation.

{{< highlight plain >}}
Register-CimIndicationEvent `
    -ClassName Win32_ProcessStartTrace `
    -SourceIdentifier "ProcessStarted"

Get-Event | `
    Select timegenerated, `
        @{L='Executable'; E = {$_.sourceeventargs.newevent.processname}}

TimeGenerated       Executable
-------------       ----------
12.06.2019 22:28:19 ps.exe
12.06.2019 22:29:13 bash.exe
12.06.2019 22:29:13 bash.exe
12.06.2019 22:29:13 bash.exe
12.06.2019 22:29:13 git.exe
12.06.2019 22:30:47 chrome.exe
12.06.2019 22:30:48 chrome.exe

# Cleanup
get-event | Remove-Event
Get-EventSubscriber | Unregister-Event

{{< / highlight >}}


See [this](https://devblogs.microsoft.com/scripting/use-powershell-to-monitor-for-process-startup/) article for details.

## How do these tools work 

### Forkstat

Forkstat uses the kernel [Netlink](https://en.wikipedia.org/wiki/Netlink) connector interface to gather process activity.  It allows program to receive notifications of process events such as fork, exec, exit, core dump as well as changes to a process's name, UID, GID or SID  over a socket connection.

With default parameters, forkstat will report fork, exec and exit events, but the -e option allows  to specify one or more of the fork, exec, exit, core, comm, clone, ptrce, uid, sid or all events.  When a fork event happens, forkstat will report the PID and process name of the parent and child, allowing one to easily identify where processes are originating. Forkstat  attempts to track the life time of a process and will log the duration of a processes when it exits where possible. Note that forkstat may miss events if the system is under heavy load. Netlink connector also requires root privilege (or using CAP_NET_ADMIN capability).

Netlink is a Linux kernel IPC mechanism, enabling communication between a userspace process and the kernel, or multiple userspace processes. Netlink sockets are the primitive which enables this communication.
`CONFIG_PROC_EVENTS` kernel option  enables `Process Events Connector` which exposes the process events to userland via a Netlink socket and was introduced in 2005 in [this](https://lwn.net/Articles/157150/) patch by Matt Helsley.

Forkstat's source code is [here](https://github.com/ColinIanKing/forkstat) but it's very C-like in a sense that it manages to obfuscate relatively simple idea.


To let userspace know about different process events we will have to 

- make a netlink socket and bind it 
- send the `PROC_CN_MCAST_LISTEN` message to the kernel to let it know we want to receive events
- receive events by reading datagrams from socket
- parse event data and extract the relevant process information


{{< highlight go >}}
sock, _ := unix.Socket(unix.AF_NETLINK,
    // used interchangeably with SOCK_RAW
    unix.SOCK_DGRAM, unix.NETLINK_CONNECTOR)
addr := &unix.SockaddrNetlink{
        Family: unix.AF_NETLINK, Groups: C.CN_IDX_PROC, Pid: uint32(os.Getpid())}
unix.Bind(sock, addr)
send(sock, C.PROC_CN_MCAST_LISTEN)
for {
    p := make([]byte, 4096)
    nbytes, from, _ := unix.Recvfrom(sock, p, 0)
    nlmessages, _ := syscall.ParseNetlinkMessage(p[:nbytes])
    for _, m := range nlmessages {
			if m.Header.Type == unix.NLMSG_DONE {
                // netlink uses the host byte order
				cnhdr := (*C.struct_cn_msg)(unsafe.Pointer(&m.Data[0]))
				ptr := uintptr(unsafe.Pointer(cnhdr))
				ptr += unsafe.Sizeof(*cnhdr)
				pe := (*C.struct_proc_event)(unsafe.Pointer(ptr))
				switch pe.what {
				case C.PROC_EVENT_EXEC:
					e := (*C.struct_exec_proc_event)(unsafe.Pointer(&pe.event_data))
					fmt.Printf("Process started: PID %d\n", e.process_pid)
				case C.PROC_EVENT_EXIT:
					e := (*C.struct_exit_proc_event)(unsafe.Pointer(&pe.event_data))
					fmt.Printf("Process exited: PID %d\n", e.process_pid)
				}
			}
            }
    }

}
{{< / highlight >}}
That's it! The only problem is that [`exec_proc_event`](https://github.com/torvalds/linux/blob/v5.0/include/uapi/linux/cn_proc.h#L80) contains little data. We could try to immediately read process information from `/proc/<PID>` but that wouldn't be reliable (it's racy). There is a risk that by that time we read process information the process has already finished or even another one took its PID. Full example is [here](https://gist.github.com/jarek-przygodzki/0fd8b2c12a91d0141ca032794d08c05e).


### execsnoop  (eBPF)
[execsnoop](https://github.com/iovisor/bcc/blob/master/tools/execsnoop.py) is part of BCC. It's a suite tools that use eBPF tracing:  infrastructure to dynamically instrument the kernel. It allows to define programs that run in kernel. Learn about eBPF [here](http://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html) or read [execsnoop source code](https://github.com/iovisor/bcc/blob/master/tools/execsnoop.py). The only downside is that these tools require new-ish kernel.

### execsnoop
Hack from Brendan Gregg's [perf-tools](https://github.com/brendangregg/perf-tools) collection. It traces `stub_execve()` or `do_execve(`), and walks the `%si` register as an array of strings. Check details on the author's blog [here](http://www.brendangregg.com/blog/2014-07-28/execsnoop-for-linux.html).


### Process Monitor
_Process Monitor_ installs a kernel driver on startup which does the system-wide monitoring of userland processes. Driver API provides the kernel routine [`PsSetCreateProcessNotifyRoutine`](https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/content/ntddk/nf-ntddk-pssetcreateprocessnotifyroutine)/[`PsSetCreateProcessNotifyRoutineEx`](https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/content/ntddk/nf-ntddk-pssetcreateprocessnotifyroutineex) to allow software to monitor process creation and termination events in the Windows kernel. No code here, but [this](https://github.com/microsoft/Windows-driver-samples/blob/41c29cb92feff490270b4ce31f67d7baddecc457/general/obcallback/README.md) example from  Windows Driver Kit (WDK) 10 is close to what we want.


### PowerShell
PowerShell example uses WMI ([Windows Management Instrumentation](https://en.wikipedia.org/wiki/Windows_Management_Instrumentation)) and [`Win32_ProcessStartTrace`](https://docs.microsoft.com/en-us/previous-versions/windows/desktop/krnlprov/win32-processstarttrace) event.


Creating your own monitoring tool requires few lines of code

{{< highlight go >}}
/*
 * csc procmon_wmi.cs
 */
using System;
using System.Management;

class ProcessMonitor
{
    static public void Main(String[] args)
    {
        var processStartEvent = 
            new ManagementEventWatcher("SELECT * FROM Win32_ProcessStartTrace");
        var processStopEvent = 
            new ManagementEventWatcher("SELECT * FROM Win32_ProcessStopTrace");

        processStartEvent.EventArrived += 
            new EventArrivedEventHandler(
                delegate (object sender, EventArrivedEventArgs e)
        {
            var processName = e.NewEvent.Properties["ProcessName"].Value;
            var processId = e.NewEvent.Properties["ProcessID"].Value;

            Console.WriteLine("{0} Process started. Name: {1} | PID: {2}", 
                DateTime.Now, processName, processId);
        });

        processStopEvent.EventArrived += 
            new EventArrivedEventHandler(
                delegate (object sender, EventArrivedEventArgs e)
        {
            var processName = e.NewEvent.Properties["ProcessName"].Value;
            var processId = e.NewEvent.Properties["ProcessID"].Value;

            Console.WriteLine("{0} Process stopped. Name: {1} | PID: {2}", 
                DateTime.Now, processName, processId);
        });

        processStartEvent.Start();
        processStopEvent.Start();

        Console.ReadKey();
    }
}
{{< / highlight >}}