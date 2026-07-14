import 'package:hive/hive.dart';

class ChallengeModel extends HiveObject {
  final String id;
  final String title;
  final String description;
  final String targetCategory;
  final double targetReductionPercent;
  final int durationDays;
  final DateTime startDate;
  bool isCompleted;
  bool isFailed;

  ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCategory,
    required this.targetReductionPercent,
    required this.durationDays,
    required this.startDate,
    this.isCompleted = false,
    this.isFailed = false,
  });
}

class ChallengeModelAdapter extends TypeAdapter<ChallengeModel> {
  @override
  final int typeId = 3;

  @override
  ChallengeModel read(BinaryReader reader) {
    return ChallengeModel(
      id: reader.read() as String,
      title: reader.read() as String,
      description: reader.read() as String,
      targetCategory: reader.read() as String,
      targetReductionPercent: reader.read() as double,
      durationDays: reader.read() as int,
      startDate: DateTime.fromMillisecondsSinceEpoch(reader.read() as int),
      isCompleted: reader.read() as bool,
      isFailed: reader.read() as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChallengeModel obj) {
    writer.write(obj.id);
    writer.write(obj.title);
    writer.write(obj.description);
    writer.write(obj.targetCategory);
    writer.write(obj.targetReductionPercent);
    writer.write(obj.durationDays);
    writer.write(obj.startDate.millisecondsSinceEpoch);
    writer.write(obj.isCompleted);
    writer.write(obj.isFailed);
  }
}
