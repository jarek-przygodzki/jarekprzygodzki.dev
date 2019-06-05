---
title: "Podstawy Akka – izolacja aktorów"
date: 2016-07-05
tags: [Akka]
draft: true
---
Aktorzy w Akka mogą się komunikować tylko przez asynchroniczne przesyłanie komunikatów. Do wysłania komunikatu potrzebny jest uchwyt na aktora (lub selecja) który może być uzyskany w wyniku

- rodzicielstwa (parenthood) – aktor A tworzy B więc posiada na niego referencję
- obdarowania (endowment) – kiedy A tworzy B może mu przekazać cześć lub wszystkie uchwyty które sam posiada
- przedstawienia (introduction) –  jeśli aktor A posiada uchwyty na B i C może wysłać do C komunikat zawierający uchwyt do B. B może wówczas zachować ten uchwyt do dalszego użycia
- selekcji – w praktyce selekcja jest bardzo podobna do uchwytu. Aktor może wyszukać innych aktorów po nazwach stosując m.in wyrażenia wieloznaczne (context.actorSelection(„/user/*”)) i ścieżki względne (context.actorSelection(„../*”))

[http://doc.akka.io/docs/akka/current/general/addressing.html](http://doc.akka.io/docs/akka/current/general/addressing.html)