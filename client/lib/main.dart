import 'dart:convert';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initUser();
    });
    super.initState();
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
              onSend: (message) {},
              messages: [],
              inputOptions: const InputOptions(
                alwaysShowSend: true,
              ),
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
