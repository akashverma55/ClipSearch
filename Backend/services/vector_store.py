import chromadb
from chromadb.config import Settings
from typing import Optional

class VectorStore:
    def __init__(self, persist_directory: str = "./chroma_db"):
        self.client = chromadb.Client(Settings(
            persist_directory = persist_directory,
            anonymized_telemetry = False
        ))
        self.collection = None
        self.current_video_id = None

    def create_collection(self, video_id:str):
        collection_name = f"video_{video_id}"
        try:
            self.collection = self.client.get_collection(collection_name)
            print(f"Loaded existing collection: {collection_name}")
        except:
            self.collection = self.client.create_collection(
                name = collection_name,
                metadata = {"hnsw:space": "cosine"}
            )
            print(f"Created new collection: {collection_name}")
        self.current_video_id = video_id
        return self.collection
    
    def add_segment_data(self, segment_data: dict, embeddings: list[float], video_type:str, video_source:str):
        if not self.collection:
            raise ValueError("Collection not initialized. Call create_collection first.")
        
        try:
            segment_id = f"segment_{str(segment_data['timestamp']).replace('.', '_')}"
            self.collection.add(
                ids = [segment_id],
                embeddings = [embeddings],
                metadatas = [{
                    "timestamp": float(segment_data['timestamp']),
                    "description": segment_data['description'],
                    "video_type": video_type,
                    "video_source": video_source
                }],
            )
            print(f"Added segment {segment_id} to collection.")
            return True
        except Exception as e:
            print(f"Error adding segment data: {e}")
            return False
        
    def add_batch_segment_data(self, segment_data: list[dict], embeddings: list[list[float]], video_str:str, video_source:str):
        if not self.collection:
            raise ValueError("Collection not initialized. Call create_collection first.")
        
        if len(segment_data) != len(embeddings):
            raise ValueError("Segment data and embeddings length mismatch.")
        
        try:
            ids = [f"segment_{str(seg['timestamp']).replace('.', '_')}" for seg in segment_data]
            metadatas = [
                {
                    "timestamp": float(seg['timestamp']),
                    "description": seg['description'],
                    "video_type": video_str,
                    "video_source": video_source
                } 
                for seg in segment_data
            ]

            self.collection.add(
                ids=ids,
                embeddings=embeddings,
                metadatas=metadatas
            )

            return True
        except Exception as e:
            print(f"Error adding batch segment data: {e}")
            return False
        
    def search(self, query_embedding: list[float], top_k: int = 5, min_similarity: float = 0)-> list[dict]:
        if not self.collection:
            raise ValueError("Collection not initialized. Call create_collection first.")
        
        try:
            results = self.collection.query(
                query_embeddings = [query_embedding],
                n_results = top_k,
            )

            matches = []
            if results['ids'] and len(results['ids'][0])>0:
                for i in range(len(results['ids'][0])):
                    similarity = 1 - results['distances'][0][i]
                    if similarity >= min_similarity:
                        matches.append({
                            'timestamp': results['metadatas'][0][i]['timestamp'],
                            'description': results['metadatas'][0][i]['description'],
                            'video_type': results['metadatas'][0][i]['video_type'],
                            'video_source': results['metadatas'][0][i]['video_source'],
                            'similarity': round(similarity, 4)
                        })
            
            return matches
        except Exception as e:
            print(f"Error during search: {e}")
            return []
        
    def get_all_segments(self) -> list[dict]:
        if not  self.collection:
            return []
        
        try:
            results = self.collection.get()
            segments = []

            if results['ids']:
                for i in range(len(results['ids'])):
                    segments.append({
                        'timestamp': results['metadatas'][i]['timestamp'],
                        'description': results['metadatas'][i]['description'],
                        'video_type': results['metadatas'][i]['video_type'],
                        'video_source': results['metadatas'][i]['video_source'],
                    })
            return sorted(segments, key=lambda x: x['timestamp'])
        
        except Exception as e:
            print(f"Error retrieving all segments: {e}")
            return []
        
    def get_segment_at_timestamp(self, timestamp: float, tolerance: float = 1.0)-> Optional[dict]:
        segments = self.get_all_segments()
        for segment in segments:
            if abs(segment['timestamp'] - timestamp) <= tolerance:
                return segment
        return None
    
    def delete_collection(self, video_id:str)-> bool:
        try:
            collection_name = f"video_{video_id}"
            self.client.delete_collection(collection_name)
            print(f"Deleted collection: {collection_name}")

            if self.current_video_id == video_id:
                self.collection = None
                self.current_video_id = None
            
            return True
        except Exception as e:
            print(f"Error deleting collection: {e}")
            return False
    
    def get_collection_count(self)-> int:
        if not self.collection:
            return 0
        try:
            count = self.collection.count()
            return count
        except Exception as e:
            print(f"Error getting collection count: {e}")
            return 0
        
    def list_all_videos(self)-> list[str]:
        try:
            collections = self.client.list_collections()
            return [col.name.replace('video_', '') for col in collections]
        except Exception as e:
            print(f"Error listing all videos: {e}")
            return []