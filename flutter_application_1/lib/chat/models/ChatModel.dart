class Message {
  // String avatar;
  String text;
  bool isMyself;

  Message({
    // this.avatar = "",
    this.text = "",
    this.isMyself = false,
  });
  List<Message> getList() {
    return <Message>[];
  }

  Map toJson() => {
        // 'avatar': avatar,
        'text': text, 'isMyself': isMyself
      };
}
