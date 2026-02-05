import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/video_repository.dart';
import 'video_event.dart';
import 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final VideoRepository repository;

  VideoBloc({required this.repository}) : super(const VideoInitial()) {
    on<LoadVideosEvent>(_onLoadVideos);
    on<UploadYoutubeVideoEvent>(_onUploadYoutubeVideo);
    on<UploadFileVideoEvent>(_onUploadFileVideo);
    on<GetVideoSegmentsEvent>(_onGetVideoSegments);
    on<UpdateUploadProgressEvent>(_onUpdateUploadProgress);
  }

  Future<void> _onLoadVideos(
    LoadVideosEvent event,
    Emitter<VideoState> emit,
  ) async {
    emit(const VideoLoading());
    try {
      final videos = await repository.getAllVideos();
      emit(VideosLoaded(videos));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> _onUploadYoutubeVideo(
    UploadYoutubeVideoEvent event,
    Emitter<VideoState> emit,
  ) async {
    emit(const VideoLoading());
    try {
      final response = await repository.uploadYouTubeVideo(
        url: event.url,
        interval: event.interval,
      );
      emit(VideoUploaded(response));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> _onUploadFileVideo(
    UploadFileVideoEvent event,
    Emitter<VideoState> emit,
  ) async {
    emit(const VideoUploadInProgress(0.0));
    try {
      final response = await repository.uploadVideoFile(
        file: event.file,
        interval: event.interval,
        onProgress: (sent, total) {
          add(UpdateUploadProgressEvent(sent: sent, total: total));
        },
      );
      emit(VideoUploaded(response));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> _onGetVideoSegments(
    GetVideoSegmentsEvent event,
    Emitter<VideoState> emit,
  ) async {
    emit(const VideoLoading());
    try {
      final segments = await repository.getVideoSegments(event.videoId);
      emit(VideoSegmentsLoaded(segments));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  void _onUpdateUploadProgress(
    UpdateUploadProgressEvent event,
    Emitter<VideoState> emit,
  ) {
    final progress = event.sent / event.total;
    emit(VideoUploadInProgress(progress));
  }
}