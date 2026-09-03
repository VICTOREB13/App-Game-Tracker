import 'package:flutter/material.dart';

import '../../../services/theme_manager.dart';
import '../app_cover_image.dart';
import '../platform_helper.dart';
import '../status_helper.dart';

/// Encabezado cinematográfico con backdrop difuminado, portada Hero y badges de estado/plataforma
class GameDetailHeader extends StatelessWidget {
  final String gameId;
  final String? coverUrl;
  final String platform;
  final String status;

  const GameDetailHeader({
    super.key,
    required this.gameId,
    required this.coverUrl,
    required this.platform,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = coverUrl != null && coverUrl!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (hasCover)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 260,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppCoverImage(
                        coverUrl: coverUrl,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.background(context).withOpacity(0.5),
                              AppColors.background(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Hero(
              tag: 'game-cover-$gameId',
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppCoverImage(
                    coverUrl: coverUrl,
                    height: 220,
                    width: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (platform.isNotEmpty)
                PlatformHelper.buildBadge(
                  platform,
                  fontSize: 11,
                  iconSize: 14,
                ),
              StatusHelper.buildStatusPill(context, status),
            ],
          ),
        ),
      ],
    );
  }
}

