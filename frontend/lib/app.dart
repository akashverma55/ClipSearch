import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/network/dio_client.dart';
import 'data/repositories/video_repository.dart';
import 'presentation/bloc/video/video_bloc.dart';
import 'presentation/bloc/search/search_bloc.dart';
import 'router/app_router.dart';

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    final dioClient = DioClient();
    final videoRepository = VideoRepository(dioClient: dioClient);

    return MultiRepositoryProvider(
      providers: [RepositoryProvider.value(value: videoRepository)],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => VideoBloc(repository: context.read<VideoRepository>())),
          BlocProvider(create: (context) => SearchBloc(repository: context.read<VideoRepository>()))
        ],
        child: MaterialApp.router(
          title: 'Clip Search',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.accent,
              surface: AppColors.surface,
              background: AppColors.background,
              error: AppColors.error,
            ),
            textTheme: GoogleFonts.interTextTheme(
              ThemeData.dark().textTheme.copyWith(
                    displayLarge: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    displayMedium: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    displaySmall: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    bodyLarge: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    bodyMedium: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    bodySmall: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surface,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: AppColors.textPrimary),
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardTheme(
              color: AppColors.surface,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              hintStyle: const TextStyle(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}