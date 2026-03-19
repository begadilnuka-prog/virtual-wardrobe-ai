import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/ai_stylist_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wardrobe_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/premium_badge.dart';
import '../../widgets/common/premium_gate_sheet.dart';
import '../../widgets/common/usage_meter.dart';
import '../../widgets/premium_scaffold.dart';

class AiStylistScreen extends StatefulWidget {
  const AiStylistScreen({super.key});

  @override
  State<AiStylistScreen> createState() => _AiStylistScreenState();
}

class _AiStylistScreenState extends State<AiStylistScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastVisibleMessageCount = 0;
  bool _lastTypingState = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt(String prompt, {bool advanced = false}) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final status = await context.read<AiStylistProvider>().sendMessage(
          trimmed,
          advanced: advanced,
        );
    if (!mounted) {
      return;
    }

    switch (status) {
      case ChatRequestStatus.sent:
        _controller.clear();
        _scheduleAutoScroll();
        return;
      case ChatRequestStatus.limitReached:
        await showPremiumGateSheet(
          context,
          featureName: context.l10n.t('ai_unlimited_feature'),
        );
        return;
      case ChatRequestStatus.premiumLocked:
        await showPremiumGateSheet(
          context,
          featureName: context.l10n.t('ai_advanced_prompts_feature'),
        );
        return;
    }
  }

  void _scheduleAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final targetOffset = _scrollController.position.maxScrollExtent + 24;
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stylist = context.watch<AiStylistProvider>();
    final subscription = context.watch<SubscriptionProvider>();
    final wardrobeCount = context.watch<WardrobeProvider>().allItems.length;
    final progress = subscription.isPremium
        ? 0.0
        : 1 -
            (subscription.remainingChatQuestions /
                AppConstants.freeDailyChatLimit);
    final visibleMessageCount =
        stylist.messages.length + (stylist.isTyping ? 1 : 0);
    if (visibleMessageCount != _lastVisibleMessageCount ||
        stylist.isTyping != _lastTypingState) {
      _lastVisibleMessageCount = visibleMessageCount;
      _lastTypingState = stylist.isTyping;
      _scheduleAutoScroll();
    }
    final showPromptBundle = stylist.messages.length <= 1;
    final conversationWidgets = <Widget>[
      if (showPromptBundle)
        _PromptBundle(
          subscriptionIsPremium: subscription.isPremium,
          onPromptTap: _sendPrompt,
        ),
      if (wardrobeCount == 0)
        _InlineInfoCard(message: l10n.t('ai_empty_wardrobe_note')),
      for (final message in stylist.messages)
        _ChatBubble(
          text: message.text,
          isUser: message.isUser,
        ),
      if (stylist.isTyping) const _TypingBubble(),
    ];

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(l10n.t('ai_title')),
        actions: [
          IconButton(
            tooltip: l10n.t('ai_clear_chat'),
            onPressed:
                stylist.messages.length <= 1 ? null : stylist.clearConversation,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            UsageMeter(
              title: subscription.isPremium
                  ? l10n.t('ai_usage_unlimited',
                      args: {'plan': subscription.tierLabel})
                  : l10n.t('ai_usage_free'),
              subtitle: subscription.isPremium
                  ? l10n.t('ai_unlimited_subtitle')
                  : friendlyRemainingCount(
                      subscription.remainingChatQuestions, 'question'),
              progress: progress,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.softSurface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppTheme.accentDeep),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.t('ai_intro_title'),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            l10n.t('ai_intro_subtitle'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ListView.separated(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                  itemCount: conversationWidgets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => conversationWidgets[index],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 132),
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => _sendPrompt(_controller.text),
                        decoration: InputDecoration(
                          hintText: l10n.t('ai_input_hint'),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: stylist.isTyping
                        ? null
                        : () => _sendPrompt(_controller.text),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      padding: const EdgeInsets.all(0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptBundle extends StatelessWidget {
  const _PromptBundle({
    required this.subscriptionIsPremium,
    required this.onPromptTap,
  });

  final bool subscriptionIsPremium;
  final Future<void> Function(String prompt, {bool advanced}) onPromptTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('ai_quick_prompts'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _PromptSection(
            prompts: AppConstants.wardrobePromptSuggestions(),
            onTap: (prompt) => onPromptTap(prompt, advanced: false),
          ),
          const SizedBox(height: 14),
          _PromptSection(
            prompts: AppConstants.stylistFollowUpSuggestions(),
            leading: PremiumBadge(
              label: l10n.t('ai_follow_up'),
              icon: Icons.forum_outlined,
            ),
            onTap: (prompt) => onPromptTap(prompt, advanced: false),
          ),
          const SizedBox(height: 14),
          _PromptSection(
            prompts: AppConstants.advancedPromptSuggestions(),
            leading: subscriptionIsPremium
                ? PremiumBadge(label: l10n.t('ai_advanced'))
                : PremiumBadge(label: l10n.t('ai_premium_badge')),
            onTap: (prompt) => subscriptionIsPremium
                ? onPromptTap(prompt, advanced: true)
                : showPremiumGateSheet(
                    context,
                    featureName: l10n.t('ai_advanced_prompts_feature'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PromptSection extends StatelessWidget {
  const _PromptSection({
    required this.prompts,
    required this.onTap,
    this.leading,
  });

  final List<String> prompts;
  final ValueChanged<String> onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = MediaQuery.sizeOf(context).width - 92;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prompts.map((prompt) {
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxChipWidth),
              child: ActionChip(
                label: Text(
                  prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => onTap(prompt),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighlight.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppTheme.accentDeep,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.accent : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomRight: Radius.circular(isUser ? 8 : 24),
            bottomLeft: Radius.circular(isUser ? 24 : 8),
          ),
          border: Border.all(
            color: isUser ? Colors.transparent : AppTheme.border,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isUser ? Colors.white : AppTheme.text,
              ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24)
              .copyWith(bottomLeft: const Radius.circular(8)),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentSoft,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
