import 'package:hive/hive.dart';

class GoalModel extends HiveObject {
  final String id;
  final String title;
  final double targetAmount;
  double currentAmount;
  final DateTime date;

  GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.date,
  });
}

class GoalModelAdapter extends TypeAdapter<GoalModel> {
  @override
  final int typeId = 2;

  @override
  GoalModel read(BinaryReader reader) {
    return GoalModel(
      id: reader.read() as String,
      title: reader.read() as String,
      targetAmount: reader.read() as double,
      currentAmount: reader.read() as double,
      date: DateTime.fromMillisecondsSinceEpoch(reader.read() as int),
    );
  }

  @override
  void write(BinaryWriter writer, GoalModel obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.targetAmount);
    writer.write(obj.currentAmount);
    writer.write(obj.date.millisecondsSinceEpoch);
  }
}
