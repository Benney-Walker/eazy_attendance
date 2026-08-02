/// Attendance status as the backend expresses it on the wire.
///
/// The `mark-attendance` payload uses the strings `"PRESENT"` / `"ABSENT"`,
/// and `load-students` returns the same in each student's `status`. The UI
/// thinks in booleans (present = true), but persistence and the sync queue use
/// this enum so the exact wire value round-trips unchanged.
enum AttendanceStatus {
  present('PRESENT'),
  absent('ABSENT');

  const AttendanceStatus(this.wire);

  /// The exact string sent to / received from the backend.
  final String wire;

  bool get isPresent => this == AttendanceStatus.present;

  /// Map a UI boolean to the status.
  static AttendanceStatus fromBool(bool present) =>
      present ? AttendanceStatus.present : AttendanceStatus.absent;

  /// Parse a backend wire string. Unknown / null values default to absent,
  /// matching the website (`status === "PRESENT"` → present, else not).
  static AttendanceStatus fromWire(String? value) =>
      value == AttendanceStatus.present.wire
          ? AttendanceStatus.present
          : AttendanceStatus.absent;
}

/// Lifecycle of a queued attendance submission awaiting sync.
enum SyncJobStatus {
  pending('PENDING'),
  syncing('SYNCING'),
  failed('FAILED');

  const SyncJobStatus(this.wire);

  final String wire;

  static SyncJobStatus fromWire(String? value) {
    for (final s in SyncJobStatus.values) {
      if (s.wire == value) return s;
    }
    return SyncJobStatus.pending;
  }
}
