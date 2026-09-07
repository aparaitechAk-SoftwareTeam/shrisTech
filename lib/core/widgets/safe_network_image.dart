import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A safe, high-performance image widget that handles:
/// 1. Remote HTTP / HTTPS URLs with CachedNetworkImage.
/// 2. Base64 data URLs (`data:image/...;base64,...`).
/// 3. Graceful fallback for empty, invalid, or corrupted images without throwing decompression exceptions.
class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget Function(BuildContext, ImageProvider)? imageBuilder;
  final Duration fadeInDuration;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fadeInDuration = const Duration(milliseconds: 220),
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) {
      return errorWidget?.call(context, trimmed, 'Empty URL') ??
          const SizedBox.shrink();
    }

    if (trimmed.startsWith('data:image') || trimmed.startsWith('data:application')) {
      final comma = trimmed.indexOf(',');
      if (comma != -1) {
        try {
          final base64Str = trimmed.substring(comma + 1).trim();
          final bytes = base64Decode(base64Str);
          if (bytes.isNotEmpty) {
            if (imageBuilder != null) {
              return imageBuilder!(context, MemoryImage(bytes));
            }
            return Image.memory(
              bytes,
              fit: fit,
              errorBuilder: (ctx, err, stack) =>
                  errorWidget?.call(ctx, trimmed, err) ??
                  const SizedBox.shrink(),
            );
          }
        } catch (e) {
          return errorWidget?.call(context, trimmed, e) ??
              const SizedBox.shrink();
        }
      }
    }

    final uri = Uri.tryParse(trimmed);
    final isValidHttp =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isValidHttp) {
      return errorWidget?.call(context, trimmed, 'Invalid URL scheme') ??
          const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: trimmed,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      imageBuilder: imageBuilder != null
          ? (ctx, provider) => imageBuilder!(ctx, provider)
          : null,
      placeholder: placeholder != null
          ? (ctx, url) => placeholder!(ctx, url)
          : null,
      errorWidget: (ctx, url, error) =>
          errorWidget?.call(ctx, url, error) ?? const SizedBox.shrink(),
    );
  }
}
