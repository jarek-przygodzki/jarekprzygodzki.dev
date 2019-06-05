---
title: "Scala partial function literal"
date: 2016-06-27
tags: [Scala]
draft: false
---
In Scala there’s no literal for partial function types. You have to give the exact signature of the PartialFunction

```
val pf: PartialFunction[Double, Double] = { case x if x >= 0 => Math.sqrt(x) }
```
Though I personally prefer to use type ascription bacause you can define and lift in the same place if needed.
```
val pf = { case x if x >= 0 => Math.sqrt(x) } : PartialFunction[Double, Double]
```
It’s unwieldy, but I’ve learned to live with it.

But lately someone (can’t remember who – sorry!) told me that you don’t need a literal because you can write your own type alias and use it with infix operator concise syntax.
```
type :=>[A, B] = PartialFunction[A, B]

val pf: Double :=> Double = { case x if x >= 0 => Math.sqrt(x) }
```