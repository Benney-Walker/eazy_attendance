import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'sync_controller.dart';

/// A deliberately quiet sync-status chip. It shows only when there's something
/// worth saying — syncing, pending items, offline, or a brief "Synced"
/// confirmation — and stays out of the way otherwise (renders nothing when idle
/// with an empty queue). Reuses the app's pill styling so it never feels
/// foreign.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);

    final _ChipData? data = _chipFor(sync);
    if (data == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          data.showSpinner
              ? SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(data.foreground),
                  ),
                )
              : Icon(data.icon, size: 12, color: data.foreground),
          const SizedBox(width: 5),
          Text(
            data.label,
            style: AppTextStyles.footer.copyWith(
              color: data.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  _ChipData? _chipFor(SyncState sync) {
    if (sync.phase == SyncPhase.syncing) {
      return _ChipData(
        label: 'Syncing…',
        background: AppColors.blue50,
        foreground: AppColors.blue600,
        showSpinner: true,
      );
    }
    if (sync.justSynced) {
      return const _ChipData(
        label: 'Synced',
        background: Color(0xFFECFDF5), // subtle green tint
        foreground: Color(0xFF059669),
        icon: Icons.cloud_done_outlined,
      );
    }
    if (sync.phase == SyncPhase.offline && sync.pending > 0) {
      return _ChipData(
        label: '${sync.pending} pending',
        background: AppColors.gray100,
        foreground: AppColors.gray600,
        icon: Icons.cloud_off_outlined,
      );
    }
    if (sync.phase == SyncPhase.offline) {
      return _ChipData(
        label: 'Offline',
        background: AppColors.gray100,
        foreground: AppColors.gray600,
        icon: Icons.cloud_off_outlined,
      );
    }
    if (sync.pending > 0) {
      return _ChipData(
        label: '${sync.pending} pending',
        background: AppColors.blue50,
        foreground: AppColors.blue600,
        icon: Icons.sync_outlined,
      );
    }
    return null; // idle + nothing queued → show nothing.
  }
}

class _ChipData {
  const _ChipData({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon = Icons.sync,
    this.showSpinner = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;
  final bool showSpinner;
}
