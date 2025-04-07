/*
Helper functions for handling images in the application
Provides methods for constructing image URLs and handling image loading
*/

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';

class ImageHelper {
  // Base URL for images
  static final String _imageBaseUrl = AppConfig.imageBaseUrl;

  /*
  * Get the full URL for an image
  *
  * @param imagePath The image path or filename from the API
  * @return The full URL to the image
  */
  static String getImageUrl(String? imagePath) {
    // If imagePath is null or empty, return an empty string
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }

    // If the imagePath is already a full URL (starts with http:// or https://), return it as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove any leading slash from the imagePath
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

    // Construct the full URL
    return '$_imageBaseUrl/$cleanPath';
  }

  /*
  * Check if an image URL is valid
  *
  * @param url The image URL to check
  * @return True if the URL is valid, false otherwise
  */
  static bool isValidImageUrl(String? url) {
    return url != null && url.isNotEmpty;
  }

  /*
  * Get a cached network image widget
  *
  * @param imageUrl The image URL
  * @param width The width of the image
  * @param height The height of the image
  * @param fit How the image should be inscribed into the box
  * @param placeholder The placeholder widget to show while loading
  * @param errorWidget The widget to show if there's an error loading the image
  * @return A CachedNetworkImage widget
  */
  static Widget getCachedNetworkImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // If the image URL is not valid, return the error widget or a default one
    if (!isValidImageUrl(imageUrl)) {
      return errorWidget ?? const Icon(Icons.image_not_supported, color: Colors.grey);
    }

    // Get the full URL
    final fullUrl = getImageUrl(imageUrl);

    // Return a cached network image
    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey[400],
        ),
      ),
      errorWidget: (context, url, error) => errorWidget ?? const Icon(
        Icons.broken_image,
        color: Colors.grey,
      ),
    );
  }
}
