// lib/presentation/screens/life_screen.dart — AI Chat (SahayaK)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/hive_models.dart';
import '../providers/ai_chat_provider.dart';

class LifeScreen extends StatefulWidget {
  const LifeScreen({Key? key}) : super(key: key);
  @override
  State<LifeScreen> createState() => _LifeScreenState();
}

class _LifeScreenState extends State<LifeScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _send(AIChatProvider prov) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    prov.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _controller.dispose(); _scrollController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIChatProvider>(builder: (context, chatProv, _) {
      final msgs = chatProv.messages;
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: Column(children: [
          // App Bar
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 16, 0), child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.self_improvement, color: AppColors.bg, size: 18)),
            const SizedBox(width: 10),
            const Text('Mindful Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
              onPressed: () => chatProv.clearChat()),
          ])),
          // Messages
          Expanded(child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: msgs.length + (chatProv.isLoading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == msgs.length) return _TypingIndicator();
              return _ChatBubble(message: msgs[i], onAction: (action) {
                chatProv.handleQuickAction(action);
                _scrollToBottom();
              });
            },
          )),
          // Quick Actions
          if (msgs.isNotEmpty && !msgs.last.isUser && msgs.last.actionButtons.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Wrap(
              spacing: 8, runSpacing: 8,
              children: ['✨ Summarize my week', '🧘 Schedule a break', '🎯 Break down a goal'].map((a) =>
                GestureDetector(onTap: () { chatProv.handleQuickAction(a); _scrollToBottom(); },
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                    child: Text(a, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                ),
              ).toList(),
            )),
          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: const BoxDecoration(color: AppColors.bgSecondary,
              border: Border(top: BorderSide(color: AppColors.cardBorder))),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder)),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Tell SahayaK what's on your mind...",
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true, fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                onSubmitted: (_) => _send(chatProv),
              )),
              const SizedBox(width: 8),
              GestureDetector(onTap: () => _send(chatProv),
                child: Container(width: 40, height: 40, decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  child: const Icon(Icons.send, color: AppColors.bg, size: 18)),
              ),
            ]),
          ),
        ])),
      );
    });
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String) onAction;
  const _ChatBubble({required this.message, required this.onAction});
  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(width: 28, height: 28, margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
              color: AppColors.surface),
            child: const Center(child: Icon(Icons.auto_awesome, size: 14, color: AppColors.primary))),
          const SizedBox(width: 8),
        ],
        Flexible(child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUser ? AppColors.chatUser : AppColors.chatAI,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4), bottomRight: Radius.circular(isUser ? 4 : 18)),
            border: isUser ? null : Border.all(color: AppColors.primary.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(message.content, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
            if (message.actionButtons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: message.actionButtons.map((a) =>
                GestureDetector(onTap: () => onAction(a),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_arrow, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(a, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ).toList()),
            ],
          ]),
        )),
        if (isUser) ...[
          const SizedBox(width: 8),
          Container(width: 28, height: 28, margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
            child: const Center(child: Icon(Icons.person, size: 16, color: AppColors.bg))),
        ],
      ],
    ));
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 28, height: 28, margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 1.5), color: AppColors.surface),
          child: const Center(child: Icon(Icons.auto_awesome, size: 14, color: AppColors.primary))),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.chatAI, borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
            border: Border.all(color: AppColors.primary.withOpacity(0.2))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(delay: 0), const SizedBox(width: 4), _Dot(delay: 1), const SizedBox(width: 4), _Dot(delay: 2),
          ]),
        ),
      ],
    ));
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delay * 200), () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) =>
      Container(width: 8, height: 8, decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.3 + _ctrl.value * 0.7), shape: BoxShape.circle)));
  }
}
