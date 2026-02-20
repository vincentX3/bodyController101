import '../database/database.dart';
import '../database/database_manager.dart';

class AIConfigRepository {
  final AppDatabase _db = DatabaseManager.instance;

  // 保存AI配置
  Future<int> saveAIConfig({
    required String apiKey,
    required String provider,
  }) async {
    // 先删除旧配置
    await _db.delete(_db.aiConfigs).go();
    
    return await _db.into(_db.aiConfigs).insert(
      AIConfigsCompanion.insert(
        apiKey: apiKey,
        provider: provider,
      ),
    );
  }

  // 获取AI配置
  Future<AIConfig?> getAIConfig() async {
    final configs = await _db.select(_db.aiConfigs).get();
    if (configs.isEmpty) return null;
    return configs.first;
  }

  // 检查是否已配置API Key
  Future<bool> hasAPIKey() async {
    final config = await getAIConfig();
    return config != null && config.apiKey.isNotEmpty;
  }

  // 获取API Key
  Future<String?> getAPIKey() async {
    final config = await getAIConfig();
    return config?.apiKey;
  }

  // 删除AI配置
  Future<void> deleteAIConfig() async {
    await _db.delete(_db.aiConfigs).go();
  }
}