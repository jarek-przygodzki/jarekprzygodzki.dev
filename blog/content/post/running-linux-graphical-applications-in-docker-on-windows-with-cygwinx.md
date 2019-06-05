---
title: "Running Linux graphical applications in Docker on Windows with Cygwin/X"
date: 2017-07-11
tags: [Docker,Windows,CYGWIN/X]
draft: false
---
## Install Babun
[Cygwin](https://www.cygwin.com/) is a great tool, but not the easiest to install. Babun consists of a pre-configured Cygwin  that does not interfere with existing Cygwin installation.

Download the dist file from [http://babun.github.io](http://babun.github.io/), unzip it and run the install.bat script. After a few minutes the application will be installed to the `%USERPROFILE%\.babun` directory. You can use the /target (or /t)  option to install babun to a custom directory.

## Install Cygwin/X
Run pact from babun shell (pact is a babun package manager )
```
pact install xorg-server xinit xhost
```
## Start the X server

Once the installation has completed, open a Cygwin terminal and run `XWin :0 -listen tcp -multiwindow`. This will start an X server on Windows machine
with the ability to listen to connections from the network (`-listen tcp`) and display each application in its own window (`-multiwindow`), rather than a single window acting as a virtual screen to display applications on. Once it’s started, you should see an „X” icon in Windows tray area.

## Run graphical application
[fr3nd/xeyes](https://github.com/fr3nd/docker-xeyes)  is a good test to run
```
// don't forget to change WINDOWS_MACHINE_IP_ADDR!
// 'localhost' obviously won't work from within Docker container
docker run -e DISPLAY=$WINDOWS_MACHINE_IP_ADDR:0 --rm fr3nd/xeyes
```
Or we can build ourselves image with Firefox using the following Dockerfile as a starting point

```
FROM centos
 
RUN yum -y update && yum install -y firefox
 
CMD /usr/bin/firefox
```
`docker build -t firefox` . it and run the container with
```
export DISPLAY=$WINDOWS_MACHINE_IP_ADD:0
docker run -ti --rm -e DISPLAY=$DISPLAY firefox
```
If all goes well you should see Firefox running from within a Docker container.
## Troubleshooting
If you have issues with authorization you may want to try running the insecure `xhost + command` to permit access from all machines. See [xhost(1) Linux man page](http://linux.die.net/man/1/xhost).


## Alternatives
There are a few different options to run GUI applications inside a Docker container like using [SSH with X11 forwarding](https://blog.docker.com/2013/07/docker-desktop-your-desktop-over-ssh-running-inside-of-a-docker-container/) or [VNC](http://stackoverflow.com/questions/16296753/can-you-run-gui-apps-in-a-docker-container/16311264#16311264).