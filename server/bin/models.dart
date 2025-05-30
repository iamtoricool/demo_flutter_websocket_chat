// Taken From `https://pub.dev/packages/dash_chat_2`

class ChatMessage {
  ChatMessage({
    required this.user,
    required this.createdAt,
    this.text = '',
    this.medias,
    this.quickReplies,
    this.customProperties,
    this.mentions,
    this.status = MessageStatus.none,
    this.replyTo,
  });

  /// Create a ChatMessage instance from json data
  factory ChatMessage.fromJson(Map<String, dynamic> jsonData) {
    return ChatMessage(
      user: ChatUser.fromJson(jsonData['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(jsonData['createdAt'].toString()).toLocal(),
      text: jsonData['text']?.toString() ?? '',
      medias: jsonData['medias'] != null
          ? (jsonData['medias'] as List<dynamic>)
                .map(
                  (dynamic media) =>
                      ChatMedia.fromJson(media as Map<String, dynamic>),
                )
                .toList()
          : <ChatMedia>[],
      quickReplies: jsonData['quickReplies'] != null
          ? (jsonData['quickReplies'] as List<dynamic>)
                .map(
                  (dynamic quickReply) =>
                      QuickReply.fromJson(quickReply as Map<String, dynamic>),
                )
                .toList()
          : <QuickReply>[],
      customProperties: jsonData['customProperties'] as Map<String, dynamic>?,
      mentions: jsonData['mentions'] != null
          ? (jsonData['mentions'] as List<dynamic>)
                .map(
                  (dynamic mention) =>
                      Mention.fromJson(mention as Map<String, dynamic>),
                )
                .toList()
          : <Mention>[],
      status: MessageStatus.parse(jsonData['status'].toString()),
      replyTo: jsonData['replyTo'] != null
          ? ChatMessage.fromJson(jsonData['replyTo'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Text of the message (optional because you can also just send a media)
  String text;

  /// Author of the message
  ChatUser user;

  /// List of medias of the message
  List<ChatMedia>? medias;

  /// A list of quick replies that users can use to reply to this message
  List<QuickReply>? quickReplies;

  /// A list of custom properties to extend the existing ones
  /// in case you need to store more things.
  /// Can be useful to extend existing features
  Map<String, dynamic>? customProperties;

  /// Date of the message
  DateTime createdAt;

  /// Mentionned elements in the message
  List<Mention>? mentions;

  /// Status of the message TODO:
  MessageStatus? status;

  /// If the message is a reply of another one TODO:
  ChatMessage? replyTo;

  /// Convert a ChatMessage into a json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user': user.toJson(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'text': text,
      'medias': medias?.map((ChatMedia media) => media.toJson()).toList(),
      'quickReplies': quickReplies
          ?.map((QuickReply quickReply) => quickReply.toJson())
          .toList(),
      'customProperties': customProperties,
      'mentions': mentions,
      'status': status.toString(),
      'replyTo': replyTo?.toJson(),
    };
  }
}

class MessageStatus {
  const MessageStatus._internal(this._value);
  final String _value;

  @override
  String toString() => _value;

  static MessageStatus parse(String value) {
    switch (value) {
      case 'none':
        return MessageStatus.none;
      case 'read':
        return MessageStatus.read;
      case 'received':
        return MessageStatus.received;
      case 'pending':
        return MessageStatus.pending;
      default:
        return MessageStatus.none;
    }
  }

  static const MessageStatus none = MessageStatus._internal('none');
  static const MessageStatus read = MessageStatus._internal('read');
  static const MessageStatus received = MessageStatus._internal('received');
  static const MessageStatus pending = MessageStatus._internal('pending');
}

class ChatMedia {
  ChatMedia({
    required this.url,
    required this.fileName,
    required this.type,
    this.isUploading = false,
    this.uploadedDate,
    this.customProperties,
  });

  /// Create a ChatMedia instance from json data
  factory ChatMedia.fromJson(Map<String, dynamic> jsonData) {
    return ChatMedia(
      url: jsonData['url'].toString(),
      fileName: jsonData['fileName'].toString(),
      type: MediaType.parse(jsonData['type'].toString()),
      isUploading: jsonData['isUploading'] == true,
      uploadedDate: jsonData['uploadedDate'] != null
          ? DateTime.parse(jsonData['uploadedDate'].toString()).toLocal()
          : null,
      customProperties: jsonData['customProperties'] as Map<String, dynamic>?,
    );
  }

  /// URL of the media, can local (will use FileImage) or remote (will use NetworkImage)
  String url;

  /// Name of the file that will be shown in some cases
  String fileName;

  /// Type of media
  MediaType type;

  /// If the media is still uploading, usefull to add a visual feedback
  bool isUploading;

  /// Uploaded date of the media
  DateTime? uploadedDate;

  /// A list of custom properties to extend the existing ones
  /// in case you need to store more things.
  /// Can be useful to extend existing features
  Map<String, dynamic>? customProperties;

  /// Convert a ChatMedia into a json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'url': url,
      'type': type.toString(),
      'fileName': fileName,
      'isUploading': isUploading,
      'uploadedDate': uploadedDate?.toUtc().toIso8601String(),
      'customProperties': customProperties,
    };
  }
}

class MediaType {
  const MediaType._internal(this._value);
  final String _value;

  @override
  String toString() => _value;

  static MediaType parse(String value) {
    switch (value) {
      case 'image':
        return MediaType.image;
      case 'video':
        return MediaType.video;
      case 'file':
        return MediaType.file;
      default:
        throw UnsupportedError('$value is not a valid MediaType');
    }
  }

  static const MediaType image = MediaType._internal('image');
  static const MediaType video = MediaType._internal('video');
  static const MediaType file = MediaType._internal('file');
}

class ChatUser {
  ChatUser({
    required this.id,
    this.profileImage,
    this.customProperties,
    this.firstName,
    this.lastName,
  });

  /// Create a ChatUser instance from json data
  factory ChatUser.fromJson(Map<String, dynamic> jsonData) {
    return ChatUser(
      id: jsonData['id'].toString(),
      profileImage: jsonData['profileImage']?.toString(),
      firstName: jsonData['firstName']?.toString(),
      lastName: jsonData['lastName']?.toString(),
      customProperties: jsonData['customProperties'] as Map<String, dynamic>?,
    );
  }

  /// Id of the user
  String id;

  /// Profile image of the user
  String? profileImage;

  /// A list of custom properties to extend the existing ones
  /// in case you need to store more things.
  /// Can be useful to extend existing features
  Map<String, dynamic>? customProperties;

  /// First name of the user,
  /// if you only have the name as one string
  /// you can put the entire value in the [fristName] field
  String? firstName;

  /// Last name of the user
  String? lastName;

  /// Get the full name (firstName + lastName) of the user
  String getFullName() {
    return (firstName ?? '') +
        (firstName != null && lastName != null
            ? ' ${lastName!}'
            : lastName ?? '');
  }

  /// Convert a ChatUser into a json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'profileImage': profileImage,
      'firstName': firstName,
      'lastName': lastName,
      'customProperties': customProperties,
    };
  }
}

class QuickReply {
  QuickReply({required this.title, this.value, this.customProperties});

  /// Create a QuickReply instance from json data
  factory QuickReply.fromJson(Map<String, dynamic> jsonData) {
    return QuickReply(
      title: jsonData['title'].toString(),
      value: jsonData['value']?.toString(),
      customProperties: jsonData['customProperties'] as Map<String, dynamic>?,
    );
  }

  /// Title of the quick reply,
  /// it's what will be visible in the quick replies list
  String title;

  /// Actual value of the quick reply
  /// Use that if you want to have a message text different from the title
  String? value;

  /// A list of custom properties to extend the existing ones
  /// in case you need to store more things.
  /// Can be useful to extend existing features
  Map<String, dynamic>? customProperties;

  /// Convert a QuickReply into a json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'value': value,
      'customProperties': customProperties,
    };
  }
}

class Mention {
  Mention({required this.title, this.customProperties});

  /// Create a Mention instance from json data
  factory Mention.fromJson(Map<String, dynamic> jsonData) {
    return Mention(
      title: jsonData['title'].toString(),
      customProperties: jsonData['customProperties'] as Map<String, dynamic>?,
    );
  }

  /// Title of the mention,
  /// it's what is visible in the message: @userName
  String title;

  /// A list of custom properties to save any data you might need
  /// For instance a user Id
  Map<String, dynamic>? customProperties;

  /// Convert a Mention into a json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'customProperties': customProperties,
    };
  }
}
