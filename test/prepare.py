import os
from string import punctuation
import re

# str库的punctuation只是英文字符，加上一些特殊符号和全角符号
punctuation = punctuation + '【】『』@#э￥%&*（）'


# 读取txt文件
def readTxt(path):
    doc = open(path, 'rb').read().decode(encoding='UTF-8')
    return doc


# 将文档内的章节名分割出来
def split_title(test_sentence):
    pattern = re.compile('([\u4e00-\u9fa5])([1-9]?[0-9])([\u4e00-\u9fa5]\n)([\u4e00-\u9fa5]*)(\n)')
    title = re.search(pattern, test_sentence)
    new_sentence = re.sub(pattern, '', test_sentence)
    title = re.sub('\n', ' ', title.group(0))
    return title, new_sentence


# 数据预处理——数据清洗
def pre(path):
    test_sentence = readTxt(path)

    # 数据清洗
    # 特殊符号全部换成空格
    process_dicts = {i: '' for i in punctuation}
    punc_table = str.maketrans(process_dicts)
    test_sentence = test_sentence.translate(punc_table)

    # 将文本从被替换的空格进行分割
    test_sentence_list = test_sentence.lower().split()
    # 将分割的文本合并
    test_sentence = '\n'.join([str(elem) for i, elem in enumerate(test_sentence_list)])

    title, test_sentence = split_title(test_sentence)

    # 将清洗后的文本保存成txt
    txt = open('data/' + title + '.txt', 'w')
    txt.write(test_sentence)

    return 'data/' + title + '.txt'


# 数据预处理
# 主程序
def main():
    filepath = "../數據/西游记白话文"
    files = os.listdir(filepath)
    for file in files:
        path = os.path.join(filepath, file)
        if os.path.isfile(path):
            pre(path)


if __name__ == '__main__':
    main()
