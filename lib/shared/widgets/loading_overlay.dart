import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';

/// A shimmer-based loading indicator used while the WebView is warming up
/// or when a heavy JS injection is in progress.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.navBarBorder,
          period: const Duration(milliseconds: 1200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: AppColors.accent,
                size: 56,
              ),
              const SizedBox(height: 16),
              if (message != null)
                Text(
                  message!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
