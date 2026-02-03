class ApiConstants {
  static const String baseUrl = 'http://192.168.1.5:5000';
  static const String health = '/health';
  static const String uploadYoutube = '/upload/youtube';
  static const String uploadFile = '/upload/file';
  static const String search = '/search';
  static const String videos = '/videos';
  static String videoSegments(String videoId) => '/video/$videoId/segments';
  static String streamVideo(String filename) => '/stream/$filename';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration recieveTimeout = Duration(minutes: 5);
  static const Duration sendTimeout = Duration(minutes: 5);
}