import 'package:flutter/material.dart';
import '../utils/text_styles.dart';

class SeasonCard extends StatelessWidget {
  final String seasonName;
  final String groupName;
  final int currentDay;
  final int totalDays;
  final int streakDays;
  final String thumbnailUrl;
  final bool hasUploadedToday;
  final String? imageUrl;
  final VoidCallback onTap;

  const SeasonCard({
    super.key,
    required this.seasonName,
    required this.groupName,
    required this.currentDay,
    required this.totalDays,
    required this.streakDays,
    required this.thumbnailUrl,
    this.hasUploadedToday = false,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentDay / totalDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(
              thumbnailUrl.isNotEmpty
                  ? thumbnailUrl
                  : imageUrl ?? 'https://via.placeholder.com/400x200',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                seasonName,
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                groupName,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Día $currentDay/$totalDays',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE50914),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (streakDays > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$streakDays',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}