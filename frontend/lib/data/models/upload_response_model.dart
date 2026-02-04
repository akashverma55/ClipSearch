import 'package:equatable/equatable.dart';

class UploadResponseModel extends Equatable {
  final String videoId;
  final String videoType;
  final String message;
  final int segmentsProcessed;
  final String? videoUrl;
  final String? streamUrl;
  final String? filename;
  final String? title;
  final int? duration;
  final String? thumbnail;
  
  const UploadResponseModel({
    required this.videoId,
    required this.videoType,
    required this.message,
    required this.segmentsProcessed,
    this.videoUrl,
    this.streamUrl,
    this.filename,
    this.title,
    this.duration,
    this.thumbnail,
  });
  
  factory UploadResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadResponseModel(
      videoId: json['video_id'] as String,
      videoType: json['video_type'] as String,
      message: json['message'] as String,
      segmentsProcessed: json['segments_processed'] as int,
      videoUrl: json['video_url'] as String?,
      streamUrl: json['stream_url'] as String?,
      filename: json['filename'] as String?,
      title: json['title'] as String?,
      duration: json['duration'] as int?,
      thumbnail: json['thumbnail'] as String?,
    );
  }
  
  @override
  List<Object?> get props => [
        videoId,
        videoType,
        message,
        segmentsProcessed,
        videoUrl,
        streamUrl,
        filename,
        title,
        duration,
        thumbnail,
      ];
}