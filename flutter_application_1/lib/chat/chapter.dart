// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat/models/ChatModel.dart';
import 'package:flutter_application_1/chat/models/DataModel.dart';
import 'chat.dart';
import 'models/ChapterListModel.dart';

//章节选择页
class ChapterChoose extends StatelessWidget {
  const ChapterChoose({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            centerTitle: true, //让标题置中
            title: const Text('章节选择',
                style: TextStyle(color: Color.fromARGB(242, 255, 255, 255))),
            backgroundColor: const Color.fromARGB(218, 0, 137, 123),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(); //返回上一页
              },
            ),
          ),
          body: const ChapterList()),
    );
  }
}

class ChapterList extends StatefulWidget {
  const ChapterList({super.key});

  @override
  _ChapterListState createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  List<ChapterListModel> chapterListModel = [];
  List<String> chosenChapter = [];
  int _currentPage = 0; // 当前页码
  _getChapters() async {
    var url = 'http://127.0.0.1:5000/api/getChapter';
    var httpClient = HttpClient();

    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        // 获取response的body
        var json = await response.transform(utf8.decoder).join();
        // 解析json
        var data = jsonDecode(json);
        // 将所获取的列表加入到chapterListModel列表中
        for (var element in data) {
          chapterListModel
              .add(ChapterListModel(chapterName: element['chapterName']));
          // 默认全选，所以将章节名全放入已选列表中
          chosenChapter.add(element['chapterName']);
        }
      }
    } catch (exception) {
      print(exception);
    }
    setState(() {
      // 按照章回顺序排序
      chapterListModel.sort((a, b) =>
          int.parse(a.chapterName.replaceAll(RegExp(r'\D'), '')).compareTo(
              int.parse(b.chapterName.replaceAll(RegExp(r'\D'), ''))));
    });
  }

  @override
  initState() {
    super.initState();
    _getChapters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          // 自动拉伸组件大小
          _chapterView(),
          const SizedBox(height: 25),
          // 按钮
          _btnView(),
          const SizedBox(height: 35),
        ],
      ),
    );
  }

  Widget _chapterView() {
    return Expanded(
        flex: 3,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: _listView(),
        ));
  }

  Widget _listView() {
    final List<ChapterListModel> displayedChapters = chapterListModel.sublist(
        _currentPage * 10,
        ((_currentPage + 1) * 10) >= chapterListModel.length
            ? chapterListModel.length
            : ((_currentPage + 1) * 10));
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ListView支持懒加载
        ListView.builder(
            // 设定prototypeItem
            prototypeItem: const ListTile(
              contentPadding: EdgeInsets.all(5),
            ),
            shrinkWrap: true,
            // itemExtent: 10,
            itemCount: displayedChapters.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                color: const Color.fromARGB(245, 242, 253, 252),
                child: _checkboxView(index),
              );
            }),
      ],
    );
  }

  Widget _checkboxView(index) {
    final List<ChapterListModel> displayedChapters = chapterListModel.sublist(
        _currentPage * 10,
        ((_currentPage + 1) * 10) >= chapterListModel.length
            ? chapterListModel.length
            : ((_currentPage + 1) * 10));
    return Column(
      children: <Widget>[
        CheckboxListTile(
          activeColor: const Color.fromARGB(184, 19, 102, 94),
          title: Text(
            displayedChapters[index].chapterName,
          ),
          value: displayedChapters[index].isCheck,
          onChanged: (bool? val) {
            setState(() {
              displayedChapters[index].isCheck = val!;
              // 已选章节不在已选列表中
              if (displayedChapters[index].isCheck &&
                  !chosenChapter
                      .contains(displayedChapters[index].chapterName)) {
                // 将章节名加入已选列表
                chosenChapter.add(displayedChapters[index].chapterName);
              } else if (!displayedChapters[index].isCheck) {
                // 取消选择则从已选列表中移除章节名
                chosenChapter.remove(displayedChapters[index].chapterName);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _btnView() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage = _currentPage - 1;
                    });
                  }
                : null,
            icon: Icon(Icons.arrow_back),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20.0),
                textStyle: const TextStyle(fontSize: 20, color: Colors.white),
                backgroundColor: const Color.fromARGB(184, 23, 142, 130)),
            onPressed: chosenChapter.isNotEmpty
                ? () {
                    // 跳转到提问页面
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => ChatScreen(
                                  // filename: '',

                                  // chapterList: chosenChapter,
                                  history: Data(
                                      datetime: DateTime.now()
                                          .toString()
                                          .substring(0, 19),
                                      message: <Message>[],
                                      chapterList: chosenChapter),
                                )),
                        //便利路由的回调
                        (Route<dynamic> route) {
                      //返回的事false的都会被从路由队列里面清除掉=》即chat page中返回会回到chapter page的上一页
                      return route.isFirst;
                    });
                  }
                : null,
            child: chosenChapter.isNotEmpty
                ? const Text('开始对话')
                : const Text('请选择章节'),
          ),
          IconButton(
              onPressed: _currentPage < chapterListModel.length / 10 - 1
                  ? () {
                      setState(() {
                        _currentPage = _currentPage + 1;
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward)),
        ]);
  }
}
