class RouteConstants {
  static const String home = '/';
  static const String upload = '/upload';
  static const String videoList = '/videos';
  static const String search = '/search';
  static const String videoPlayer = '/player';

  static String videoPlayerWithId(String videoId, double timestamp) => '/player?videoId=$videoId&timestamp=$timestamp';
  static String searchWithVideoId(String videoId) => '/search?videoId=$videoId';
}