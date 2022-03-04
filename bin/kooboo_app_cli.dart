import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:kooboo_app_cli/src/commands/commands.dart';

void main(List<String> arguments) {
  CommandRunner runner = configureCommand(arguments);
  bool hasCommand = runner.commands.keys.any((key) => arguments.contains(key));
  if (hasCommand) {
    executeCommand(runner, arguments);
  } else {
    ArgParser parser = runner.argParser;
    ArgResults results = parser.parse(arguments);
    executeOptions(results, arguments, runner);
  }
}

void executeCommand(CommandRunner runner, List<String> arguments) {
  runner.run(arguments).catchError((error) {
    if (error is! UsageException) throw error;
    print(error);
  });
}

void executeOptions(
    ArgResults results, List<String> arguments, CommandRunner runner) {
  if (results.wasParsed('help') || arguments.isEmpty) {
    print(runner.usage);
  }
  if (results.wasParsed('version')) {
    String version = '0.0.1';
    print('v$version');
  }
}

CommandRunner configureCommand(List<String> arguments) {
  CommandRunner runner = CommandRunner('kapp', 'Kooboo app CLI for Flutter')
    ..addCommand(CreateCommand());
  runner.argParser.addFlag('version', abbr: 'v', negatable: false);
  return runner;
}
