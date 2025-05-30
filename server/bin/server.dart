import 'dart:io';
import 'dart:convert';

import 'models.dart';

final List<WebSocket> _clients = [];
final List<ChatMessage> _history = [];

Future<void> main() async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    8080,
    shared: true,
  );
  print('🚀 WS listening at ws://${server.address.address}:${server.port}');

  await for (var req in server) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      WebSocketTransformer.upgrade(req).then((socket) {
        _handleConnection(socket);
      });
    } else {
      req.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }
}

void _handleConnection(WebSocket socket) {
  _clients.add(socket);
  print('➕ ${socket.hashCode} connected (total: ${_clients.length})');

  // Send history to newly connected client
  for (var msg in _history) {
    socket.add(jsonEncode(msg.toJson()));
  }

  socket.listen(
    (dynamic data) {
      try {
        final incoming = jsonDecode(data as String) as Map<String, dynamic>;
        final msg = ChatMessage.fromJson(incoming);

        if (incoming['createdAt'] == null) {
          msg.createdAt = DateTime.now().toLocal();
        }

        // Store in history
        _history.add(msg);

        final outJson = jsonEncode(msg.toJson());

        for (var c in List<WebSocket>.from(_clients)) {
          if (c.readyState == WebSocket.open) {
            c.add(outJson);
          }
        }
      } catch (e) {
        print('⚠️ Error handling message: $e');
      }
    },
    onDone: () {
      _clients.remove(socket);
      print('➖ ${socket.hashCode} disconnected (total: ${_clients.length})');
    },
    onError: (e) {
      _clients.remove(socket);
      print('⚠️ Socket error (${socket.hashCode}): $e');
    },
  );
}
