import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/providers.dart';
import '../../data/services/ai_service.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final List<String> _conversationHistory = [];
  int _questionCount = 0;
  final int _maxQuestions = 3;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiConfigState = ref.watch(aiConfigStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI教练'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: aiConfigState.hasAPIKey
          ? _buildChatInterface()
          : _buildSetupPrompt(),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              '设置AI教练',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '请先配置阿里云百炼API Key以使用AI教练功能',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showSettingsDialog(),
              icon: const Icon(Icons.settings),
              label: const Text('配置API Key'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // 操作按钮
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generateInsights,
                  icon: const Icon(Icons.insights),
                  label: const Text('数据洞察'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _generatePlan,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('生成计划'),
                ),
              ),
            ],
          ),
        ),

        // 对话历史
        Expanded(
          child: _conversationHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '点击上方按钮开始',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '或直接输入问题与我对话',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversationHistory.length,
                  itemBuilder: (context, index) {
                    final isUser = index % 2 == 0;
                    return _buildMessageBubble(
                      _conversationHistory[index],
                      isUser,
                    );
                  },
                ),
        ),

        // 剩余提问次数提示
        if (_questionCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '剩余提问次数：${_maxQuestions - _questionCount}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),

        // 输入框
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: _questionCount >= _maxQuestions
                        ? '提问次数已用完'
                        : '输入问题或调整建议...',
                    border: const OutlineInputBorder(),
                    enabled: _questionCount < _maxQuestions,
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _questionCount < _maxQuestions
                    ? _sendMessage
                    : null,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.psychology, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateInsights() async {
    setState(() {
      _conversationHistory.add('生成数据洞察');
      _conversationHistory.add('正在分析您的训练数据...');
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final insights = await aiService.generateInsights();

      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add(insights);
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add('生成洞察时出错：$e');
      });
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _conversationHistory.add('生成训练计划');
      _conversationHistory.add('正在为您制定下周训练计划...');
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final plan = await aiService.generatePlan();

      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add(plan);
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add('生成计划时出错：$e');
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _conversationHistory.add(message);
      _conversationHistory.add('正在思考...');
      _questionCount++;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.chat(
        message,
        conversationHistory: _conversationHistory.sublist(0, _conversationHistory.length - 1),
      );

      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add(response);
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add('回复时出错：$e');
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSettingsDialog() {
    final aiConfigState = ref.read(aiConfigStateProvider);
    final apiKeyController = TextEditingController(
      text: aiConfigState.apiKey ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('阿里云百炼API Key'),
            const SizedBox(height: 8),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            const Text(
              '获取API Key：访问阿里云百炼控制台',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final apiKey = apiKeyController.text.trim();
              if (apiKey.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入API Key')),
                );
                return;
              }

              try {
                await ref.read(aiConfigStateProvider.notifier).saveAPIKey(apiKey);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key已保存')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('保存失败：$e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}