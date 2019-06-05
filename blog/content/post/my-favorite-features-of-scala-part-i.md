---
title: "My favorite features of Scala – part I"
date: 2015-07-29
tags: [Scala]
draft: false
---
During the last few months I’ve spent substantial amount of free time learning Scala and consider it time well spent. This article is first part describing my favorite features of Scala

## Extractor Objects
Whenever you define a val or var, what comes after the keyword is not simply an identifier but rather a pattern.
```
val regex = "(\\d+)/(\\d+)/(\\d+)".r
val regex(year, month, day) = "2015/7/29"
```
The `val regex` is an instance of Regex, and when you use it in a pattern, you’re implicitly calling `regex.unapplySeq` , which extracts the match groups into a `Seq[String]`, the elements of which are assigned in order to the variables year, month, and day.