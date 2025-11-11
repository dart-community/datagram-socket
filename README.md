## Datagram Socket

Provides a buffered interface to a
[RawDatagramSocket](https://api.dart.dev/dart-io/RawDatagramSocket-class.html)-backed
UDP socket.

The Dart SDK itself does not provide a high-level wrapper around
`RawDatagramSocket` in the same way it provides `Socket` to wrap `RawSocket`.
This package exists to provide such a wrapper, to make it easier to correctly
implement sending and receiving UDP datagrams.
