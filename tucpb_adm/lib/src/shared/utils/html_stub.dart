// ignore_for_file: camel_case_types
class AnchorElement {
  AnchorElement({this.href});
  String? href;
  String? download;
  void click() {}
  void setAttribute(String name, String value) {}
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class Blob {
  Blob(List<dynamic> parts, String type);
}
