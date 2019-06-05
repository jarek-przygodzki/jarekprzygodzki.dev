---
title: A curious case of slow Docker image builds
date: 2018-08-31
description: Investigating slow Docker image builds
tags: [docker,devicemapper,overlay2,linux]
draft: false
---

# Investigating slow Docker image builds

_A rather short but hopefully interesting troubleshooting story that happened recently._

Lately, I was investigating a case of slow Docker image builds on CI server (Oracle Linux 7.5 with Docker devicemapper storage driver in direct-lvm mode). Each operation which altered layers (ADD, COPY, RUN) took up to 20 seconds - the larger the image, the longer. 

A typical way of dealing with with apparently stuck program is collecting thread stack traces. Or goroutines' stacktraces in the case of the Go application.

## Dump of dockerd 
Docker deamon will write goroutines stacktraces to a file named `goroutine-stacks-<datetime>.log` after receving a SIGUSR1 signal ([engine/daemon/debugtrap_unix.go](https://github.com/docker/docker-ce/blob/18.09/components/engine/daemon/debugtrap_unix.go#L16))
```
pkill -SIGUSR1 dockerd
```
A quick analysis showed that almost all the time was spent in `NaiveDiffDriver.Diff`. Here it is one of the dumps

{{< gist jarek-przygodzki f342c6e9b688d0d119737e8be03d9351  >}}

## What is a NaiveDiffDriver and why is it naive?
Docker image consist of immutable layers that are based on ordered root filesystem changes (and some metadata). Storage driver implementation handles merging of layers into a single mount point and provides a writable layer (called the “container layer”) on top of the underlying layers. All filesystem changes are written to this thin writable container layer. Each time a container is committed (manually or as part of building a Dockerfile), the storage driver needs to provide a list of modified files and directories relative to the base image to create a new layer. Some drivers keep track of these changes at run time and can generate that list easily but for drivers with no native handling for calculating changes Docker provides `NaiveDiffDriver`. This driver produces a list of changes between current container filesystem  and its parent layer by recursively traversing both directory trees and comparing file metadata. This operation is expensive for big images with many files and directories. See [here](https://integratedcode.us/2016/08/30/storage-drivers-in-docker-a-deep-dive/) and [here](https://portworx.com/lcfs-speed-up-docker-commit/) for in depth description of storage drivers in Docker.

## Solution
The Device Mapper storage driver is good choice for running container in production on Red Hat and it's derivatives but not for building images because it's lack of native diff support. After some thought I choose [overlay2](https://docs.docker.com/storage/storagedriver/overlayfs-driver/) as a replacement. It turned out that native diff support in overlay2 in incompatible with [OVERLAY_FS_REDIRECT_DIR](https://github.com/torvalds/linux/blob/v4.18/fs/overlayfs/Kconfig#L13) option enabled in modern kernels: [storage driver falls back to NaiveDiffDriver with a waring when it's detected](https://github.com/moby/moby/pull/34342).
```
# https://github.com/docker/docker-ce/blob/18.09/components/engine/daemon/graphdriver/overlay2/overlay.go#L287
Not using native diff for overlay2, this may cause degraded performance for building images: kernel has CONFIG_OVERLAY_FS_REDIRECT_DIR enabled
```
The workaround I came up with is to disable _overlay_redirect_dir_ option in overlay module
```
echo 'options overlay redirect_dir=off' > /etc/modprobe.d/disable_overlay_redirect_dir.conf
```
which finally enables native diffs
```
Storage Driver: overlay2
 Backing Filesystem: xfs
 Supports d_type: true
 Native Overlay Diff: true
```
No more time an CPU cycles lost computing layer diffs.

## Bonus

I created [a few virtual machines](https://github.com/jarek-przygodzki/docker-image-build-times) to confirm the source of the problem and to work on the solution. 

Nice think about Go is that it integrates pprof into the standard library and dockerd enables pprof/debug endpoints by default since 17.07.0-ce (2017-08-29) (earlier the profiler api was only available in debug mode: --debug/-D, [Enable pprof/debug endpoints by default #32453](https://github.com/moby/moby/pull/32453)).

Docker in flames
```
go-torch --file docker-build.svg --title="docker build" \
    --url http://localhost:2375
```

![docker build flame graph](https://github.com/jarek-przygodzki/docker-image-build-times/raw/master/assets/docker-build-devicemapper.png)

Docker daemon is spending most of its time in `NaiveDiffDriver.Diff`.

```
go-torch --file docker-build-inversed.svg --inversed --title="docker build" \
    --url http://localhost:2375
```

![docker build flame graph inversed](https://github.com/jarek-przygodzki/docker-image-build-times/raw/master/assets/docker-build-devicemapper-inversed.png)

... doing syscalls.
