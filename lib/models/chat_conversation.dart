import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_message.dart';

class PersonaPreset {
  const PersonaPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.systemPrompt,
  });

  final String id;
  final String title;
  final String description;
  final String systemPrompt;
}

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.personaId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    final updated = data['updatedAt'];
    final rawMessages = (data['messages'] as List<dynamic>? ?? const [])
        .map((e) => ChatMessageModel.fromMap(
        Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList(growable: false);
    return ChatConversation(
      id: doc.id,
      personaId: data['personaId'] as String? ?? 'writer',
      messages: rawMessages,
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
      updatedAt: updated is Timestamp
          ? updated.toDate()
          : DateTime.tryParse(updated?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String personaId;
  final List<ChatMessageModel> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toFirestore() {
    return {
      'personaId': personaId,
      'messages': messages.map((e) => e.toFirestore()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}