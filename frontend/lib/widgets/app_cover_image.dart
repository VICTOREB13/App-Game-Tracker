import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget unificado para renderizar carátulas de videojuegos,
/// soportando URLs de internet (CachedNetworkImage) y archivos locales de la galería (Image.file).
class AppCoverImage extends StatelessWidget {
  final String? coverUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCoverImage({
    super.key,
    required this.coverUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    final url = coverUrl?.trim();

    if (url == null || url.isEmpty) {
      content = _buildDefaultPlaceholder(context);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (ctx, _) => placeholder ?? _buildDefaultPlaceholder(ctx),
        errorWidget: (ctx, _, __) => errorWidget ?? _buildDefaultPlaceholder(ctx),
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, _, __) => errorWidget ?? _buildDefaultPlaceholder(ctx),
        );
      } else {
        content = _buildDefaultPlaceholder(context);
      }
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
