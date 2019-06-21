---
title: "Converting Old Java Future To CompletableFuture Monadic Goodness"
date: 2019-06-21
tags: ["java", "concurrency", "parallelism"]
draft: false
---

In 2004 Java 5 was released introducing a load of new features: generics, autoboxing, annotations, and… `java.util.concurrent`. You could use the exciting new `java.util.concurrent.Future` class to represent the result of an asynchronous computation, but it did not have any methods to combine these computations withoung blocking to get a result.

In Java 8, the `CompletableFuture` class was introduced to solve that problem. It allows to register callbacks to be executed once the computation is complete. The `CompletionStage` interfaces (implemented by CompletableFuture) defines the contract for an asynchronous computation step that can be combined with other steps and, in turn, makes possible to efficiently support many operation that the basic `Future` interface cannot.


# Problem
Many libraries still do not support the `CompletableFuture`, and never will. How to convert Future to CompletableFuture and use the power of new API?

The usual approch is to sacrifice a thread and block. 

{{< highlight plain>}}
<T> CompletableFuture<T> blockInNewThread(Future<T> source) {
    CompletableFuture<T> target = new CompletableFuture<>();
    // or `ThreadFactory.newThread` or `Executor.execute`
    new Thread(() -> {
        try {
            // Thread is never interrupted.
            target.complete(getUninterruptibly(source));
        } catch (ExecutionException e) {
            target.completeExceptionally(e.getCause());
        }
    }).start();
    return target;
}

<V> V getUninterruptibly(Future<V> future) throws ExecutionException {
    for (; ; ) {
        try {
            return future.get();
        } catch (InterruptedException ignore) {
        }
    }
}
{{< / highlight >}}

The obvious problem with this approach is, that for each Future, a thread will be blocked to wait for the result. It works well for a few futures, but what if we have thousands of them? How to be notified, without blocking, when a task represented by `j.u.c.Future` completes since it has no callback methods? 

It might be possible to do better than blocking thread for each future if we are willing to sacrifice some latency. For many use cases, like background tasks, it's an acceptable trade-off. 
Instead of blockig, we can periodically poll future completion status. That way, we can monitor many futures using only one thread

{{< highlight plain>}}

pollSchedule = scheduler.scheduleAtFixedRate(() -> poll(), pollPeriod, pollPeriod, pollUnit);

void poll() {
    while (pendingPolls.hasNext()) {
        Poll poll = pendingPolls.next();
        if (poll.isReady()) {
            poll.completeSync();
            pendingPolls.remove();
        }
    }
}

{{< / highlight >}}


How to use?

{{< highlight plain>}}
Future oldFuture = ...;
// poll every 100 ms - default
Poller poller = new Poller(100, TimeUnit.MILLISECONDS);

CompletableFuture cf = poller.register(oldFutue);


{{< / highlight >}}

Full source code is [on GitHub](https://github.com/jarek-przygodzki/future-poller).