---
title: "ECJ – Eclipse Compiler for Java"
date: 2012-12-17
tags: []
draft: false
---
Nie wszyscy o tym wiedzą, ale Eclipse dostarcza i używa własnego kompilatora Javy – ECJ – zamiast standardowego [javac](http://docs.oracle.com/javase/6/docs/technotes/guides/javac/index.html). Kompilator umieszczony jest w plug-inie [JDT Core](http://www.eclipse.org/projects/project.php?id=eclipse.jdt.core) i dostępny zarówno jako cześć **Eclipse IDE for Java Developers** jak i jako samodzielna aplikacja  do wykorzystania zarówno z linii poleceń jak i programistycznego. Dlaczego ECJ jest tak interesujący? Jak pisze [Wayner](https://www.ibm.com/developerworks/mydeveloperworks/blogs/Wayner/entry/did_you_know_that_eclipse?lang=en)
> It does wonderful things. My personal favourite thing about the Eclipse Java compiler is the fact that it will compile code that contains errors. That is, when you compile code that has errors in it, the compiler will flag those errors for you and then generate the .class file anyway. You can actually run and debug the code and, should the runtime actually run into your errors, it will then throw an exception.

## Użycie z wiersza poleceń
Jest  bardzo proste – po wpisaniu
```
java -jar /apps/ecj-4.2.1.jar
```
uzyskujemy niezbędną pomoc. Przkładowo, klasę `MyApp`.java można skompilować następujaco
```
java -jar /apps/ecj-4.2.1.jar MyApp.java
```
Znacznie ciekawsze jest
## Wykorzystanie programistyczne
```
def ecjJar = '/apps/ecj-4.2.1.jar' as File
def loader = this.class.classLoader.rootLoader
loader.addURL(ecjJar.toURI().toURL())
 
 
def commandLine = '-classpath rt.jar MyApp.java'
 
org.eclipse.jdt.internal.compiler.batch.Main.compile(
    commandLine, 
    new PrintWriter(System.out), 
    new PrintWriter(System.err))
```
Oczywiście, jest to tylko [wierzchołek góry lodowej](http://help.eclipse.org/indigo/index.jsp?topic=/org.eclipse.jdt.doc.isv/guide/jdt_api_compile.htm) możliwości ECJ który oferuje dużo więcej niż standardowy kompilator z JDK, np. [wyszukiwanie w kodzie źródłowym](http://help.eclipse.org/indigo/topic/org.eclipse.jdt.doc.isv/guide/jdt_api_search.htm).

[eclipse / eclipse.jdt.core on GitHub](https://github.com/eclipse/eclipse.jdt.core)