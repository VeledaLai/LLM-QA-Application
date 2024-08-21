import 'dart:async';
import 'package:flutter/material.dart';
import './chat/chapter.dart';
import './history.dart';
import './chat/models/ChapterListModel.dart';
import 'chat/chat.dart';
import 'dart:io';

//启动应用
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //路径导航
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (context) => const HomeScreen(), //主页
        '/chapter': (context) => const ChapterChoose(), //章节选择页
        '/history': (context) => HistoryChoose(), //历史页
      },
    );
  }
}

// 主页
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            centerTitle: true, //让标题置中
            title: const Text('白话文西游记小说LLM应用',
                style: TextStyle(color: Color.fromARGB(242, 255, 255, 255))),
            backgroundColor:
                const Color.fromARGB(218, 0, 137, 123), //App bar的背景颜色
          ),
          body: _bodyview(context) //使用开始按钮部件
          ),
    );
  }

  Center _bodyview(context) {
    return Center(
        //列
        child: Column(children: <Widget>[
      const SizedBox(height: 200),
      const Icon(
        Icons.forum_outlined,
        size: 100,
        color: Color.fromARGB(238, 22, 100, 92),
      ),
      const SizedBox(height: 70),

      //圆角矩形
      ClipRRect(
        // 矩形的圆角设定
        borderRadius: BorderRadius.circular(25),
        // 栈
        child: _btn(context, ChapterChoose(), '开始使用'),
      ),
      const SizedBox(height: 20),
      ClipRRect(
        // 矩形的圆角设定
        borderRadius: BorderRadius.circular(25),
        // 栈
        child: _btn(context, HistoryChoose(), '历史对话'),
      ),
    ]));
  }

  Stack _btn(context, page, text) {
    return Stack(
      children: <Widget>[
        // 按钮的颜色设定
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color.fromARGB(184, 23, 142, 130),
                  Color.fromARGB(196, 89, 163, 155),
                  Color.fromARGB(255, 180, 215, 212),
                ],
              ),
            ),
          ),
        ),
        // 按钮
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(20.0),
            textStyle: const TextStyle(fontSize: 20),
          ),
          onPressed: () {
            // 跳转到章节选择页面
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          child: Text(text),
        ),
      ],
    );
  }
}
