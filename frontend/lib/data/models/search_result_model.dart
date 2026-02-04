import 'package:equatable/equatable.dart';

class SearchResultModel extends Equatable {
  final double timestamp;
  final String description;
  final String videoType;
  final String videoSource;
  final double similarity;
  
  const SearchResultModel({
    required this.timestamp,
    required this.description,
    required this.videoType,
    required this.videoSource,
    required this.similarity,
  });
  
  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      timestamp: (json['timestamp'] as num).toDouble(),
      description: json['description'] as String,
      videoType: json['video_type'] as String,
      videoSource: json['video_source'] as String,
      similarity: (json['similarity'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'description': description,
      'video_type': videoType,
      'video_source': videoSource,
      'similarity': similarity,
    };
  }
  
  @override
  List<Object?> get props => [timestamp, description, videoType, videoSource, similarity];
}