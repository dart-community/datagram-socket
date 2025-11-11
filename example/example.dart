// ignore_for_file: unused_local_variable
import 'dart:io';
import 'dart:typed_data';

import 'package:datagram_socket/datagram_socket.dart';

void main() async {
  final serverAddress = (await InternetAddress.lookup('pool.ntp.org')).first;
  final clientSocket = await DatagramSocket.bind(
    serverAddress.type == InternetAddressType.IPv6
        ? InternetAddress.anyIPv6
        : InternetAddress.anyIPv4,
    0,
  );

  final ntpQuery = Uint8List(48);
  ntpQuery[0] = 0x23; // See RFC 5905 7.3

  clientSocket.send(ntpQuery, serverAddress, 123);

  final datagram = await clientSocket.first;

  // Parse `datagram.data`

  clientSocket.close();
}
