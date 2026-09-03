import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../app_cover_image.dart';
import '../platform_helper.dart';
import '../status_helper.dart';

/// Componente visual puro que renderiza la tarjeta social de reseña para exportación
class SocialCardPreview extends StatelessWidget {
  final String title;
  final String platform;
  final String status;
  final num hoursPlayed;
  final String rating;
  final String summary;
  final String? coverUrl;
  final DateTime? completedDate;
  final bool isDark;

  const SocialCardPreview({
    super.key,
    required this.title,
    required this.platform,
    required this.status,
    required this.hoursPlayed,
    required this.rating,
    required this.summary,
    this.coverUrl,
    this.completedDate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = StatusHelper.getColor(status);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D10) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'VE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Victor ',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFAFAFA)
                                : const Color(0xFF09090B),
                          ),
                        ),
                        TextSpan(
                          text: 'Engineer',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        TextSpan(
                          text: ' • Game Tracker',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFFA1A1AA)
                                : const Color(0xFF71717A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (rating.isNotEmpty && rating != '✰✰✰✰✰' && rating != 'Sin calificar')
                Text(
                  rating,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCoverImage(
                  coverUrl: coverUrl,
                  width: 76,
                  height: 104,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFFAFAFA)
                            : const Color(0xFF09090B),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (platform.isNotEmpty) ...[
                          PlatformHelper.getIcon(platform, size: 14, isColor: true),
                          const SizedBox(width: 5),
                          Text(
                            platform,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 13, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          '${hoursPlayed % 1 == 0 ? hoursPlayed.toInt() : hoursPlayed}h jugadas',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFAFAFA)
                                : const Color(0xFF09090B),
                          ),
                        ),
                        if (completedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•  ${DateFormat('dd MMM yyyy').format(completedDate!)}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
                ),
              ),
              child: Text(
                '“$summary”',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF3F3F46),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
