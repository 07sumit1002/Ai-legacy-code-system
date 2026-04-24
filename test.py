from google import genai

# Configure your API key
API_KEY = "AIzaSyBVwsWFYJ5EqZWzH_4c5HtcIDwpALk3Ijo"


# Configure your API key directly in the client
# API_KEY = "gen-lang-client-0317658831"

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