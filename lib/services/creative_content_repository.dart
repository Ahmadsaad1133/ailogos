import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/generated_image.dart';
import '../models/sleep_sound_mix.dart';
import '../models/voice_narration.dart';
import '../models/writing_piece.dart';

class CreativeContentRepository {
  CreativeContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> saveGeneratedImages({
    required String userId,
    required List<GeneratedImage> images,
  }) async {
    final batch = _firestore.batch();
    final userRoot = _firestore.collection('users').doc(userId);
    for (final image in images) {
      final doc = userRoot.collection('images').doc(image.id);
      batch.set(doc, image.toFirestore());
    }
    await batch.commit();
  }

  Stream<List<GeneratedImage>> watchImages(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('images')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GeneratedImage.fromDocument(doc))
        .toList());
  }

  Future<void> saveVoiceNarration({
    required String userId,
    required VoiceNarration narration,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('voice_narrations')
        .doc(narration.id)
        .set(narration.toFirestore());
  }

  Stream<List<VoiceNarration>> watchVoiceNarrations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('voice_narrations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VoiceNarration.fromDocument(doc))
        .toList());
  }

  Future<void> saveSleepMix({
    required String userId,
    required SleepSoundMix mix,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sleep_sounds')
        .doc(mix.id)
        .set(mix.toFirestore());
  }

  Stream<List<SleepSoundMix>> watchSleepMixes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sleep_sounds')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SleepSoundMix.fromDocument(doc))
        .toList());
  }

  Future<void> saveWritingPiece({
    required String userId,
    required WritingPiece piece,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('writings')
        .doc(piece.id)
        .set(piece.toFirestore());
  }

  Stream<List<WritingPiece>> watchWritingPieces(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('writings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => WritingPiece.fromDocument(doc))
        .toList());
  }

  Future<void> saveConversation({
    required String userId,
    required ChatConversation conversation,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_conversations')
        .doc(conversation.id)
        .set(conversation.toFirestore());
  }

  Stream<List<ChatConversation>> watchConversations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_conversations')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatConversation.fromDocument(doc))
        .toList());
  }

  Future<void> appendChatMessage({
    required String userId,
    required String conversationId,
    required ChatMessageModel message,
  }) async {
    final doc = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_conversations')
        .doc(conversationId);
    await doc.set({
      'messages': FieldValue.arrayUnion([message.toFirestore()]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}