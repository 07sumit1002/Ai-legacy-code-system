# 🚀 Multi-Codebase AI Query Agent

An enterprise-grade, conversational codebase intelligence agent built on top of **Streamlit**, **LangChain**, and **Google Gemini GenAI**. This system acts as a native engineering copilot capable of interpreting antiquated architectures (Fortran, COBOL, ALGOL) and modern standards (Rust, Python, Go) locally.

Instead of navigating massive legacy codebases manually, this app vectorizes raw code files using the highly advanced `gemini-embedding-2` model, securely storing them locally with **FAISS-CPU**, and uses standard multi-history Retrieval-Augmented Generation (RAG) tied directly to a hyper-optimized context length via `gemini-2.5-flash`.

![App Display](https://img.shields.io/badge/Streamlit-Dashboard-red.svg?style=for-the-badge&logo=streamlit)
![LangChain](https://img.shields.io/badge/LangChain-Integration-blue.svg?style=for-the-badge&logo=langchain)
![Gemini AI](https://img.shields.io/badge/Google-GenAI-amber.svg?style=for-the-badge&logo=google)

---

## ✨ Core Features
1. **Multi-Project Management Dashboard:** Upload and ingest various distinct codebases asynchronously. The UI natively separates file states so you can seamlessly query a `COBOL-Banking` node and immediately switch to a `Rust-Microservice` node without polluting the response generation context.
2. **Generative Query Architecture (RAG):** Extracts and cites localized file sources whenever answering queries allowing you to confidently view the structural origins (or snippets) the model derived its architecture understanding from.
3. **Implicit Multilingual Abstraction:** Built on standard byte-abstractions, the ingestion pipeline implicitly supports all underlying syntax rules ranging safely between C++, Dart, LISP, and plain text documentation.
4. **Standalone General Agent Copilot:** Supports general queries or short sub-5 line snippet assessments securely when ignoring custom context trees natively.

---

## 🛠 Required Technologies
Ensure you have the following prerequisites activated within your development environment:
* Python `3.10+`
* Active `Google Generative AI` Developer Key provisioned for Flash endpoint testing.

---

## ⚙️ How to Setup

### 1. Clone the project locally
```bash
git clone https://github.com/your-username/ai-legacy-code-system.git
cd ai-legacy-code-system
```

### 2. Configure Local Virtual Environment and Dependencies
It is strictly recommended to keep variables isolated utilizing standard python environments.
```bash
# Initialize and activate the virtual environment
python -m venv venv
venv\Scripts\activate   # Use `source venv/bin/activate` for unix execution

# Map and install structural modules
pip install -r requirements.txt
```

### 3. Mount Secrets 
Copy the default environmental structures securely into a `.env` deployment block avoiding public commits (as registered securely in `.gitignore`).

```bash
cp .env.example .env
```
Once generated, assign your explicit API Key utilizing your favorite editor.
`GOOGLE_API_KEY="AIzaSyXXXXXXXXXXXXXXXXXX"`

### 4. Deploy UI Gateway
Launch the agent natively!
```bash
streamlit run app.py
```

---

## 🏗 Sub-Directory Architecture

* `app.py`: Primary Streamlit orchestration node mapping interactions and pipeline embedding executions natively.
* `vector_stores/`: Implicitly tracks, hosts, and preserves structural `.faiss` vector arrays securely indexed to specific codebases upon user-upload.
* `uploaded_data/`: Caching mechanism enforcing data retention across codebase uploads dynamically mapped for source citation.

*Note: Both database management structures will be generated implicitly initialized upon running the UI!*
