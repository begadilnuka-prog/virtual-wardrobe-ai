import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../models/chat_message.dart';
import '../models/marketplace_suggestion.dart';
import '../models/smart_outfit_recommendation.dart';
import '../models/user_profile.dart';
import '../models/wardrobe_item.dart';
import '../models/weather_snapshot.dart';
import 'ai_service.dart';
import 'styling_engine_service.dart';

class MockAiService implements AiService {
  MockAiService() : _stylingEngineService = StylingEngineService();

  final StylingEngineService _stylingEngineService;

  @override
  Future<String> buildReply({
    required String userId,
    required String prompt,
    required List<ChatMessage> history,
    required List<WardrobeItem> items,
    required bool premium,
    required bool plus,
    UserProfile? profile,
    WeatherSnapshot? weather,
  }) async {
    await Future<void>.delayed(Duration(milliseconds: premium ? 650 : 900));
    return _composeReply(
      userId: userId,
      prompt: prompt,
      history: history,
      items: items,
      premium: premium,
      plus: plus,
      profile: profile,
      weather: weather,
    );
  }

  @override
  String intro({String? name}) {
    final firstName = (name?.trim().isNotEmpty ?? false)
        ? name!.trim().split(' ').first
        : localizedText(en: 'there', ru: 'друг', kk: 'дос');
    return localizedText(
      en: 'Hi $firstName, I’m your I Closet stylist. Ask me about outfits, colors, weather, daily plans, or follow-up changes like making a look more formal, and I’ll keep the advice practical and polished.',
      ru: 'Привет, $firstName. Я ваш стилист в I Closet. Спрашивайте про образы, цвета, погоду, планы на день или просите доработать образ, например сделать его более формальным, а я предложу практичный и красивый вариант.',
      kk: 'Сәлем, $firstName. Мен I Closet ішіндегі стилистпін. Образ, түстер, ауа райы, күн жоспары туралы сұраңыз немесе образды, мысалы, сәл ресмилеу етіп өзгертуді сұраңыз, мен практикалық әрі сәнді нұсқа ұсынамын.',
    );
  }

  String _composeReply({
    required String userId,
    required String prompt,
    required List<ChatMessage> history,
    required List<WardrobeItem> items,
    required bool premium,
    required bool plus,
    UserProfile? profile,
    WeatherSnapshot? weather,
  }) {
    final cleanPrompt = prompt.trim();
    final normalizedPrompt = cleanPrompt.toLowerCase();
    final contextText = _recentContextText(history);
    final seed =
        '$normalizedPrompt|${history.length}|${items.length}'.hashCode.abs();

    final context = _ResolvedChatContext(
      weather: _extractWeather(normalizedPrompt) ??
          _extractWeather(contextText) ??
          weather?.condition ??
          WeatherCondition.cloudy,
      occasion: _extractOccasion(normalizedPrompt) ??
          _extractOccasion(contextText) ??
          DailyOccasion.casualWalk,
      mentionedColors: _extractColors('$normalizedPrompt $contextText'),
      mentionedCategory: _extractCategory(normalizedPrompt),
      definitionTopic: _extractDefinitionTopic(normalizedPrompt),
      asksForShopping: _containsAny(normalizedPrompt, const [
        'shop',
        'buy',
        'marketplace',
        'brand',
        'куп',
        'магаз',
        'бренд',
        'сатып',
        'дүкен',
      ]),
      asksForShoes: _containsAny(normalizedPrompt, const [
        'shoe',
        'shoes',
        'sneaker',
        'sneakers',
        'boots',
        'обув',
        'кроссов',
        'аяқ киім',
      ]),
      isFollowUp: _containsAny(
        normalizedPrompt,
        const [
          'what about',
          'another option',
          'another one',
          'more formal',
          'more casual',
          'something else',
          'а что',
          'другой вариант',
          'более форм',
          'более повсед',
          'тағы бір',
          'ресмилеу',
          'күнделіктірек',
        ],
      ),
      seed: seed,
    );

    final intent = _detectIntent(normalizedPrompt, context);

    if (currentLanguageCode() != 'en') {
      return _composeLocalizedReply(
        userId: userId,
        items: items,
        profile: profile,
        context: context,
        intent: intent,
        premium: premium,
        plus: plus,
      );
    }

    switch (intent) {
      case _AiIntent.greeting:
        return _finalizeSentences([
          _pickVariant(const [
            'Absolutely, I’m here for styling help whenever you need it.',
            'I’m ready. Tell me the weather, the plan, or one piece you want to wear and I’ll build from there.',
            'Happy to help. Give me the occasion or the vibe you want, and I’ll turn it into a real outfit idea.',
          ], context.seed),
          'I can help with outfit ideas, follow-up tweaks, color matching, weather dressing, and occasion-based styling.',
        ]);
      case _AiIntent.gratitude:
        return _finalizeSentences([
          _pickVariant(const [
            'Any time.',
            'Of course.',
            'Always.',
          ], context.seed),
          'If you want, send me the next step like making the outfit more formal, more casual, or better for a specific weather change.',
        ]);
      case _AiIntent.definition:
        return _definitionReply(
          topic: context.definitionTopic,
          premium: premium,
          seed: context.seed,
        );
      case _AiIntent.colorTheory:
        return _colorReply(
          prompt: normalizedPrompt,
          items: items,
          profile: profile,
          context: context,
          premium: premium,
        );
      case _AiIntent.pairing:
        return _pairingReply(
          prompt: normalizedPrompt,
          items: items,
          profile: profile,
          context: context,
          premium: premium,
        );
      case _AiIntent.followUpShoes:
        return _shoesReply(
          items: items,
          profile: profile,
          context: context,
          premium: premium,
        );
      case _AiIntent.followUpFormal:
        return _styledAdjustmentReply(
          userId: userId,
          items: items,
          profile: profile,
          context:
              context.copyWith(occasion: _moreFormalOccasion(context.occasion)),
          premium: premium,
          plus: plus,
          tone: _AdjustmentTone.formal,
        );
      case _AiIntent.followUpCasual:
        return _styledAdjustmentReply(
          userId: userId,
          items: items,
          profile: profile,
          context:
              context.copyWith(occasion: _moreCasualOccasion(context.occasion)),
          premium: premium,
          plus: plus,
          tone: _AdjustmentTone.casual,
        );
      case _AiIntent.followUpAlternative:
        return _alternativeReply(
          userId: userId,
          items: items,
          profile: profile,
          context: context,
          premium: premium,
          plus: plus,
        );
      case _AiIntent.shopping:
      case _AiIntent.outfit:
        return _outfitReply(
          userId: userId,
          items: items,
          profile: profile,
          context: context,
          premium: premium,
          plus: plus,
          shoppingRequested: intent == _AiIntent.shopping,
        );
      case _AiIntent.fallback:
        return _fallbackReply(context: context, items: items);
    }
  }

  String _composeLocalizedReply({
    required String userId,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required _AiIntent intent,
    required bool premium,
    required bool plus,
  }) {
    switch (intent) {
      case _AiIntent.greeting:
        return localizedText(
          en: '',
          ru: 'Привет! Я стилист I Closet. Напишите, какая у вас погода, планы или вещи, которые хотите надеть, и я предложу удобный и стильный вариант.',
          kk: 'Сәлем! Мен I Closet стилистімін. Ауа райын, жоспарыңызды немесе кигіңіз келетін затты жазыңыз, мен ыңғайлы әрі сәнді нұсқа ұсынамын.',
        );
      case _AiIntent.gratitude:
        return localizedText(
          en: '',
          ru: 'Всегда пожалуйста. Если хотите, я могу сделать образ более формальным, более повседневным или подобрать обувь.',
          kk: 'Әрқашан көмектесемін. Қаласаңыз, образды ресмилеу, күнделіктірек ету немесе аяқ киім ұсыну жағынан жалғастыра аламын.',
        );
      case _AiIntent.definition:
        return _localizedDefinitionReply(context.definitionTopic);
      case _AiIntent.colorTheory:
      case _AiIntent.pairing:
        return _localizedColorReply(
          items: items,
          profile: profile,
          context: context,
        );
      case _AiIntent.followUpShoes:
        return _localizedShoesReply(items: items, context: context);
      case _AiIntent.followUpFormal:
      case _AiIntent.followUpCasual:
      case _AiIntent.followUpAlternative:
      case _AiIntent.shopping:
      case _AiIntent.outfit:
        if (items.isEmpty) {
          return _localizedEmptyWardrobeReply(
            weather: context.weather,
            occasion: context.occasion,
            profile: profile,
          );
        }

        final adjustedContext = switch (intent) {
          _AiIntent.followUpFormal => context.copyWith(
              occasion: _moreFormalOccasion(context.occasion),
            ),
          _AiIntent.followUpCasual => context.copyWith(
              occasion: _moreCasualOccasion(context.occasion),
            ),
          _ => context,
        };

        final recommendation = _buildRecommendation(
          userId: userId,
          items: items,
          profile: profile,
          context: adjustedContext,
          premium: premium,
          plus: plus,
        );

        if (recommendation == null) {
          return _localizedFallbackReply(
              context: adjustedContext, items: items);
        }

        final featuredItems = _selectedItems(items, recommendation);
        final intro = switch (intent) {
          _AiIntent.followUpFormal => localizedText(
              en: '',
              ru: 'Да, можно сделать образ более формальным, не перегружая его.',
              kk: 'Иә, образды артық ауырлатпай, сәл ресмилеу етуге болады.',
            ),
          _AiIntent.followUpCasual => localizedText(
              en: '',
              ru: 'Да, можно сделать образ более расслабленным, сохранив аккуратность.',
              kk: 'Иә, образды жинақылығын сақтап, еркіндеу етуге болады.',
            ),
          _AiIntent.followUpAlternative => localizedText(
              en: '',
              ru: 'Вот ещё один вариант для той же ситуации.',
              kk: 'Осы жағдайға тағы бір нұсқа мынадай болуы мүмкін.',
            ),
          _AiIntent.shopping => localizedText(
              en: '',
              ru: 'Ниже вариант образа и вещь, которую можно добавить, если хочется усилить результат.',
              kk: 'Төменде образ нұсқасы және нәтижені күшейту үшін қоса алатын зат берілген.',
            ),
          _ => localizedText(
              en: '',
              ru: 'Я бы собрал образ так, чтобы он был уместным, удобным и выглядел собранно.',
              kk: 'Мен образды орынды, ыңғайлы және жинақы көрінетіндей етіп құрастырар едім.',
            ),
        };

        return _finalizeSentences([
          intro,
          _localizedPiecesSentence(featuredItems),
          recommendation.explanation,
          if (premium) _localizedProfileSentence(profile, featuredItems),
          if (plus && intent == _AiIntent.shopping)
            _localizedPlusSentence(recommendation.marketplaceSuggestions),
        ]);
      case _AiIntent.fallback:
        return _localizedFallbackReply(context: context, items: items);
    }
  }

  _AiIntent _detectIntent(String prompt, _ResolvedChatContext context) {
    if (_containsAny(prompt, const [
      'thank you',
      'thanks',
      'ty',
      'спасибо',
      'благодар',
      'рахмет',
    ])) {
      return _AiIntent.gratitude;
    }

    if (_containsAny(prompt, const [
          'hello',
          'hi',
          'hey',
          'привет',
          'здравств',
          'сәлем',
        ]) &&
        prompt.split(RegExp(r'\s+')).length <= 5) {
      return _AiIntent.greeting;
    }

    if (context.asksForShoes) {
      return _AiIntent.followUpShoes;
    }

    if (_containsAny(prompt, const [
      'more formal',
      'make it more formal',
      'dress it up',
      'sharper',
      'более форм',
      'сделай формаль',
      'ресмилеу',
    ])) {
      return _AiIntent.followUpFormal;
    }

    if (_containsAny(prompt, const [
      'more casual',
      'make it more casual',
      'dress it down',
      'something more casual',
      'более повсед',
      'сделай проще',
      'күнделіктірек',
    ])) {
      return _AiIntent.followUpCasual;
    }

    if (_containsAny(prompt, const [
      'another option',
      'another look',
      'another one',
      'different option',
      'something else',
      'другой вариант',
      'ещё вариант',
      'тағы бір',
      'басқа нұсқа',
    ])) {
      return _AiIntent.followUpAlternative;
    }

    if (context.definitionTopic != null ||
        (_containsAny(prompt, const [
              'what is',
              'define',
              'what does',
              'что такое',
              'объясни',
              'что значит',
              'не деген',
              'түсіндір',
            ]) &&
            !_containsAny(prompt, const [
              'what should i wear',
              'outfit',
              'look',
              'что надеть',
              'образ',
              'не кием',
            ]))) {
      return _AiIntent.definition;
    }

    if (_containsAny(prompt, const [
      'what colors go together',
      'what colour goes with',
      'what color goes with',
      'color palette',
      'colour palette',
      'какие цвета',
      'цветовая палитра',
      'қай түстер',
      'түстер палитрасы',
    ])) {
      return _AiIntent.colorTheory;
    }

    if (_containsAny(prompt, const [
      'matches with',
      'goes with',
      'pair with',
      'wear with',
      'сочетается',
      'носить с',
      'үйлеседі',
      'немен киюге',
    ])) {
      return _AiIntent.pairing;
    }

    if (context.asksForShopping) {
      return _AiIntent.shopping;
    }

    if (_containsAny(prompt, const [
          'wear',
          'outfit',
          'look',
          'dress for',
          'надеть',
          'образ',
          'кию',
          'образ керек',
        ]) ||
        _extractWeather(prompt) != null ||
        _extractOccasion(prompt) != null) {
      return _AiIntent.outfit;
    }

    return _AiIntent.fallback;
  }

  String _outfitReply({
    required String userId,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
    required bool plus,
    required bool shoppingRequested,
  }) {
    if (items.isEmpty) {
      return _emptyWardrobeReply(
        weather: context.weather,
        occasion: context.occasion,
        profile: profile,
      );
    }

    final recommendation = _buildRecommendation(
      userId: userId,
      items: items,
      profile: profile,
      context: context,
      premium: premium,
      plus: plus,
    );

    if (recommendation == null) {
      return _fallbackReply(context: context, items: items);
    }

    final featuredItems = _selectedItems(items, recommendation);
    final sentences = <String>[
      _pickVariant([
        'I’d lean into a ${formatDailyOccasionLabel(context.occasion).toLowerCase()} look that still feels easy to wear.',
        'For this, I’d keep the outfit balanced and intentionally styled rather than overworked.',
        'I’d build the look around pieces that feel practical first, then polished on top of that.',
      ], context.seed),
      _piecesSentence(featuredItems),
      recommendation.explanation,
      if (premium) _profileSentence(profile, featuredItems),
      if (plus && (shoppingRequested || featuredItems.length < 4))
        _plusSentence(recommendation.marketplaceSuggestions),
    ];

    return _finalizeSentences(sentences);
  }

  String _alternativeReply({
    required String userId,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
    required bool plus,
  }) {
    if (items.isEmpty) {
      return _emptyWardrobeReply(
        weather: context.weather,
        occasion: context.occasion,
        profile: profile,
      );
    }

    final looks = _stylingEngineService.generateLooks(
      userId: userId,
      wardrobe: items,
      occasion: formatDailyOccasionLabel(context.occasion),
      weather: context.weather,
      premium: premium,
      profile: profile,
    );

    if (looks.isEmpty) {
      return _fallbackReply(context: context, items: items);
    }

    final alternative = looks.length == 1
        ? looks.first
        : looks[(context.seed % (looks.length - 1)) + 1];
    final featuredItems =
        items.where((item) => alternative.itemIds.contains(item.id)).toList();

    return _finalizeSentences([
      _pickVariant(const [
        'Here’s another option that still works for the same plan.',
        'A second route I like is a little different in mood but still very wearable.',
        'Another good version would keep the same function and shift the styling slightly.',
      ], context.seed),
      _piecesSentence(featuredItems),
      'This one still fits ${formatWeatherLabel(context.weather).toLowerCase()} weather and a ${formatDailyOccasionLabel(context.occasion).toLowerCase()} plan, but it changes the balance so the outfit feels a bit fresher.',
      if (premium) _profileSentence(profile, featuredItems),
      if (plus) _plusSentence(const <MarketplaceSuggestion>[]),
    ]);
  }

  String _styledAdjustmentReply({
    required String userId,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
    required bool plus,
    required _AdjustmentTone tone,
  }) {
    if (items.isEmpty) {
      return _emptyWardrobeReply(
        weather: context.weather,
        occasion: context.occasion,
        profile: profile,
      );
    }

    final recommendation = _buildRecommendation(
      userId: userId,
      items: items,
      profile: profile,
      context: context,
      premium: premium,
      plus: plus,
    );

    if (recommendation == null) {
      return _fallbackReply(context: context, items: items);
    }

    final featuredItems = _selectedItems(items, recommendation);
    final toneSentence = switch (tone) {
      _AdjustmentTone.formal => _pickVariant(const [
          'Yes, we can make it more formal without making it feel stiff.',
          'Definitely. I’d sharpen the look a little rather than pushing it all the way into businesswear.',
          'Absolutely. The best move is to clean up the silhouette and make the finish more intentional.',
        ], context.seed),
      _AdjustmentTone.casual => _pickVariant(const [
          'Yes, we can relax the outfit and keep it looking put together.',
          'Definitely. I’d make it more casual by softening the structure, not by making it sloppy.',
          'Absolutely. The easiest way is to keep the outfit lighter and a little less polished.',
        ], context.seed),
    };

    final finishingSentence = switch (tone) {
      _AdjustmentTone.formal =>
        'A cleaner shoe, a sharper outer layer, and simpler accessories will do most of the work here.',
      _AdjustmentTone.casual =>
        'Softer layers, easier shoes, and a lighter finish will keep it more relaxed.',
    };

    return _finalizeSentences([
      toneSentence,
      _piecesSentence(featuredItems),
      finishingSentence,
      recommendation.explanation,
      if (premium) _profileSentence(profile, featuredItems),
    ]);
  }

  String _shoesReply({
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
  }) {
    final shoes = _rankItems(
      items.where((item) => item.category == ClothingCategory.shoes).toList(),
      context: context,
      profile: profile,
    );

    if (shoes.isEmpty) {
      final generalShoeLine = switch (context.weather) {
        WeatherCondition.rainy =>
          'For shoes, I’d stay with something closed, easy to walk in, and a little more practical for wet ground.',
        WeatherCondition.cold =>
          'For shoes, I’d go with something closed and a bit more substantial so the outfit still feels grounded.',
        WeatherCondition.hot =>
          'For shoes, keep them light and comfortable so the look stays breathable.',
        _ =>
          'For shoes, I’d pick something clean and comfortable that doesn’t fight the rest of the outfit.',
      };

      return _finalizeSentences([
        generalShoeLine,
        'If you tell me whether you want the outfit to feel more polished or more relaxed, I can narrow the shoe direction down further.',
      ]);
    }

    final bestShoe = shoes.first;
    final weatherSentence = switch (context.weather) {
      WeatherCondition.rainy =>
        'That choice works especially well because it keeps the outfit practical for rain without making it feel heavy.',
      WeatherCondition.cold =>
        'It also suits cooler weather because the outfit still feels grounded and finished.',
      WeatherCondition.hot =>
        'It helps the outfit stay easy and comfortable without adding visual weight.',
      _ =>
        'It keeps the outfit balanced and stops the look from feeling unfinished.',
    };

    return _finalizeSentences([
      'For shoes, I’d go with ${bestShoe.name}.',
      weatherSentence,
      if (premium)
        'If you want a dressier version, I’d tighten up the rest of the palette and keep accessories more minimal around it.',
    ]);
  }

  String _pairingReply({
    required String prompt,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
  }) {
    if (prompt.contains('black pants') || prompt.contains('black trousers')) {
      final tops = _rankItems(
        items.where((item) => item.category == ClothingCategory.tops).toList(),
        context: context.copyWith(
          mentionedColors: const [
            'White',
            'Warm White',
            'Muted Blue',
            'Powder Blue',
            'Blush'
          ],
        ),
        profile: profile,
      );
      final topNames = tops
          .take(2)
          .map((item) => formatWardrobeItemName(item.name))
          .toList();
      final topSentence = topNames.isEmpty
          ? 'I’d pair black pants with a crisp white, warm white, muted blue, or soft blush top.'
          : 'I’d pair your black pants with ${_joinNatural(topNames)} because those pieces keep the contrast clean without looking harsh.';

      return _finalizeSentences([
        'Black pants are one of the easiest anchors in a wardrobe because they make the whole look feel cleaner straight away.',
        topSentence,
        _shoeFinishSentence(items, context),
        if (premium)
          'If you want the outfit to feel sharper, add one structured layer and keep the rest of the palette calm.',
      ]);
    }

    if (prompt.contains('white sneakers')) {
      final bottoms = _rankItems(
        items
            .where((item) => item.category == ClothingCategory.bottoms)
            .toList(),
        context: context,
        profile: profile,
      );
      final outerwear = _rankItems(
        items
            .where((item) => item.category == ClothingCategory.outerwear)
            .toList(),
        context: context,
        profile: profile,
      );
      final supportingPieces = <String>[
        if (bottoms.isNotEmpty) formatWardrobeItemName(bottoms.first.name),
        if (outerwear.isNotEmpty) formatWardrobeItemName(outerwear.first.name),
      ];

      return _finalizeSentences([
        'White sneakers work best when the rest of the outfit feels clean and a little intentional.',
        supportingPieces.isEmpty
            ? 'I’d pair them with straight trousers or denim and one neat top or light layer.'
            : 'I’d style them with ${_joinNatural(supportingPieces)} so the sneakers keep the look relaxed without making it feel unfinished.',
        'That mix gives you comfort first, but it still looks styled rather than thrown on.',
      ]);
    }

    return _colorReply(
      prompt: prompt,
      items: items,
      profile: profile,
      context: context,
      premium: premium,
    );
  }

  String _colorReply({
    required String prompt,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
  }) {
    final colors = context.mentionedColors;
    final preferredColors =
        profile?.preferredColors.take(3).toList() ?? const <String>[];

    if (colors.isNotEmpty) {
      final target = colors.first;
      final suggestedPair = _colorPairingFor(target);
      return _finalizeSentences([
        '$target works best when it has one softer partner and one cleaner neutral around it.',
        'I’d pair it with ${_joinNatural(suggestedPair)} so the look feels balanced instead of busy.',
        if (premium && preferredColors.isNotEmpty)
          'That also stays close to your usual palette, so the outfit will feel more consistent with the rest of your wardrobe.',
      ]);
    }

    final wardrobeColors =
        items.map((item) => item.color).toSet().take(4).toList();
    final paletteSource =
        wardrobeColors.isNotEmpty ? wardrobeColors : preferredColors;
    final paletteLine = paletteSource.isEmpty
        ? 'Soft navy, warm white, muted blue, camel, cool gray, and blush are all easy combinations because they feel polished without trying too hard.'
        : '${_joinNatural(paletteSource)} already give you a strong calm palette to work with.';

    return _finalizeSentences([
      'The easiest color combinations are usually one anchor shade, one lighter neutral, and one softer accent.',
      paletteLine,
      'That keeps the outfit feeling intentional, especially if you want something wearable for everyday life rather than overly styled.',
    ]);
  }

  String _definitionReply({
    required String? topic,
    required bool premium,
    required int seed,
  }) {
    switch (topic) {
      case 'smart casual':
        return _finalizeSentences([
          'Smart casual sits between relaxed and polished.',
          'Think clean trousers or denim, a refined top, and shoes that look intentional rather than sporty-for-the-gym.',
          premium
              ? 'The goal is to look put together without feeling overdressed, so structure matters more than formality.'
              : 'The goal is to look put together without seeming overdressed.',
        ]);
      case 'capsule wardrobe':
        return _finalizeSentences([
          'A capsule wardrobe is a smaller closet built from pieces that mix easily together.',
          'The idea is to have fewer items, but make each one more useful across work, casual plans, and weather changes.',
          'It usually works best when the colors stay consistent and the shapes are easy to layer.',
        ]);
      case 'business casual':
        return _finalizeSentences([
          'Business casual is a little more polished than smart casual and a little less formal than full office tailoring.',
          'Clean trousers, refined knitwear, shirts, simple dresses, and structured shoes usually fit well here.',
          'You still want comfort, but the overall finish should look deliberate and work-ready.',
        ]);
      default:
        return _finalizeSentences([
          _pickVariant(const [
            'I can explain style terms, but this one needs a little more context.',
            'I can help with that, although I’d want to know how you plan to use the term.',
            'I’m not fully sure which style term you mean here, but I can still guide you.',
          ], seed),
          'If you tell me the occasion or the kind of look you want, I can translate it into something much more practical.',
        ]);
    }
  }

  String _emptyWardrobeReply({
    required WeatherCondition weather,
    required DailyOccasion occasion,
    required UserProfile? profile,
  }) {
    final style = profile != null
        ? titleCase(profile.favoriteStyle.name)
        : 'smart casual';
    final weatherLine = switch (weather) {
      WeatherCondition.rainy =>
        'For the weather, I’d stay with a light layer, practical shoes, and pieces that can handle a damp commute.',
      WeatherCondition.hot =>
        'For the weather, focus on breathable fabrics, lighter colors, and as few layers as possible.',
      WeatherCondition.cold =>
        'For the weather, start with warmth first, then add one structured outer layer and grounded shoes.',
      _ =>
        'For the weather, keep the base simple and add just enough structure to make the outfit feel finished.',
    };

    return _finalizeSentences([
      'You can still build a strong ${formatDailyOccasionLabel(occasion).toLowerCase()} outfit even before your wardrobe is uploaded.',
      weatherLine,
      'Once you add a few pieces, I can make the advice much more personal and keep it closer to your $style preferences.',
    ]);
  }

  String _fallbackReply({
    required _ResolvedChatContext context,
    required List<WardrobeItem> items,
  }) {
    final categoryHint = switch (context.mentionedCategory) {
      ClothingCategory.tops => 'your top',
      ClothingCategory.bottoms => 'your pants or trousers',
      ClothingCategory.outerwear => 'your outer layer',
      ClothingCategory.dresses => 'your dress',
      ClothingCategory.shoes => 'your shoes',
      ClothingCategory.bags => 'your bag',
      ClothingCategory.accessories => 'your accessories',
      null => 'one piece you want to wear',
    };
    final wardrobeLine = items.isEmpty
        ? 'Even without wardrobe items, I can still help you choose colors, build outfits, and dress for the weather.'
        : 'I can use your wardrobe, the weather, and your daily plans to make the advice much more specific.';

    return _finalizeSentences([
      context.isFollowUp
          ? 'I’m not fully sure which part of the last look you want to change, but I can still refine it with you.'
          : 'I’m not fully sure what direction you want yet, but I can help with outfit ideas, colors, weather dressing, or styling for a specific plan.',
      wardrobeLine,
      'Try telling me the occasion, the weather, or how you want to style $categoryHint, and I’ll build from there.',
    ]);
  }

  SmartOutfitRecommendation? _buildRecommendation({
    required String userId,
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
    required bool premium,
    required bool plus,
  }) {
    return _stylingEngineService.generateSmartRecommendation(
      userId: userId,
      wardrobe: items,
      occasion: context.occasion,
      weather: context.weather,
      premium: premium,
      plus: plus,
      profile: profile,
    );
  }

  List<WardrobeItem> _selectedItems(
    List<WardrobeItem> items,
    SmartOutfitRecommendation recommendation,
  ) {
    final selected = items
        .where((item) => recommendation.look.itemIds.contains(item.id))
        .toList();
    selected.sort((a, b) => recommendation.look.itemIds.indexOf(a.id).compareTo(
          recommendation.look.itemIds.indexOf(b.id),
        ));
    return selected;
  }

  List<WardrobeItem> _rankItems(
    List<WardrobeItem> items, {
    required _ResolvedChatContext context,
    required UserProfile? profile,
  }) {
    final preferredColors = {
      ...?profile?.preferredColors,
      ...context.mentionedColors,
    };
    final preferredStyle = profile?.favoriteStyle;
    final ranked = [...items];
    ranked.sort((a, b) {
      final scoreB = _itemScore(
        b,
        preferredColors: preferredColors,
        preferredStyle: preferredStyle,
        weather: context.weather,
      );
      final scoreA = _itemScore(
        a,
        preferredColors: preferredColors,
        preferredStyle: preferredStyle,
        weather: context.weather,
      );
      return scoreB - scoreA;
    });
    return ranked;
  }

  int _itemScore(
    WardrobeItem item, {
    required Set<String> preferredColors,
    required StyleTag? preferredStyle,
    required WeatherCondition weather,
  }) {
    var score = item.isFavorite ? 4 : 0;
    if (preferredColors.contains(item.color)) {
      score += 3;
    }
    if (preferredStyle != null && item.style == preferredStyle) {
      score += 2;
    }
    if (weather == WeatherCondition.rainy &&
        item.category == ClothingCategory.outerwear) {
      score += 2;
    }
    if (weather == WeatherCondition.hot &&
        (item.category == ClothingCategory.dresses ||
            item.category == ClothingCategory.tops)) {
      score += 1;
    }
    if (weather == WeatherCondition.cold &&
        item.category == ClothingCategory.outerwear) {
      score += 2;
    }
    return score;
  }

  String _piecesSentence(List<WardrobeItem> items) {
    final featured =
        items.take(4).map((item) => formatWardrobeItemName(item.name)).toList();
    if (featured.isEmpty) {
      return 'I’d start with one clean base, then add a layer or accessory so the outfit feels finished.';
    }
    return 'I’d build it around ${_joinNatural(featured)} because those pieces already give you a cohesive silhouette.';
  }

  String _profileSentence(UserProfile? profile, List<WardrobeItem> items) {
    final styleText = profile == null
        ? 'overall mood'
        : titleCase(profile.favoriteStyle.name);
    final colors = items.map((item) => item.color).toSet().take(2).toList();
    if (colors.isEmpty) {
      return 'I’d also keep the palette calm so the styling feels more intentional.';
    }
    return 'It also stays close to a $styleText direction, with ${_joinNatural(colors)} helping the outfit feel balanced.';
  }

  String _plusSentence(List<MarketplaceSuggestion> suggestions) {
    final suggestion = suggestions.isEmpty ? null : suggestions.first;
    if (suggestion == null) {
      return 'If you want, I can also mix in a shoppable partner piece to push the look a little further.';
    }
    return 'If you want a wardrobe-plus-shopping version, ${suggestion.title} from ${suggestion.brand} would slot in nicely without taking over the whole outfit.';
  }

  String _shoeFinishSentence(
      List<WardrobeItem> items, _ResolvedChatContext context) {
    final shoes =
        items.where((item) => item.category == ClothingCategory.shoes).toList();
    if (shoes.isEmpty) {
      return context.weather == WeatherCondition.rainy
          ? 'Finish with closed shoes so the look stays practical in wet weather.'
          : 'Finish with clean, simple shoes so the outfit still feels intentional.';
    }
    return 'Finish with ${formatWardrobeItemName(shoes.first.name)} or another clean shoe so the outfit keeps that easy, balanced feel.';
  }

  String _localizedDefinitionReply(String? topic) {
    switch (topic) {
      case 'smart casual':
        return localizedText(
          en: '',
          ru: 'Смарт-кэжуал находится между повседневностью и более собранным стилем. Обычно это чистые брюки или джинсы, аккуратный верх и обувь, которая выглядит продуманно, а не слишком спортивно.',
          kk: 'Смарт-кэжуал күнделікті стиль мен жинақы көріністің ортасындағы бағыт. Әдетте оған таза шалбар не джинсы, ұқыпты үстіңгі бөлік және ойластырылған аяқ киім кіреді.',
        );
      case 'capsule wardrobe':
        return localizedText(
          en: '',
          ru: 'Капсульный гардероб - это небольшой набор вещей, которые легко сочетаются между собой. Идея в том, чтобы иметь меньше вещей, но использовать каждую из них чаще и эффективнее.',
          kk: 'Капсулалық гардероб - бір-бірімен оңай үйлесетін аздау, бірақ тиімді заттар жиынтығы. Мақсат - зат аз болса да, әрқайсысын жиі қолдану.',
        );
      case 'business casual':
        return localizedText(
          en: '',
          ru: 'Бизнес-кэжуал чуть строже, чем смарт-кэжуал, но мягче, чем полностью формальный офисный стиль. Здесь хорошо работают чистые брюки, рубашки, трикотаж и структурная обувь.',
          kk: 'Бизнес-кэжуал смарт-кэжуалдан сәл ресмилеу, бірақ толық формалды офистік стильден жеңілірек. Мұнда таза шалбар, жейде, трикотаж және құрылымды аяқ киім жақсы жарасады.',
        );
      default:
        return localizedText(
          en: '',
          ru: 'Я могу объяснить стильный термин, если вы подскажете, что именно хотите разобрать. Например: смарт-кэжуал, бизнес-кэжуал или капсульный гардероб.',
          kk: 'Стиль терминін түсіндіріп бере аламын, тек қай ұғымды ашу керек екенін жазыңыз. Мысалы: смарт-кэжуал, бизнес-кэжуал немесе капсулалық гардероб.',
        );
    }
  }

  String _localizedColorReply({
    required List<WardrobeItem> items,
    required UserProfile? profile,
    required _ResolvedChatContext context,
  }) {
    final colors = context.mentionedColors;
    if (colors.isNotEmpty) {
      final baseColor = formatColorLabel(colors.first);
      final pairings =
          _colorPairingFor(colors.first).map(formatColorLabel).toList();
      return localizedText(
        en: '',
        ru: '$baseColor лучше всего раскрывается рядом с более мягким оттенком и спокойным нейтралом. Я бы сочетал его с ${_joinNatural(pairings)}.',
        kk: '$baseColor түсі қасында жұмсағырақ реңк пен тыныш нейтрал болғанда жақсы ашылады. Мен оны ${_joinNatural(pairings)} түстерімен үйлестірер едім.',
      );
    }

    final palette =
        (profile?.preferredColors ?? items.map((item) => item.color).toList())
            .map(formatColorLabel)
            .take(4)
            .toList();
    final joined = palette.isEmpty
        ? localizedText(
            en: 'soft navy, warm white, muted blue, and camel',
            ru: 'мягкий тёмно-синий, тёплый белый, приглушённый синий и кэмел',
            kk: 'жұмсақ қою көк, жылы ақ, бәсең көк және кэмел',
          )
        : _joinNatural(palette);

    return localizedText(
      en: '',
      ru: 'Самый простой способ собрать красивую палитру - выбрать один базовый оттенок, один светлый нейтрал и один мягкий акцент. В вашем случае хорошо работают $joined.',
      kk: 'Әдемі палитра құрудың ең оңай жолы - бір базалық түс, бір ашық нейтрал және бір жұмсақ акцент таңдау. Сізге $joined жақсы жұмыс істейді.',
    );
  }

  String _localizedShoesReply({
    required List<WardrobeItem> items,
    required _ResolvedChatContext context,
  }) {
    final shoes =
        items.where((item) => item.category == ClothingCategory.shoes).toList();
    if (shoes.isEmpty) {
      return localizedText(
        en: '',
        ru: 'Я бы выбрал закрытую и удобную обувь, которая не спорит с остальным образом. Если скажете, хотите ли вы более собранный или более расслабленный вариант, я уточню направление.',
        kk: 'Мен образбен таласпайтын, жабық әрі ыңғайлы аяқ киім таңдар едім. Егер жинақырақ па, әлде еркіндеу ме екенін айтсаңыз, нақтырақ ұсынамын.',
      );
    }

    return localizedText(
      en: '',
      ru: 'По обуви я бы поставил на ${formatWardrobeItemName(shoes.first.name)}. Она поддержит образ и сохранит нужный баланс по погоде и настроению.',
      kk: 'Аяқ киім ретінде мен ${formatWardrobeItemName(shoes.first.name)} нұсқасын таңдар едім. Ол образды қолдап, ауа райы мен көңіл күйге сай тепе-теңдікті сақтайды.',
    );
  }

  String _localizedPiecesSentence(List<WardrobeItem> items) {
    final featured =
        items.take(4).map((item) => formatWardrobeItemName(item.name)).toList();
    if (featured.isEmpty) {
      return localizedText(
        en: '',
        ru: 'Я бы начал с чистой базы, а затем добавил слой или аксессуар, чтобы образ выглядел завершённым.',
        kk: 'Мен алдымен таза базадан бастап, кейін образ толық сезілуі үшін қабат не аксессуар қосар едім.',
      );
    }

    return localizedText(
      en: '',
      ru: 'Я бы построил образ вокруг ${_joinNatural(featured)}, потому что эти вещи уже дают цельный силуэт.',
      kk: 'Мен образды ${_joinNatural(featured)} айналасында құрар едім, өйткені бұл заттар өздері-ақ жинақы силуэт береді.',
    );
  }

  String _localizedProfileSentence(
      UserProfile? profile, List<WardrobeItem> items) {
    if (profile == null) {
      return '';
    }
    final colors = items
        .map((item) => formatColorLabel(item.color))
        .toSet()
        .take(2)
        .toList();
    return localizedText(
      en: '',
      ru: 'Это также остаётся близко к вашему любимому направлению ${formatStyleTagLabel(profile.favoriteStyle).toLowerCase()}${colors.isEmpty ? '' : ' и поддерживается оттенками ${_joinNatural(colors)}'}.',
      kk: 'Бұл сонымен қатар сіздің ${formatStyleTagLabel(profile.favoriteStyle).toLowerCase()} бағытыңызға жақын${colors.isEmpty ? '' : ' және ${_joinNatural(colors)} реңктерімен толыққан'} .',
    ).replaceAll(' .', '.');
  }

  String _localizedPlusSentence(List<MarketplaceSuggestion> suggestions) {
    final suggestion = suggestions.isEmpty ? null : suggestions.first;
    if (suggestion == null) {
      return localizedText(
        en: '',
        ru: 'Если захотите, я могу также предложить покупаемую вещь от партнёров, чтобы усилить образ.',
        kk: 'Қаласаңыз, образды күшейту үшін серіктес дүкеннен қосымша зат та ұсына аламын.',
      );
    }

    return localizedText(
      en: '',
      ru: 'Если смотреть на вариант с покупкой, ${suggestion.title} от ${suggestion.brand} хорошо встроится в этот образ.',
      kk: 'Сатып алуға болатын нұсқа ретінде ${suggestion.brand} брендінің ${suggestion.title} бұл образға жақсы үйлеседі.',
    );
  }

  String _localizedEmptyWardrobeReply({
    required WeatherCondition weather,
    required DailyOccasion occasion,
    required UserProfile? profile,
  }) {
    final style = profile == null
        ? localizedText(
            en: 'smart casual', ru: 'смарт-кэжуал', kk: 'смарт-кэжуал')
        : formatStyleTagLabel(profile.favoriteStyle).toLowerCase();
    return localizedText(
      en: '',
      ru: 'Даже без загруженного гардероба можно собрать хороший образ для ${formatDailyOccasionLabel(occasion).toLowerCase()}. Начните с простого базового комплекта, ориентируйтесь на погоду "${formatWeatherLabel(weather).toLowerCase()}", а после добавления вещей я смогу делать советы гораздо точнее и ближе к вашему стилю $style.',
      kk: 'Гардероб әлі жүктелмесе де, ${formatDailyOccasionLabel(occasion).toLowerCase()} жоспарына жақсы образ құруға болады. Алдымен қарапайым базадан шығып, "${formatWeatherLabel(weather).toLowerCase()}" ауа райына сүйеніңіз, ал заттар қосылғаннан кейін кеңестерді $style бағытыңызға анағұрлым дәл қыламын.',
    );
  }

  String _localizedFallbackReply({
    required _ResolvedChatContext context,
    required List<WardrobeItem> items,
  }) {
    final wardrobeLine = items.isEmpty
        ? localizedText(
            en: '',
            ru: 'Даже без вещей в гардеробе я могу помочь с палитрой, погодой и общим направлением образа.',
            kk: 'Гардеробта заттар болмаса да, палитра, ауа райы және образ бағыты бойынша көмектесе аламын.',
          )
        : localizedText(
            en: '',
            ru: 'Я могу использовать ваш гардероб, погоду и планы на день, чтобы дать более точную рекомендацию.',
            kk: 'Нақтырақ кеңес беру үшін мен сіздің гардеробыңызды, ауа райын және күн жоспарын пайдалана аламын.',
          );

    return localizedText(
      en: '',
      ru: 'Пока не до конца понимаю, какой именно результат вы хотите получить. $wardrobeLine Напишите повод, погоду или вещь, вокруг которой хотите собрать образ.',
      kk: 'Қазір сізге нақты қандай нәтиже керек екенін толық түсінбей тұрмын. $wardrobeLine Жоспарды, ауа райын немесе образды қай заттың айналасында құрғыңыз келетінін жазыңыз.',
    );
  }

  WeatherCondition? _extractWeather(String query) {
    if (_containsAny(query, const [
      'rain',
      'rainy',
      'wet',
      'storm',
      'дожд',
      'ливень',
      'жаңбыр',
    ])) {
      return WeatherCondition.rainy;
    }
    if (_containsAny(query, const [
      'hot',
      'summer',
      'warm',
      'жар',
      'ыстық',
      'аптап',
    ])) {
      return WeatherCondition.hot;
    }
    if (_containsAny(query, const [
      'cold',
      'winter',
      'chilly',
      'freezing',
      'холод',
      'мороз',
      'суық',
      'аяз',
    ])) {
      return WeatherCondition.cold;
    }
    if (_containsAny(query, const [
      'wind',
      'windy',
      'breezy',
      'ветер',
      'ветрено',
      'жел',
      'желді',
    ])) {
      return WeatherCondition.windy;
    }
    if (_containsAny(query, const [
      'sun',
      'sunny',
      'bright',
      'солн',
      'ясно',
      'күн',
      'ашық',
    ])) {
      return WeatherCondition.sunny;
    }
    if (_containsAny(query, const [
      'cloud',
      'cloudy',
      'overcast',
      'cool',
      'облач',
      'пасмур',
      'бұлт',
      'салқын',
    ])) {
      return WeatherCondition.cloudy;
    }
    return null;
  }

  DailyOccasion? _extractOccasion(String query) {
    if (_containsAny(query, const [
      'college',
      'class',
      'campus',
      'учеб',
      'универ',
      'оқу',
      'сабақ',
    ])) {
      return DailyOccasion.college;
    }
    if (_containsAny(query, const [
      'meeting',
      'presentation',
      'встреч',
      'презент',
      'кездес',
    ])) {
      return DailyOccasion.meeting;
    }
    if (_containsAny(query, const [
      'office',
      'work',
      'офис',
      'работ',
      'жұмыс',
    ])) {
      return DailyOccasion.work;
    }
    if (_containsAny(query, const [
      'date',
      'romantic',
      'свидан',
      'романт',
      'кездесу',
    ])) {
      return DailyOccasion.date;
    }
    if (_containsAny(query, const ['dinner', 'ужин', 'кешкі ас'])) {
      return DailyOccasion.dinner;
    }
    if (_containsAny(query, const ['party', 'вечерин', 'кеш'])) {
      return DailyOccasion.party;
    }
    if (_containsAny(query, const [
      'travel',
      'flight',
      'airport',
      'поезд',
      'самолет',
      'сапар',
      'ұшу',
    ])) {
      return DailyOccasion.travel;
    }
    if (_containsAny(query, const ['shopping', 'шоп', 'дүкен'])) {
      return DailyOccasion.shopping;
    }
    if (_containsAny(query, const ['gym', 'workout', 'зал', 'жаттығу'])) {
      return DailyOccasion.gym;
    }
    if (_containsAny(query, const [
      'event',
      'wedding',
      'событ',
      'мероприят',
      'іс-шара',
      'той',
    ])) {
      return DailyOccasion.event;
    }
    if (_containsAny(query, const [
      'home',
      'relaxed day',
      'staying in',
      'дом',
      'үй',
    ])) {
      return DailyOccasion.home;
    }
    if (_containsAny(query, const [
      'casual walk',
      'walk',
      'weekend',
      'casual',
      'прогул',
      'выходн',
      'серуен',
      'демалыс',
    ])) {
      return DailyOccasion.casualWalk;
    }
    return null;
  }

  ClothingCategory? _extractCategory(String query) {
    if (_containsAny(query, const [
      'top',
      'shirt',
      'tee',
      'blouse',
      'топ',
      'рубаш',
      'блуз',
    ])) {
      return ClothingCategory.tops;
    }
    if (_containsAny(query, const [
      'pants',
      'trousers',
      'jeans',
      'bottom',
      'брюк',
      'джинс',
      'шалбар',
      'джинсы',
    ])) {
      return ClothingCategory.bottoms;
    }
    if (_containsAny(query, const [
      'jacket',
      'blazer',
      'coat',
      'outerwear',
      'курт',
      'пальто',
      'пидж',
      'күрте',
    ])) {
      return ClothingCategory.outerwear;
    }
    if (_containsAny(query, const ['dress', 'плать', 'көйлек'])) {
      return ClothingCategory.dresses;
    }
    if (_containsAny(query, const [
      'shoe',
      'sneaker',
      'boot',
      'обув',
      'кроссов',
      'аяқ киім',
    ])) {
      return ClothingCategory.shoes;
    }
    if (_containsAny(query, const ['bag', 'сумк', 'сөмке'])) {
      return ClothingCategory.bags;
    }
    if (_containsAny(query, const [
      'accessory',
      'necklace',
      'sunglasses',
      'jewelry',
      'аксесс',
      'ожерел',
      'көзілдірік',
    ])) {
      return ClothingCategory.accessories;
    }
    return null;
  }

  String? _extractDefinitionTopic(String query) {
    if (query.contains('smart casual') || query.contains('смарт')) {
      return 'smart casual';
    }
    if (query.contains('capsule wardrobe') || query.contains('капсуль')) {
      return 'capsule wardrobe';
    }
    if (query.contains('business casual') || query.contains('business')) {
      return 'business casual';
    }
    return null;
  }

  List<String> _extractColors(String query) {
    const colorAliases = <String, String>{
      'black': 'Black',
      'white': 'White',
      'warm white': 'Warm White',
      'navy': 'Soft Navy',
      'soft navy': 'Soft Navy',
      'muted blue': 'Muted Blue',
      'blue': 'Muted Blue',
      'powder blue': 'Powder Blue',
      'cool gray': 'Cool Gray',
      'grey': 'Cool Gray',
      'gray': 'Cool Gray',
      'lavender': 'Lavender Gray',
      'camel': 'Camel',
      'olive': 'Olive',
      'blush': 'Blush',
      'denim': 'Denim',
      'чёрный': 'Black',
      'черный': 'Black',
      'белый': 'White',
      'синий': 'Muted Blue',
      'голубой': 'Powder Blue',
      'серый': 'Cool Gray',
      'бежевый': 'Camel',
      'оливковый': 'Olive',
      'розовый': 'Blush',
      'деним': 'Denim',
      'қара': 'Black',
      'ақ': 'White',
      'көк': 'Muted Blue',
      'сұр': 'Cool Gray',
      'құм': 'Camel',
      'зәйтүн': 'Olive',
      'қызғылт': 'Blush',
    };

    final matches = <String>[];
    for (final entry in colorAliases.entries) {
      if (query.contains(entry.key) && !matches.contains(entry.value)) {
        matches.add(entry.value);
      }
    }
    return matches;
  }

  DailyOccasion _moreFormalOccasion(DailyOccasion occasion) {
    switch (occasion) {
      case DailyOccasion.casualWalk:
      case DailyOccasion.shopping:
      case DailyOccasion.home:
        return DailyOccasion.work;
      case DailyOccasion.college:
        return DailyOccasion.meeting;
      case DailyOccasion.travel:
        return DailyOccasion.work;
      default:
        return occasion;
    }
  }

  DailyOccasion _moreCasualOccasion(DailyOccasion occasion) {
    switch (occasion) {
      case DailyOccasion.meeting:
      case DailyOccasion.work:
      case DailyOccasion.event:
      case DailyOccasion.dinner:
        return DailyOccasion.casualWalk;
      case DailyOccasion.date:
        return DailyOccasion.shopping;
      default:
        return occasion;
    }
  }

  List<String> _colorPairingFor(String color) {
    switch (color) {
      case 'Black':
        return const ['Warm White', 'Camel', 'Powder Blue'];
      case 'Soft Navy':
        return const ['Warm White', 'Cool Gray', 'Blush'];
      case 'Muted Blue':
        return const ['Warm White', 'Camel', 'Denim'];
      case 'Camel':
        return const ['Soft Navy', 'White', 'Olive'];
      default:
        return const ['Warm White', 'Cool Gray', 'Soft Navy'];
    }
  }

  String _recentContextText(List<ChatMessage> history) {
    return history.reversed
        .take(6)
        .map((message) => message.text.toLowerCase())
        .join(' ');
  }

  String _pickVariant(List<String> options, int seed) {
    return options[seed % options.length];
  }

  bool _containsAny(String text, List<String> values) {
    for (final value in values) {
      if (text.contains(value)) {
        return true;
      }
    }
    return false;
  }

  String _joinNatural(List<String> values) {
    if (values.isEmpty) {
      return '';
    }
    if (values.length == 1) {
      return values.first;
    }
    if (values.length == 2) {
      return localizedText(
        en: '${values.first} and ${values.last}',
        ru: '${values.first} и ${values.last}',
        kk: '${values.first} және ${values.last}',
      );
    }
    final head = values.sublist(0, values.length - 1).join(', ');
    return localizedText(
      en: '$head, and ${values.last}',
      ru: '$head и ${values.last}',
      kk: '$head және ${values.last}',
    );
  }

  String _finalizeSentences(List<String> sentences) {
    return sentences
        .where((sentence) => sentence.trim().isNotEmpty)
        .take(5)
        .map((sentence) => sentence.trim())
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

enum _AiIntent {
  greeting,
  gratitude,
  outfit,
  pairing,
  colorTheory,
  definition,
  followUpShoes,
  followUpFormal,
  followUpCasual,
  followUpAlternative,
  shopping,
  fallback,
}

enum _AdjustmentTone { formal, casual }

class _ResolvedChatContext {
  const _ResolvedChatContext({
    required this.weather,
    required this.occasion,
    required this.mentionedColors,
    required this.mentionedCategory,
    required this.definitionTopic,
    required this.asksForShopping,
    required this.asksForShoes,
    required this.isFollowUp,
    required this.seed,
  });

  final WeatherCondition weather;
  final DailyOccasion occasion;
  final List<String> mentionedColors;
  final ClothingCategory? mentionedCategory;
  final String? definitionTopic;
  final bool asksForShopping;
  final bool asksForShoes;
  final bool isFollowUp;
  final int seed;

  _ResolvedChatContext copyWith({
    WeatherCondition? weather,
    DailyOccasion? occasion,
    List<String>? mentionedColors,
    ClothingCategory? mentionedCategory,
    String? definitionTopic,
    bool? asksForShopping,
    bool? asksForShoes,
    bool? isFollowUp,
    int? seed,
  }) {
    return _ResolvedChatContext(
      weather: weather ?? this.weather,
      occasion: occasion ?? this.occasion,
      mentionedColors: mentionedColors ?? this.mentionedColors,
      mentionedCategory: mentionedCategory ?? this.mentionedCategory,
      definitionTopic: definitionTopic ?? this.definitionTopic,
      asksForShopping: asksForShopping ?? this.asksForShopping,
      asksForShoes: asksForShoes ?? this.asksForShoes,
      isFollowUp: isFollowUp ?? this.isFollowUp,
      seed: seed ?? this.seed,
    );
  }
}
