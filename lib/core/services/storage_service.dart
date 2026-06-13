import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Uploads image bytes to Firebase Storage under the specified directory path.
  /// Returns the public download URL.
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String folder,
    required String fileExtension,
  }) async {
    final fileName = '${_uuid.v4()}.$fileExtension';
    final ref = _storage.ref().child('$folder/$fileName');
    
    // Set appropriate metadata
    final metadata = SettableMetadata(
      contentType: 'image/$fileExtension',
      cacheControl: 'public, max-age=31536000',
    );

    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Deletes an image from Firebase Storage using its public download URL.
  Future<void> deleteImageByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // If the file does not exist or deletion fails, we do not throw to prevent blocking
    }
  }
}
