import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      print('Starting upload for user: $userId');
      final String fileName = 'profile_images/$userId.jpg';
      final Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      
      if (kIsWeb) {
        print('Uploading for web platform');
        // For web platform
        final bytes = await imageFile.readAsBytes();
        print('Image size: ${bytes.length} bytes');
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'max-age=3600',
            customMetadata: {
              'uploadedBy': userId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        print('Uploading for mobile platform');
        // For mobile platforms
        final File file = File(imageFile.path);
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'max-age=3600',
            customMetadata: {
              'uploadedBy': userId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final TaskSnapshot snapshot = await uploadTask;
      print('Upload completed successfully');
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      // Verify the upload by checking if file exists
      await _verifyUpload(ref);
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Verify that the uploaded file exists and is accessible
  Future<void> _verifyUpload(Reference ref) async {
    try {
      final metadata = await ref.getMetadata();
      print('File verified - Size: ${metadata.size} bytes, Type: ${metadata.contentType}');
    } catch (e) {
      print('Warning: Could not verify upload: $e');
    }
  }

  // Get profile image URL with better error handling
  Future<String?> getProfileImageUrl(String userId) async {
    try {
      final String fileName = 'profile_images/$userId.jpg';
      final Reference ref = _storage.ref().child(fileName);
      final String downloadUrl = await ref.getDownloadURL();
      print('Retrieved profile image URL for user $userId: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error getting profile image URL for user $userId: $e');
      if (e.toString().contains('object-not-found')) {
        print('Profile image not found for user $userId');
        return null;
      }
      throw Exception('Failed to get profile image: $e');
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage(String userId) async {
    try {
      final String fileName = 'profile_images/$userId.jpg';
      final Reference ref = _storage.ref().child(fileName);
      await ref.delete();
      print('Successfully deleted profile image for user: $userId');
    } catch (e) {
      print('Error deleting profile image: $e');
      // If file doesn't exist, that's fine
      if (!e.toString().contains('object-not-found')) {
        throw Exception('Failed to delete image: $e');
      }
    }
  }

  // Test Firebase Storage connection
  Future<bool> testStorageConnection() async {
    try {
      final ref = _storage.ref().child('test');
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      print('Storage connection test failed: $e');
      return false;
    }
  }

  // Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog() async {
    // This will be implemented in the UI layer
    // Return ImageSource.gallery as default for now
    return ImageSource.gallery;
  }
} 