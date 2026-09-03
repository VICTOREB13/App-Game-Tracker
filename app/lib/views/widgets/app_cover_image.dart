import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget unificado y de alto rendimiento para renderizar carátulas de videojuegos,
/// soportando URLs remotas (CachedNetworkImage con límites de textura) y archivos locales
/// (Image.file con límites de decodificación y sin I/O bloqueante síncrono en build).
class AppCoverImage extends StatelessWidget {
  final String? coverUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? cacheWidth;
  final int? cacheHeight;

  const AppCoverImage({
    super.key,
    required this.coverUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 600,
    this.memCacheHeight,
    this.cacheWidth = 600,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final url = coverUrl?.trim();

    if (url == null || url.isEmpty) {
      content = placeholder ?? _buildDefaultPlaceholder(context);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (ctx, _) => placeholder ?? _buildDefaultPlaceholder(ctx),
        errorWidget: (ctx, _, __) =>
            errorWidget ?? _buildDefaultPlaceholder(ctx),
      );
    } else {
      // Carga asíncrona no bloqueante de archivo local
      content = Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (ctx, _, __) =>
            errorWidget ?? _buildDefaultPlaceholder(ctx),
        frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return placeholder ?? _buildDefaultPlaceholder(ctx);
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.sports_esports_rounded,
        color: Color(0xFFA1A1AA),
        size: 24,
      ),
    );
  }
}
