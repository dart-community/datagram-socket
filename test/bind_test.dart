import 'dart:io';

import 'package:datagram_socket/src/datagram_socket.dart';
import 'package:test/test.dart';

void main() {
  group('DatagramSocket.bind', () {
    test('IPv4', () async {
      final socket1 = await DatagramSocket.bind(InternetAddress.anyIPv4, 0);
      expect(socket1.address, equals(InternetAddress.anyIPv4));
      expect(socket1.port, isNonZero);
      await socket1.close();

      final socket2 =
          await DatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      expect(socket2.address, equals(InternetAddress.loopbackIPv4));
      expect(socket2.port, isNonZero);
      final availablePort = socket2.port;
      await socket2.close();

      final socket3 = await DatagramSocket.bind(
          InternetAddress.loopbackIPv4, availablePort);
      expect(socket3.address, equals(InternetAddress.loopbackIPv4));
      expect(socket3.port, equals(availablePort));
      await socket3.close();
    });

    test('IPv6', () async {
      final socket1 = await DatagramSocket.bind(InternetAddress.anyIPv6, 0);
      expect(socket1.address, equals(InternetAddress.anyIPv6));
      expect(socket1.port, isNonZero);
      await socket1.close();

      final socket2 =
          await DatagramSocket.bind(InternetAddress.loopbackIPv6, 0);
      expect(socket2.address, equals(InternetAddress.loopbackIPv6));
      expect(socket2.port, isNonZero);
      final availablePort = socket2.port;
      await socket2.close();

      final socket3 = await DatagramSocket.bind(
          InternetAddress.loopbackIPv6, availablePort);
      expect(socket3.address, equals(InternetAddress.loopbackIPv6));
      expect(socket3.port, equals(availablePort));
      await socket3.close();
    });

    test('hostname', () async {
      final socket1 = await DatagramSocket.bind('localhost', 0);
      expect(socket1.address.host, equals('localhost'));
      expect(socket1.port, isNonZero);
      final availablePort = socket1.port;
      await socket1.close();

      final socket2 = await DatagramSocket.bind('localhost', availablePort);
      expect(socket1.address.host, equals('localhost'));
      expect(socket2.port, equals(availablePort));
      await socket2.close();
    });
  });
}
