import yt_dlp
import os
from typing import Optional, List, Dict
from services.video_processor import VideoProcessor


class YouTubeHandler:
    def __init__(self, api_key: str):
        self.processor = VideoProcessor(api_key)
    
    def extract_video_id(self,url:str)->Optional[str]:
        import re
        patterns = [
            r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)',
            r'youtube\.com\/embed\/([^&\n?#]+)',
        ]

        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        return None
    
    def download_youtube_video(self, url:str, output_path:str="uploads/video.mp4")->str:
        ydl_opts = {
            'format':'best[ext=mp4]',
            'outtmpl': output_path,
            'quiet': False,
        }
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            return output_path
        except Exception as e:
            print(f"Error downloading YouTube video: {e}")
        
    def get_video_info(self, url: str) -> dict:

        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
        }
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=False)
                return {
                    'title': info.get('title','Unknown'),
                    'duration': info.get('duration',0),
                    'thumbnail': info.get('thumbnail'),
                }
        except Exception as e:
            print(f"Could not fetch video info: {e}")
            return {'title': 'Unknown', 'duration': 0, 'thumbnail': ''}
    def process_youtube_video(self, url:str, interval_seconds:int=10)->list[Dict]:
        
        video_id = self.extract_video_id(url)
        if not video_id:
            raise ValueError("Invalid YouTube URL")

        print(f"Downloading YouTube video: {url}")

        video_path = f"uploads/{video_id}.mp4"

        try:
            self.download_youtube_video(url, video_path)
            print(f"Video downloaded successfully to: {video_path}")

            segments = self.processor.process_video_with_gemini(video_path, interval_seconds)
            print("Video processed successfully.")

            if os.path.exists(video_path):
                os.remove(video_path)
                print(f"Temporary video file deleted from server: {video_path}")

            return segments
        
        except Exception as e:
            if os.path.exists(video_path):
                os.remove(video_path)
            raise Exception(f"Failed to process YouTube video: {e}")

