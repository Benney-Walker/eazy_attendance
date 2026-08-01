import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../dashboard/data/level_models.dart';

/// TEMPORARY attendance screen for Phase 4, so the dashboard's Load Students
/// flow is testable end-to-end. Phase 5 replaces this with the real screen
/// (toggles, mark-all, summary, save-to-local + enqueue).
///
/// It shows the loaded roster and an offline notice if the data came from
/// cache — enough to confirm the local-first load path works.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({
    super.key,
    required this.levelId,
    required this.date,
    required this.students,
    this.loadedFromCache = false,
  });

  final String levelId;
  final String date;
  final List<StudentModel> students;
  final bool loadedFromCache;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (loadedFromCache)
            Container(
              width: double.infinity,
              color: AppColors.blue50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Loaded from saved data — offline',
                  style: AppTextStyles.footer),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(navDate(parseIsoDate(date)),
                style: AppTextStyles.cardSubtitle),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(
              child: Text('No students found',
                  style: AppTextStyles.cardSubtitle),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: students.length,
              itemBuilder: (context, i) {
                final s = students[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name, style: AppTextStyles.input),
                  subtitle: Text('#${s.id}', style: AppTextStyles.mono),
                  trailing: Text(
                    s.presentByDefault ? 'Present' : 'Absent',
                    style: AppTextStyles.footer.copyWith(
                      color: s.presentByDefault
                          ? AppColors.blue600
                          : AppColors.gray400,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'The full attendance screen (toggles, summary, save) arrives in '
                  'the next phase.',
              style: AppTextStyles.footer,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}