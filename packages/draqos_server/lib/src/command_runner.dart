import 'dart:async';
import 'dart:io';

/// Testable shell-out abstraction (real impl runs processes;
/// tests inject a fake).
class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  const CommandResult(this.exitCode, this.stdout, this.stderr);
}

abstract class CommandRunner {
  Future<CommandResult> run(String exe, List<String> args);
}

class ProcessCommandRunner implements CommandRunner {
  @override
  Future<CommandResult> run(String exe, List<String> args) async {
    final res = await Process.run(exe, args);
    return CommandResult(
      res.exitCode,
      res.stdout as String,
      res.stderr as String,
    );
  }
}
