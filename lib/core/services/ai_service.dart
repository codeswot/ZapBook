import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:zapbook/core/services/device_capability_service.dart';

enum AiModelStatus { notSet, downloading, paused, verifying, ready, skipped }

class AiModelState extends Equatable {
  final AiModelStatus status;
  final double downloadProgress;
  final bool bannerDismissed;
  final String? taskId;
  final String? expectedHash;
  final DeviceCapability? capability;

  const AiModelState({
    required this.status,
    this.downloadProgress = 0.0,
    this.bannerDismissed = false,
    this.taskId,
    this.expectedHash,
    this.capability,
  });

  @override
  List<Object?> get props => [
    status,
    downloadProgress,
    bannerDismissed,
    taskId,
    expectedHash,
    capability,
  ];

  AiModelState copyWith({
    AiModelStatus? status,
    double? downloadProgress,
    bool? bannerDismissed,
    String? taskId,
    String? expectedHash,
    DeviceCapability? capability,
  }) {
    return AiModelState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      bannerDismissed: bannerDismissed ?? this.bannerDismissed,
      taskId: taskId ?? this.taskId,
      expectedHash: expectedHash ?? this.expectedHash,
      capability: capability ?? this.capability,
    );
  }
}

abstract class AiService {
  Stream<AiModelState> get aiState;
  AiModelState get currentState;

  Future<void> startDownload(String modelUrl, String expectedHash);
  Future<void> pauseDownload();
  Future<void> resumeDownload();
  Future<void> cancelDownload();
  Future<void> skipSetup();
  Future<void> reset();
  void dismissBanner();
}

@LazySingleton(as: AiService)
class AiServiceImpl implements AiService {
  final SharedPreferences _prefs;
  final DeviceCapabilityService _deviceCapabilityService;

  static const _statusKey = 'ai_model_status';
  static const _taskIdKey = 'ai_model_task_id';
  static const _hashKey = 'ai_model_hash';
  static const _progressKey = 'ai_model_progress';

  final _stateController = StreamController<AiModelState>.broadcast();
  late AiModelState _currentState;

  AiServiceImpl(this._prefs, this._deviceCapabilityService) {
    _currentState = const AiModelState(status: AiModelStatus.notSet);
    _init();
  }

  Future<void> _init() async {
    final statusString = _prefs.getString(_statusKey);
    final taskId = _prefs.getString(_taskIdKey);
    final expectedHash = _prefs.getString(_hashKey);
    final progress = _prefs.getDouble(_progressKey) ?? 0.0;
    final capability = await _deviceCapabilityService.checkDeviceCapability();

    AiModelStatus initialStatus = AiModelStatus.notSet;

    if (statusString != null) {
      initialStatus = AiModelStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => AiModelStatus.notSet,
      );
    }

    _currentState = AiModelState(
      status: initialStatus,
      taskId: taskId,
      expectedHash: expectedHash,
      downloadProgress: progress,
      capability: capability,
    );
    _stateController.add(_currentState);

    FileDownloader().registerCallbacks(
      taskProgressCallback: (update) {
        if (update.progress >= 0.0 && update.progress <= 1.0) {
          _prefs.setDouble(_progressKey, update.progress);
          _updateState(
            _currentState.copyWith(
              status: AiModelStatus.downloading,
              downloadProgress: update.progress,
            ),
          );
        } else if (update.progress == progressPaused) {
          _updateState(_currentState.copyWith(status: AiModelStatus.paused));
        }
      },
      taskStatusCallback: (update) async {
        if (update.status == TaskStatus.complete) {
          await _handleDownloadComplete(update.task as DownloadTask);
        } else if (update.status == TaskStatus.failed ||
            update.status == TaskStatus.canceled ||
            update.status == TaskStatus.notFound) {
          _updateState(
            const AiModelState(
              status: AiModelStatus.notSet,
              downloadProgress: 0.0,
            ),
          );
          await _clearPrefs();
        }
      },
    );

    await FileDownloader().trackTasks();

    if (initialStatus == AiModelStatus.downloading ||
        initialStatus == AiModelStatus.paused ||
        initialStatus == AiModelStatus.verifying) {
      if (taskId != null) {
        final task = await FileDownloader().taskForId(taskId);
        if (task != null &&
            task is DownloadTask &&
            initialStatus == AiModelStatus.verifying) {
          unawaited(_handleDownloadComplete(task));
        } else if (task == null) {
          _updateState(const AiModelState(status: AiModelStatus.notSet));
          await _clearPrefs();
        }
      } else {
        _updateState(const AiModelState(status: AiModelStatus.notSet));
        await _clearPrefs();
      }
    }
  }

  Future<void> _handleDownloadComplete(DownloadTask task) async {
    _updateState(_currentState.copyWith(status: AiModelStatus.verifying));

    final expectedHash = _currentState.expectedHash;
    if (expectedHash == null) {
      _setReady();
      return;
    }

    final filePath = await task.filePath();
    final file = File(filePath);

    if (!await file.exists()) {
      _updateState(const AiModelState(status: AiModelStatus.notSet));
      await _clearPrefs();
      return;
    }

    try {
      final digest = await sha256.bind(file.openRead()).first;
      if (digest.toString() == expectedHash) {
        _setReady();
      } else {
        await file.delete();
        _updateState(const AiModelState(status: AiModelStatus.notSet));
        await _clearPrefs();
      }
    } catch (e) {
      _updateState(const AiModelState(status: AiModelStatus.notSet));
      await _clearPrefs();
    }
  }

  Future<void> _setReady() async {
    _updateState(
      const AiModelState(status: AiModelStatus.ready, downloadProgress: 1.0),
    );
    await _prefs.setString(_statusKey, AiModelStatus.ready.name);
  }

  Future<void> _clearPrefs() async {
    await _prefs.remove(_statusKey);
    await _prefs.remove(_taskIdKey);
    await _prefs.remove(_hashKey);
    await _prefs.remove(_progressKey);
  }

  void _updateState(AiModelState newState) {
    var stateToEmit = newState;
    if (stateToEmit.capability == null && _currentState.capability != null) {
      stateToEmit = stateToEmit.copyWith(capability: _currentState.capability);
    }
    _currentState = stateToEmit;
    _stateController.add(_currentState);

    _prefs.setString(_statusKey, stateToEmit.status.name);
    if (stateToEmit.taskId != null) {
      _prefs.setString(_taskIdKey, stateToEmit.taskId!);
    }
    if (stateToEmit.expectedHash != null) {
      _prefs.setString(_hashKey, stateToEmit.expectedHash!);
    }
  }

  @override
  Stream<AiModelState> get aiState => _stateController.stream;

  @override
  AiModelState get currentState => _currentState;

  @override
  Future<void> startDownload(String modelUrl, String expectedHash) async {
    final task = DownloadTask(
      url: modelUrl,
      filename: 'gemma_model.litertlm',
      directory: 'ai_models',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: true,
    );

    _updateState(
      AiModelState(
        status: AiModelStatus.downloading,
        downloadProgress: 0.0,
        taskId: task.taskId,
        expectedHash: expectedHash,
      ),
    );

    await FileDownloader().enqueue(task);
  }

  @override
  Future<void> pauseDownload() async {
    if (_currentState.taskId != null) {
      final task = await FileDownloader().taskForId(_currentState.taskId!);
      if (task != null && task is DownloadTask) {
        await FileDownloader().pause(task);
        _updateState(_currentState.copyWith(status: AiModelStatus.paused));
      }
    }
  }

  @override
  Future<void> resumeDownload() async {
    if (_currentState.taskId != null) {
      final task = await FileDownloader().taskForId(_currentState.taskId!);
      if (task != null && task is DownloadTask) {
        await FileDownloader().resume(task);
        _updateState(_currentState.copyWith(status: AiModelStatus.downloading));
      }
    }
  }

  @override
  Future<void> cancelDownload() async {
    if (_currentState.taskId != null) {
      await FileDownloader().cancelTaskWithId(_currentState.taskId!);
      _updateState(
        const AiModelState(status: AiModelStatus.notSet, downloadProgress: 0.0),
      );
      await _clearPrefs();
    }
  }

  @override
  Future<void> skipSetup() async {
    _updateState(const AiModelState(status: AiModelStatus.skipped));
    await _prefs.setString(_statusKey, AiModelStatus.skipped.name);
  }

  @override
  Future<void> reset() async {
    _updateState(const AiModelState(status: AiModelStatus.notSet));
    await _clearPrefs();
  }

  @override
  void dismissBanner() {
    _updateState(_currentState.copyWith(bannerDismissed: true));
  }
}
