import '../data/models/expense.dart';

/// Builds a CSV from expenses for export/backup.
class ExportService {
  static String expensesCsv(List<Expense> list) {
    final sorted = [...list]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final b = StringBuffer()
      ..writeln('date,amount,category,type,mood,time_minutes,note');
    for (final e in sorted) {
      final cat = ExpenseCategory.byId(e.categoryId).label;
      final type = e.needWant == NeedWant.want ? 'want' : 'need';
      final note = (e.note ?? '').replaceAll('"', '""');
      b.writeln(
          '${e.createdAt.toIso8601String()},${e.amount.toStringAsFixed(2)},$cat,$type,${e.mood.name},${e.timeCostMinutes.round()},"$note"');
    }
    return b.toString();
  }
}
