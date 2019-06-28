---
title: "Proxy address forwarding in WildFly explained"
date: 2019-06-28
tags: [WildFly]
draft: true
---

## What is proxy address forwarding in WildFly

Proxy address forwarding allows applications that are behind a proxy to see the real address of the client, rather than the address of the proxy. In many deployment scenarios we have other servers sitting in front of application, be they proxies, web servers, load balancers, or other similar systems

## proxy-address-forwarding
With that option enabled, Undertow (WildFly's HTTP  server) will respect `X-Forwarded-For`, `X-Forwarded-Host`, `X-Forwarded-Port` `X-Forwarded-Proto` request headers, allowing JAX-RS and servlet applications work seamlessly behind proxy: methods like

- `HttpServletRequest.getRequestURL()`
- `javax.ws.rs.core.UriInfo.getAbsolutePath()`

 will return public address through which the client accesses the resource.

Details of how headers are processed can be found in 
[undertow/&hellip;/ProxyPeerAddressHandler.java](https://github.com/undertow-io/undertow/blob/2.0.22.Final/core/src/main/java/io/undertow/server/handlers/ProxyPeerAddressHandler.java#L56).

