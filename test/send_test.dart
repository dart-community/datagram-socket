import 'dart:io';

import 'package:datagram_socket/datagram_socket.dart';
import 'package:test/test.dart';

void main() {
  test('DatagramSocket.send', () async {
    // Normal send.
    final socket1 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket1.send([0], InternetAddress.loopbackIPv4, 1);
    expect(socket1.drain(), completes);
    await socket1.close();

    // Empty payload.
    final socket2 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket2.send([], InternetAddress.loopbackIPv4, 1);
    expect(socket2.drain(), completes);
    await socket2.close();

    // Bad port: error reported by OS.
    final socket3 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket3.send([0], InternetAddress.loopbackIPv4, 0);
    expect(socket3.drain(), throwsA(isA<SocketException>()));
    await socket3.close();

    // Bad port: error reported by Dart.
    final socket4 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket4.send([0], InternetAddress.loopbackIPv4, -10);
    expect(socket4.drain(), throwsA(isA<ArgumentError>()));
    await socket4.close();

    // Send to 0.0.0.0
    final socket5 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket5.send([0], InternetAddress.anyIPv4, 1);
    expect(socket5.drain(), completes);
    await socket5.close();

    // Invalid address family.
    final socket6 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket6.send([0], InternetAddress.loopbackIPv6, 1);
    expect(socket6.drain(), throwsA(isA<SocketException>()));
    await socket6.close();
  });
}
