import 'dart:io';
import 'dart:convert';

import 'models.dart';

final List<WebSocket> _clients = [];
final List<ChatMessage> _history = [];
final Set<ChatUser> _typingUsers = {};

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
    socket.add(jsonEncode({'type': 'message', ...msg.toJson()}));
  }

  socket.listen(
    (dynamic data) {
      try {
        final incoming = jsonDecode(data as String) as Map<String, dynamic>;

        // 1) TYPING EVENTS: handle & return immediately
        if (incoming['type'] == 'typing') {
          final user = ChatUser.fromJson(
            incoming['user'] as Map<String, dynamic>,
          );
          final isTyping = incoming['isTyping'] == true;

          if (isTyping) {
            _typingUsers.add(user);
          } else {
            _typingUsers.removeWhere((u) => u.id == user.id);
          }

          final payload = jsonEncode({
            'type': 'typing',
            'users': _typingUsers.map((u) => u.toJson()).toList(),
          });

          for (var c in _clients) {
            if (c.readyState == WebSocket.open) c.add(payload);
          }
          return;
        }

        // 2) CHAT MESSAGES: now safe to parse into ChatMessage
        //    (we wrap createdAt parsing to default to now if missing)
        final msg = ChatMessage.fromJson(incoming);

        // Stamp server time if the client didn’t send one
        if (incoming['createdAt'] == null) {
          msg.createdAt = DateTime.now().toLocal();
        }

        // Store in history
        _history.add(msg);

        // Broadcast as a message‐typed envelope
        final out = jsonEncode({'type': 'message', ...msg.toJson()});

        for (var c in List<WebSocket>.from(_clients)) {
          if (c.readyState == WebSocket.open) {
            c.add(out);
          }
        }
      } catch (e, st) {
        print('⚠️ Error handling message: $e\n$st');
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
