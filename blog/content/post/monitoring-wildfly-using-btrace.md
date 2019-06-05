---
title: "Monitoring WildFly Using BTrace"
date: 2016-02-18
tags: [BTrace]
draft: false
---
Today I was hoping to use BTrace to track a rather anoying bug in web application running inside WildFly application server. I’ve used BTrace some times in the past and my experience was nothing but positive. Until today, that is.

Probe deployment caused a myriad of exceptions inside application server coming from instrumented classes  and all caused by missing btrace runtime.   The classloader separation of the AS getting in my way! I know a thing or two about classloading in WildFly, so I decided to add btrace  to system packages(just like [Byteman](http://byteman.jboss.org/))

```
jboss.modules.system.pkgs=org.jboss.byteman,com.sun.btrace
```
To my suprise, it wasn’t the end of the story because now my btrace script was unavailable

```
java.lang.ClassNotFoundException: TracingScript$1 from [Module "deployment.atrem.incubator.e5.ml-web.war:main" from Service Module Loader]
    at org.jboss.modules.ModuleClassLoader.findClass(ModuleClassLoader.java:198)
    at org.jboss.modules.ConcurrentClassLoader.performLoadClassUnchecked(ConcurrentClassLoader.java:363)
    at org.jboss.modules.ConcurrentClassLoader.performLoadClass(ConcurrentClassLoader.java:351)
    at org.jboss.modules.ConcurrentClassLoader.loadClass(ConcurrentClassLoader.java:93)
    ... 120 more
```

My solution was to place tracing script in non-root package `btrace.scripts`
```
package btrace.scripts;
 
import com.sun.btrace.*;
import com.sun.btrace.annotations.*;
import static com.sun.btrace.BTraceUtils.*;
 
@BTrace
public class TracingScript {
//
}
```
and add the package itself to system packages
```
jboss.modules.system.pkgs=org.jboss.byteman,com.sun.btrace,btrace.scripts
```
– which finally made it work. Now, back to the problem at hand.
