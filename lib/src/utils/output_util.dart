import 'package:ansicolor/ansicolor.dart';

AnsiPen red = AnsiPen()..red(bold: true);
AnsiPen green = AnsiPen()..green(bold: true);
AnsiPen white = AnsiPen()..white(bold: true);
AnsiPen yellow = AnsiPen()..yellow(bold: true);
AnsiPen gray = AnsiPen()..gray();
AnsiPen blue = AnsiPen()..blue(bold: true);

void success(msg) => print(green('SUCCESS: $msg'));
void title(msg) => print(green('$msg'));
void warn(msg) => print(yellow('WARN: $msg'));
void error(msg) => print(red('ERROR: $msg'));
void msg(msg) => print(white('$msg'));
