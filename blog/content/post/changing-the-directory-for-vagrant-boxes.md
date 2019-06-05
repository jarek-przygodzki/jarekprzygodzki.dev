---
title: "Changing the directory for Vagrant boxes"
date: 2016-06-21
draft: false
tags: [Vagrant]
---

The successfully downloaded Vagrant boxes are located at `~/.vagrant.d/boxes` on Mac/Linux System and `%USERPROFILE%/.vagrant.d/boxes` on Windows. This can be changed by setting an environment variable named VAGRANT_HOME to specify the location of .vagrant.d, as in `VAGRANT_HOME=F:\.vagrant.d`
```
# Windows
# current terminal session
set VAGRANT_HOME=F:\.vagrant.d
# current user environment
setx VAGRANT_HOME F:\.vagrant.d
# system wide environment
setx VAGRANT_HOME F:\.vagrant.d /M
```
VAGRANT_HOME is documented [here](https://www.vagrantup.com/docs/other/environmental-variables.html) along with other interesting options.

