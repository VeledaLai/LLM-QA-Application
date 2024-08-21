class Source {
  // String avatar;
  int source;
  String content;

  Source({
    // this.avatar = "",
    this.source = 0,
    this.content = "",
  });

  Map toJson() => {
        // 'avatar': avatar,
        'source': source, 'content': content
      };
}
