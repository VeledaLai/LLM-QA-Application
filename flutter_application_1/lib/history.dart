import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'chat/chat.dart';
import 'chat/models/DataModel.dart';

class HistoryChoose extends StatefulWidget {
  const HistoryChoose({super.key});
  @override
  _HistoryChooseState createState() => _HistoryChooseState();
}

// 历史会话选择页
class _HistoryChooseState extends State {
  List<Data> _data = [];

  Future<List<Data>> _getList() async {
    String path = await _localfilePath();

    File file = File('$path/chat.json');
    try {
      if (await file.exists()) {
        print(path);

        // 从文件读取数据
        String contents = await file.readAsString();
        print(contents);
        // 将文件内容从string格式换成map格式
        Iterable l = json.decode(contents);
        _data = List<Data>.from(l.map(
            (model) => Data(message: [], chapterList: []).fromJson(model)));
      }
    } catch (e) {
      print(e);
    }
    return _data;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              centerTitle: true, //让标题置中
              title: const Text('历史对话',
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
            body: _bodyView()));
  }

  Widget _nullBodyView() {
    return const Center(
      child: Text(
        '无历史记录',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _bodyView() {
    return FutureBuilder(
        future: _getList(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            print(_data.first.title);
            // if (_data.isEmpty) {
            return Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
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
                          itemCount: _data.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              color: const Color.fromARGB(245, 242, 253, 252),
                              child: ListTile(
                                  onTap: () => {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                    history: _data[index],
                                                  )),
                                        )
                                      },
                                  title: Text(_data[index].title),
                                  subtitle: Text(_data[index].datetime)),
                            );
                            // return
                          }),
                    ],
                  ),
                ));
          } else {
            return _nullBodyView();
          }
        });
  }

  // Widget _listView() {
  //   return ;
  // }

  /// 获取文档目录
  Future<String> _localfilePath() async {
    // 获取本地文件路径
    Directory tempDir = await getApplicationDocumentsDirectory();
    return tempDir.path;
  }
}
