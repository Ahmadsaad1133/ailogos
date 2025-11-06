import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  const ChatMessageModel({
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return ChatMessageModel(
      role: data['role'] as String? ?? 'user',
      text: data['text'] as String? ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String role;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'role': role,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}