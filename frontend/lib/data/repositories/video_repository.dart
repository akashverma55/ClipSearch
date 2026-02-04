import 'dart:io';
import 'package:dio/dio.dart';
import 'package:frontend/core/network/dio_client.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/data/models/video_model.dart';
import 'package:frontend/data/models/upload_response_model.dart';
import 'package:frontend/data/models/search_result_model.dart';
import 'package:frontend/data/models/segment_model.dart';

class VideoRepository {
  final DioClient dioClient;

  const VideoRepository({
    required this.dioClient
  });

  Future<bool> healthCheck() async {
    try {
      final response = await dioClient.get(ApiConstants.health);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<UploadResponseModel> uploadYoutubeVideo({required String url, int interval = 10}) async{
    try{
      final response = await dioClient.post(ApiConstants.uploadYoutube, data: {'url':url,'interval':interval});
      return UploadResponseModel.fromJson(response.data);
    }
    catch(e){
      throw Exception('Failed to upload YouTube video: $e');
    }
  }

  Future<UploadResponseModel> uploadVideoFile({required File file, int interval = 10, Function(int, int)? onProgress}) async {
    try{
      final formData = FormData.fromMap({
        'video':await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last
        ),
        'interval': interval.toString()
      });
      final response = await dioClient.postFormData(
        ApiConstants.uploadFile,
        formData: formData,
        onSendProgress: (sent, total){
          if (onProgress != null){
            onProgress(sent, total);
          }
        }
      );
      return UploadResponseModel.fromJson(response.data);
    }
    catch(e){
      throw Exception('Failed to upload video file: $e');
    }
  }

  Future<List<SearchResultModel>> searchVideo({required String videoId, required String query, int topK=3}) async{
    try{
      final response = await dioClient.post(
        ApiConstants.search,
        data:{
          'video_id': videoId,
          'query': query,
          'top_k': topK
        }
      );

      final results = (response.data['results'] as List).map((json)=>SearchResultModel.fromJson(json)).toList();
      return results;
    }
    catch (e){
      throw Exception('Failed to search video: $e');
    }
  } 

  Future<List<VideoModel>> getAllVideos() async{
    try{
      final response = await dioClient.get(ApiConstants.videos);
      final videos = (response.data['videos'] as List).map((json) => VideoModel.fromJson(json)).toList();
      return videos;
    }
    catch(e){
      throw Exception('Failed to get videos: $e');
    }
  }

  Future<List<SegmentModel>> getVideoSegments(String videoId) async {
    try{
      final response = await dioClient.get(
        ApiConstants.videoSegments(videoId)
      );
      final segments = (response.data['segments'] as List).map((json)=>SegmentModel.fromJson(json)).toList();
      return segments;
    }
    catch (e){
      throw Exception('Failed to get video segments: $e');
    }
  }
}