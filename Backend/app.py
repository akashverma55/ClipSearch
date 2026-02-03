from flask import Flask, request, jsonify, send_file
import time
from flask_cors import CORS
import os
from dotenv import load_dotenv
import uuid

from services.file_handler import FileHandler
from services.youtube_handler import YouTubeHandler
from services.vector_store import VectorStore
from services.video_processor import VideoProcessor
from services.embeddings import EmbeddingService

load_dotenv()

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads/'
MAX_FILE_SIZE = 500 * 1024 * 1024 

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

os.makedirs(UPLOAD_FOLDER, exist_ok = True)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
embedding_service =  EmbeddingService(GEMINI_API_KEY)
vector_store = VectorStore()
youtube_handler = YouTubeHandler(GEMINI_API_KEY)
file_handler = FileHandler(GEMINI_API_KEY, UPLOAD_FOLDER)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "Healthy", "message": "Video-RAG Backend is running"}), 200

@app.route('/upload/youtube', methods=['POST'])
def upload_youtube():
    try:
        data = request.get_json()
        if not data or 'url' not in data:
            return jsonify({'error': 'No YouTube URL provided'}), 400
        
        youtube_url = data['url']
        interval = int(data.get('interval', 10))

        video_id = youtube_handler.extract_video_id(youtube_url)
        if not video_id:
            return jsonify({'error':'Invalid YouTube URL'}), 400
        print(f"Processing YouTube Video: {video_id}")

        video_info = youtube_handler.get_video_info(youtube_url)
        segments = youtube_handler.process_youtube_video(youtube_url, interval)

        if not segments:
            return jsonify({'error': 'No segments generated from video'}), 500
        
        print(f"Generated {len(segments)} segments")

        vector_store.create_collection(video_id)

        for idx, segment in enumerate(segments):
            print(f"Embedding segments {idx+1}/{len(segments)}")
            time.sleep(5)
            embedding = embedding_service.get_embedding(segment['description'])

            if embedding:
                vector_store.add_segment_data(
                    segment,
                    embedding,
                    video_type='YouTube',
                    video_source=youtube_url
                )

        return jsonify({
            'video_id':video_id,
            'video_type': 'YouTube',
            'video_url':youtube_url,
            'title':video_info.get('title'),
            'duration':video_info.get('duration'),
            'thumbnail':video_info.get('thumbnail'),
            'message':'YouTube video processed successfully',
            'segments_processed': len(segments)
        }), 200
    
    except Exception as e:
        print(f"YouTube upload error: {e}")
        return jsonify({'error':str(e)}), 500
    
@app.route('/upload/file', methods=['POST'])
def upload_file():
    try:
        if 'video' not in request.files:
            return jsonify({'error':'No video files provided'}), 400
        file = request.files['video']

        if file.filename == '':
            return jsonify({'error':'No selected file'}), 400 
        
        video_id = str(uuid.uuid4())

        video_path, saved_filename = file_handler.save_uploaded_file(file, video_id)

        interval = int(request.form.get('interval',10))

        print(f"Processing uploaded file: {video_id}")

        segments = file_handler.process_uploaded_file(video_path, interval)

        if not segments:
            return jsonify({'error':'No segments generated from video'}), 500
        
        print(f"Generated {len(segments)} segments")

        stream_url = file_handler.get_stream_url(saved_filename, request.host_url)

        vector_store.create_collection(video_id)

        for idx, segment in enumerate(segments):
            print(f"Embedding segment {idx+1}/{len(segments)}")
            time.sleep(5)
            embedding = embedding_service.get_embedding(segment['description'])
            if embedding:
                vector_store.add_segment_data(
                    segment,
                    embedding,
                    video_type="FILE",
                    video_source=stream_url
                )

        return jsonify({
            'video_id':video_id,
            'video_type':"FILE",
            'stream_url':stream_url,
            'filename':saved_filename,
            'message':'Video file processed successfully',
            'segments_processed':len(segments)
        })
    
    except ValueError as e:
        return jsonify({'error':str(e)}), 400
    except Exception as e:
        print('File upload error: {e}')
        return jsonify({'error':str(e)}), 500
    
@app.route('/stream/<filename>', methods=['GET'])
def stream_video(filename):
    try:
        video_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if not os.path.exists(video_path):
            return jsonify({'error':'Video not found'}), 400
        return send_file(video_path, mimetype='video/mp4')
    except Exception as e:
        return jsonify({'error':str(e)}), 500 
    
@app.route('/search', methods=['POST'])
def search_clip():
    try:
        data = request.get_json()
        if not data or 'query' not in data or 'video_id' not in data:
            return jsonify({'error':'Missing query or video_id'}), 400
        
        query = data['query']
        video_id = data['video_id']
        top_k = data.get('top_k', 5)

        print(f"Searching video {video_id} for: {query}")

        vector_store.create_collection(video_id)
        query_embedding = embedding_service.get_query_embedding(query)

        if not query_embedding:
            return jsonify({'error':'Failed to generate query embedding'}), 500
        
        results = vector_store.search(query_embedding,top_k)

        return jsonify({
            'query':query,
            'results':results
        }), 200
    
    except Exception as e:
        print('Search error: {e}')
        return jsonify({'error':str(e)}), 500
    
@app.route('/videos', methods=['GET'])
def list_videos():
    try:
        collections = vector_store.client.list_collections()
        videos = []

        for collection in collections:
            video_id = collection.name.replace('video_','')
            vector_store.create_collection(video_id)
            segments = vector_store.get_all_segments()

            if segments:
                videos.append({
                    'video_id':video_id,
                    'video_type':segments[0]['video_type'],
                    'video_source':segments[0]['video_source'],
                    'segment_count':len(segments)
                })

        return jsonify({'videos':videos}), 200
    
    except Exception as e:
        return jsonify({'error':str(e)}), 500
    
@app.route('/video/<video_id>/segments', methods=['GET'])
def get_video_segments(video_id):
    try:
        vector_store.create_collection(video_id)
        segments = vector_store.get_all_segments()

        return jsonify({
            'video_id':video_id,
            'segments':segments
        }), 200
    
    except Exception as e:
        return jsonify({'error':str(e)}), 500

if __name__=='__main__':
    import socket
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)

    print(f"\n{'='*50}")
    print(f"🚀 Video-RAG Backend Starting...")
    print(f"📡 Local: http://localhost:5000")
    print(f"📱 Network: http://{local_ip}:5000")
    print(f"{'='*50}\n")

    app.run(debug=True, host='0.0.0.0', port=5000)