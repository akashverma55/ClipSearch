import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_formatter.dart';
import '../../data/models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  width: 120,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.surfaceLight,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: video.thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: video.thumbnail!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceLight,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceLight,
                              child: const Icon(
                                Icons.video_library,
                                color: AppColors.textTertiary,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceLight,
                            child: const Icon(
                              Icons.video_library,
                              color: AppColors.textTertiary,
                              size: 40,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Video Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        video.title ?? 'Untitled Video',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: video.videoType == 'YouTube'
                              ? Colors.red.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              video.videoType == 'YouTube'
                                  ? Icons.play_circle_outline
                                  : Icons.file_present,
                              size: 16,
                              color: video.videoType == 'YouTube'
                                  ? Colors.red
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              video.videoType,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: video.videoType == 'YouTube'
                                    ? Colors.red
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Duration and Segments
                      Row(
                        children: [
                          if (video.duration != null) ...[
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TimeFormatter.formatDuration(
                                video.duration!.toDouble(),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Icon(
                            Icons.grid_view_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${video.segmentCount} segments',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}