import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// A single queued / running / completed download.
class DownloadTask {
  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.fileName,
    required this.savedDir,
    required this.status,
    required this.progress,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String title;
  final String fileName;
  final String savedDir;
  final DownloadStatus status;
  final int progress;
  final DateTime createdAt;

  DownloadTask copyWith({
    DownloadStatus? status,
    int? progress,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      title: title,
      fileName: fileName,
      savedDir: savedDir,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt,
    );
  }

  String get fullPath => '$savedDir/$fileName';
}

enum DownloadStatus { queued, running, completed, failed, canceled }

/// Global download queue, exposed via Riverpod.
final downloadServiceProvider =
    NotifierProvider<DownloadService, List<DownloadTask>>(
  DownloadService.new,
);

class DownloadService extends Notifier<List<DownloadTask>> {
  final StreamController<String> _messages =
      StreamController<String>.broadcast();

  /// Stream of user-facing messages ("Downloading: …", "Storage permission
  /// denied", etc.) that the UI listens to in order to show snackbars.
  Stream<String> get messages => _messages.stream;

  @override
  List<DownloadTask> build() {
    ref.onDispose(_messages.close);
    return <DownloadTask>[];
  }

  /// Request storage permission, resolve a save directory, and enqueue the
  /// download via flutter_downloader. Safe to call from a JS channel callback.
  Future<void> startDownload({
    required String url,
    required String title,
    String? suggestedFileName,
  }) async {
    if (url.isEmpty) return;

    final granted = await _ensurePermissions();
    if (!granted) {
      _messages.add('Storage permission denied');
      return;
    }

    String saveDir;
    try {
      final dir = await getApplicationDocumentsDirectory();
      saveDir = dir.path;
    } catch (e) {
      _messages.add('Could not resolve save directory: $e');
      return;
    }

    final safeTitle = title.replaceAll(RegExp(r'[^\w\s\-\.]'), '_').trim();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ext = _guessExtension(url);
    final fileName = suggestedFileName ??
        '${safeTitle.isEmpty ? "cineby" : safeTitle}_$stamp$ext';

    final task = DownloadTask(
      id: 'dl_$stamp',
      url: url,
      title: title,
      fileName: fileName,
      savedDir: saveDir,
      status: DownloadStatus.queued,
      progress: 0,
      createdAt: DateTime.now(),
    );
    state = [task, ...state];

    try {
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: saveDir,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        requiresStorageNotLow: true,
        saveInPublicStorage: false,
      );
      // Ensure the global callback dispatcher is registered so updates flow.
      FlutterDownloader.registerCallback(downloadCallbackDispatcher);
      _messages.add('Downloading: $title');
      // ignore: avoid_print
      print('[DownloadService] enqueued flutter task $taskId for ${task.id}');
    } catch (e) {
      _updateTask(task.id, status: DownloadStatus.failed, progress: 0);
      _messages.add('Download failed: $e');
    }
  }

  /// Remove a task from the in-app list. Does NOT delete the file or cancel
  /// the underlying download — that requires the original taskId from
  /// flutter_downloader.
  void removeTask(String id) {
    state = state.where((t) => t.id != id).toList(growable: false);
  }

  /// Update task from a flutter_downloader callback.
  /// Called from [downloadCallbackDispatcher] and from the downloads screen.
  void applyUpdate({
    required String flutterTaskId,
    required int rawStatus,
    required int progress,
  }) {
    // The internal id we stored is prefixed with 'dl_'; we don't have the
    // flutterTaskId → internalId mapping, so we update by index in the most
    // recent queued/running task. For a more robust system, maintain a map
    // from flutterTaskId to internalId.
    final idx = state.indexWhere(
      (t) => t.status == DownloadStatus.running ||
          t.status == DownloadStatus.queued,
    );
    if (idx < 0) return;
    _updateTask(
      state[idx].id,
      status: _mapStatus(rawStatus),
      progress: progress,
    );
  }

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) return true;
    final storage = await Permission.storage.request();
    if (storage.isGranted || storage.isLimited) return true;
    final media = await Permission.manageExternalStorage.request();
    return media.isGranted;
  }

  void _updateTask(String id, {DownloadStatus? status, int? progress}) {
    final idx = state.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final next = state[idx].copyWith(status: status, progress: progress);
    final list = [...state];
    list[idx] = next;
    state = list;
  }

  String _guessExtension(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8')) return '.m3u8';
    if (lower.contains('.mp4')) return '.mp4';
    if (lower.contains('.mkv')) return '.mkv';
    if (lower.contains('.webm')) return '.webm';
    return '.mp4';
  }
}

/// Map flutter_downloader DownloadStatus enum to our local one.
DownloadStatus _mapStatus(int raw) {
  switch (raw) {
    case 0:
      return DownloadStatus.queued;
    case 1:
      return DownloadStatus.running;
    case 2:
      return DownloadStatus.completed;
    case 3:
      return DownloadStatus.failed;
    case 4:
      return DownloadStatus.canceled;
    default:
      return DownloadStatus.queued;
  }
}

/// Global callback dispatcher — must be a top-level / static function and
/// must be registered in `main.dart` before runApp.
///
/// flutter_downloader invokes this in a background isolate, so we cannot
/// touch Riverpod state here directly. We just log and rely on the
/// downloads screen to poll for status updates.
@pragma('vm:entry-point')
void downloadCallbackDispatcher(String id, int status, int progress) {
  // ignore: avoid_print
  print('[flutter_downloader] task=$id status=$status progress=$progress');
}
