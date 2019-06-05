---
title: "Implemeting CIMD Protocol in Python, sans I/O"
date: 2019-02-07T22:01:47+01:00
draft: true
---

Historically people have been implementing network protocols with the I/O parts baked in. Cory Benfield's PyCon US 2016 talk [https://www.youtube.com/watch?v=7cC3_jGwl_U] provides a nice overview as to why designing protocol implementations that perform no I/O provides a number of useful benefits, both to the implemenation itself and to clients using it.  This doesn't mean simply abstracting out the I/O so that you can plug in I/O code that can conform to your abstraction. No, to work with any sort of I/O (so that they can be used by both synchronous and asynchronous I/O and APIs on different platforms) the network protocol library needs to operate sans I/O; working directly off of the bytes or text coming off the network.  See https://sans-io.readthedocs.io/ for much more detailed justification.



Writing I/O-Free (Sans-I/O) CIMD protocol implementations

## What is CIMD?
Computer Interface to Message Distribution (CIMD) is a proprietary short message service centre protocol developed Nokia. In Poland it's supported by all major carriers other than Orange (which uses similiar EMI-UCP)

## Why
There's no CIMD implementaion in Python.  Good enough reasonn to start one.

## Framing
Network protocols, at a fundamental level all consume and produce byte sequences that are transmited over some kind of network.
The core of the problem here is that the  protocols are message based and TCP is a stream protocol. These bytes are delivered in chunks. The purpose of framing is to decode the chunked stream into a sequence of messages. Note that there may be several chunks per message or several messages per chunk.

The simple summary is: we have an endless incoming stream of bytes, from which we need to deduce structured data frames

Each CIMD protocol message starts with STX (0x02) and ends with ETX (0x03). In ABNF notation CIMD frame looks like this

```
STX=%x02
ETX=%x03

cimd-frame = STX / cimd-frame-data / ETX
```

```
# divide binary stream into frames

class Buffer(object):
    def __init__(self):
        self.buffer = bytearray()
        self.bytes_used = 0
    
HEADER=b'\x61'
FOOTER=b'\x62'



class FrameDecoder:
    (WAIT_HEADER, IN_MSG) = range(2)
    def __init__(self):
        self.buffer = bytearray()
        self.state = self.WAIT_HEADER

    def feed(self, new_bytes):
        self.buffer += new_bytes

    def next_chunk(self, new_bytes):
        self.feed(new_bytes)
    
    def process_buffer(self):
        if self.state == self.WAIT_HEADER:
            
        elif self.state == self.IN_MSG:
            if byte == self.footer:
                self.state = self.WAIT_HEADER

    
class FrameDecoder
    def next_chunk(self, buffer: Buffer) -> Vec<Frame>
```


stream based protocol

datagram based protocols, it is usually important to preserve the datagram boundaries




https://users.rust-lang.org/t/how-to-work-with-network-sockets/5385/2
https://sans-io.readthedocs.io/how-to-sans-io.html#how-to-write-i-o-free-protocol-implementations
https://snarky.ca/network-protocols-sans-i-o/
