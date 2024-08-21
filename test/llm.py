import os

from langchain.chains import RetrievalQA
from langchain.llms import LlamaCpp
from langchain.prompts import PromptTemplate
from langchain.retrievers import ContextualCompressionRetriever, EnsembleRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor

import embedding


def start(chapterList, query):
    # 通用模版
    template = """请利用下列的西游记原文来回答问题。
    如果你不知道答案，就说"根据已知信息无法回答该问题" 或"没有提供足够的相关信息"，不要试图编造答案。
    答案最多使用两个句子并保持简洁，不要重复回答相同的内容，并只能用简体中文回答。
    答案请勿使用任何表情符号、URL 链接、程序代码、列表、空行或所提供的示例。
    请仿照以下示例进行推理步骤，最后只需要输出回答。但注意需要根据你的问题推理出答案，不可直接使用示例。
    
    示例：
    ###问题：谁住在花果山？
    ###推理步骤：回答前请逐步思考。首先分析问题，发现需要找到与问题中的地方强烈关联角色，从而推理出谁住在这个地方。然后从原文中定位问题相关的句子，找出关键字所在的上下文，发现孙悟空离开后就驾着筋斗云回到了花果山，可以推断住在花果山的角色是孙悟空。
    ###回答：孙悟空。
    
    ###问题：观音菩萨喜欢吃人参果吗？
    ###推理步骤：回答前请逐步思考。首先分析问题，发现需要找到问题中角色对某一物件的评价，从而分析角色对物件的情感偏好。然后从原文中定位相关的句子，找出关键字所在的上下文，发现观音菩萨吃了人参果，但没有对人参果进行任何评价，因此无法根据已知信息推理出答案。
    ###回答：根据已知信息无法回答该问题。
    
    ###问题：金角大王和银角大王是谁？
    推理步骤：回答前请逐步思考。首先分析问题，发现需要找出问题提及的角色的身份。然后从原文中定位相关的句子，找出关键字所在的上下文，发现原文中"原来金角和银角是太上老君手下两个看炉子的童子。"直接存在答案。
    ###回答：金角和银角是太上老君手下两个看炉子的童子。
    
    ###问题：白骨精被打死了几次？
    ###推理步骤：回答前请逐步思考。首先分析问题，发现需要找出问题提及的角色发生某一件事情，并统计发生在这个角色身上的次数。然后从原文中定位相关的句子，找出关键字所在的上下文，发现白骨精被孙悟空用棒子打了三次，根据原文中"悟空忍着疼，挣扎起来，一棒子打死了妖怪。被打死的妖怪现了原形，成了一堆白骨，在脊梁骨上还刻有“白骨夫人”四个字。"推论，白骨精只被打死了一次。
    ###回答：一次。
    
    ###问题：女儿国的女王想和谁结婚？
    ###推理步骤：回答前请逐步思考。首先分析问题，然后从原文中定位相关的句子，找出关键字所在的上下文，发现原文中"女王让太师作媒人，到驿馆向唐僧求亲。"直接存在答案。
    ###回答：唐僧。
    
    现在开始，根据下面的西游记原文，回答问题：

    {context}
    ###问题：{question}
    ###回答："""

    PROMPT = PromptTemplate(template=template, input_variables=["context", "question"])

    llm = LlamaCpp(
        model_path="llama.cpp/models/llama-2-7b.gguf.q4_K_S.bin",
        temperature=0.00,
        max_tokens=1024,
        top_p=0.4,
        verbose=False,  # 不显示log信息
        n_ctx=16184,
        stop=["###", "\n\n"]
    )
    # 上下文压缩器
    compressor = LLMChainExtractor.from_llm(llm)
    # 获取父文档检索器和关键字检索器
    chroma_retriever, bm25_retriever = embedding.getContent(chapterList)

    #
    # 通过更改search_type对检索算法进行对比实验
    # retriever = docsearch.as_retriever(
    #     search_type="mmr",
    #     search_kwargs={'lambda_mult': 0.3, 'fetch_k': 15, "k": 5}
    # )

    # 构建压缩检索器
    compression_retriever = ContextualCompressionRetriever(base_compressor=compressor,
                                                           base_retriever=chroma_retriever)
    # 初始化集成檢索器（bm25 + Parent Document Retriever
    bm25_retriever.k = 1
    ensemble_retriever = EnsembleRetriever(retrievers=[bm25_retriever, compression_retriever], weights=[0.3, 0.7])

    # print("chain_type:stuff")
    # start = time.time()

    # 实例化一个RetrievalQA链
    qa_chain = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=ensemble_retriever,
        chain_type_kwargs={"prompt": PROMPT},
        return_source_documents=True,
        verbose=True)

    # end = time.time()
    response = qa_chain(query)
    # print(time.strftime("%H:%M:%S", time.gmtime(end - start)))
    return response['result'], response['source_documents']
