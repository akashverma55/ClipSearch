import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideosEvent extends VideoEvent {
  const LoadVideosEvent();
}

class UploadYoutubeVideoEvent extends VideoEvent {
  final String url;
  final int interval;

  const UploadYoutubeVideoEvent({
    required this.url,
    this.interval = 10,
  });

  @override
  List<Object?> get props => [url, interval];
}

class UploadFileVideoEvent extends VideoEvent {
  final File file;
  final int interval;

  const UploadFileVideoEvent({
    required this.file,
    this.interval = 10,
  });

  @override
  List<Object?> get props => [file, interval];
}

class GetVideoSegmentsEvent extends VideoEvent {
  final String videoId;

  const GetVideoSegmentsEvent(this.videoId);

  @override
  List<Object?> get props => [videoId];
}

class UpdateUploadProgressEvent extends VideoEvent {
  final int sent;
  final int total;

  const UpdateUploadProgressEvent({
    required this.sent,
    required this.total,
  });

  @override
  List<Object?> get props => [sent, total];
}