import json
import os
from llm import start
from flask import Flask, jsonify, request


# 创建flask对象
app = Flask(__name__)

# 解决数据出现中文乱码问题
app.json.ensure_ascii = False
app.config['JSON_AS_ASCII'] = False


# 创建路由
# 获取data中所有章节名字并返回
@app.route('/api/getChapter', methods=['GET'])
def getChapter():
    filepath = "/Users/Veleda/Desktop/jnu/Y4/FYP/test/data/"
    files = os.listdir(filepath)
    result = list()
    for file in files:
        result.append({"chapterName": file.split('.')[0]})

    return jsonify(result)


# 将query发送到llm，返回llm的答案
@app.route('/api/llm', methods=["POST"])
def llm():
    # 获取所选的章节列表
    chapterList = json.loads(request.get_json().get('chapterList', ''))
    # 获取用户提问的问题
    query = request.get_json().get('query', '')
    res, source_documents = start(chapterList, query)
    result = []
    for x in source_documents:
        source = x.metadata['source'].split('/')[-1]
        result.append({'content': x.page_content, 'source': source})
    response = {'result': res, 'source': result}
    return jsonify(response), 200, {'Content-Type': 'application/json; charset=UTF-8'}


if __name__ == '__main__':
    app.run(debug=True)
