import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'database.dart';

export 'package:drift/drift.dart';

part 'database_manager.g.dart';

@DriftDatabase(tables: [
  RunRecords,
  StrengthRecords,
  ExerciseSets,
  Goals,
  AIConfigs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // 未来版本升级逻辑
      },
    );
  }
}

class DatabaseManager {
  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= _createDatabase();
    return _instance!;
  }

  static AppDatabase _createDatabase() {
    final executor = LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'body_controller.db'));
      return NativeDatabase.createInBackground(file);
    });
    return AppDatabase(executor);
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}