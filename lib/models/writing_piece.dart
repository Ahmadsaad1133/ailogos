import 'package:cloud_firestore/cloud_firestore.dart';

enum WritingCategory { story, poem, blog, script }

extension WritingCategoryName on WritingCategory {
  String get label {
    switch (this) {
      case WritingCategory.story:
        return 'Story';
      case WritingCategory.poem:
        return 'Poem';
      case WritingCategory.blog:
        return 'Blog';
      case WritingCategory.script:
        return 'Script';
    }
  }

  String get firestoreValue {
    return toString().split('.').last;
  }

  static WritingCategory fromValue(String value) {
    return WritingCategory.values.firstWhere(
          (element) => element.firestoreValue == value,
      orElse: () => WritingCategory.story,
    );
  }
}

class WritingPiece {
  const WritingPiece({
    required this.id,
    required this.prompt,
    required this.category,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory WritingPiece.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return WritingPiece(
      id: doc.id,
      prompt: data['prompt'] as String? ?? '',
      category: WritingCategoryName.fromValue(
        data['category'] as String? ?? 'story',
      ),
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.tryParse(timestamp?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String prompt;
  final WritingCategory category;
  final String title;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() {
    return {
      'prompt': prompt,
      'category': category.firestoreValue,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}