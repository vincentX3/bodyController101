import 'package:drift/drift.dart';

// 跑步记录表
@DataClassName('RunRecord')
class RunRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get distance => real()(); // km
  IntColumn get durationMinutes => integer()(); // 分钟
  IntColumn get durationSeconds => integer()(); // 秒
  TextColumn get pace => text()(); // 配速，格式 "5:30/km"
  IntColumn get perceivedExertion => integer()(); // 体感 1-5
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 力量训练记录表
@DataClassName('StrengthRecord')
class StrengthRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get splitType => text()(); // 分化类型：推日/拉日/腿日
  IntColumn get durationMinutes => integer()(); // 训练时长
  RealColumn get totalVolume => real()(); // 总容量 Σ重量×次数
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 动作组记录表
@DataClassName('ExerciseSet')
class ExerciseSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get strengthRecordId => integer().references(StrengthRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseName => text()(); // 动作名称
  IntColumn get setNumber => integer()(); // 第几组
  RealColumn get weight => real()(); // 重量 kg
  IntColumn get reps => integer()(); // 次数
  IntColumn? get rpe => integer().nullable()(); // RPE 1-10，可选
}

// 目标表
@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get goalType => text()(); // 目标类型：half_marathon/squat/bench_press/deadlift
  TextColumn get title => text()(); // 目标标题
  DateTimeColumn? get targetDate => dateTime().nullable()(); // 目标日期（半马）
  TextColumn? get targetValue => text().nullable()(); // 目标值（如 "1:30:00" 或 "100kg"）
  TextColumn? get currentValue => text().nullable()(); // 当前值
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// AI配置表
@DataClassName('AIConfig')
class AIConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get apiKey => text()(); // API Key
  TextColumn get provider => text()(); // 提供商：dashscope
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
