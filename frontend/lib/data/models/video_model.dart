import 'package:equatable/equatable.dart';

class VideoModel extends Equatable {
  final String videoId;
  final String videoType;
  final String videoSource;
  final int segmentCount;
  final String? title;
  final int? duration;
  final String? thumbnail;
  
  const VideoModel({
    required this.videoId,
    required this.videoType,
    required this.videoSource,
    required this.segmentCount,
    this.title,
    this.duration,
    this.thumbnail,
  });
  
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      videoId: json['video_id'] as String,
      videoType: json['video_type'] as String,
      videoSource: json['video_source'] as String,
      segmentCount: json['segment_count'] as int,
      title: json['title'] as String?,
      duration: json['duration'] as int?,
      thumbnail: json['thumbnail'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'video_id': videoId,
      'video_type': videoType,
      'video_source': videoSource,
      'segment_count': segmentCount,
      if (title != null) 'title': title,
      if (duration != null) 'duration': duration,
      if (thumbnail != null) 'thumbnail': thumbnail,
    };
  }
  
  @override
  List<Object?> get props => [videoId, videoType, videoSource, segmentCount, title, duration, thumbnail];
}