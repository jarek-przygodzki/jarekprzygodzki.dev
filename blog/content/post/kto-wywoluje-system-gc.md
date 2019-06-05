---
title: "Kto wywołuje System.gc() ?"
date: 2013-07-25
tags: [JVM,BTrace]
draft: false
---
Każdy, kto miał do czynienia z aplikacjami Javy których rozmiar sterty liczy się w gigabajtach wie, że jedną z rzeczy których należy unikać jak ognia jest tzw. odśmiecanie pełne (Full GC). W większości przypadków można to osiągnąć przez rozważny wybór algorytmu GC i staranne dobranie jego parametrów. Nie rozwiązuje to jednak przypadku, gdy cykl pełnego odśmiecania wyzwalany jest przez jawne wywołanie System.gc() co manifestuje się wpisami w logach procesu odśmiecania zaczynających się od Full GC (System) (HotSpot) lub [&lt;sys&gt;](http://publib.boulder.ibm.com/infocenter/javasdk/v6r0/topic/com.ibm.java.doc.diagnostics.60/diag/tools/gcpd_verbosegc_triggered.html) (IBM J9).
W przypadku maszyny wirtualnej IBM (IBM J9) w celu wykrycia miejsc skąd pochodzą te wywołania wystarczy dodać odpowiednią opcję do parametrów uruchomieniowych maszyny wirtualnej
```
-Xtrace:print=mt,methods={java/lang/System.gc},trigger=method{java/lang/System.gc,jstacktrace}
```
W przypadku maszyny Oracle HotSpot sprawa jest nieco trudniejsza. Początkowo planowałem wykorzystać [instrumentalizację](http://docs.oracle.com/javase/6/docs/api/java/lang/instrument/Instrumentation.html) przez [BCEL](http://commons.apache.org/proper/commons-bcel/) ale w końcu zdecydowałem się na wykorzystanie [BTrace](https://github.com/btraceio/btrace). W tym celu napisałem prosty próbnik
```
import com.sun.btrace.annotations.*; 
import static com.sun.btrace.BTraceUtils.*; 
@BTrace class SystemGcCalls {    
    @OnMethod(clazz="java.lang.System", method="gc")    
    public void printStack() {
        Threads.jstack();
        println("");    
    } 
}
```
i zainstalowałem go dla testu w działającej instalacji Eclipse (o które wiedziałem, że Full GC jest wywoływane bez potrzeby co wyłączyłem, [świadom konsekwencji](http://stackoverflow.com/questions/12847151/setting-xxdisableexplicitgc-in-production-what-could-go-wrong), za pomocą opcji `-XX:+DisableExplicitGC`).
```
$ ./btrace <pid> /Users/Jarek/Code/BTrace/SystemGcCalls.java
```
Wkrótce moim oczom ukazały się stosy wywołań
```
java.lang.System.gc(System.java)
org.eclipse.ui.internal.ide.application.IDEIdleHelper$3.run(IDEIdleHelper.java:181)
org.eclipse.core.internal.jobs.Worker.run(Worker.java:53)
```
Okazuje się, że klasa [org.eclipse.ui.internal.ide.application.IDEIdleHelper](http://grepcode.com/file/repository.grepcode.com/java/eclipse.org/4.2/org.eclipse.ui.ide/application/1.0.400/org/eclipse/ui/internal/ide/application/IDEIdleHelper.java) próbuje wykrywać, kiedy IDE jest bezczynne i wywołuje wtedy `System.gc()`. Po prostu cudownie! Analizując kod klasy IDEIdleHelper okazuje się, że można doprowadzić do tego, że System.gc() nie będzie wywołane przez IDE ustawiając parametr „ide.gc” w eclipse.ini
```
-Dide.gc=false
```
Dalsza analiza wskazuje na błędy dotyczące tego zachowania zgłoszone do Eclipse Bugzilla: [Bug 118335](https://bugs.eclipse.org/bugs/show_bug.cgi?id=118335) i [Bug 136855](https://bugs.eclipse.org/bugs/show_bug.cgi?id=136855). Jest to kolejny przykład na to, że zakładanie że wie się lepiej od JVM kiedy przeprowadzić odśmiecanie rzadko prowadzi do czegokolwiek dobrego.