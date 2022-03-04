import 'dart:convert';
import 'dart:io';
import 'console_selector.dart';
import 'output_util.dart';

///获取用户输入内容
String input({
  String message = '',
  String defaultValue = '',
}) {
  stdout.write(blue(message) +
      white(defaultValue.isEmpty ? '' : '($defaultValue)') +
      ': ');
  String? line = stdin.readLineSync(
      encoding: Encoding.getByName('utf-8') ?? systemEncoding);
  if (line == null || line.trim().isEmpty) {
    _answer(defaultValue);
    return defaultValue;
  } else {
    _answer(line);
    return line;
  }
}

///获取用户选择的内容
String select({
  required String message,
  required List options,
}) {
  print(blue(message) + white('(Use arrow keys)'));
  final menu = ConsoleSelector(options);
  final result = menu.choose();
  _answer(result.toString());
  return result.toString();
}

void _answer(String result) {
  print('answer: ${green(result)}');
}
