---
title: "Debugging any JVM in a Docker container"
date: 2017-10-15
tags: []
draft: false
---
Thanks to [JAVA_TOOL_OPTIONS](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/envvars002.html) variable it’s easy to run any JVM-based Docker image in debug mode. All we have to do is  add environment variable definition `JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005` in docker run or docker-compose.yml and expose port to connect debugger.

```
# docker run
-e "JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005" \
-p 5005:5005

# docker-compose
    environment:
      - "JAVA_TOOL_OPTIONS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"
    ports:
      -  5005:5005
 ```
If it's possible, it's handy to extend application entrypoint

```
# Set debug options if required
if [ x"${JAVA_ENABLE_DEBUG}" != x ] && [ "${JAVA_ENABLE_DEBUG}" != "false" ]; then
    java_debug_args="-agentlib:jdwp=transport=dt_socket,server=y,suspend=${JAVA_DEBUG_SUSPEND:-n},address=${JAVA_DEBUG_PORT:-5005}"
fi
```