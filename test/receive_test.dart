import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:datagram_socket/src/datagram_socket.dart';
import 'package:test/test.dart';

void main() {
  test('DatagramSocket.listen', () async {
    final socket1 = await DatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final socket2 = await DatagramSocket.bind(InternetAddress.loopbackIPv4, 0);

    expect(socket1.done, completes);
    expect(socket2.done, completes);

    final subscription =
        socket1.listen(null, onError: (e, s) => fail('Unexpected error $e'));

    subscription.onData((datagram) {
      expect(datagram.address, equals(socket2.address));
      expect(datagram.port, equals(socket2.port));

      expect(datagram.data.length, equals(1));

      subscription.onData((datagram) {
        expect(datagram.address, equals(socket2.address));
        expect(datagram.port, equals(socket2.port));

        expect(datagram.data.length, equals(2));

        // Ensure pausing does not drop datagrams.
        subscription.pause(Future.delayed(Duration(seconds: 5)));

        subscription.onData((datagram) {
          expect(datagram.address, equals(socket2.address));
          expect(datagram.port, equals(socket2.port));

          expect(datagram.data.length, equals(3));

          for (var i = 0; i <= 3; i++) {
            socket1.send(Uint8List(i), socket1.address, socket1.port);
          }

          subscription.onData((datagram) {
            expect(datagram.address, equals(socket1.address));
            expect(datagram.port, equals(socket1.port));

            expect(datagram.data.length, equals(1));

            subscription.onData((datagram) {
              expect(datagram.address, equals(socket1.address));
              expect(datagram.port, equals(socket1.port));

              expect(datagram.data.length, equals(2));

              // Ensure pausing does not drop datagrams.
              subscription.pause(Future.delayed(Duration(seconds: 5)));

              subscription.onData((datagram) {
                expect(datagram.address, equals(socket1.address));
                expect(datagram.port, equals(socket1.port));

                expect(datagram.data.length, equals(3));

                socket1.close();
                socket2.close();
              });
            });
          });
        });
      });
    });

    for (var i = 1; i <= 3; i++) {
      socket2.send(Uint8List(i), socket1.address, socket1.port);
    }
  });
}
