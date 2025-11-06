import 'dart:typed_data';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class CloudMediaRepository {
  CloudMediaRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadBytes({
    required Uint8List data,
    required String path,
    String contentType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(data, metadata);
    return ref.getDownloadURL();
  }

  Future<String> uploadFile({
    required String filePath,
    required String path,
    String contentType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putFile(
      File(filePath),
      metadata,
    );
    return ref.getDownloadURL();
  }
}