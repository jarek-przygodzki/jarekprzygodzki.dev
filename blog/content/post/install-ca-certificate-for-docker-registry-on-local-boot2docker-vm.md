---
title: "Install Ca Certificate for Docker Registry on Local Boot2docker Vm"
date: 2018-05-23
tags: [Docker,DevOps,Boot2Docker,CA]
draft: false
---

Annoyingly often internal Docker registries are secured with certificates signed by company's own PKI or enterprise IT does a MitM to replace all HTTPS certs.

Commonly, company's root CA certificate is installed by IT on developers machines and servers, but not on VMs run by developers on their own machines. When using Docker with local VMs like boot2docker, do we need to install the company root CA certificate on the VM to avoid x509: certificate signed by unknown authority errors.

There are two ways to do it  - both are documented [here](https://github.com/boot2docker/boot2docker#installing-secure-registry-certificates).

## Adding trusted CA root certificates to VM OS cert store
Let's start with this option. Docker daemon respects OS cert store. To make the certificate survive machine restart it has to be placed in `/var/lib/boot2docker/certs` directory on persistent partition . In Boot2Docker certificates (in .pem or .crt format) from that directory are automatically load at boot. See [boot2docker/rootfs/etc/rc.d/install-ca-certs](https://github.com/boot2docker/boot2docker/blob/v18.05.0-ce/rootfs/rootfs/etc/rc.d/install-ca-certs) for details.

There's also open issue in docker-machine to support [installing root CA certificates on machine creation](http://install%20roohttps//github.com/docker/machine/issues/3822t/CA%20certificates%20on%20machine%20creation) and instruction how to build [boot2docker ISO with custom CA certificate for private docker registry](https://gist.github.com/mickep76/707450361be4a2da3d0b).

## Addding trusted CA root certificate for specific registries
Docker allows to specify custom CA root for a
specific registry hostname. It can configured per registry by creating a directory under `/etc/docker/certs.d` using the same name as the registry’s hostname (including port number if any). All *.crt files from this directory are added as CA roots, details are in [moby/registry.go#newTLSConfig](https://github.com/moby/moby/blob/5a68e2617da4b18ea4bae9fb3205026bb541e8d4/registry/registry.go#L28).

Another option to deal with insecure registries is enabling insecure communication with specified registries (no certificate verification and HTTP fallback). See [insecure-registry](https://github.com/boot2docker/boot2docker#insecure-registry) for details.