import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core_providers.dart';
import '../../../core/sync/sync_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/application/auth_controller.dart';

/// The signed-in staff's ID (read from secure storage; not held in AuthState).
final _staffIdProvider = FutureProvider<String?>((ref) {
  return ref.watch(secureStorageProvider).readStaffId();
});

/// App version shown in About. Kept in sync with pubspec.yaml `version:` by
/// hand (a one-line edit on release). Avoids a native plugin — see note below.
///
/// We intentionally do NOT use package_info_plus: it triggered a Kotlin
/// incremental-compiler crash when the Pub cache and the project live on
/// different Windows drives ("different roots"), and it emits a Kotlin Gradle
/// Plugin deprecation warning. A constant is simpler and has no build cost.
const String kAppVersion = '1.0.0';

/// Settings tab. The website has no settings page, so this is a restrained,
/// native addition: profile, a sync section (status + manual "Sync now"),
/// about, and logout. No invented features (no password change — admins reset
/// staff passwords — no theme/language toggles).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign out', style: AppTextStyles.cardTitle),
            content: const Text('Are you sure you want to sign out?',
                style: AppTextStyles.cardSubtitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sign out',
                    style: TextStyle(color: AppColors.errorText)),
              ),
            ],
          ),
        ) ??
        false;
    if (shouldLogout) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffName =
        ref.watch(authControllerProvider).valueOrNull?.staffName ?? 'Teacher';
    final staffId = ref.watch(_staffIdProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileCard(staffName: staffName, staffId: staffId),
          const SizedBox(height: 24),
          _SectionLabel('Sync'),
          const SizedBox(height: 8),
          const _SyncCard(),
          const SizedBox(height: 24),
          _SectionLabel('About'),
          const SizedBox(height: 8),
          const _AboutCard(),
          const SizedBox(height: 24),
          _LogoutButton(onPressed: () => _confirmLogout(context, ref)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.fieldLabel);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.staffName, required this.staffId});

  final String staffName;
  final String? staffId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.blue100, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.blue500,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            alignment: Alignment.center,
            child: Text(
              initialsOf(staffName),
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staffName,
                    style: AppTextStyles.input
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  staffId == null || staffId!.isEmpty
                      ? 'Signed in as Teacher'
                      : 'ID: $staffId',
                  style: AppTextStyles.mono.copyWith(color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends ConsumerWidget {
  const _SyncCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);

    final String statusText;
    final IconData statusIcon;
    final Color statusColor;
    if (sync.phase == SyncPhase.syncing) {
      statusText = 'Syncing…';
      statusIcon = Icons.sync;
      statusColor = AppColors.blue600;
    } else if (sync.pending > 0) {
      statusText =
          '${sync.pending} record${sync.pending == 1 ? '' : 's'} waiting to sync';
      statusIcon = Icons.cloud_upload_outlined;
      statusColor = AppColors.gray600;
    } else {
      statusText = 'All attendance synced';
      statusIcon = Icons.cloud_done_outlined;
      statusColor = const Color(0xFF059669);
    }

    final last = sync.lastSyncedAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.gray100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 20, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(statusText,
                    style: AppTextStyles.input
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (last != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text('Last synced ${_timeOfDay(last)}',
                  style: AppTextStyles.footer),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: sync.phase == SyncPhase.syncing
                  ? null
                  : () => ref.read(syncControllerProvider.notifier).syncNow(),
              icon: const Icon(Icons.sync, size: 18),
              label: Text(
                  sync.phase == SyncPhase.syncing ? 'Syncing…' : 'Sync now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue600,
                side: const BorderSide(color: AppColors.blue200, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeOfDay(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.gray100, width: 1.5),
      ),
      child: Column(
        children: [
          _AboutRow(label: 'App', value: 'Eazy Attendance'),
          const Divider(height: 1),
          _AboutRow(label: 'Version', value: kAppVersion, mono: true),
          const Divider(height: 1),
          _AboutRow(label: 'Provider', value: 'Bynex Labs'),
          const Divider(height: 1),
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/terms'),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.radiusMd)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('Terms of Service', style: AppTextStyles.input),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(
      {required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.input),
          const Spacer(),
          Text(
            value,
            style: mono
                ? AppTextStyles.mono.copyWith(color: AppColors.gray600)
                : AppTextStyles.input.copyWith(color: AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTheme.controlHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorText,
          side: const BorderSide(color: AppColors.errorBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }
}
