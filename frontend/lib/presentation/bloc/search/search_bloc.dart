import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/video_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final VideoRepository repository;

  SearchBloc({required this.repository}) : super(const SearchInitial()) {
    on<SearchVideoEvent>(_onSearchVideo);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onSearchVideo(
    SearchVideoEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    try {
      final results = await repository.searchVideo(
        videoId: event.videoId,
        query: event.query,
        topK: event.topK,
      );
      emit(SearchSuccess(results: results, query: event.query));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<SearchState> emit,
  ) {
    emit(const SearchInitial());
  }
}