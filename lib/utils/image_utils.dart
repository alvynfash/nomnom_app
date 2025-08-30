import 'dart:io';
import 'package:flutter/material.dart';

/// Utility functions for handling images in the app
class ImageUtils {
  /// Check if a URL is a network URL (http/https) or local file path
  static bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Get the appropriate ImageProvider for a given URL
  /// Returns NetworkImage for network URLs, FileImage for local files
  static ImageProvider getImageProvider(String url) {
    if (isNetworkUrl(url)) {
      return NetworkImage(url);
    } else {
      return FileImage(File(url));
    }
  }

  /// Build an Image widget that automatically handles network vs local files
  static Widget buildImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
    Widget? loadingWidget,
  }) {
    if (isNetworkUrl(url)) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget
            : null,
        loadingBuilder: loadingWidget != null
            ? (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return loadingWidget;
              }
            : null,
      );
    } else {
      return Image.file(
        File(url),
        fit: fit,
        errorBuilder: errorWidget != null
            ? (context, error, stackTrace) => errorWidget
            : null,
      );
    }
  }

  /// Build a DecorationImage that automatically handles network vs local files
  static DecorationImage buildDecorationImage(
    String url, {
    BoxFit fit = BoxFit.cover,
  }) {
    return DecorationImage(image: getImageProvider(url), fit: fit);
  }
}
