class ChapterListModel {
  String chapterName;
  bool isCheck;

  ChapterListModel({
    this.chapterName = "",
    this.isCheck = true,
  });

  Map toJson() => {'chapterName': chapterName, 'isCheck': isCheck};
}
