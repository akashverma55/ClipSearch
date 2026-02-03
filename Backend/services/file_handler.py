import os
from services.video_processor import VideoProcessor
from werkzeug.datastructures import FileStorage

class FileHandler:

    def __init__(self, api_key:str, upload_folder:str = "uploads/"):
        self.processor = VideoProcessor(api_key)
        self.upload_folder = upload_folder
        self.allowed_extensions = {'mp4', 'mov', 'avi', 'mkv', 'webm'}

    def allowed_file(self, filename: str) -> bool:
        return '.' in filename and filename.rsplit('.', 1)[1].lower() in self.allowed_extensions
    
    def save_uploaded_file(self, file:FileStorage, video_id:str) -> tuple[str,str]:
        if not self.allowed_file(file.filename):
            raise ValueError(f"Invalid file type: {file.filename}")
        
        extension = file.filename.rsplit('.', 1)[1].lower()
        saved_filename = f"{video_id}.{extension}"
        video_path = os.path.join(self.upload_folder, saved_filename)
        file.save(video_path)

        return video_path, saved_filename
    
    def process_uploaded_file(self, video_path:str, interval_seconds:int=10) -> list[dict]:
        print(f"Processing uploaded file: {video_path}")

        try:
            segments = self.processor.process_video_with_gemini(video_path, interval_seconds)
            return segments
        except Exception as e:
            print(f"Failed to process uploaded file: {e}")

    def get_stream_url(self, saved_filename:str, host_url:str)->str:
        return f"{host_url}/stream/{saved_filename}"
    
    def delete_video_file(self, saved_filename:str)->bool:
        try: 
            video_path = os.path.join(self.upload_folder, saved_filename)
            if os.path.exists(video_path):
                os.remove(video_path)
                print(f"Deleted video file: {video_path}")
                return True
            else:
                print(f"Video file not found for deletion: {video_path}")
                return False
        
        except Exception as e:
            print(f"Error deleting video file: {e}")
            return False