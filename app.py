import os
import streamlit as st
import tempfile
import shutil
from dotenv import load_dotenv

from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings
from langchain_community.vectorstores import FAISS
try:
    from langchain.chains import create_retrieval_chain
    from langchain.chains.combine_documents import create_stuff_documents_chain
except ImportError:
    from langchain_classic.chains import create_retrieval_chain
    from langchain_classic.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Load environment variables
load_dotenv()

st.set_page_config(page_title="Multi-Codebase Query Agent", layout="wide")

# Persistent Directory setup
VECTOR_STORE_DIR = "vector_stores"
UPLOADED_DATA_DIR = "uploaded_data"
os.makedirs(VECTOR_STORE_DIR, exist_ok=True)
os.makedirs(UPLOADED_DATA_DIR, exist_ok=True)

class PatchedEmbeddings(GoogleGenerativeAIEmbeddings):
    def embed_documents(self, texts):
        return [self.embed_query(t) for t in texts]

def get_embeddings():
    return PatchedEmbeddings(model="models/gemini-embedding-2")

@st.cache_resource
def load_vector_store(codebase_name):
    index_path = os.path.join(VECTOR_STORE_DIR, codebase_name)
    if os.path.exists(index_path):
        return FAISS.load_local(
            index_path, 
            get_embeddings(),
            allow_dangerous_deserialization=True
        )
    return None

def process_and_ingest_files(uploaded_files, codebase_name):
    # Create persistent data directory to adhere to keeping physical source files
    cb_data_dir = os.path.join(UPLOADED_DATA_DIR, codebase_name)
    os.makedirs(cb_data_dir, exist_ok=True)
    
    # Text abstraction and splitting
    documents = []
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=800,
        chunk_overlap=150
    )
    
    progress_text = st.empty()
    
    for i, file in enumerate(uploaded_files):
        # Read the abstract file content
        content = file.read()
        file_path = os.path.join(cb_data_dir, file.name)
        
        # Save exact copy of the underlying code
        with open(file_path, "wb") as f:
            f.write(content)
            
        progress_text.text(f"Processing source file {file.name} ({i+1}/{len(uploaded_files)})...")
        try:
            # Leverage TextLoader implicitly on the absolute paths (handles most code paradigms)
            loader = TextLoader(file_path, autodetect_encoding=True)
            documents.extend(loader.load())
        except Exception as e:
            st.warning(f"Failed to process source structure {file.name}: {e}")

    progress_text.text("Parsing Syntax & Generating Native Embeddings Network... (This may take a minute).")
    chunks = text_splitter.split_documents(documents)
    vector_store = FAISS.from_documents(chunks, get_embeddings())
    
    # Save the FAISS mapping locally
    save_path = os.path.join(VECTOR_STORE_DIR, codebase_name)
    vector_store.save_local(save_path)
    
    progress_text.text("Ingestion Matrix Online!")
    progress_text.empty()
    return True

def main():
    st.title("IT Services Multi-Codebase Query Agent")
    st.markdown("Automated ingestion and AI query integration for historical and modern architectural codebases.")
    
    if not os.environ.get("GOOGLE_API_KEY"):
        st.error("Please bind your GOOGLE_API_KEY in the environment or a .env file.")
        return

    # Isolate memory stores per codebase route natively inside streamlit
    if "histories" not in st.session_state:
        st.session_state.histories = {}

    # Render Multi-Model Dashboard Sidebar
    with st.sidebar:
        st.header("Codebase Dashboard")
        
        # Ingestion Matrix Panel
        st.subheader("Upload Architecture")
        with st.form("upload_form", clear_on_submit=True):
            cb_name_input = st.text_input("Project Definition", help="e.g., 'Rust_Server_V3'")
            
            # File Type parameter intentionally omitted to implicitly support Fortran, C, Rust, Go, PBX, etc.
            uploaded_files = st.file_uploader(
                "Upload codebase snippets (Fortran, Cobol, C, Java, JavaScript, Rust, Dart, PHP, etc.)", 
                accept_multiple_files=True
            )
            submit_upload = st.form_submit_button("Index System")

        if submit_upload:
            if not cb_name_input.strip():
                st.error("Please define a valid project alias.")
            elif not uploaded_files:
                st.error("Please mount at least one file reference.")
            else:
                cb_ref = cb_name_input.strip()
                if os.path.exists(os.path.join(VECTOR_STORE_DIR, cb_ref)):
                    st.warning(f"Architecture '{cb_ref}' already exists in Vector Store!")
                else:
                    with st.spinner("Compiling and vectorizing code natively..."):
                        if process_and_ingest_files(uploaded_files, cb_ref):
                            st.success(f"System '{cb_ref}' processed and routed!")

        st.divider()
        
        # System Selection Matrix
        st.subheader("Active System Hub")
        existing_cbs = [d for d in os.listdir(VECTOR_STORE_DIR) if os.path.isdir(os.path.join(VECTOR_STORE_DIR, d))] if os.path.exists(VECTOR_STORE_DIR) else []
        
        # Map manual legacy index if still hovering
        if os.path.exists("faiss_legacy_index") and "Legacy Code Base (Default)" not in existing_cbs:
            # Move the old index into the new standard architecture manually behind scenes
            try:
                os.rename("faiss_legacy_index", os.path.join(VECTOR_STORE_DIR, "Legacy_Base"))
                existing_cbs.append("Legacy_Base")
            except:
                pass
            
        selected_cb = st.selectbox("Select Target Codebase", options=["[General Chat]"] + existing_cbs)
        
        if selected_cb and selected_cb != "[General Chat]":
            if st.button(f"🗑️ Delete '{selected_cb}'", use_container_width=True):
                # Delete persistent files and vectors securely to avoid clutter
                shutil.rmtree(os.path.join(VECTOR_STORE_DIR, selected_cb), ignore_errors=True)
                shutil.rmtree(os.path.join(UPLOADED_DATA_DIR, selected_cb), ignore_errors=True)
                if selected_cb in st.session_state.histories:
                    del st.session_state.histories[selected_cb]
                st.rerun()

    # Core Query Module 
    if selected_cb and selected_cb != "[General Chat]":
        active_codebase = selected_cb
        st.subheader(f"Query Node: `{active_codebase}`")
        
        # Inject standard architecture RAG
        vector_store = load_vector_store(active_codebase)
        if vector_store is None:
            st.error("Fatal Load Exception! Vector DB corrupted.")
            return
            
        retriever = vector_store.as_retriever(search_kwargs={"k": 4})
        
        # Map Gemini Latest Flagship Endpoint
        llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0)
        
        system_prompt = (
            "You are an embedded software engineering prodigy. You are capable of auditing ancient architectural implementations (Fortran, LISP, ALGOL, Ada) natively alongside strictly modern codebases (Rust, Next.js, Zig, Carbon).\n"
            "CRITICAL GUARDRAIL: You must strictly answer ONLY questions related to programming, software architecture, code analysis, or the provided codebase. If the user's question is about general knowledge, history, daily life, politics, or anything unrelated to software engineering, you MUST politely decline to answer and state that you are exclusively a Code Query Agent.\n"
            "Use the provided exact context snippets below to decipher frameworks and answer the underlying question precisely.\n"
            "If the implementation data lacks clarity, explicitly notify the user.\n\n"
            "Active Implementation Nodes:\n{context}"
        )
        prompt = ChatPromptTemplate.from_messages([
            ("system", system_prompt),
            ("human", "{input}"),
        ])
        question_answer_chain = create_stuff_documents_chain(llm, prompt)
        rag_chain = create_retrieval_chain(retriever, question_answer_chain)

        # Allocate session memory node
        if active_codebase not in st.session_state.histories:
            st.session_state.histories[active_codebase] = []

        # Reconstruct message objects
        for message in st.session_state.histories[active_codebase]:
            with st.chat_message(message["role"]):
                st.markdown(message["content"])
                if "sources" in message and message["sources"]:
                    with st.expander("Explore Decoded Code Nodes"):
                        for i, doc in enumerate(message["sources"]):
                            source_file = os.path.basename(doc.metadata.get('source', 'Unknown'))
                            st.markdown(f"**Node {i+1}** - Output `{source_file}`")
                            st.code(doc.page_content)

        # Map UI Inputs
        if user_query := st.chat_input(f"Analyze the structural context of {active_codebase}..."):
            st.session_state.histories[active_codebase].append({"role": "user", "content": user_query})
            with st.chat_message("user"):
                st.markdown(user_query)

            # Fire Agent Thread
            with st.chat_message("assistant"):
                with st.spinner("Auditing Codebase Architecture..."):
                    try:
                        response = rag_chain.invoke({"input": user_query})
                        answer = response.get("answer", "No analysis found.")
                        source_docs = response.get("context", [])
                        
                        st.markdown(answer)
                        
                        if source_docs:
                            with st.expander("Explore Decoded Code Nodes"):
                                for i, doc in enumerate(source_docs):
                                    source_file = os.path.basename(doc.metadata.get('source', 'Unknown'))
                                    st.markdown(f"**Node {i+1}** - Output `{source_file}`")
                                    st.code(doc.page_content)
                    except Exception as e:
                        answer = f"Engine Failure: {str(e)}"
                        st.error(answer)
                        source_docs = []
                        
            st.session_state.histories[active_codebase].append({
                "role": "assistant",
                "content": answer,
                "sources": source_docs
            })
    else:
        st.subheader("General Chat & Snippet Analysis")
        st.markdown("Paste small code snippets (4-5 lines) or ask general programming questions here without mounting a full codebase.")

        # Allocate session memory node
        if "General Chat" not in st.session_state.histories:
            st.session_state.histories["General Chat"] = []

        # Reconstruct message objects
        for message in st.session_state.histories["General Chat"]:
            with st.chat_message(message["role"]):
                st.markdown(message["content"])

        # Map UI Inputs
        if user_query := st.chat_input("Ask a general question or paste a snippet..."):
            st.session_state.histories["General Chat"].append({"role": "user", "content": user_query})
            with st.chat_message("user"):
                st.markdown(user_query)

            # Fire Agent Thread for General Chat
            with st.chat_message("assistant"):
                with st.spinner("Thinking..."):
                    try:
                        llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", temperature=0)
                        messages_list = [
                            ("system", "You are an embedded software engineering prodigy.\n"
                                       "CRITICAL GUARDRAIL: You must strictly answer ONLY questions related to programming, software architecture, or code analysis. If the user asks about unrelated topics (like cooking, weather, politics, or general knowledge), you MUST politely decline to answer and state that your sole purpose is coding assistance.\n"
                                       "Answer general programming questions and analyze short code snippets accurately.")
                        ]
                        # Inject conversational history 
                        for msg in st.session_state.histories["General Chat"][:-1]:
                            if msg["role"] == "user":
                                messages_list.append(("human", msg["content"]))
                            elif msg["role"] == "assistant":
                                messages_list.append(("ai", msg["content"]))
                                
                        messages_list.append(("human", "{input}"))
                        prompt = ChatPromptTemplate.from_messages(messages_list)
                        chain = prompt | llm
                        response = chain.invoke({"input": user_query})
                        answer = response.content
                        st.markdown(answer)
                    except Exception as e:
                        answer = f"Engine Failure: {str(e)}"
                        st.error(answer)
                        
            st.session_state.histories["General Chat"].append({
                "role": "assistant",
                "content": answer
            })

if __name__ == "__main__":
    main()
