---
title: "Monitorowanie i przechwytywanie ruchu sieciowego kontenerów Dockera"
date: 2018-03-12
tags: [DevOps,Docker,Linux]
draft: false
---
Ten wpis to krótki tutorial jak przechwycić ruch sieciowych z wybranych kontenerów Dockera, np. usług uruchomionych w ramach klastra Docker Swarm.

Na początek minimum teorii. Docker używa [przestrzeni nazw](https://en.wikipedia.org/wiki/Linux_namespaces) w celu zapewnienia izolacji procesów. Przestrzenie nazw (których od jądra 4.10 jest 7 rodzajów) są cechą jądra systemu Linux, która pozwala na izolację i wirtualizację zasobów systemowych. Funkcja przestrzeni nazw jest taka sama dla każdego typu: każdy proces jest powiązany z przestrzenią nazw danego rodzaju i może wykorzystywać zasoby powiązane z tą przestrzenią, oraz, w stosownych przypadkach, przestrzeniami nazw potomków. W kontekście ruchu sieciowego interesuje nas przestrzeń nazw dla sieci (network namespace).

Sieciowe przestrzenie nazw wirtualizują stos sieciowy – umożliwiają odizolowanie całego podsystemu sieciowego dla grupy procesów. Każda przestrzeń nazw posiada prywatny zestaw adresów IP, własną tabelę routingu, listę gniazd, tabelę śledzenia połączeń, zaporę i inne zasoby związane z siecią.

W celu przechwycenia ruchu sieciowego kontenera musimy uruchomić nasz program przechwytujący (tdpdump, tshark, etc.) w kontekście właściwej przestrzeni sieciowej docelowego kontenera. Jak to zrobić? Istnieją dwa typowe sposoby, w zależności od tego, czy chcemy skorzystać z oprogramowania dostępnego w systemie hosta czy też wolimy uruchomić stosowne narzędzia w kontenerze.

## nsenter
nsenter umożliwia uruchomienie procesu (domyślnie shella) we wskazanych przestrzeniach nazw docelowego procesu. W przypadku kontenerów Dockera typowy sposób postępowania polega na tym, że najpierw znajdujemy identyfikator kontenera, a następnie jego PID w przestrzeni procesów hosta.

```
mkdir ~/data
CID=$(docker ps --format {{.Names}} | grep CONTAINER_NAME)
PID=$(docker inspect --format {{.State.Pid}} $CID)
nsenter --target $PID --net tcpdump -i any \
        -w ~/data/$(hostname)-$(date +%Y-%m-%d_%H-%M).pcap
```
Przełącznik `-i any` powoduje przechwytywanie ruchu z wszystkich interfejsów sieciowych (za pomocą `tcpdump -D ` lub ``ip addr show` można sprawdzić jakich dokładnie). Jeśli wersja nsenter dostępna w repozytorium dystrybucji nie jest odpowiednia można zainstalować aktualną w sposób opisany [tutaj](https://github.com/jpetazzo/nsenter).

## Uruchomienie kontenera z narzędziami w przestrzeni sieciowej docelowego kontenera
Uruchamiając kontener można użyć istniejącej przestrzeni sieciowej związanej z kontenerem który chcemy monitorować; stosując opcję `–net==container:<name|id>` można uruchomić procesy używając wirtualnego stosu sieciowego, który został już utworzony w innym kontenerze.
Ta opcja jest wygodna, gdy nie możemy/nie chcemy instalować niczego w systemie hosta. Często używanym do tego celu kontenerem z mnóstwem dostępnych narzędzie jest [nicolaka/netshoot](https://hub.docker.com/r/nicolaka/netshoot/)

```
mkdir ~/data
CID=$(docker ps --format {{.Names}} | grep CONTAINER_NAME)
docker run --rm -it  -v ~/data:/data \
        --net=container:$CID nicolaka/netshoot \
        tcpdump -i any -w /data/$(hostname)-$(date +%Y-%m-%d_%H-%M).pcap
```