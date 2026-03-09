import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
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
      // 在Android上，确保sqlite3_flutter_libs的原生库被正确加载
      if (Platform.isAndroid) {
        // 通过打开内存数据库来初始化sqlite3原生库
        sqlite3.openInMemory().dispose();
      }

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