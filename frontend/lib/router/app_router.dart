import 'package:flutter/material.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/presentation/bloc/video/video_bloc.dart';
import 'package:frontend/presentation/screens/error_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/presentation/screens/home_screen.dart';
import 'package:frontend/presentation/screens/upload_screen.dart';
import 'package:frontend/presentation/screens/video_list_screen.dart';
import 'package:frontend/presentation/screens/search_screen.dart';
import 'package:frontend/presentation/screens/video_player_screen.dart';
import 'package:frontend/core/constants/route_constants.dart';

class AppRouter {
  static final GoRouter router= GoRouter(
    initialLocation: RouteConstants.home,
    debugLogDiagnostics: true,
    routes: [

      // Home Screen 
      GoRoute(
        path: RouteConstants.home,
        name: 'home',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomeScreen()
        )
      ),

      // Upload Screen
      GoRoute(
        path: RouteConstants.upload,
        name: 'upload',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const UploadScreen()
        )
      ),

      // Video List Screen
      GoRoute(
        path: RouteConstants.videoList,
        name: 'videoList',
        pageBuilder:(context, state) => MaterialPage(
          key: state.pageKey,
          child: const VideoListScreen();
        ),
      ),

      // Search Screen
      GoRoute(
        path: ApiConstants.search,
        name: 'search',
        pageBuilder: (context, state){
          final videoId = state.uri.queryParameters['videoId'];
          return MaterialPage(
            key: state.pageKey,
            child: SearchScreen(preSelectedVideoId: videoId)
          );
        }
      ),

      // Video Player Screen
      GoRoute(
        path: RouteConstants.videoPlayer,
        name: 'videoPlayer',
        pageBuilder: (context, state) {
          final videoId = state.uri.queryParameters['videoId']??'';
          final timestampStr = state.uri.queryParameters['timestamp']??'0';
          final timestamp = double.tryParse(timestampStr)??0.0;
          final videosource = state.uri.queryParameters['videoSource']??'';
          final videoType = state.uri.queryParameters['videoType']??'';

          return MaterialPage(
            key: state.pageKey,
            child: VideoPlayerScreen(
              videoId: videoId,
              timestamp: timestamp,
              videoType: videoType,
              videosource: videosource
            )
          )
        },
      )
    ],

    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: ErrorScreen(state:state),
    ),
  );
}

