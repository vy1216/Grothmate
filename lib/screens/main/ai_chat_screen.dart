import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../database/app_database.dart';
import '../../services/app_state.dart';
import '../../services/groq_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _inputC = TextEditingController();
  final ScrollController _scrollC = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  String _contextPill = '';

  static const List<String> _quickReplies = [
    'What should I eat tonight?',
    "I'm feeling low today",
    'How am I doing this week?',
    'Suggest a workout for me',
    "I can't stop overthinking",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final state = context.read<AppState>();
    final user = state.user;
    if (user == null) return;
    
    // Load history from DB
    final history = await AppDatabase.instance.getConversationHistory(user.id!);
    
    final totalCal = state.totalCalToday.round();
    final moodLabel = state.todayMood?.moodLabel ?? 'not logged';
    final streak = state.streak;
    if (!mounted) return;
    setState(() {
      _contextPill =
          'Today: $totalCal kcal · Mood: $moodLabel · Streak: $streak days';
      if (_messages.isEmpty) {
        if (history.isEmpty) {
          _messages.add({
            'role': 'assistant',
            'content':
                "Hey ${user.name}! I'm ${user.aiCompanionName} — I know your calorie goals, mood patterns, and workout history. Ask me anything about your health, or just talk. I'm here. 🌱",
          });
        } else {
          for (var h in history) {
            _messages.add({
              'role': h['role'].toString(),
              'content': h['content'].toString(),
            });
          }
        }
      }
    });
    _scrollToBottom();
  }

  Future<void> _send([String? preset]) async {
    final msg = preset ?? _inputC.text.trim();
    if (msg.isEmpty || _loading) return;
    _inputC.clear();
    final user = context.read<AppState>().user;
    if (user == null) return;
    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _loading = true;
    });
    _scrollToBottom();
    final reply = await GroqService.sendMessage(user.id!, msg);
    await AppDatabase.instance.markStreakAction(user.id!, 'ai_checkin');
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _loading = false;
    });
    _scrollToBottom();
    await context.read<AppState>().refreshStreak();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollC.hasClients) {
        _scrollC.animateTo(
          _scrollC.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(user?.aiCompanionName ?? 'GrowthMate AI'),
          if (_contextPill.isNotEmpty) _buildContextPill(),
          Expanded(child: _buildMessagesList()),
          _buildQuickReplies(),
          _buildInput(),
        ]),
      ),
    );
  }

  Widget _buildHeader(String aiName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
      ),
      child: Row(children: [
        Stack(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.secondary,
            child: const Text('🌱', style: TextStyle(fontSize: 18)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg, width: 2),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              aiName,
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'Online · knows your full history',
              style: TextStyle(fontSize: 11, color: AppColors.accent),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/weekly-review'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border2),
            ),
            child: const Text(
              'Weekly Review',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildContextPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _contextPill,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollC,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length) return _TypingIndicator();
        final msg = _messages[i];
        final isUser = msg['role'] == 'user';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.secondary,
                  child: const Text('🌱', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.secondary : AppColors.card2,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(17),
                      topRight: const Radius.circular(17),
                      bottomLeft:
                          Radius.circular(isUser ? 17 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 17),
                    ),
                  ),
                  child: Text(
                    msg['content']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUser ? AppColors.pale : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => _send(_quickReplies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border2),
            ),
            child: Text(
              _quickReplies[i],
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border2),
            ),
            child: TextField(
              controller: _inputC,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Ask anything about your health...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
              ),
              onSubmitted: (_) => _send(),
              maxLines: null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _loading ? null : () => _send(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _loading ? AppColors.border2 : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.pale,
              size: 20,
            ),
          ),
        ),
      ]),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0.2, end: 1.0).animate(c))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.secondary,
            child: const Text('🌱', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
                bottomRight: Radius.circular(17),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _anims[i],
                  builder: (_, __) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(_anims[i].value),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
