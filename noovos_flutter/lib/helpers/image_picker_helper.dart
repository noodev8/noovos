/*
Image Picker Helper
Provides methods for picking images from camera or gallery
Handles permissions and provides a consistent interface for image selection
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /*
  * Show image source selection dialog
  * Allows user to choose between camera and gallery
  *
  * @param context The build context for showing dialogs
  * @return File? The selected image file or null if cancelled
  */
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose how you want to select an image:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('camera'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 18),
                  SizedBox(width: 8),
                  Text('Camera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('gallery'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 18),
                  SizedBox(width: 8),
                  Text('Gallery'),
                ],
              ),
            ),
          ],
        );
      },
    );

    // Handle the user's choice
    if (choice == 'camera') {
      return await pickImageFromCamera(context);
    } else if (choice == 'gallery') {
      return await pickImageFromGallery(context);
    }

    return null; // User cancelled
  }

  /*
  * Pick image from camera
  * Requests camera permission if needed
  *
  * @param context The build context for showing permission dialogs
  * @return File? The captured image file or null if failed/cancelled
  */
  static Future<File?> pickImageFromCamera(BuildContext context) async {
    try {
      // Check and request camera permission
      final cameraPermission = await Permission.camera.status;

      if (cameraPermission.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _showPermissionDeniedDialog(context, 'Camera');
          return null;
        }
      }

      if (cameraPermission.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog(context, 'Camera');
        return null;
      }

      // Pick image from camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Good quality while keeping file size reasonable
        maxWidth: 1920,   // Limit resolution to reduce file size
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      _showErrorDialog(context, 'Failed to capture image: $e');
      return null;
    }
  }

  /*
  * Pick image from gallery
  * Requests storage permission if needed
  *
  * @param context The build context for showing permission dialogs
  * @return File? The selected image file or null if failed/cancelled
  */
  static Future<File?> pickImageFromGallery(BuildContext context) async {
    try {
      // Check and request storage permission
      PermissionStatus storagePermission;

      // For Android 13+ (API level 33+), use photos permission
      if (Platform.isAndroid) {
        storagePermission = await Permission.photos.status;
        if (storagePermission.isDenied) {
          storagePermission = await Permission.photos.request();
        }

        // Fallback to storage permission for older Android versions
        if (storagePermission.isDenied) {
          storagePermission = await Permission.storage.status;
          if (storagePermission.isDenied) {
            storagePermission = await Permission.storage.request();
          }
        }
      } else {
        // For iOS, use photos permission
        storagePermission = await Permission.photos.status;
        if (storagePermission.isDenied) {
          storagePermission = await Permission.photos.request();
        }
      }

      if (storagePermission.isDenied) {
        _showPermissionDeniedDialog(context, 'Photo Library');
        return null;
      }

      if (storagePermission.isPermanentlyDenied) {
        _showPermissionPermanentlyDeniedDialog(context, 'Photo Library');
        return null;
      }

      // Pick image from gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Good quality while keeping file size reasonable
        maxWidth: 1920,   // Limit resolution to reduce file size
        maxHeight: 1920,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      _showErrorDialog(context, 'Failed to select image: $e');
      return null;
    }
  }

  /*
  * Show permission denied dialog
  */
  static void _showPermissionDeniedDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text('$permissionType permission is required to select images. Please grant permission and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /*
  * Show permission permanently denied dialog
  */
  static void _showPermissionPermanentlyDeniedDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text('$permissionType permission has been permanently denied. Please enable it in app settings to select images.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  /*
  * Show error dialog
  */
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
