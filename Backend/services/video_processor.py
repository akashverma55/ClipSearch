import google.generativeai as genai
import time
import json
import re

class VideoProcessor:
    def __init__(self, api_key: str):
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel("gemini-2.5-flash")

    def process_video_with_gemini(self, video_path:str, interval_seconds:int=10)->list[dict]:
        print("Uploading video to Gemini...")

        video_file = genai.upload_file(video_path)

        while video_file.state.name == 'PROCESSING':
            time.sleep(5)
            video_file = genai.get_file(video_file.name)

        if video_file.state.name == 'FAILED':
            print("Failed to process uploaded video.")
        
        print("Video uploaded successfully.")

        prompt = f"""Analyze this entire video and provide a detailed description for every {interval_seconds} seconds.

            For each {interval_seconds}-second segment, describe:
            - What is visible (slides, people, objects, actions, text on screen)
            - What is being said (complete thoughts and sentences, even if they span multiple segments)
            - Important context or events

            Return ONLY a valid JSON array with this exact structure:
            [
            {{"timestamp": 0, "description": "Opening slide with company logo. Speaker introduces Q3 revenue review and mentions upcoming challenges."}},
            {{"timestamp": {interval_seconds}, "description": "CEO walks to whiteboard showing graphs. Discusses the main reason for decline was reduced marketing budget in July."}}
            ]

            Important: Include complete sentences and thoughts in descriptions, don't cut them off at segment boundaries."""

        print("Sending video analysis request to Gemini...")

        try:
            response = self.model.generate_content([prompt, video_file])
            results = VideoProcessor.parse_gemini_response(response.text)
            genai.delete_file(video_file.name)
            return results
        except Exception as e:
            print(f"Error analyzing video: {e}")
            genai.delete_file(video_file.name)
            raise

    @staticmethod
    def parse_gemini_response(response_text:str)->list[dict]:
        json_match = re.search(r'```json\s*(.*?)\s*```', response_text, re.DOTALL)

        if json_match:
            json_str = json_match.group(1)

        else:
            json_match =  re.search(r'\[\s*\{.*\}\s*\]', response_text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
            else:
                json_str = response_text

        try: 
            data = json.loads(json_str)

            results = []
            for item in data:
                if 'timestamp' in item and 'description' in item:
                    results.append({
                        'timestamp': float(item['timestamp']),
                        'description': item['description']
                    })

            return results
        
        except Exception as e:
            print(f"Error parsing Gemini response JSON: {e}")
            return VideoProcessor.fallback_parse(response_text)
        
    @staticmethod
    def fallback_parse(text: str)-> list[dict]:
        results = []
        lines = text.split('\n')
        current_timestamp = None
        current_description = []

        for line in lines:
            timestamp_match = re.match(r'timestamp["\s:]*(\d+)', line, re.IGNORECASE)
            
            if timestamp_match:
                if current_timestamp is not None and current_description:
                    results.append({
                        'timestamp': float(current_timestamp),
                        'description': ' '.join(current_description).strip()
                    })

                current_timestamp = timestamp_match.group(1)
                current_description = []

            desc_match = re.match(r'description["\s:]*["\'](.+?)["\']', line, re.IGNORECASE)
            if desc_match:
                current_description.append(desc_match.group(1))

        if current_timestamp is not None and current_description:
            results.append({
                'timestamp': float(current_timestamp),
                'description': ' '.join(current_description).strip()
            })

        return results