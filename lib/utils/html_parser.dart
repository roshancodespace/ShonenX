import 'package:html/parser.dart' as html_parser;

String parseHtmlToString(String htmlString) {
  final document = html_parser.parse(htmlString);
  return document.body?.text ?? '';
}
