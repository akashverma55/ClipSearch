import 'package:equatable/equatable.dart';
import '../../../data/models/video_model.dart';
import '../../../data/models/segment_model.dart';
import '../../../data/models/upload_response_model.dart';

abstract class VideoState extends Equatable {
  const VideoState();

  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {
  const VideoInitial();
}

class VideoLoading extends VideoState {
  const VideoLoading();
}

class VideoUploadInProgress extends VideoState {
  final double progress;
  const VideoUploadInProgress(this.progress);

  @override
  List<Object?> get props => [progress];
}

class VideosLoaded extends VideoState {
  final List<VideoModel> videos;
  const VideosLoaded(this.videos);

  @override
  List<Object?> get props => [videos];
}

class VideoUploaded extends VideoState {
  final UploadResponseModel response;
  const VideoUploaded(this.response);

  @override
  List<Object?> get props => [response];
}

class VideoSegmentsLoaded extends VideoState {
  final List<SegmentModel> segments;
  const VideoSegmentsLoaded(this.segments);

  @override
  List<Object?> get props => [segments];
}

class VideoError extends VideoState {
  final String message;
  const VideoError(this.message);

  @override
  List<Object?> get props => [message];
}