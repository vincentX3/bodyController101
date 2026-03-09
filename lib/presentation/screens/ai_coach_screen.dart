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
  final List<Map<String, String>> _conversationHistory = [];
  int _questionCount = 0;
  final int _maxQuestions = 3;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _selectedModel = 'qwen-turbo';

  final List<Map<String, String>> _modelOptions = [
    {'value': 'qwen-turbo', 'label': 'Qwen-Turbo（快速）'},
    {'value': 'qwen-plus', 'label': 'Qwen-Plus（平衡）'},
    {'value': 'qwen-max', 'label': 'Qwen-Max（强大）'},
  ];

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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
            const SizedBox(height: 8),
            Text(
              '获取API Key：dashscope.console.aliyun.com',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
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
                  onPressed: _isLoading ? null : _generateInsights,
                  icon: const Icon(Icons.insights),
                  label: const Text('数据洞察'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _generatePlan,
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
                    final msg = _conversationHistory[index];
                    return _buildMessageBubble(
                      msg['content']!,
                      msg['role'] == 'user',
                    );
                  },
                ),
        ),

        // 剩余提问次数提示
        if (_questionCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '剩余追问次数：${_maxQuestions - _questionCount}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        // 加载指示器
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
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
                        ? '追问次数已用完，请重新生成'
                        : '输入问题或调整建议...',
                    border: const OutlineInputBorder(),
                    enabled: _questionCount < _maxQuestions && !_isLoading,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_questionCount < _maxQuestions && !_isLoading) {
                      _sendMessage();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _questionCount < _maxQuestions && !_isLoading
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
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
              child: SelectableText(
                message,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generateInsights() async {
    setState(() {
      _isLoading = true;
      _conversationHistory.clear();
      _questionCount = 0;
      _conversationHistory.add({'role': 'user', 'content': '生成数据洞察'});
      _conversationHistory.add({'role': 'assistant', 'content': '正在分析您的训练数据...'});
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      aiService.setModel(_selectedModel);
      final insights = await aiService.generateInsights();

      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add({'role': 'assistant', 'content': insights});
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add({'role': 'assistant', 'content': '生成洞察时出错：$e'});
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isLoading = true;
      _conversationHistory.clear();
      _questionCount = 0;
      _conversationHistory.add({'role': 'user', 'content': '生成训练计划'});
      _conversationHistory.add({'role': 'assistant', 'content': '正在为您制定下周训练计划...'});
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      aiService.setModel(_selectedModel);
      final plan = await aiService.generatePlan();

      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add({'role': 'assistant', 'content': plan});
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add({'role': 'assistant', 'content': '生成计划时出错：$e'});
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
      _conversationHistory.add({'role': 'user', 'content': message});
      _conversationHistory.add({'role': 'assistant', 'content': '正在思考...'});
      _questionCount++;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      aiService.setModel(_selectedModel);
      
      // 提取对话历史（排除最后两条）
      final history = _conversationHistory
          .sublist(0, _conversationHistory.length - 1)
          .map((m) => m['content']!)
          .toList();
      
      final response = await aiService.chat(message, conversationHistory: history);

      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add({'role': 'assistant', 'content': response});
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _conversationHistory.removeLast();
        _conversationHistory.add({'role': 'assistant', 'content': '回复时出错：$e'});
        _isLoading = false;
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
    String tempModel = _selectedModel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
              ),
              const SizedBox(height: 16),
              const Text('模型选择'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: tempModel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _modelOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    tempModel = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                '获取API Key：dashscope.console.aliyun.com',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  setState(() {
                    _selectedModel = tempModel;
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('配置已保存')),
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
      ),
    );
  }
}