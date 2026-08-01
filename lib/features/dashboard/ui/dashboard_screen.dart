import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/loading_button.dart';
import '../../attendance/application/load_students_controller.dart';
import '../../attendance/ui/attendance_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../application/dashboard_controller.dart';
import '../data/level_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _loadingStudents = false;

  Future<void> _confirmLogout() async {
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

  Future<void> _pickDate(String currentIso) async {
    final current = parseIsoDate(currentIso);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // can't mark future attendance
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.blue500),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      await ref.read(dashboardControllerProvider.notifier).selectDate(picked);
    }
  }

  Future<void> _loadStudents(String levelId, String date, String className) async {
    // The AttendanceScreen loads the roster itself (local-first). We still do a
    // quick pre-check here so a totally empty offline state surfaces on the
    // dashboard rather than pushing an empty screen.
    setState(() => _loadingStudents = true);
    try {
      final result =
      await ref.read(loadStudentsControllerProvider).load(levelId, date);
      if (!mounted) return;
      if (result.students.isEmpty) {
        _showError('No students found for this class.');
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AttendanceScreen(
            levelId: levelId,
            date: date,
            className: className,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Could not load students.');
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorText,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(dashboardControllerProvider);
    final staffName =
        ref.watch(authControllerProvider).valueOrNull?.staffName ?? 'Teacher';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.blue500,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.school_outlined,
                  size: 18, color: AppColors.white),
            ),
            const SizedBox(width: 10),
            const Text('Eazy Attendance'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(navDate(DateTime.now()),
                  style: AppTextStyles.footer
                      .copyWith(color: AppColors.gray600)),
            ),
          ),
          IconButton(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign out',
            color: AppColors.gray600,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue500),
        ),
        error: (_, __) => _DashboardError(
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
        data: (state) => _DashboardBody(
          state: state,
          staffName: staffName,
          loadingStudents: _loadingStudents,
          onSelectClass: (id) =>
              ref.read(dashboardControllerProvider.notifier).selectClass(id),
          onPickDate: () => _pickDate(state.date),
          onLoadStudents: state.hasSelection
              ? () {
            final selected = state.classes.firstWhere(
                  (c) => c.id == state.selectedClassId,
              orElse: () => const LevelModel(id: '', name: ''),
            );
            _loadStudents(
                state.selectedClassId!, state.date, selected.name);
          }
              : null,
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.staffName,
    required this.loadingStudents,
    required this.onSelectClass,
    required this.onPickDate,
    required this.onLoadStudents,
  });

  final DashboardState state;
  final String staffName;
  final bool loadingStudents;
  final ValueChanged<String?> onSelectClass;
  final VoidCallback onPickDate;
  final VoidCallback? onLoadStudents;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Text('Take Attendance', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 4),
          const Text('Select a class and date to begin',
              style: AppTextStyles.sectionSubtitle),
          const SizedBox(height: 20),

          // Teacher info strip
          _TeacherStrip(staffName: staffName),
          const SizedBox(height: 20),

          // Class + Date card
          _SelectionCard(
            state: state,
            onSelectClass: onSelectClass,
            onPickDate: onPickDate,
          ),
          const SizedBox(height: 20),

          // Load Students
          LoadingButton(
            label: 'Load Students',
            busyLabel: 'Loading…',
            icon: Icons.groups_outlined,
            loading: loadingStudents,
            onPressed: onLoadStudents,
          ),
        ],
      ),
    );
  }
}

class _TeacherStrip extends StatelessWidget {
  const _TeacherStrip({required this.staffName});

  final String staffName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.blue100, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.person_outline,
                size: 20, color: AppColors.blue600),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(staffName,
                  style: AppTextStyles.input
                      .copyWith(fontWeight: FontWeight.w600)),
              Text('Signed in as Teacher', style: AppTextStyles.footer),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.state,
    required this.onSelectClass,
    required this.onPickDate,
  });

  final DashboardState state;
  final ValueChanged<String?> onSelectClass;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.gray100, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class / Level
          Row(
            children: [
              const Icon(Icons.class_outlined,
                  size: 14, color: AppColors.gray600),
              const SizedBox(width: 6),
              Text('CLASS / LEVEL', style: AppTextStyles.fieldLabel),
            ],
          ),
          const SizedBox(height: 6),
          _ClassDropdown(
            classes: state.classes,
            selectedId: state.selectedClassId,
            loading: state.loadingClasses,
            onChanged: onSelectClass,
          ),
          if (state.offlineNotice) ...[
            const SizedBox(height: 8),
            const _OfflineHint(),
          ],
          const SizedBox(height: 16),

          // Date
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.gray600),
              const SizedBox(width: 6),
              Text('DATE', style: AppTextStyles.fieldLabel),
            ],
          ),
          const SizedBox(height: 6),
          _DateField(iso: state.date, onTap: onPickDate),
        ],
      ),
    );
  }
}

class _ClassDropdown extends StatelessWidget {
  const _ClassDropdown({
    required this.classes,
    required this.selectedId,
    required this.loading,
    required this.onChanged,
  });

  final List<LevelModel> classes;
  final String? selectedId;
  final bool loading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hint = loading
        ? 'Loading classes…'
        : (classes.isEmpty ? 'No classes available' : 'Select a class…');

    return Container(
      height: AppTheme.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.gray200, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          hint: Text(hint, style: AppTextStyles.placeholder),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.gray400),
          style: AppTextStyles.input,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onChanged: (loading || classes.isEmpty) ? null : onChanged,
          items: [
            for (final c in classes)
              DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.iso, required this.onTap});

  final String iso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = parseIsoDate(iso);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        height: AppTheme.controlHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.gray200, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(navDate(date), style: AppTextStyles.input),
            ),
            const Icon(Icons.calendar_month_outlined,
                size: 18, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cloud_off_outlined,
            size: 14, color: AppColors.gray400),
        const SizedBox(width: 6),
        Expanded(
          child: Text('Showing saved classes — offline',
              style: AppTextStyles.footer),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray400),
            const SizedBox(height: 12),
            const Text('Something went wrong',
                style: AppTextStyles.cardTitle),
            const SizedBox(height: 20),
            LoadingButton(
              label: 'Retry',
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}