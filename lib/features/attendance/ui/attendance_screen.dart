import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_status_chip.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../dashboard/data/level_models.dart';
import '../application/attendance_controller.dart';

/// The attendance marking screen — native port of the website's AttendancePage.
/// Opened full-screen over the bottom-nav shell (its own back button + sticky
/// Save bar). Loads the roster local-first; marking and saving work identically
/// on or offline (save writes locally and enqueues for sync).
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.levelId,
    required this.date,
    required this.className,
  });

  final String levelId;
  final String date;
  final String className;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  String _query = '';

  late final AttendanceArgs _args = AttendanceArgs(
    levelId: widget.levelId,
    date: widget.date,
    className: widget.className,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  List<StudentModel> _filter(List<StudentModel> students) {
    if (_query.trim().isEmpty) return students;
    final q = _query.toLowerCase();
    return students
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.id.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _save() async {
    final ok = await ref.read(attendanceControllerProvider(_args).notifier).save();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Attendance saved'),
            backgroundColor: AppColors.blue600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.of(context).pop();
    } else {
      final error =
          ref.read(attendanceControllerProvider(_args)).error ?? 'Save failed.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.errorText,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceControllerProvider(_args));
    final visible = _filter(state.students);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: const Text('Mark Attendance'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Center(child: SyncStatusChip()),
          ),
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_searchVisible ? Icons.close : Icons.search, size: 20),
            tooltip: 'Search students',
            color: AppColors.gray600,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (_searchVisible) _SearchField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
          ),
          Expanded(
            child: state.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.blue500),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    children: [
                      _MetaHeader(
                        className: widget.className,
                        date: widget.date,
                        percent: state.percent,
                        fromCache: state.fromCache,
                      ),
                      const SizedBox(height: 16),
                      _StatsRow(state: state),
                      const SizedBox(height: 20),
                      _RateBar(percent: state.percent),
                      const SizedBox(height: 20),
                      _ActionStrip(
                        onAllPresent: () => ref
                            .read(attendanceControllerProvider(_args).notifier)
                            .markAll(true),
                        onAllAbsent: () => ref
                            .read(attendanceControllerProvider(_args).notifier)
                            .markAll(false),
                      ),
                      const SizedBox(height: 20),
                      _StudentsHeader(count: visible.length),
                      const SizedBox(height: 12),
                      if (state.students.isNotEmpty && visible.isEmpty)
                        const _EmptyState()
                      else
                        ...visible.map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _StudentCard(
                                student: s,
                                present: state.marks[s.id] ?? false,
                                onToggle: () => ref
                                    .read(attendanceControllerProvider(_args)
                                        .notifier)
                                    .toggle(s.id),
                              ),
                            )),
                    ],
                  ),
          ),
          _StickyBar(
            present: state.present,
            total: state.total,
            saving: state.saving,
            onSave: state.students.isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}

// ── Search ──

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: AppTextStyles.input,
        cursorColor: AppColors.blue500,
        decoration: InputDecoration(
          hintText: 'Search students…',
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.gray400),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 42, minHeight: 42),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
    );
  }
}

// ── Meta header (gradient) ──

class _MetaHeader extends StatelessWidget {
  const _MetaHeader({
    required this.className,
    required this.date,
    required this.percent,
    required this.fromCache,
  });

  final String className;
  final String date;
  final int percent;
  final bool fromCache;

  String get _statusLabel => percent == 100
      ? '✓ All Present'
      : (percent == 0 ? 'Not Started' : 'In Progress');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.loginBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(Icons.class_outlined,
                size: 22, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  className.isEmpty ? 'Class' : className,
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fromCache ? '${formatDateLong(date)} · offline' : formatDateLong(date),
                  style: AppTextStyles.footer.copyWith(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: AppTextStyles.footer.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ──

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final AttendanceState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(value: state.total, label: 'Total', color: AppColors.blue900),
        const SizedBox(width: 12),
        _StatBox(
            value: state.present, label: 'Present', color: AppColors.blue600),
        const SizedBox(width: 12),
        _StatBox(
            value: state.absent, label: 'Absent', color: AppColors.gray400),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.gray100, width: 1.5),
        ),
        child: Column(
          children: [
            Text('$value',
                style: AppTextStyles.sectionTitle.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(), style: AppTextStyles.footer),
          ],
        ),
      ),
    );
  }
}

// ── Rate bar ──

class _RateBar extends StatelessWidget {
  const _RateBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ATTENDANCE RATE', style: AppTextStyles.fieldLabel),
            Text('$percent%',
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.blue600,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: AppColors.gray100,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue500),
          ),
        ),
      ],
    );
  }
}

// ── Action strip ──

class _ActionStrip extends StatelessWidget {
  const _ActionStrip(
      {required this.onAllPresent, required this.onAllAbsent});

  final VoidCallback onAllPresent;
  final VoidCallback onAllAbsent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: onAllPresent,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, size: 15),
                  SizedBox(width: 6),
                  Text('All Present'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: onAllAbsent,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gray600,
                side: const BorderSide(color: AppColors.gray200, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, size: 15),
                  SizedBox(width: 6),
                  Text('All Absent'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Students header ──

class _StudentsHeader extends StatelessWidget {
  const _StudentsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('STUDENTS', style: AppTextStyles.fieldLabel),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count student${count == 1 ? '' : 's'}',
              style: AppTextStyles.footer),
        ),
      ],
    );
  }
}

// ── Student card ──

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.present,
    required this.onToggle,
  });

  final StudentModel student;
  final bool present;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: present ? AppColors.blue50 : AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: present ? AppColors.blue200 : AppColors.gray100,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: present ? AppColors.blue500 : AppColors.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                initialsOf(student.name),
                style: AppTextStyles.footer.copyWith(
                  color: present ? AppColors.white : AppColors.gray600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: AppTextStyles.input
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('#${student.id}', style: AppTextStyles.mono),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: present,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.white,
              activeTrackColor: AppColors.blue500,
              inactiveThumbColor: AppColors.white,
              inactiveTrackColor: AppColors.gray200,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ──

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const Icon(Icons.groups_outlined,
                size: 28, color: AppColors.blue400),
          ),
          const SizedBox(height: 12),
          const Text('No students found', style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}

// ── Sticky save bar ──

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.present,
    required this.total,
    required this.saving,
    required this.onSave,
  });

  final int present;
  final int total;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
            top: BorderSide(color: AppColors.gray100, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SUMMARY', style: AppTextStyles.footer),
              Text('$present / $total present',
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.blue900,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: AppTheme.controlHeight,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Saving…'),
                        ],
                      )
                    : const Text('Save Attendance'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
