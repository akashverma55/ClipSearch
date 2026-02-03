import google.generativeai as genai

class EmbeddingService:
    def __init__(self, api_key: str):
        genai.configure(api_key=api_key)
        self.model_name = "models/text-embedding-004"

    def get_embedding(self, text:str)->list[float]:
        try:
            result = genai.embed_content(
                model = self.model_name,
                content = text,
                task_type = 'retrieval_document'
            )
            return result['embedding']
        except Exception as e:
            print(f"Error generating embedding: {e}")
            return []
        
    def get_query_embedding(self, query:str)->list[float]:
        try:
            result = genai.embed_content(
                model = self.model_name,
                content = query,
                task_type = 'retrieval_query'
            )
            return result['embedding']
        except Exception as e:
            print(f"Error generating query embedding: {e}")
            return []
        
    def get_batch_embeddings(self, texts:list[str])->list[list[float]]:
        embeddings = []
        for text in texts:
            embedding = self.get_embedding(text)
            if embedding:
                embeddings.append(embedding)
            else:
                embeddings.append([0.0] * 768)
        return embeddings