import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadAvatar({
    required File file,
    required String userId,
  }) async {
    try {
      final ref = _storage.ref().child('avatars/$userId/avatar.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error subiendo avatar: $e');
      return null;
    }
  }

  Future<String?> uploadEpisodeVideo({
    required File file,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final ref = _storage.ref().child('episodes/$userId/$fileName');

      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      if (onProgress != null) {
        task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        });
      }

      await task;
      return await ref.getDownloadURL();
    } catch (e) {
      print('❌ Error subiendo video: $e');
      return null;
    }
  }
}
