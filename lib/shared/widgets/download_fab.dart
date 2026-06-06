import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

/// A floating button that opens the downloads manager. The spec places a
/// duplicate copy of this inside the app shell; both share the same
/// destination and styling.
class DownloadFab extends ConsumerWidget {
  const DownloadFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      onPressed: () {
        GoRouter.of(context).push('/downloads');
      },
      child: const Icon(Icons.download_rounded, size: 20),
    );
  }
}
