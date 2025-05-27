/*
Helper functions for handling Cloudinary images
Provides methods for constructing Cloudinary URLs and handling image operations
*/

import '../config/app_config.dart';

class CloudinaryHelper {
  /*
  * Construct a Cloudinary URL from a filename
  *
  * @param filename The image filename (e.g., 'noovos_123_1234567890')
  * @return The full Cloudinary URL
  */
  static String getCloudinaryUrl(String? filename) {
    // If filename is null or empty, return empty string
    if (filename == null || filename.isEmpty) {
      return '';
    }

    // If the filename is already a full URL, return it as is
    if (filename.startsWith('http://') || filename.startsWith('https://')) {
      return filename;
    }

    // Construct Cloudinary URL
    // Format: https://res.cloudinary.com/<cloud_name>/image/upload/<folder>/<filename>.jpg
    return 'https://res.cloudinary.com/${AppConfig.cloudinaryCloudName}/image/upload/${AppConfig.cloudinaryFolder}/$filename.jpg';
  }

  /*
  * Check if a filename is a Cloudinary image
  * This helps distinguish between old image server files and new Cloudinary files
  *
  * @param filename The image filename to check
  * @return True if it's a Cloudinary filename pattern
  */
  static bool isCloudinaryImage(String? filename) {
    if (filename == null || filename.isEmpty) {
      return false;
    }

    // If it's already a full Cloudinary URL
    if (filename.contains('cloudinary.com')) {
      return true;
    }

    // Check if it matches Cloudinary filename pattern (folder_userid_timestamp)
    // Example: noovos_123_1234567890
    final cloudinaryPattern = RegExp(r'^noovos_\d+_\d+$');
    return cloudinaryPattern.hasMatch(filename);
  }

  /*
  * Extract filename from a Cloudinary URL
  * Useful for server-side operations that need just the filename
  *
  * @param url The full Cloudinary URL
  * @return The filename without extension
  */
  static String? extractFilenameFromUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    if (url.contains('cloudinary.com')) {
      // Extract filename from URL
      // URL format: https://res.cloudinary.com/cloud_name/image/upload/folder/filename.ext
      final urlParts = url.split('/');
      if (urlParts.isNotEmpty) {
        final filenameWithExt = urlParts.last;
        // Remove extension
        final dotIndex = filenameWithExt.lastIndexOf('.');
        if (dotIndex != -1) {
          return filenameWithExt.substring(0, dotIndex);
        }
        return filenameWithExt;
      }
    }

    return url; // Return as-is if not a Cloudinary URL
  }
}
