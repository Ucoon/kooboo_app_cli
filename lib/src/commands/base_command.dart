import 'package:args/command_runner.dart';

abstract class BaseCommand extends Command {
  String? get invocationSuffix;
  @override
  String get invocation {
    return invocationSuffix != null && invocationSuffix!.isNotEmpty
        ? '${super.invocation} $invocationSuffix'
        : super.invocation;
  }
}
