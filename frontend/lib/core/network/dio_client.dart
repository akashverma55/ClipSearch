import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient(){
    return _instance;
  }

  DioClient._internal(){
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        receiveTimeout: ApiConstants.recieveTimeout,
        headers: {
          'Content-Type':'application/json',
          'Accept':'application/json'
        }
      )
    );

    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print(obj),
      )
    );
  }

  
  Future<Response> get(String path,{Map<String,dynamic>? queryParameters}) async{
      try{
        final response = await dio.get(
          path, 
          queryParameters: queryParameters
        );
        return response;
      }
      catch (e){
        rethrow;
      }
    }

  Future<Response> post(String path,{dynamic data, Map<String,dynamic>? queryParameters}) async{
    try{
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters
      );
      return response;
    }
    catch (e){
      rethrow;
    }
  }

  Future<Response> postFormData(String path,{required FormData formData, ProgressCallback? onSendProgress}) async{
    try{
      final response = await dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress
      );
      return response;
    }
    catch (e){
      rethrow;
    }
  }
}