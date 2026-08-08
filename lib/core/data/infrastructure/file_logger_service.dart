import 'dart:developer';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

@lazySingleton
class FileLoggerService {
  File? _logFile;
  final _logBuffer = <String>[];
  bool _initialized = false;
  bool _isWriting = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      _logFile = File('${docDir.path}/zapbook_session.log');

      if (_logFile!.existsSync() && _logFile!.lengthSync() > 5 * 1024 * 1024) {
        await _logFile!.writeAsString('');
      }

      await _logFile!.writeAsString(
        '\n\n--- NEW SESSION: ${DateTime.now().toIso8601String()} ---\n',
        mode: FileMode.append,
      );

      if (_logBuffer.isNotEmpty) {
        await _logFile!.writeAsString(
          '${_logBuffer.join('\n')}\n',
          mode: FileMode.append,
        );
        _logBuffer.clear();
      }

      Logger.root.onRecord.listen(_onRecord);
    } catch (e) {
      log('Failed to initialize FileLoggerService: $e');
    }
  }

  void _onRecord(LogRecord record) {
    final message =
        '${record.time.toIso8601String()} [${record.level.name}] ${record.loggerName}: ${record.message}';

    final errorPart = record.error != null ? '\nError: ${record.error}' : '';
    final stackPart = record.stackTrace != null
        ? '\nStack: ${record.stackTrace}'
        : '';

    final fullMessage = message + errorPart + stackPart;
    _logBuffer.add(fullMessage);
    _flushLogs();
  }

  Future<void> _flushLogs() async {
    if (_isWriting || _logFile == null || _logBuffer.isEmpty) return;
    _isWriting = true;

    try {
      final logsToWrite = '${_logBuffer.join('\n')}\n';
      _logBuffer.clear();
      await _logFile!.writeAsString(logsToWrite, mode: FileMode.append);
    } catch (e) {
      log('Failed to write logs: $e');
    } finally {
      _isWriting = false;
      if (_logBuffer.isNotEmpty) {
        _flushLogs();
      }
    }
  }

  Future<void> shareLogs() async {
    if (_logFile != null && _logFile?.existsSync() == true) {
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(_logFile!.path)], text: 'ZapBook QA Logs');
    } else {
      log('No log file available to share.');
    }
  }
}
