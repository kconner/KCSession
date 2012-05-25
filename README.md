# KCSession

By Kevin Conner. See [kconner.com](http://kconner.com).

## Overview

`KCSession` attempts to simplify the task of inter-app communication by stitching together Bonjour, sockets, streams, and a simple message format. This code expects ARC and iOS 5.

I built this set of classes while creating a Mac level editor for [my iOS game](http://degreesgame.com). I use them to deliver new versions of game levels over wifi while I edit them. You can use this to set up connections and pass serializable Cocoa objects, without having to worry about servers and sockets and ports.

The only requirement is that the objects you send must be serializable with `NSKeyedArchiver`. If you want to use JSON instead of Cocoa objects, that's fine: `NSStrings` are serializable with `NSKeyedArchiver`. You can write your JSON into a string, send the string using `KCSession`, and then parse it on the receiving end.

## Basic usage

### Connecting

1. Make a Bonjour service type string such as `"_myservice._tcp"`.
2. Create a `KCSessionServer` with that type. It will publish itself on Bonjour. Read KCSessionServer.h for details.
3. On the client, search for that type with a `NSNetServiceBrowser`. It will give you an `NSNetService` for the server.
4. Create a `KCNetServiceSession` with the `NSNetService` you found. Read KCNetServiceSession.h for details.

At this point, both the server and the client will have an object inheriting from `KCSession`. These are the two ends of the connecton. 

### Messaging

The `KCSession` class and its delegate handle message passing. Read KCSession.h for details.

1. To send messages, use `-sendMessageWithOpcode:object:`. Try a test message with opcode `1` and a string.
2. To receive messages, implement `-session:didReceiveMessageWithOpcode:object:`.
3. Make an enumeration for the kinds of messages you will send and receive. These are your opcodes.
4. Each message can also include a Cocoa object, or nil. Make sure your objects are serializable with `NSKeyedArchiver`.

In the server's case, the server itself receives `-session:didReceiveMessageWithOpcode:object:` and notifies its delegate.
The server can also broadcast a message to every connected client using `-broadcastMessageWithOpcode:object:`.

## Unfinished business

I ran out of time to make this code perfect before giving a talk on Bonjour.

- Message processing *should* all be done asynchronously on the main thread, but in the server's case, writes are currently synchronous.
- I didn't realize until right before my talk that NSSocketPort only exists on OS X, not on iOS. So, currently KCSessionServer won't compile on iOS. I need to replace the NSSocketPort portion with BSD socket code, which I'm told can be found in the WiTap sample. (Thanks, @Hay!)

