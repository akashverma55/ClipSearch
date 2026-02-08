import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/route_constants.dart';
import '../bloc/video/video_bloc.dart';
import '../bloc/video/video_event.dart';
import '../bloc/video/video_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
// import 'package:permission_handler/permission_handler.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _intervalController =
      TextEditingController(text: '10');
  File? _selectedFile;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _youtubeUrlController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

//   Future<void> _pickFile() async {
//   // Check permission before opening picker
//   var status = await Permission.videos.request(); 
  
//   if (status.isGranted) {
//     // Your existing FilePicker code here...
//   } else {
//     _showError("Permission denied. Please allow access to videos.");
//   }
// }

  Future<void> _pickFile() async {
    try {
      // Ensure the picker is cleared before selecting again
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false, // Explicitly set to false
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
        print("File selected: $_selectedFileName");
      } else {
        // User canceled the picker
        print("User canceled file selection");
      }
    } catch (e) {
      _showError("Could not open file manager: $e");
    }
  }

  void _uploadYoutubeVideo() {
    final url = _youtubeUrlController.text.trim();
    final interval = int.tryParse(_intervalController.text) ?? 10;

    if (url.isEmpty) {
      _showError('Please enter a YouTube URL');
      return;
    }

    context.read<VideoBloc>().add(
          UploadYoutubeVideoEvent(url: url, interval: interval),
        );
  }

  void _uploadFile() {
    if (_selectedFile == null) {
      _showError('Please select a video file');
      return;
    }

    final interval = int.tryParse(_intervalController.text) ?? 10;

    context.read<VideoBloc>().add(
          UploadFileVideoEvent(file: _selectedFile!, interval: interval),
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<VideoBloc, VideoState>(
        listener: (context, state) {
          if (state is VideoUploaded) {
            _showSuccess('Video uploaded successfully!');
            Future.delayed(const Duration(seconds: 2), () {
              context.go(RouteConstants.videoList);
            });
          } else if (state is VideoError) {
            _showError(state.message);
          }
        },
        builder: (context, state) {
          if (state is VideoLoading) {
            return Center(
              child: LoadingIndicator(
                message: 'Processing video...\nThis may take a few minutes',
              ),
            );
          }

          if (state is VideoUploadInProgress) {
            return Center(
              child: LoadingIndicator(
                message: 'Uploading video...',
                progress: state.progress,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Tab Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('YouTube'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_upload_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('File'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tab Views
                SizedBox(
                  // Use a flexible height or simply larger constant if needed,
                  // but IntrinsicHeight is safer for dynamic content.
                  height: 550,
                  child: TabBarView(
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent horizontal swipe conflicts
                    controller: _tabController,
                    children: [
                      _buildYoutubeUpload(),
                      _buildFileUpload(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYoutubeUpload() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.red,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                'YouTube Video',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Paste a YouTube URL to analyze the video',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // YouTube URL Input
          const Text(
            'YouTube URL',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _youtubeUrlController,
            decoration: const InputDecoration(
              hintText: 'https://youtube.com/watch?v=...',
              prefixIcon: Icon(Icons.link, color: AppColors.primary),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),

          // Interval Input
          const Text(
            'Interval (seconds)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '10',
              prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
              helperText: 'Lower = More precise, Higher = Faster processing',
              helperStyle: TextStyle(color: AppColors.textTertiary),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),

          const Spacer(),

          // Upload Button
          CustomButton(
            text: 'Process Video',
            icon: Icons.cloud_upload_rounded,
            onPressed: _uploadYoutubeVideo,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildFileUpload() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.file_upload_outlined,
                color: AppColors.primary,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                'Upload File',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload MP4, AVI, MOV, MKV, or WEBM files',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // File Picker
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.video_file_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFileName ?? 'Tap to select video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedFileName != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _selectedFileName != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFileName == null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Max size: 500MB',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Interval Input
          const Text(
            'Interval (seconds)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '10',
              prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
              helperText: 'Lower = More precise, Higher = Faster processing',
              helperStyle: TextStyle(color: AppColors.textTertiary),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),

          const Spacer(),

          // Upload Button
          CustomButton(
            text: 'Upload & Process',
            icon: Icons.cloud_upload_rounded,
            onPressed: _uploadFile,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
