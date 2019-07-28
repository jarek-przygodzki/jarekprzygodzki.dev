---
title: "Notes and Thoughts on Strace for Windows"
date: 2019-07-28
tags: [Windows, Internals, DevOps, Troubleshooting]
draft: false
---

_strace_ and it's cousin _ltrace_ are well known and invaluable diagnostic and debugging tools for Linux. Here are articles explaining how they work: [How does strace work?](https://blog.packagecloud.io/eng/2016/02/29/how-does-strace-work/), [How does ltrace work?](https://blog.packagecloud.io/eng/2016/03/14/how-does-ltrace-work/). But what about Windows?

There are tools for Windows that provide a similar functionality to strace/ltrace on Linux. From all of the following tools, _drstrace_, _Nektra SpyStudio_ and _Rohitab API Monitor_ are most realiable and useful.


## Strace for Windows from Dr. Memory
drstrace works by using the Dr. Syscall System Call Monitoring Extension

Pros:

- Source code available under the LGPL license (except certain portions) at [github](https://github.com/DynamoRIO/drmemory)

Home page: [System Call Tracer ("strace") for Windows](http://drmemory.org/strace_for_windows.html)


## Nektra SpyStudio

Pros

- Free for any use
- Does not require installation (just unzip and use it)
- 32-bit/64-bit

Cons

- No source code


Home page: [SpyStudio API Monitor](https://www.nektra.com/products/spystudio-api-monitor/)


## Windows API Monitor from rohitab
Pros

- Freeware
- 32-bit/64-bit

Cons

- No source code

Home page:  [API Monitor](http://www.rohitab.com/apimonitor)



## StraceNT from IntellectualHeaven
StraceNT works by using Import Address Table (IAT) patching . Implementation is explained in [this](http://intellectualheaven.com/Articles/StraceNT.pdf) article along with others system call hooking techniques.

Pros

- Source code available under the BSD license at [github](https://github.com/intellectualheaven/stracent)

Cons

- [made for x86 only (32-bit)](https://github.com/l0n3c0d3r/stracent/issues/2)

Home page: [StraceNT - A System Call Tracer for Windows](http://intellectualheaven.com/default.asp?BH=StraceNT)

## NtTrace
NtTrace can be used to execute a program or to attach to an existing process by PID or, using the -a option, by name. It works by using the Windows debug interface to place breakpoints in NtDll

Pros

- Actively developed
- Source code available under the BSD license at [github](https://github.com/rogerorr/NtTrace)
- 32-bit/64-bit
- Can show stack trace

Cons

- Slow
- No prebuilt binaries


Home page: [NtTrace - Native API tracing for Windows](http://rogerorr.github.io/NtTrace/)

# Legacy projects
Does not work on new Windows versions.

## API Monitor
Display Win32 API calls made by applications.

Cons 

- Not free software.
- No source code
- 32-bit only

Home page: [Win32 API Monitor](https://www.apimonitor.com/)

## strace from BindView 
Can be found on the [archive.org](http://web.archive.org/web/20070915180821/http://www.bindview.com/Services/razor/Utilities/Windows/strace_readme.cfm) web site. It uses the system call hooking technique described by [Undocumented Windows NT](https://dl.acm.org/citation.cfm?id=554827). Source code is provided under the terms of BindView's Open Source license. 


