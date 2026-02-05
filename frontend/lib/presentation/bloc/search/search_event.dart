import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchVideoEvent extends SearchEvent {
  final String videoId;
  final String query;
  final int topK;

  const SearchVideoEvent({
    required this.videoId,
    required this.query,
    this.topK = 5,
  });

  @override
  List<Object?> get props => [videoId, query, topK];
}

class ClearSearchEvent extends SearchEvent {
  const ClearSearchEvent();
}