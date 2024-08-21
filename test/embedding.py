import os.path
import jieba
from langchain.document_loaders import TextLoader
from langchain.retrievers import ParentDocumentRetriever
from langchain.storage import InMemoryStore
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.vectorstores import Chroma
from langchain_community.embeddings import ModelScopeEmbeddings
from langchain_community.retrievers import BM25Retriever

import prepare


def getContent(chapterList):
    filepath = "/Users/Veleda/Desktop/jnu/Y4/FYP/test/data/"
    suffix = ".txt"
    # files = os.listdir(filepath)
    loader = TextLoader(filepath + chapterList[0] + suffix, encoding='utf-8')
    documents = loader.load()

    # print("分割文档")
    if len(chapterList) > 1:
        for fi in chapterList:
            fi_d = os.path.join(filepath, fi)
            if fi == filepath[0]:
                continue
            documents = documents + TextLoader(fi_d + suffix, encoding='utf-8').load()

    # 建立metadata索引
    # metadata = []
    # page_content = [doc.page_content for doc in documents]
    #
    # for i in range(len(documents)):
    #     source = documents[i].metadata['source']
    #     chapter = re.sub("([\u4e00-\u9fa5])([1-9]?[0-9])([\u4e00-\u9fa5])", '', source)
    #     chapter = chapter.split('.')[0]
    #     metadata.append({"source": source, "chapter_name": chapter})

    # 文本分割实验，透过更改chunk_size比对实验分割长度对的影响
    # splitter = RecursiveCharacterTextSplitter(chunk_size=256, separators=['\n', '”。', '。'])
    # docsearch = Chroma.from_documents(splitter)

    embeddings = ModelScopeEmbeddings(model_id="damo/nlp_corom_sentence-embedding_chinese-base")
    # 创建向量数据库对象，collection_metadata中对余弦相似度
    vectorstore = Chroma(
        collection_name="split_parents", embedding_function=embeddings, collection_metadata={"hnsw:space": "cosine"}
    )
    parent_splitter = RecursiveCharacterTextSplitter(chunk_size=2048, chunk_overlap=0, separators=['\n', '。”', '。'])
    # 创建子文档分割器
    child_splitter = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=0, separators=['\n', '。”', '！”', '。'])
    # 创建内存存储对象
    store = InMemoryStore()
    # 创建父文档检索器
    chroma_retriever = ParentDocumentRetriever(
        vectorstore=vectorstore,
        docstore=store,
        child_splitter=child_splitter,
        parent_splitter=parent_splitter,
        search_kwargs={'lambda_mult': 0.7, 'fetch_k': 5, "k": 1},
        search_type="mmr"
    )
    # 添加文档集(混合搜索)
    chroma_retriever.add_documents(documents, ids=None)

    # bm25 分割文档
    splitter = RecursiveCharacterTextSplitter(chunk_size=1024, separators=['\n', '”。', '。'])
    split_docs = splitter.split_documents(documents)
    # preprocess_func是文本的预处理函数
    bm25_retriever = BM25Retriever.from_documents(split_docs, preprocess_func=cut_words, k=1)

    return chroma_retriever, bm25_retriever


# 使用结巴分词作关键字提取
def cut_words(text):
    """
    利用jieba库进行文本分词
    """
    # 直接返回 list
    return jieba.lcut(text)
