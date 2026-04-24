from google import genai
import os
from dotenv import load_dotenv

# Load your API key securely from .env
load_dotenv()
API_KEY = os.environ.get("GOOGLE_API_KEY")

def test_api_key():
    print("Testing Gemini API Key with the new SDK...")
    
    try:
        # Initialize the new client
        client = genai.Client(api_key=API_KEY)
        
        # Send a simple test prompt using the updated method
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents="Hello! This is a quick system test. Please reply with 'Connection successful'."
        )
        
        print("\n✅ API Connection Successful!")
        print("-" * 30)
        print("Model Reply: ", response.text)
        print("-" * 30)
        
    except Exception as e:
        print("\n❌ API Connection Failed!")
        print("Error details:", str(e))

if __name__ == "__main__":
    test_api_key()