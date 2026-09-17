import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shonenx/features/sync/domain/models/seeder_blob.dart';
import 'package:shonenx/features/sync/network/seeder_storage_manager.dart';

/// Represents a network message exchanged between KuroX peers.
class P2PMessage {
  final String type; // 'hello', 'get_blob', 'blob_data', 'seed_offer', 'pex'
  final Map<String, dynamic> payload;

  const P2PMessage({required this.type, required this.payload});

  Map<String, dynamic> toJson() => {'type': type, 'payload': payload};

  factory P2PMessage.fromJson(Map<String, dynamic> json) => P2PMessage(
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
      );

  Uint8List toBytes() => Uint8List.fromList(utf8.encode('${jsonEncode(toJson())}\n'));
}

/// Manages direct TCP socket connections and P2P protocol messaging between KuroX nodes.
class P2PChannel {
  final String localPeerId;
  final SeederStorageManager _storageManager;
  final void Function(SeederBlob blob)? onBlobReceived;
  final void Function(String peerId, String ip, int port)? onPeerDiscovered;

  ServerSocket? _serverSocket;
  int? _localPort;
  final List<Socket> _activeSockets = [];

  P2PChannel({
    required this.localPeerId,
    required SeederStorageManager storageManager,
    this.onBlobReceived,
    this.onPeerDiscovered,
  }) : _storageManager = storageManager;

  int? get localPort => _localPort;
  int get activeConnectionsCount => _activeSockets.length;

  /// Starts the local server socket to listen for incoming peer connections.
  Future<int> startServer({int port = 0}) async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _localPort = _serverSocket!.port;

      _serverSocket!.listen(
        _handleIncomingSocket,
        onError: (_) {},
        cancelOnError: false,
      );

      return _localPort!;
    } catch (_) {
      return 0;
    }
  }

  /// Stops server and closes all active sockets.
  Future<void> stop() async {
    try {
      for (final s in _activeSockets) {
        s.destroy();
      }
      _activeSockets.clear();
      await _serverSocket?.close();
      _serverSocket = null;
    } catch (_) {}
  }

  /// Connects to a remote peer by IP and port, performs handshake, and queries for blobs.
  Future<Socket?> connectToPeer(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 4));
      _activeSockets.add(socket);

      _setupSocketListener(socket);

      // Send HELLO handshake
      final hello = P2PMessage(
        type: 'hello',
        payload: {
          'peerId': localPeerId,
          'port': _localPort,
        },
      );
      socket.add(hello.toBytes());

      return socket;
    } catch (_) {
      return null;
    }
  }

  /// Broadcasts a seed offer to all currently connected peers.
  void broadcastSeedOffer(SeederBlob blob) {
    final msg = P2PMessage(
      type: 'seed_offer',
      payload: blob.toJson(),
    );
    final bytes = msg.toBytes();

    for (final socket in List<Socket>.from(_activeSockets)) {
      try {
        socket.add(bytes);
      } catch (_) {
        _activeSockets.remove(socket);
      }
    }
  }

  /// Requests a blob for a target peer ID from all connected peers.
  void requestBlob(String targetPeerId) {
    final msg = P2PMessage(
      type: 'get_blob',
      payload: {'targetPeerId': targetPeerId},
    );
    final bytes = msg.toBytes();

    for (final socket in List<Socket>.from(_activeSockets)) {
      try {
        socket.add(bytes);
      } catch (_) {
        _activeSockets.remove(socket);
      }
    }
  }

  void _handleIncomingSocket(Socket socket) {
    _activeSockets.add(socket);
    _setupSocketListener(socket);

    // Send HELLO back
    final hello = P2PMessage(
      type: 'hello',
      payload: {
        'peerId': localPeerId,
        'port': _localPort,
      },
    );
    try {
      socket.add(hello.toBytes());
    } catch (_) {}
  }

  void _setupSocketListener(Socket socket) {
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _processIncomingMessage(socket, line),
          onError: (_) {
            _activeSockets.remove(socket);
            socket.destroy();
          },
          onDone: () {
            _activeSockets.remove(socket);
            socket.destroy();
          },
          cancelOnError: false,
        );
  }

  Future<void> _processIncomingMessage(Socket socket, String line) async {
    if (line.trim().isEmpty) return;
    try {
      final jsonMap = jsonDecode(line) as Map<String, dynamic>;
      final msg = P2PMessage.fromJson(jsonMap);

      switch (msg.type) {
        case 'hello':
          final remotePeerId = msg.payload['peerId'] as String?;
          final remotePort = msg.payload['port'] as int?;
          if (remotePeerId != null && remotePort != null) {
            onPeerDiscovered?.call(remotePeerId, socket.remoteAddress.address, remotePort);
          }
          break;

        case 'get_blob':
          final targetPeerId = msg.payload['targetPeerId'] as String?;
          if (targetPeerId != null) {
            final localBlob = await _storageManager.getBlob(targetPeerId);
            if (localBlob != null) {
              final resp = P2PMessage(
                type: 'blob_data',
                payload: localBlob.toJson(),
              );
              socket.add(resp.toBytes());
            }
          }
          break;

        case 'seed_offer':
          // Another peer is asking us to seed their blob!
          final blob = SeederBlob.fromJson(msg.payload);
          await _storageManager.saveBlob(blob);
          onBlobReceived?.call(blob);
          break;

        case 'blob_data':
          // Delivery of a requested blob
          final blob = SeederBlob.fromJson(msg.payload);
          await _storageManager.saveBlob(blob);
          onBlobReceived?.call(blob);
          break;
      }
    } catch (_) {}
  }
}
