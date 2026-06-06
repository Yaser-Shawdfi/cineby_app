import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/download_service.dart';

/// In-app downloads manager. Lists active + completed downloads.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadServiceProvider);
    final service = ref.read(downloadServiceProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Downloads',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: tasks.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.divider,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final t = tasks[index];
                return _DownloadTile(
                  task: t,
                  onRemove: () => service.removeTask(t.id),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_outlined,
            color: AppColors.iconInactive,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap a download button on a title page to start.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.iconInactive,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({required this.task, required this.onRemove});

  final DownloadTask task;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final progress = (task.progress.clamp(0, 100)) / 100.0;
    return Dismissible(
      key: ValueKey(task.id),
      background: Container(color: AppColors.accent),
      onDismissed: (_) => onRemove(),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _iconFor(task.status),
            color: _colorFor(task.status),
          ),
        ),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _subtitleFor(task),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: task.status == DownloadStatus.completed ? 1 : progress,
                backgroundColor: AppColors.divider,
                color: AppColors.accent,
                minHeight: 3,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.iconInactive,
          onPressed: onRemove,
        ),
      ),
    );
  }

  IconData _iconFor(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.queued:
        return Icons.schedule;
      case DownloadStatus.running:
        return Icons.downloading;
      case DownloadStatus.completed:
        return Icons.check_circle_outline;
      case DownloadStatus.failed:
        return Icons.error_outline;
      case DownloadStatus.canceled:
        return Icons.cancel_outlined;
    }
  }

  Color _colorFor(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.completed:
        return Colors.greenAccent;
      case DownloadStatus.failed:
        return AppColors.accent;
      default:
        return AppColors.iconInactive;
    }
  }

  String _subtitleFor(DownloadTask t) {
    switch (t.status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.running:
        return 'Downloading — ${t.progress}%';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.canceled:
        return 'Canceled';
    }
  }
}
