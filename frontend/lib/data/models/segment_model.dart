import 'package:equatable/equatable.dart';

class SegmentModel extends Equatable {
  final double timestamp;
  final String description;
  final String videoType;
  final String videoSource;

  const SegmentModel({
    required this.timestamp,
    required this.description,
    required this.videoType,
    required this.videoSource
  });

  factory SegmentModel.fromJson(Map<String, dynamic> json){
    return SegmentModel(
      timestamp: (json['timestamp'] as num).toDouble(),
      description: json['description'] as String,
      videoType: json['video_type'] as String,
      videoSource: json['video_source'] as String
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'timestamp': timestamp,
      'description': description,
      'video_type': videoType,
      'video_source': videoSource
    };
  }

  @override
  List<Object?> get props => [timestamp, description, videoType, videoSource];
}