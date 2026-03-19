import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/app_utils.dart';
import '../models/chat_message.dart';
import '../repositories/preferences_repository.dart';
import '../services/ai_service.dart';
import '../services/mock_ai_service.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';
import 'subscription_provider.dart';
import 'wardrobe_provider.dart';
import 'weather_provider.dart';

enum ChatRequestStatus {
  sent,
  limitReached,
  premiumLocked,
}

class AiStylistProvider extends ChangeNotifier {
  AiStylistProvider({
    required AuthProvider authProvider,
    required WardrobeProvider wardrobeProvider,
    required ProfileProvider profileProvider,
    required WeatherProvider weatherProvider,
    required SubscriptionProvider subscriptionProvider,
    required PreferencesRepository repository,
    AiService? aiService,
  })  : _authProvider = authProvider,
        _wardrobeProvider = wardrobeProvider,
        _profileProvider = profileProvider,
        _weatherProvider = weatherProvider,
        _subscriptionProvider = subscriptionProvider,
        _repository = repository,
        _aiService = aiService ?? MockAiService();

  AuthProvider _authProvider;
  WardrobeProvider _wardrobeProvider;
  ProfileProvider _profileProvider;
  WeatherProvider _weatherProvider;
  SubscriptionProvider _subscriptionProvider;
  PreferencesRepository _repository;
  final AiService _aiService;

  final List<ChatMessage> _messages = [];
  bool isTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void updateDependencies(
    AuthProvider authProvider,
    WardrobeProvider wardrobeProvider,
    ProfileProvider profileProvider,
    WeatherProvider weatherProvider,
    SubscriptionProvider subscriptionProvider,
    PreferencesRepository repository,
  ) {
    final previousUserId = _authProvider.currentUser?.id;
    _authProvider = authProvider;
    _wardrobeProvider = wardrobeProvider;
    _profileProvider = profileProvider;
    _weatherProvider = weatherProvider;
    _subscriptionProvider = subscriptionProvider;
    _repository = repository;
    if (previousUserId != _authProvider.currentUser?.id) {
      loadMessages();
    }
  }

  Future<void> loadMessages() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      _messages.clear();
      notifyListeners();
      return;
    }

    final saved = await _repository.fetchMessages(user.id);
    _messages
      ..clear()
      ..addAll(saved);

    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          id: const Uuid().v4(),
          text: _aiService.intro(
              name: _profileProvider.profile?.name ?? user.displayName),
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );
      await _persist();
    }
    notifyListeners();
  }

  Future<ChatRequestStatus> sendMessage(
    String prompt, {
    bool advanced = false,
  }) async {
    final user = _authProvider.currentUser;
    if (user == null || prompt.trim().isEmpty) {
      return ChatRequestStatus.limitReached;
    }

    if (advanced && !_subscriptionProvider.isPremium) {
      return ChatRequestStatus.premiumLocked;
    }

    final allowed = await _subscriptionProvider.consumeChatQuestion();
    if (!allowed) {
      return ChatRequestStatus.limitReached;
    }

    _messages.add(
      ChatMessage(
        id: const Uuid().v4(),
        text: prompt.trim(),
        isUser: true,
        createdAt: DateTime.now(),
      ),
    );
    final history = List<ChatMessage>.unmodifiable(_messages);
    isTyping = true;
    notifyListeners();
    await _persist();

    String reply;
    try {
      reply = await _aiService.buildReply(
        userId: user.id,
        prompt: prompt,
        history: history,
        items: _wardrobeProvider.allItems,
        premium: _subscriptionProvider.isPremium,
        plus: _subscriptionProvider.isPlus,
        profile: _profileProvider.profile,
        weather: _weatherProvider.snapshot,
      );
    } catch (_) {
      reply = localizedText(
        en: 'I’m not fully sure, but I can help with outfit ideas, colors, weather, or styling for a specific occasion. Tell me the plan or the weather and I’ll give you a clearer suggestion.',
        ru: 'Я не до конца уверен, какой вариант подойдёт лучше, но могу помочь с образами, цветами, погодой и стилем под конкретный повод. Напишите планы или погоду, и я дам более точную рекомендацию.',
        kk: 'Қай нұсқа ең жақсы болатынына толық сенімді болмасам да, образ, түстер, ауа райы және нақты жоспарға сай стиль бойынша көмектесе аламын. Жоспарыңызды не ауа райын жазыңыз, мен нақтырақ кеңес беремін.',
      );
    }

    _messages.add(
      ChatMessage(
        id: const Uuid().v4(),
        text: reply,
        isUser: false,
        createdAt: DateTime.now(),
      ),
    );
    isTyping = false;
    notifyListeners();
    await _persist();
    return ChatRequestStatus.sent;
  }

  Future<void> clearConversation() async {
    _messages.clear();
    await loadMessages();
  }

  Future<void> _persist() async {
    final user = _authProvider.currentUser;
    if (user == null) {
      return;
    }
    await _repository.saveMessages(userId: user.id, messages: _messages);
  }
}
