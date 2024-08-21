import 'package:flutter_application_1/chat/chapter.dart';

import 'ChatModel.dart';
import 'ChapterListModel.dart';

class Data {
  String title;
  String datetime;
  List<Message> message;
  List<String> chapterList;

  Data({
    this.title = "",
    this.datetime = "",
    required this.message,
    required this.chapterList,
  });
  List<Data> getList() {
    return <Data>[];
  }

  Data fromJson(Map<String, dynamic> json) {
    title = json['title'];
    datetime = json['datetime'];
    for (var element in json['message']) {
      if (element['isMyself']) {
        message
            .add(Message(text: element['text'], isMyself: element['isMyself']));
      } else {
        message
            .add(Message(text: element['text'], isMyself: element['isMyself']));
      }
    }

    for (var element in json['chapterList'].toList()) {
      chapterList.add(element);
    }

    return Data(
        title: title,
        datetime: datetime,
        message: message,
        chapterList: chapterList);
  }

  Map toJson() => {
        'title': title,
        'datetime': datetime,
        'message': message,
        'chapterList': chapterList
      };
}
