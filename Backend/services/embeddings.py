import google.generativeai as genai

class EmbeddingService:
    def __init__(self, api_key: str):
        genai.configure(api_key=api_key)
        self.model_name = "models/gemini-embedding-001"

    def get_embedding(self, text: str) -> list[float]:
        try:
            result = genai.embed_content(
                model=self.model_name,
                content=text,
                task_type='retrieval_document'
            )
            return result['embedding']
        except Exception as e:
            print(f"❌ Error generating embedding: {e}")
            return []

    def get_batch_embeddings(self, texts: list[str]) -> list[list[float]]:
        """Optimized: Sends all segments in ONE API call"""
        try:
            result = genai.embed_content(
                model=self.model_name,
                content=texts, # Pass the whole list here
                task_type='retrieval_document'
            )
            return result['embedding']
        except Exception as e:
            print(f"❌ Error in batch embedding: {e}")
            # Fallback to zero-vectors if the whole batch fails
            return [[0.0] * 768 for _ in texts]

    def get_query_embedding(self, query: str) -> list[float]:
        try:
            result = genai.embed_content(
                model=self.model_name,
                content=query,
                task_type='retrieval_query'
            )
            return result['embedding']
        except Exception as e:
            print(f"❌ Error generating query embedding: {e}")
            return []