import 'package:hive/hive.dart';

class BudgetModel extends HiveObject {
  final String categoryName;
  final double limitAmount;
  double spentAmount;

  BudgetModel({
    required this.categoryName,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });
}

class BudgetModelAdapter extends TypeAdapter<BudgetModel> {
  @override
  final int typeId = 1;

  @override
  BudgetModel read(BinaryReader reader) {
    return BudgetModel(
      categoryName: reader.read() as String,
      limitAmount: reader.read() as double,
      spentAmount: reader.read() as double,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetModel obj) {
    writer.write(obj.categoryName);
    writer.write(obj.limitAmount);
    writer.write(obj.spentAmount);
  }
}
