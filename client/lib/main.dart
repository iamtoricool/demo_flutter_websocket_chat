import 'dart:async';
import 'dart:convert';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

late final SharedPreferences sharedPrefs;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();
  runApp(const DChatApp());
}

class DChatApp extends StatelessWidget {
  const DChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatUI(),
    );
  }
}

class ChatUI extends StatefulWidget {
  const ChatUI({super.key});

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  ChatUser? _currentUser;
  Future<void> initUser() async {
    final _savedUser = sharedPrefs.getString('user');

    if (_savedUser == null) {
      return await _showUserCreationDialog();
    }

    setState(() {
      _currentUser = ChatUser.fromJson(jsonDecode(_savedUser));
    });
    _initSocket();
  }

  final List<ChatUser> _typingUsers = [];
  final List<ChatMessage> _messages = [];
  late final WebSocketChannel _channel;
  bool _socketInitialized = false;

  void _initSocket() {
    if (_socketInitialized) return;
    _socketInitialized = true;

    _channel = WebSocketChannel.connect(
      Uri.parse('wss://ee03-103-180-245-250.ngrok-free.app'),
    );

    _channel.stream.listen(
      (data) {
        final decoded = jsonDecode(data as String);
        final type = decoded['type'];

        if (type == 'typing') {
          final users = (decoded['users'] as List)
              .map((j) => ChatUser.fromJson(j as Map<String, dynamic>))
              .toList();
          setState(
            () => _typingUsers
              ..clear()
              ..addAll(users),
          );
        } else if (type == 'message') {
          if (decoded is List) {
            final history = decoded
                .map(
                  (item) => ChatMessage.fromJson(item as Map<String, dynamic>),
                )
                .toList()
                .cast<ChatMessage>();
            setState(() {
              _messages.clear();
              _messages.addAll(history.reversed);
            });
          } else if (decoded is Map<String, dynamic>) {
            final msg = ChatMessage.fromJson(decoded);
            setState(() {
              _messages.insert(0, msg);
            });
          }
        }
      },
      onDone: () {
        // TODO: try reconnect
      },
      onError: (_) {
        // TODO: show error / retry
      },
    );
  }

  void _handleSend(ChatMessage msg) {
    final outbound = msg.copyWith(
      user: _currentUser!,
      createdAt: DateTime.now(),
    );
    _channel.sink.add(jsonEncode(outbound.toJson()));
  }

  Timer? _typingTimer;
  bool _isTyping = false;

  void _sendTyping(bool isTyping) {
    _channel.sink.add(
      jsonEncode({
        'type': 'typing',
        'user': _currentUser!.toJson(),
        'isTyping': isTyping,
      }),
    );
    _isTyping = isTyping;
  }

  void _onTextChanged(String text) {
    if (!_isTyping) {
      _sendTyping(true);
    }
    _typingTimer?.cancel();
    // after 2s of no typing→ send stop
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _sendTyping(false);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initUser();
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_socketInitialized) {
      _channel.sink.close(status.goingAway);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DChat')),

      body: _currentUser == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No user created.\n Create an user to start chatting!',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _showUserCreationDialog,
                    child: const Text('Create User'),
                  ),
                ],
              ),
            )
          : DashChat(
              currentUser: _currentUser!,
              messages: _messages,
              onSend: _handleSend,
              inputOptions: InputOptions(
                alwaysShowSend: true,
                onTextChange: _onTextChanged,
              ),
              messageOptions: MessageOptions(
                userNameBuilder: (user) {
                  return Text(
                    user.customProperties?['username'] ?? 'Anonymous',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
              messageListOptions: MessageListOptions(
                typingBuilder: (user) {
                  if (user.id == _currentUser!.id) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    "${user.customProperties?['username'] ?? 'Anonymous'} is typing...",
                  );
                },
              ),
              typingUsers: _typingUsers,
            ),
    );
  }

  Future<void> _showUserCreationDialog() async {
    final _result = await showDialog<ChatUser>(
      context: context,
      builder: (context) => const UserCreationDialog(),
    );

    if (_result != null) {
      setState(() {
        _currentUser = _result;
        sharedPrefs.setString('user', jsonEncode(_result.toJson()));
      });
      _initSocket();
    }
  }
}

class UserCreationDialog extends StatefulWidget {
  const UserCreationDialog({super.key});

  @override
  State<UserCreationDialog> createState() => _UserCreationDialogState();
}

class _UserCreationDialogState extends State<UserCreationDialog> {
  late final userNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (formContext) {
          return AlertDialog(
            title: Text('Create a new user'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userNameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Sweet Mango',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an username';
                      }
                      if (value.trim().length < 6) {
                        return 'Username must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (Form.maybeOf(formContext)?.validate() == true) {
                    final _user = ChatUser(
                      id: Uuid().v4(),
                      customProperties: {'username': userNameController.text},
                      profileImage: 'https://picsum.photos/400',
                    );

                    return Navigator.of(context).pop(_user);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on ChatMessage {
  ChatMessage copyWith({
    ChatUser? user,
    DateTime? createdAt,
    String? text,
    List<ChatMedia>? medias,
    List<QuickReply>? quickReplies,
    Map<String, dynamic>? customProperties,
    List<Mention>? mentions,
    MessageStatus? status,
    ChatMessage? replyTo,
  }) {
    return ChatMessage(
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      text: text ?? this.text,
      medias: medias ?? this.medias,
      quickReplies: quickReplies ?? this.quickReplies,
      customProperties: customProperties ?? this.customProperties,
      mentions: mentions ?? this.mentions,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
    );
  }
}
