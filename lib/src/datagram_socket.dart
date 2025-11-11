import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// An interface to a UDP socket.
///
/// A [DatagramSocket] receives UDP [Datagram]s which are made available by the
/// [Stream] interface on this class, and can be sent using the [StreamSink]
/// interface or the [send] method of this class.
class DatagramSocket extends Stream<Datagram> implements StreamSink<Datagram> {
  final RawDatagramSocket _raw;
  final StreamController<Datagram> _incomingDatagrams = StreamController();
  final StreamController<Datagram> _outgoingDatagrams = StreamController();

  final Completer<void> _doneCompleter = Completer();

  @override
  Future<dynamic> get done => _doneCompleter.future;

  /// The address used by this socket.
  InternetAddress get address => _raw.address;

  /// The port used by this socket.
  int get port => _raw.port;

  /// Whether IPv4 broadcast is enabled.
  ///
  /// IPv4 broadcast needs to be enabled by the sender for sending IPv4
  /// broadcast packages. By default IPv4 broadcast is disabled.
  ///
  /// For IPv6 there is no general broadcast mechanism. Use multicast instead.
  bool get broadcastEnabled => _raw.broadcastEnabled;
  set broadcastEnabled(bool value) => _raw.broadcastEnabled = value;

  /// The maximum network hops for multicast packages originating from this
  /// socket.
  ///
  /// For IPv4 this is referred to as TTL (time to live).
  ///
  /// By default this value is 1 causing multicast traffic to stay on the local
  /// network.
  int get multicastHops => _raw.multicastHops;
  set multicastHops(int value) => _raw.multicastHops = value;

  /// Whether multicast traffic is looped back to the host.
  ///
  /// By default multicast loopback is enabled.
  bool get multicastLoopback => _raw.multicastLoopback;
  set multicastLoopback(bool value) => _raw.multicastLoopback = value;

  DatagramSocket._fromRawSocket(this._raw) {
    // Delay read events until we have a listener.
    _raw.readEventsEnabled = false;
    // Delay write events until we have a pending datagram.
    _raw.writeEventsEnabled = false;

    _incomingDatagrams
      ..onListen = () {
        _raw.readEventsEnabled = true;
      }
      ..onPause = () {
        _raw.readEventsEnabled = false;
      }
      ..onResume = () {
        _raw.readEventsEnabled = true;
      }
      ..onCancel = () {
        _raw.readEventsEnabled = false;
      };

    // Errors are never added to _outgoingDatagrams, see [addError].
    final outgoingSubscription = _outgoingDatagrams.stream.listen(
      null,
      onDone: () {
        _raw.close();
      },
    );

    Datagram? pendingDatagram;
    void send() {
      try {
        assert(pendingDatagram != null);

        final sent = _raw.send(
          pendingDatagram!.data,
          pendingDatagram!.address,
          pendingDatagram!.port,
        );

        // Assume a return of 0 when sending 0 bytes means the datagram was
        // successfully sent.
        // See https://github.com/dart-lang/sdk/issues/61942
        if (sent < pendingDatagram!.data.length) {
          assert(!outgoingSubscription.isPaused);
          outgoingSubscription.pause();
          _raw.writeEventsEnabled = true;
        } else {
          pendingDatagram = null;
          if (outgoingSubscription.isPaused) {
            outgoingSubscription.resume();
          }
        }
      } catch (e, s) {
        _incomingDatagrams.addError(e, s);
      }
    }

    outgoingSubscription.onData((d) {
      assert(pendingDatagram == null);
      pendingDatagram = d;
      send();
    });

    _raw.listen(
      cancelOnError: false,
      (event) {
        switch (event) {
          case RawSocketEvent.read:
            final datagram = _raw.receive();
            if (datagram == null) return;
            _incomingDatagrams.add(datagram);
          case RawSocketEvent.write:
            send();
          case RawSocketEvent.readClosed:
            assert(false, 'UDP Socket received readClosed event');
          case RawSocketEvent.closed:
        }
      },
      onError: _incomingDatagrams.addError,
      onDone: () {
        assert(_outgoingDatagrams.isClosed);
        _incomingDatagrams.close();
        _doneCompleter.complete();
      },
    );
  }

  /// Binds a socket to the given host and port.
  ///
  /// When the socket is bound and has started listening on [port], the returned
  /// future completes with the [DatagramSocket] of the bound socket.
  ///
  /// The [host] can either be a [String] or an [InternetAddress]. If host is a
  /// [String], bind will perform a [InternetAddress.lookup] and use the first
  /// value in the list. To listen on the loopback interface, which will allow
  /// only incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or [InternetAddress.loopbackIPv6]. To allow
  /// for incoming connection from any network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to bind to all
  /// interfaces, or use the IP address of a specific interface.
  ///
  /// The [reuseAddress] should be set for all listeners that bind to the same
  /// address. Otherwise, it will fail with a [SocketException].
  ///
  /// The [reusePort] specifies whether the port can be reused.
  ///
  /// The [ttl] sets time to live of a datagram sent on the socket.
  static Future<DatagramSocket> bind(
    dynamic host,
    int port, {
    bool reuseAddress = true,
    bool reusePort = false,
    int ttl = 1,
  }) async {
    final rawSocket = await RawDatagramSocket.bind(
      host,
      port,
      reuseAddress: reuseAddress,
      reusePort: reusePort,
      ttl: ttl,
    );

    return DatagramSocket._fromRawSocket(rawSocket);
  }

  /// Joins a multicast group.
  ///
  /// If an error occur when trying to join the multicast group, an exception is
  /// thrown.
  void joinMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      _raw.joinMulticast(group, interface);

  /// Leaves a multicast group.
  ///
  /// If an error occur when trying to join the multicast group, an exception is
  /// thrown.
  void leaveMulticast(InternetAddress group, [NetworkInterface? interface]) =>
      _raw.leaveMulticast(group, interface);

  /// Reads low level information about the RawSocket.
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Returns [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure.
  Uint8List getRawOption(RawSocketOption option) => _raw.getRawOption(option);

  /// Customizes the [RawDatagramSocket].
  ///
  /// See [RawSocketOption] for available options.
  ///
  /// Throws an [OSError] on failure.
  void setRawOption(RawSocketOption option) => _raw.setRawOption(option);

  /// {@template add}
  /// Asynchronously sends a [Datagram].
  ///
  /// Transmission of the [datagram] may be delayed until the
  /// [RawDatagramSocket] is ready to write.
  ///
  /// If an error occurs while sending the [datagram], it will be added to the
  /// [Stream] interface of this [DatagramSocket].
  ///
  /// The maximum size of a IPv4 UDP datagram is 65535 bytes (including both
  /// data and headers) but the practical maximum size is likely to be much
  /// lower due to operating system limits and the network's maximum
  /// transmission unit (MTU).
  ///
  /// Some IPv6 implementations may support payloads up to 4GB (see RFC-2675)
  /// but that support is limited (see RFC-6434) and has been removed in later
  /// standards (see RFC-8504).
  ///
  /// [Empirical testing by the Chromium team](https://groups.google.com/a/chromium.org/g/proto-quic/c/uKWLRh9JPCo)
  /// suggests that payloads later than 1350 cannot be reliably received.
  /// {@endtemplate}
  @override
  void add(Datagram datagram) {
    _outgoingDatagrams.add(datagram);
  }

  /// {@macro add}
  void send(List<int> buffer, InternetAddress address, int port) {
    if (buffer is! Uint8List) {
      buffer = Uint8List.fromList(buffer);
    }
    add(Datagram(buffer, address, port));
  }

  /// Unsupported operation on sockets.
  ///
  /// This method, which is inherited from [StreamSink], is not supported on
  /// sockets, and must not be called. Sockets have no way to report errors,
  /// so any error passed in to a socket using addError would be lost.
  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    throw UnsupportedError('Cannot add errors to a DatagramSocket');
  }

  @override
  Future<dynamic> addStream(Stream<Datagram> stream) {
    return _outgoingDatagrams.addStream(stream);
  }

  @override
  StreamSubscription<Datagram> listen(
    void Function(Datagram event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _incomingDatagrams.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<dynamic> close() {
    if (!_outgoingDatagrams.isClosed) {
      _outgoingDatagrams.close();
    }

    return done;
  }
}
