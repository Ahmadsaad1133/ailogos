import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'service_exceptions.dart';

class StorageService {
  const StorageService();

  Future<String> saveToGallery(Uint8List bytes, String filename) async {
    final permission = await _ensurePermission();
    if (!permission) {
      throw const AppServiceException('Gallery permission denied.');
    }

    final result = await ImageGallerySaverPlus.saveImage(bytes, name: filename);
    final isSuccess = (result['isSuccess'] as bool?) ?? false;
    final filePath = result['filePath']?.toString() ?? '';
    if (!isSuccess || filePath.isEmpty) {
      throw const AppServiceException('Failed to save image to gallery.');
    }
    return filePath;
  }

  Future<void> shareImage(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename.png');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'Created in Powered by OBSDIV');
  }

  Future<bool> _ensurePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      return status.isGranted;
    } else {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }
      if (storageStatus.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
  }
}