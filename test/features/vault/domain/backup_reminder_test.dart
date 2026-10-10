import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/features/vault/domain/backup_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 10);
  const enough = AppConfig.backupReminderMinEntries;

  test('não lembra com poucas senhas', () {
    expect(BackupReminder.isDue(entryCount: enough - 1, now: now), isFalse);
  });

  test('lembra quando nunca houve backup', () {
    expect(BackupReminder.isDue(entryCount: enough, now: now), isTrue);
  });

  test('lembra de novo só quando o último backup fica antigo', () {
    final recent = now.subtract(AppConfig.backupReminderMaxAge);
    expect(BackupReminder.isDue(entryCount: enough, now: now, lastBackupAt: recent), isFalse);
    final old = recent.subtract(const Duration(days: 1));
    expect(BackupReminder.isDue(entryCount: enough, now: now, lastBackupAt: old), isTrue);
  });

  test('"Depois" esconde até o prazo acabar', () {
    final until = now.add(AppConfig.backupReminderSnooze);
    expect(BackupReminder.isDue(entryCount: enough, now: now, snoozedUntil: until), isFalse);
    expect(BackupReminder.isDue(entryCount: enough, now: until, snoozedUntil: until), isTrue);
  });
}
