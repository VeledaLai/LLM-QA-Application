import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'models/ChatModel.dart';
import 'models/DataModel.dart';

// 会话页

class ChatScreen extends StatefulWidget {
  // final String filename;
  // final String datetime;
  // final List<String> chapterList;
  final Data history;
  const ChatScreen({super.key, required this.history});

  @override
  _ChatScreenState createState() => _ChatScreenState(
      history.title, history.datetime, history.chapterList, history.message);
}

class _ChatScreenState extends State<ChatScreen> {
  // controller
  final TextEditingController _controller = TextEditingController();
  final ScrollController _listViewController = ScrollController();

  final String _filename;
  final String _datetime;
  final List<String> _chapterList;
  final List<Message> _historyChat;
  // 从Stateful传值来的值
  _ChatScreenState(
      this._filename, this._datetime, this._chapterList, this._historyChat);

  List<Message> _data = [];
  String _title = "新会话";
  bool isResponding = false;

  @override
  void initState() {
    super.initState();
    print(_datetime);
    // 需要加载历史对话
    if (_filename.isNotEmpty) {
      _title = _filename;
      _data = _historyChat;
    }

    // 监听器，实现自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listViewController.animateTo(
        _listViewController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              // 检查是否存在对话，如存在则保存到本地
              _CheckChat();
              Navigator.of(context).pop(); //返回上一页
            },
          ),
          centerTitle: true, //让标题置中
          title: Text(_title,
              style:
                  const TextStyle(color: Color.fromARGB(242, 255, 255, 255))),
          backgroundColor: const Color.fromARGB(218, 0, 137, 123),
        ),
        body: _bodyview(),
      ),
    );
  }

  Widget _bodyview() {
    // 手势控制
    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 点击其他地方，则输入框失去焦点
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: <Widget>[
            //对话内容显示
            _chatView(),
            // 输入框
            _inputView()
          ],
        ));
  }

// 对话内容显示
  Widget _chatView() {
    return Expanded(
      /// builder会逐个添加需要的属性
      child: ListView.builder(
          key: UniqueKey(),
          controller: _listViewController,
          reverse: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

          ///ListView子Item的个数
          itemCount: _data.length,

          ///子Item的构建器
          itemBuilder: (context, index) {
            final model = _data.elementAt(index);

            ///在这里是封装到了独立的 StatelessWidget
            // 对话气泡，通过isMyself区分TextDirection（自己发送或对方发送）
            return BubbleWidget(
              key: GlobalObjectKey(index),
              text: model.text,
              direction: model.isMyself ? TextDirection.rtl : TextDirection.ltr,
              avatar: model.isMyself
                  ? const CircleAvatar(
                      radius: 24, // 只要不比48的二分之一小就是圆形
                    )
                  : const CircleAvatar(
                      backgroundColor: Color.fromARGB(218, 0, 137, 123),
                      radius:
                          24, // 只要不比48的二分之一小就是圆形radius: 24, // 只要不比48的二分之一小就是圆形
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
            );
          }),
    );
  }

// 输入框
  Widget _inputView() {
    final outlineInputBorder = OutlineInputBorder(
        borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16));
    return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左侧文字输入框
            Expanded(
              child: TextField(
                maxLength: 500,
                maxLines: null,
                controller: _controller,
                cursorColor: Colors.black,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  isDense: true, // Added this
                  hintText: isResponding ? "答案生成中" : "请输入问题",
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabledBorder: outlineInputBorder,
                  focusedBorder: outlineInputBorder,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 右侧的发送按钮
            ElevatedButton(
              onPressed: isResponding
                  ? null
                  : () {
                      final text = _controller.text;
                      // 清空输入
                      _controller.clear();
                      // 把数据抽出来
                      // 检查如果是空白内容则不会发送
                      if (text.trim().isNotEmpty) {
                        // 这里写死
                        final model = Message(
                          text: text,
                          isMyself: true,
                        );

                        // 局部刷新
                        setState(() {
                          // 显示用户的问题
                          _data.add(model);
                          // 设置按钮状态为禁止
                          isResponding = true;
                        });

                        // 滚底操作
                        _toButton();
                        Message response = Message();
                        // 获取回答=>异步回调
                        _getAns(text, _data.length).then((value) {
                          // 回调成功
                          response.text = value.text;
                          // 启用发送按钮
                          // isResponding = false;
                        }).catchError((error) {
                          // 回调失败
                          response.text = '获取答案失败，请重新提问';
                          // _data.add(response);
                        }).whenComplete(() {
                          print(response.text);
                          // 局部刷新
                          setState(() {
                            // 显示回答
                            _data.add(response);
                            isResponding = false;

                            // 更改标题
                            if (_data.length == 2 && !_data[1].isMyself) {
                              _title = _data[0].text.length >= 15
                                  ? _data[0].text.substring(0, 14)
                                  : _data[0].text;
                            }
                          });
                          // 滚底操作
                          _toButton();
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '发送',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ));
  }

  /// 保存对话
  Future<void> _CheckChat() async {
    // 有聊天记录就保存
    if (_data.isNotEmpty) {
      _saveFile();
    }
  }

  /// 保存权限
  static Future requestPermission() async {
    if (await Permission.contacts.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
    }
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    // print(statuses[Permission.storage]);
  }

  /// 获取文档目录
  Future<String> _localfilePath() async {
    // 获取本地文件路径
    Directory tempDir = await getApplicationDocumentsDirectory();
    return tempDir.path;
  }

  /// 获取文档
  Future<File> _localfile() async {
    final path = await _localfilePath();
    File file = File('$path/chat.json');
    if (await file.exists()) {
      // 档案存在，获取文档
      return file;
    } else {
      return await File('$path/chat.json').create(recursive: true);
    }
  }

  /// 保存内容到文本
  void _saveFile() async {
    try {
      print(_datetime);
      // 获取保存权限
      requestPermission();
      // 获取文件
      File file = await _localfile();
      // 从文件读取数据
      String contents = await file.readAsString();
      List<Data> data = [];
      bool isHistory = false;
      // 获取历史会话
      if (contents != "") {
        // 将文件内容从string格式换成map格式
        Iterable l = json.decode(contents);
        List<Data> list = List<Data>.from(l.map(
            (model) => Data(message: [], chapterList: []).fromJson(model)));

        for (var element in list) {
          // 本次会话为历史会话
          if (element.title == _title && element.datetime == _datetime) {
            // 更新会话记录
            element.message = _data;
            isHistory = true;
          }
          data.add(Data(
              title: element.title,
              datetime: element.datetime,
              message: element.message,
              chapterList: element.chapterList));
        }
        // 非历史聊天记录
        if (!isHistory) {
          print(_datetime);
          data.add(Data(
              title: _title,
              datetime: _datetime,
              message: _data,
              chapterList: _chapterList));
        }
      } else {
        print("new");
        // 新增历史会话记录
        data.add(Data(
            title: _title,
            datetime: _datetime,
            message: _data,
            chapterList: _chapterList));
      }
      // 覆盖写入
      // var sink = file.openWrite();
      // 将data转换成json格式保存
      String jsonString = json.encode(data.map((p) => p.toJson()).toList());

      await file.writeAsString(jsonString);
    } catch (e) {
      // 写入错误
      print(e);
    }
  }

  Future<void> _loadHistory() async {
    File file = await _localfile();
    String historyChat = await file.readAsString();
    _data = json.decode(historyChat);

    // 局部刷新
    setState(() {
      _title = _data[0].text.length >= 15
          ? _data[0].text.substring(0, 14)
          : _data[0].text;
    });
  }

  Future<Message> _getAns(String query, int i) async {
    var url = 'http://127.0.0.1:5000/api/llm';
    var body = {'chapterList': jsonEncode(_chapterList), 'query': query};
    // 设置请求头
    var header = {
      "Content-Type": "application/json; charset=UTF-8",
      "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    };
    Message result = Message(
      text: '获取失败',
      isMyself: false,
    );
    try {
      final response = await http.post(Uri.parse(url),
          headers: header, body: jsonEncode(body));

      if (response.statusCode == HttpStatus.ok) {
        // 响应状态为成功
        var json = response.body;
        var data = jsonDecode(json);
        print('get response successfully');
        List source = data['source'];

        result.text = data['result'] +
            "资料来源：" +
            source[0]['source'] +
            "\n" +
            source[0]['content'];
        return await result;
      } else {
        // 响应失败
        print('get response faliure');
        return await result;
      }
    } catch (exception) {
      print(exception);
      return await result;
    }
  }

  _toButton() {
    // 在添加数据后再次执行滚动到底部操作
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listViewController.animateTo(
        _listViewController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }
}

//聊天气泡
class BubbleWidget extends StatelessWidget {
  const BubbleWidget(
      {super.key,
      required this.text,
      // 默认是系统发出的聊天气泡
      required this.direction,
      this.source = "无",
      this.avatar = const CircleAvatar(
        radius: 24, // 只要不比48的二分之一小就是圆形
      )});

  final CircleAvatar avatar;
  final String text;
  final TextDirection direction;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        textDirection: direction,
        children: [
          avatar,
          // const Flexible(fit: FlexFit.tight, child: SizedBox()),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
          Flexible(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(32)),
            child: direction == TextDirection.ltr
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SelectableText(text.split('\n')[0]),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 5)),
                      SelectableText(
                        "文档来源:${text.replaceAll(text.split('\n')[0], '')}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      )
                    ],
                  )
                : SelectableText(text),
          ))
        ],
      ),
      const SizedBox(
        height: 15,
      )
    ]);
  }
}
