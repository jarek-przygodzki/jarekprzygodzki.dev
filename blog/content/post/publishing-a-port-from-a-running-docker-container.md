---
title: "Publishing a port from a running Docker container"
date: 2018-04-08
tags: [Docker,Linux,DevOps]
draft: false
---
It’s not obvious, but it’s possible to publish an additional port from a running Docker container.

Note: Assuming container is attached to user-defined bridge network or default bridge network. Publishing ports doesn’t make sense with [MacVLAN or IPVLAN](https://docs.docker.com/network/macvlan/) since then every container has a uniquely routable IP address and can offer service on any port.

## What can we do to make container port externally accessible?
One possibile solution is to exploit the fact that communication between containers inside the same bridge network is switched at layer 2 and they can communiate with each other without any restrictions (unless ICC is disabled, that is). That means when can run another container with socat inside target network with published port and setup forwarding

```
docker run --rm -it \
    --net=[TARGET_NETWORK]
    -p [PORT]:[PORT] \
    bobrik/socat TCP-LISTEN:[PORT],fork TCP:[CONTAINER_IP]:[CONTAINER_PORT]
```
What else can we do do? It’s not immediately obvious, but each bridge network is reachable from the host. We can verify with `ip route show` that in host’s routing table exists routing table entry for each bridge network

```
$ ip route show
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 
172.18.0.0/16 dev br-b4247d00e80c proto kernel scope link src 172.18.0.1
172.19.0.0/16 dev br-acd7d3307ea3 proto kernel scope link src 172.19.0.1
```
That means we can as well setup socat relay in host network namespace

```
docker run --rm -it \
    --net=host \
    -p [PORT]:[PORT] \
    bobrik/socat TCP-LISTEN:[PORT],fork TCP:[CONTAINER_IP]:[CONTAINER_PORT]
```
or just run socat directly on host
```
socat TCP-LISTEN:[PORT],fork TCP:[CONTAINER_IP]:[CONTAINER_PORT]
```
But we can still do better! We can replace socat relay with iptables DNAT. For inbound traffic, we’ll need to create a custom rule that uses Network Address Translation (NAT) to map a port on the host to the service port in the container. We can do that with a rule like this:

```
# must be added into DOCKER chain
 iptables -t nat -A DOCKER -p tcp -m tcp \
    --dport [PORT] -j DNAT \
    --to-destination [CONTAINER_IP]:[CONTAINER_PORT]
```
This is pretty much how Docker publishes ports from containers using the bridged network when option `-publish|-p` is used with docker run. The only difference is that DNAT rule created by Docker is restricted not to affect traffic originating from bridge

```
iptables -t nat -A DOCKER ! -i [BRIDGE_NAME] -p tcp -m tcp \
   --dport [PORT] -j DNAT \
   --to-destination [CONTAINER_IP]:[CONTAINER_PORT]
```
The DOCKER chain is a custom chain defined at the FORWARD chain. When a packet hits any interface and is bound to the one of bridge interfaces, it is sent to the custom DOCKER chain. Now the DOCKER chain will take all incoming packets, except ones coming from bridge (say docker0 for default network), and send them to a container IP (usually 172.x.x.x) and port.