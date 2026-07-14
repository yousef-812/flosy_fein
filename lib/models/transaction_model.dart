import 'package:hive/hive.dart';

class TransactionModel extends HiveObject {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense; // true for expense, false for income
  final String categoryName;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryName,
  });
}

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    return TransactionModel(
      id: reader.read() as String,
      title: reader.read() as String,
      amount: reader.read() as double,
      date: DateTime.fromMillisecondsSinceEpoch(reader.read() as int),
      isExpense: reader.read() as bool,
      categoryName: reader.read() as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.amount);
    writer.write(obj.date.millisecondsSinceEpoch);
    writer.write(obj.isExpense);
    writer.write(obj.categoryName);
  }
}
