---
title: "Play! Framework – część I"
date: 2016-07-12
tags: [PlayFramework]
draft: false
---
Z związku z moim zainteresowaniem Scalą i Akką naturalnym jest zajęcie się ostatnim elementem stosu reaktywnych technologii dla JVM od Typesafe – frameworkiem Play. Niniejszy wpis stanowi, mam nadzieję, pierwszy z serii wpisów opisujących moją przygodę z tym frameworkiem.

## Czym jest Play?
Play jest moim zdaniem najlepszym frameworkiem ogólnego przeznaczenia dla JVM
Ogólnie rzeczy ujmując Play to implementacja wzorca MVC w oparciu o model aktów Akka połączona ze środowiskiem do zarządzania projektem i uruchamiania go

## Co w nim tak bardzo mi się podoba?
Jednym z głównych filarów architektonicznych Play jest podejście bezstanowe i asynchroniczne.  W Play nie ma tradycyjnej „sesji”. Takie podejście nastręcza czasami pewne trudności, ale są one z nawiązką rekompensowane przez zalety takie jak łatwość horyzontalnego skalowania i wsparcie dla technologi reaktywnych. I Scala. Uwielbiam Scalę.
## Zacznijmy jednak od podstaw
Szkielet aplikacji Play można łatwo wygenerować za pomocą narzędzia Typesafe Activator  – `activator new [name] [template-id]` – ale nie jest dobry sposób na rozpoczęcie przygody z Play.
```
activator new my-play-app play-scala
```
Zacznijmy więc od minimalnej aplikacji Play do której będziemy dodawać kolejne elementy w miarę potrzeby. Minimalna aplikacja jest naprawdę niewielka i składa się z czterech plików z których jeden (application.conf) jest pusty a jeden (build.properties) tak naprawdę  opcjonalny.
```
$ ls -R
.:
build.properties build.sbt conf/ project/
 
./conf:
application.conf
 
./project:
plugins.sbt
```
build.sbt
```
name := """my-play-app"""
 
version := "1.0-SNAPSHOT"
 
lazy val root = (project in file(".")).enablePlugins(PlayScala)
 
scalaVersion := "2.11.7"
 
resolvers += "scalaz-bintray" at "http://dl.bintray.com/scalaz/releases"
````
project/plugins.sbt
```
// The Play plugin
addSbtPlugin("com.typesafe.play" % "sbt-plugin" % "2.5.4")
```
project/build.properties
```
sbt.version=0.13.11
```
Nie jest to co prawda zbyt przydatna aplikacja – ale kompiluje się i uruchamia bez przeszkód o czym możemy się przekonać wydając polecenie `activator ~run` w katalogu aplikacji.

Skrypt wykonujący poszczególne krotki jest dostępny jako [Gist](https://gist.github.com/jarek-przygodzki/ce8e8777df8a72b8e07ef3fd173563c1)
```
bash <(curl -fsSL https://git.io/vKW88) my-play-app
```
