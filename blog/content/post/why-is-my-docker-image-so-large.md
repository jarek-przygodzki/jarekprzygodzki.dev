---
title: Why is my Docker image so large?
date: 2019-05-12
description: Troubleshooting issues with Docker image size
tags: [docker,linux]
draft: false
---

Keeping Docker images as small as possible has a lot of practical benefits. But even when following best practices 

- use stripped-down base image
- utilize multi-stage builds
- don't install what you don't need
- optimize build context
- minimize number of layers

some images end up being larger than they have to be inadvertently including files that are not necessary .

# How to troubleshoot issues with image size?

Image filesystem changes are tracked in layers. Each layer is the the representation of the file system changes for each instruction in Dockerfile. Layers of a Docker image are essentially  files generated from running some command during `docker build` in ephemeral intermediate container.


In the past, I used to perform `docker history <image name>` to view all the layers that make up the image, manually extract suspicious layers and inspect their content. It worked, but it was tedious.


# Dive
[Dive](https://github.com/wagoodman/dive) is a new tool for exploring a Docker images, inspecting layer contents and discovering ways to shrink your Docker image size - all that in a nice text-based user interface.

I recently used it to diagnose an unexpected image size growth caused by change of  file ownership & permissions. One of the instructions in `jboss/wildfly` based Dockerfile was `chown -R jboss:jboss /opt/jboss/wildfly/`. It looks innocent, but these files are originally owned by _jboos:root_. Docker doesn't know what changes have happened inside a layer, only which files are affected.  As such, this will cause Docker to create a new layer, replacing all those files (same content as _/opt/jboss/wildfly/_ but with with new ownership), adding hundreds of megabytes to image size. 


# Resources
- [Dive GitHub Page](https://github.com/wagoodman/dive)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

