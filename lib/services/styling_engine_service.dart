import 'package:uuid/uuid.dart';

import '../core/app_assets.dart';
import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../models/marketplace_suggestion.dart';
import '../models/outfit_look.dart';
import '../models/smart_outfit_recommendation.dart';
import '../models/user_profile.dart';
import '../models/wardrobe_item.dart';

class StylingEngineService {
  static const _uuid = Uuid();

  List<OutfitLook> generateLooks({
    required String userId,
    required List<WardrobeItem> wardrobe,
    required String occasion,
    required WeatherCondition weather,
    required bool premium,
    DailyOccasion? occasionType,
    UserProfile? profile,
  }) {
    if (wardrobe.isEmpty) {
      return [];
    }

    final smartOccasion = occasionType ?? _occasionFromLabel(occasion);
    final occasionLabel =
        occasion.isEmpty ? formatDailyOccasionLabel(smartOccasion) : occasion;
    final recipes = <_LookRecipe>[
      _LookRecipe(
        title: _generatedRecipeTitle(index: 0, occasion: smartOccasion),
        vibe: _generatedRecipeVibe(
          index: 0,
          occasion: smartOccasion,
          premium: premium,
        ),
        useDress: _occasionPrefersDress(smartOccasion) &&
            _hasCategory(wardrobe, ClothingCategory.dresses),
        preferLayers: _needsLayer(weather, smartOccasion),
      ),
      _LookRecipe(
        title: _generatedRecipeTitle(index: 1, occasion: smartOccasion),
        vibe: _generatedRecipeVibe(
          index: 1,
          occasion: smartOccasion,
          premium: premium,
        ),
        useDress: smartOccasion == DailyOccasion.date &&
            _hasCategory(wardrobe, ClothingCategory.dresses),
        preferLayers: weather != WeatherCondition.hot,
      ),
      _LookRecipe(
        title: _generatedRecipeTitle(index: 2, occasion: smartOccasion),
        vibe: _generatedRecipeVibe(
          index: 2,
          occasion: smartOccasion,
          premium: premium,
        ),
        useDress: weather == WeatherCondition.hot &&
            _hasCategory(wardrobe, ClothingCategory.dresses),
        preferLayers: true,
      ),
    ];

    return [
      for (var index = 0; index < recipes.length; index++)
        _buildLook(
          userId: userId,
          wardrobe: wardrobe,
          profile: profile,
          occasionLabel: occasionLabel,
          occasion: smartOccasion,
          recipe: recipes[index],
          weather: weather,
          offset: index,
          premium: premium,
        ),
    ].whereType<OutfitLook>().toList();
  }

  OutfitLook? buildWeatherLook({
    required String userId,
    required List<WardrobeItem> wardrobe,
    required WeatherCondition weather,
    required bool premium,
    UserProfile? profile,
  }) {
    final looks = generateLooks(
      userId: userId,
      wardrobe: wardrobe,
      occasion: formatDailyOccasionLabel(DailyOccasion.casualWalk),
      weather: weather,
      premium: premium,
      occasionType: DailyOccasion.casualWalk,
      profile: profile,
    );

    return looks.isEmpty ? null : looks.first;
  }

  SmartOutfitRecommendation? generateSmartRecommendation({
    required String userId,
    required List<WardrobeItem> wardrobe,
    required DailyOccasion occasion,
    required WeatherCondition weather,
    required bool premium,
    required bool plus,
    UserProfile? profile,
    DateTime? date,
  }) {
    if (wardrobe.isEmpty) {
      return null;
    }

    final look = _buildLook(
      userId: userId,
      wardrobe: wardrobe,
      profile: profile,
      occasionLabel: formatDailyOccasionLabel(occasion),
      occasion: occasion,
      recipe: _LookRecipe(
        title: _smartTitleForOccasion(occasion),
        vibe: _vibeForOccasion(occasion, premium),
        useDress: _occasionPrefersDress(occasion) &&
            _hasCategory(wardrobe, ClothingCategory.dresses),
        preferLayers: _needsLayer(weather, occasion),
      ),
      weather: weather,
      offset: 0,
      premium: premium,
    );

    if (look == null) {
      return null;
    }

    final itemCount = look.itemIds.length;
    final limitedWardrobe =
        itemCount < 3 || !_hasCategory(wardrobe, ClothingCategory.shoes);
    final explanation = _buildNaturalExplanation(
      weather: weather,
      occasion: occasion,
      look: look,
      limitedWardrobe: limitedWardrobe,
      premium: premium,
      profile: profile,
    );

    final marketSuggestions = plus
        ? _buildMarketplaceSuggestions(
            occasion: occasion,
            weather: weather,
            limitedWardrobe: limitedWardrobe,
          )
        : const <MarketplaceSuggestion>[];

    return SmartOutfitRecommendation(
      look: look.copyWith(notes: explanation, isPremium: premium || plus),
      explanation: explanation,
      date: normalizeDate(date ?? DateTime.now()),
      occasion: occasion,
      weather: weather,
      marketplaceSuggestions: marketSuggestions,
    );
  }

  OutfitLook? _buildLook({
    required String userId,
    required List<WardrobeItem> wardrobe,
    required String occasionLabel,
    required DailyOccasion occasion,
    required WeatherCondition weather,
    required _LookRecipe recipe,
    required int offset,
    required bool premium,
    UserProfile? profile,
  }) {
    final preferredColors =
        profile?.preferredColors.toSet() ?? const <String>{};
    final preferredStyle = profile?.favoriteStyle;

    final dress = recipe.useDress
        ? _pickItem(
            wardrobe,
            category: ClothingCategory.dresses,
            offset: offset,
            preferredColors: preferredColors,
            preferredStyle: preferredStyle,
            weather: weather,
            occasion: occasion,
          )
        : null;

    final top = dress == null
        ? _pickItem(
            wardrobe,
            category: ClothingCategory.tops,
            offset: offset,
            preferredColors: preferredColors,
            preferredStyle: preferredStyle,
            weather: weather,
            occasion: occasion,
          )
        : null;

    final bottom = dress == null
        ? _pickItem(
            wardrobe,
            category: ClothingCategory.bottoms,
            offset: offset + 1,
            preferredColors: preferredColors,
            preferredStyle: preferredStyle,
            weather: weather,
            occasion: occasion,
          )
        : null;

    final outerwear = recipe.preferLayers
        ? _pickItem(
            wardrobe,
            category: ClothingCategory.outerwear,
            offset: offset,
            preferredColors: preferredColors,
            preferredStyle: preferredStyle,
            weather: weather,
            occasion: occasion,
          )
        : null;

    final shoes = _pickItem(
      wardrobe,
      category: ClothingCategory.shoes,
      offset: offset,
      preferredColors: preferredColors,
      preferredStyle: preferredStyle,
      weather: weather,
      occasion: occasion,
    );

    final bag = _pickItem(
      wardrobe,
      category: ClothingCategory.bags,
      offset: offset,
      preferredColors: preferredColors,
      preferredStyle: preferredStyle,
      weather: weather,
      occasion: occasion,
    );

    final accessory = premium ||
            occasion == DailyOccasion.date ||
            occasion == DailyOccasion.party
        ? _pickItem(
            wardrobe,
            category: ClothingCategory.accessories,
            offset: offset,
            preferredColors: preferredColors,
            preferredStyle: preferredStyle,
            weather: weather,
            occasion: occasion,
          )
        : null;

    final items = [
      if (dress != null) dress,
      if (top != null) top,
      if (bottom != null) bottom,
      if (outerwear != null) outerwear,
      if (shoes != null) shoes,
      if (bag != null) bag,
      if (accessory != null) accessory,
    ];

    if (items.length < 2) {
      return null;
    }

    final tags = <String>{
      formatDailyOccasionLabel(occasion).toLowerCase(),
      formatWeatherLabel(weather).toLowerCase(),
      if (weather == WeatherCondition.rainy) 'rainy day',
      if (weather == WeatherCondition.hot) 'hot weather',
      if (weather == WeatherCondition.cold) 'cozy',
      if (occasion == DailyOccasion.meeting || occasion == DailyOccasion.work)
        'smart casual',
    }.toList();

    final colors = items
        .map((item) => formatColorLabel(item.color))
        .toSet()
        .take(3)
        .join(', ');
    final notes = localizedText(
      en: 'Recommended because the mix of $colors keeps the outfit balanced for $occasionLabel and ${formatWeatherLabel(weather).toLowerCase()} weather.',
      ru: 'Этот образ рекомендован, потому что сочетание оттенков $colors хорошо поддерживает сценарий "$occasionLabel" и подходит для погоды: ${formatWeatherLabel(weather).toLowerCase()}.',
      kk: 'Бұл образ ұсынылады, себебі $colors реңктерінің үйлесімі "$occasionLabel" жоспарына және ${formatWeatherLabel(weather).toLowerCase()} ауа райына жақсы сай келеді.',
    );

    return OutfitLook(
      id: _uuid.v4(),
      userId: userId,
      title: recipe.title,
      itemIds: items.map((item) => item.id).toList(),
      occasion: occasionLabel,
      style: preferredStyle != null
          ? formatStyleTagLabel(preferredStyle)
          : recipe.vibe,
      notes: notes,
      tags: tags,
      weatherContext: formatWeatherLabel(weather),
      createdAt: DateTime.now(),
      isGenerated: true,
      isPremium: premium,
    );
  }

  WardrobeItem? _pickItem(
    List<WardrobeItem> wardrobe, {
    required ClothingCategory category,
    required int offset,
    required Set<String> preferredColors,
    required WeatherCondition weather,
    required DailyOccasion occasion,
    StyleTag? preferredStyle,
  }) {
    final matches =
        wardrobe.where((item) => item.category == category).toList();
    if (matches.isEmpty) {
      return null;
    }

    matches.sort((a, b) =>
        _scoreItem(
          b,
          preferredColors: preferredColors,
          preferredStyle: preferredStyle,
          weather: weather,
          occasion: occasion,
        ) -
        _scoreItem(
          a,
          preferredColors: preferredColors,
          preferredStyle: preferredStyle,
          weather: weather,
          occasion: occasion,
        ));

    return matches[offset % matches.length];
  }

  int _scoreItem(
    WardrobeItem item, {
    required Set<String> preferredColors,
    required WeatherCondition weather,
    required DailyOccasion occasion,
    StyleTag? preferredStyle,
  }) {
    var score = 0;
    if (item.isFavorite) {
      score += 30;
    }
    if (preferredColors.contains(item.color)) {
      score += 18;
    }
    if (preferredStyle == item.style) {
      score += 14;
    }
    if (_preferredStylesForOccasion(occasion).contains(item.style)) {
      score += 12;
    }
    if (_preferredCategoriesForOccasion(occasion).contains(item.category)) {
      score += 10;
    }
    if (weather == WeatherCondition.rainy &&
        item.category == ClothingCategory.outerwear) {
      score += 10;
    }
    if (weather == WeatherCondition.hot &&
        (item.season == SeasonTag.summer ||
            item.season == SeasonTag.allSeason)) {
      score += 8;
    }
    if (weather == WeatherCondition.cold &&
        (item.season == SeasonTag.winter ||
            item.season == SeasonTag.allSeason)) {
      score += 8;
    }
    if (occasion == DailyOccasion.meeting || occasion == DailyOccasion.work) {
      if (item.style == StyleTag.smartCasual ||
          item.style == StyleTag.formal ||
          item.style == StyleTag.chic) {
        score += 10;
      }
    }
    if (occasion == DailyOccasion.college || occasion == DailyOccasion.travel) {
      if (item.style == StyleTag.casual || item.style == StyleTag.minimal) {
        score += 10;
      }
    }
    if (occasion == DailyOccasion.date ||
        occasion == DailyOccasion.party ||
        occasion == DailyOccasion.event) {
      if (item.style == StyleTag.chic || item.style == StyleTag.formal) {
        score += 12;
      }
    }
    return score +
        item.createdAt.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  List<MarketplaceSuggestion> _buildMarketplaceSuggestions({
    required DailyOccasion occasion,
    required WeatherCondition weather,
    required bool limitedWardrobe,
  }) {
    final suggestions = <MarketplaceSuggestion>[
      switch (occasion) {
        DailyOccasion.meeting || DailyOccasion.work => MarketplaceSuggestion(
            brand: 'COS',
            title: localizedText(
              en: 'Structured Blazer',
              ru: 'Структурный блейзер',
              kk: 'Құрылымды блейзер',
            ),
            priceLabel: '\$190',
            reason: localizedText(
              en: 'Adds polish for a sharper office or meeting finish.',
              ru: 'Добавляет образу собранность для офиса или деловой встречи.',
              kk: 'Офис не кездесу образын жинақы етіп толықтырады.',
            ),
            imageUrl: AppAssets.partnerBlazer,
          ),
        DailyOccasion.date || DailyOccasion.dinner => MarketplaceSuggestion(
            brand: 'Reformation',
            title: localizedText(
              en: 'Elegant Slip Dress',
              ru: 'Элегантное платье-комбинация',
              kk: 'Талғампаз комбинация көйлек',
            ),
            priceLabel: '\$218',
            reason: localizedText(
              en: 'Adds an easy statement piece for a date-night look.',
              ru: 'Даёт выразительный акцент для свидания или вечернего выхода.',
              kk: 'Кездесу не кешкі жоспарға айқын акцент қосады.',
            ),
            imageUrl: AppAssets.partnerDress,
          ),
        DailyOccasion.party || DailyOccasion.event => MarketplaceSuggestion(
            brand: 'Aritzia',
            title: localizedText(
              en: 'Sculpted Going-Out Top',
              ru: 'Акцентный топ для выхода',
              kk: 'Кешкі шығуға арналған акцентті топ',
            ),
            priceLabel: '\$88',
            reason: localizedText(
              en: 'Adds a more elevated option for social plans.',
              ru: 'Добавляет более выразительный вариант для вечерних планов.',
              kk: 'Әлеуметтік жоспарларға сәндірек нұсқа қосады.',
            ),
            imageUrl: AppAssets.partnerTop,
          ),
        DailyOccasion.travel => MarketplaceSuggestion(
            brand: 'Uniqlo',
            title: localizedText(
              en: 'Light Utility Layer',
              ru: 'Лёгкий утилитарный слой',
              kk: 'Жеңіл утилитарлық қабат',
            ),
            priceLabel: '\$69',
            reason: localizedText(
              en: 'Useful for travel days and easy temperature shifts.',
              ru: 'Удобен в поездках и при резких перепадах температуры.',
              kk: 'Сапар күндері мен ауа райы құбылғанда ыңғайлы.',
            ),
            imageUrl: AppAssets.partnerLayer,
          ),
        _ => MarketplaceSuggestion(
            brand: 'Everlane',
            title: localizedText(
              en: 'Everyday Cotton Shirt',
              ru: 'Базовая хлопковая рубашка',
              kk: 'Күнделікті мақта жейдесі',
            ),
            priceLabel: '\$58',
            reason: localizedText(
              en: 'A flexible staple that mixes easily with most wardrobes.',
              ru: 'Универсальная база, которую легко встроить почти в любой гардероб.',
              kk: 'Көп гардеробпен оңай үйлесетін әмбебап база.',
            ),
            imageUrl: AppAssets.partnerTop,
          ),
      },
      switch (weather) {
        WeatherCondition.rainy => MarketplaceSuggestion(
            brand: 'Veja',
            title: localizedText(
              en: 'Water-Friendly Sneakers',
              ru: 'Кроссовки для влажной погоды',
              kk: 'Ылғалды ауа райына арналған кроссовка',
            ),
            priceLabel: '\$140',
            reason: localizedText(
              en: 'Better for a wet day when you need practical shoes.',
              ru: 'Подойдут для дождливого дня, когда нужна практичная обувь.',
              kk: 'Практикалық аяқ киім керек жаңбырлы күнге лайық.',
            ),
            imageUrl: AppAssets.partnerSneakers,
          ),
        WeatherCondition.cold => MarketplaceSuggestion(
            brand: 'Mango',
            title: localizedText(
              en: 'Soft Wool Coat',
              ru: 'Мягкое шерстяное пальто',
              kk: 'Жұмсақ жүн пальто',
            ),
            priceLabel: '\$179',
            reason: localizedText(
              en: 'Adds warmth and structure for colder temperatures.',
              ru: 'Добавляет тепло и структуру в холодную погоду.',
              kk: 'Суық күнде жылылық пен құрылым қосады.',
            ),
            imageUrl: AppAssets.partnerLayer,
          ),
        WeatherCondition.hot => MarketplaceSuggestion(
            brand: 'Linen House',
            title: localizedText(
              en: 'Breathable Linen Trousers',
              ru: 'Льняные брюки',
              kk: 'Дем алатын зығыр шалбар',
            ),
            priceLabel: '\$92',
            reason: localizedText(
              en: 'Keeps the outfit cooler in hotter weather.',
              ru: 'Помогают сохранить комфорт в жаркую погоду.',
              kk: 'Ыстық ауа райында образды жеңілірек ұстайды.',
            ),
            imageUrl: AppAssets.partnerTrousers,
          ),
        _ => MarketplaceSuggestion(
            brand: 'Charles & Keith',
            title: localizedText(
              en: 'Clean Structured Bag',
              ru: 'Структурная сумка',
              kk: 'Құрылымды сөмке',
            ),
            priceLabel: '\$79',
            reason: localizedText(
              en: 'Completes the outfit without overpowering it.',
              ru: 'Завершает образ, не перегружая его.',
              kk: 'Образды ауырлатпай толықтырады.',
            ),
            imageUrl: AppAssets.partnerBag,
          ),
      },
    ];

    if (limitedWardrobe) {
      suggestions.add(
        MarketplaceSuggestion(
          brand: 'Massimo Dutti',
          title: localizedText(
            en: 'Versatile Layering Knit',
            ru: 'Универсальный трикотажный слой',
            kk: 'Әмбебап трикотаж қабаты',
          ),
          priceLabel: '\$110',
          reason: localizedText(
            en: 'Helps fill wardrobe gaps while staying easy to style.',
            ru: 'Помогает закрыть пробелы в гардеробе и легко комбинируется.',
            kk: 'Гардеробтағы бос орынды толтырып, оңай үйлеседі.',
          ),
          imageUrl: AppAssets.partnerLayer,
        ),
      );
    }

    return suggestions.take(3).toList();
  }

  String _buildNaturalExplanation({
    required WeatherCondition weather,
    required DailyOccasion occasion,
    required OutfitLook look,
    required bool limitedWardrobe,
    required bool premium,
    UserProfile? profile,
  }) {
    final weatherLabel = formatWeatherLabel(weather).toLowerCase();
    final occasionLabel = formatDailyOccasionLabel(occasion).toLowerCase();
    final base = switch (currentLanguageCode()) {
      'ru' => switch ((weather, occasion)) {
          (WeatherCondition.rainy, DailyOccasion.college) =>
            'Этот образ хорошо подходит для дождливого учебного дня, потому что сочетает комфорт, многослойность и практичную обувь.',
          (WeatherCondition.hot, DailyOccasion.shopping) =>
            'Этот образ подходит для тёплой погоды и шопинга: он остаётся лёгким, удобным и подвижным.',
          (WeatherCondition.cold, DailyOccasion.meeting) =>
            'Это удачный вариант для холодного дня со встречей, потому что он выглядит собранно и при этом сохраняет тепло.',
          (WeatherCondition.sunny, DailyOccasion.date) =>
            'Этот образ хорошо подходит для солнечного свидания: он выглядит выверенно, легко и чуть более нарядно.',
          _ =>
            'Этот образ подходит для погоды "$weatherLabel" и плана "$occasionLabel", сохраняя баланс между практичностью и собранным силуэтом.',
        },
      'kk' => switch ((weather, occasion)) {
          (WeatherCondition.rainy, DailyOccasion.college) =>
            'Бұл образ жаңбырлы оқу күніне жақсы сай келеді, өйткені жайлылықты, қабаттарды және практикалық аяқ киімді біріктіреді.',
          (WeatherCondition.hot, DailyOccasion.shopping) =>
            'Бұл образ жылы ауа райы мен шопингке лайық: ол жеңіл, ыңғайлы және еркін қимылдауға ыңғайлы.',
          (WeatherCondition.cold, DailyOccasion.meeting) =>
            'Бұл суық күнгі кездесуге жақсы таңдау, өйткені ол жинақы көрініп, жылылықты сақтайды.',
          (WeatherCondition.sunny, DailyOccasion.date) =>
            'Бұл образ күн ашық кездесу үшін жарасады: жинақы, тепе-тең әрі артық күшсіз сәл сәндірек көрінеді.',
          _ =>
            'Бұл образ "$weatherLabel" ауа райы мен "$occasionLabel" жоспарына сай келіп, практикалық пен жинақы силуэттің арасын тең ұстайды.',
        },
      _ => switch ((weather, occasion)) {
          (WeatherCondition.rainy, DailyOccasion.college) =>
            'This outfit works well for a rainy college day because it combines comfort, layering, and practical shoes.',
          (WeatherCondition.hot, DailyOccasion.shopping) =>
            'This look suits warm weather and a shopping plan, keeping things light, comfortable, and easy to move in.',
          (WeatherCondition.cold, DailyOccasion.meeting) =>
            'This outfit is a strong choice for a cold meeting day because it feels polished while still keeping you warm.',
          (WeatherCondition.sunny, DailyOccasion.date) =>
            'This look fits a sunny date because it feels styled, balanced, and a little more elevated without trying too hard.',
          _ =>
            'This outfit fits $weatherLabel weather and a $occasionLabel plan by balancing practicality with a polished silhouette.',
        },
    };

    final profileLine = profile == null
        ? ''
        : localizedText(
            en: ' It also stays close to your ${titleCase(profile.favoriteStyle.name)} preference and preferred palette.',
            ru: ' Он также остаётся близким к вашему любимому стилю ${formatStyleTagLabel(profile.favoriteStyle).toLowerCase()} и привычной палитре.',
            kk: ' Ол сонымен қатар сіздің ${formatStyleTagLabel(profile.favoriteStyle).toLowerCase()} бағытыңызға және ұнататын палитраңызға жақын.',
          );
    final limitedLine = limitedWardrobe
        ? localizedText(
            en: ' I kept the mix simple because your current wardrobe has a few gaps, but it is still the strongest combination available.',
            ru: ' Я оставил сочетание более простым, потому что в текущем гардеробе ещё есть пробелы, но это всё равно самая сильная комбинация из доступных.',
            kk: ' Қазіргі гардеробта әлі аздаған бос орындар болғандықтан, комбинацияны қарапайымдау ұстадым, бірақ бұл қолда бардың ішіндегі ең мықтысы.',
          )
        : '';
    final premiumLine = premium
        ? localizedText(
            en: ' The matching logic is a little more precise here, with extra attention on occasion fit and overall balance.',
            ru: ' Здесь подбор работает точнее: больше внимания уделено уместности для повода и общему балансу.',
            kk: ' Мұнда сәйкестендіру дәлірек: жоспарға сәйкестік пен жалпы тепе-теңдікке көбірек көңіл бөлінеді.',
          )
        : '';

    return '$base$profileLine$limitedLine$premiumLine';
  }

  String _smartTitleForOccasion(DailyOccasion occasion) {
    switch (currentLanguageCode()) {
      case 'ru':
        switch (occasion) {
          case DailyOccasion.college:
            return 'Образ для учёбы';
          case DailyOccasion.work:
            return 'Рабочий образ';
          case DailyOccasion.meeting:
            return 'Готово к встрече';
          case DailyOccasion.casualWalk:
            return 'Лёгкий образ для прогулки';
          case DailyOccasion.shopping:
            return 'Образ для шопинга';
          case DailyOccasion.date:
            return 'Образ для свидания';
          case DailyOccasion.dinner:
            return 'Образ для ужина';
          case DailyOccasion.party:
            return 'Образ для вечеринки';
          case DailyOccasion.travel:
            return 'Образ для поездки';
          case DailyOccasion.home:
            return 'Расслабленный домашний образ';
          case DailyOccasion.gym:
            return 'Образ для зала';
          case DailyOccasion.event:
            return 'Образ для события';
        }
      case 'kk':
        switch (occasion) {
          case DailyOccasion.college:
            return 'Оқуға арналған образ';
          case DailyOccasion.work:
            return 'Жұмыс күніне образ';
          case DailyOccasion.meeting:
            return 'Кездесуге дайын образ';
          case DailyOccasion.casualWalk:
            return 'Серуенге жеңіл образ';
          case DailyOccasion.shopping:
            return 'Шопингке образ';
          case DailyOccasion.date:
            return 'Кездесуге образ';
          case DailyOccasion.dinner:
            return 'Кешкі асқа образ';
          case DailyOccasion.party:
            return 'Кешке дайын образ';
          case DailyOccasion.travel:
            return 'Сапарға образ';
          case DailyOccasion.home:
            return 'Үйге арналған еркін образ';
          case DailyOccasion.gym:
            return 'Залға арналған образ';
          case DailyOccasion.event:
            return 'Іс-шараға образ';
        }
      default:
        switch (occasion) {
          case DailyOccasion.college:
            return 'Today’s College Fit';
          case DailyOccasion.work:
            return 'Workday Edit';
          case DailyOccasion.meeting:
            return 'Meeting Ready';
          case DailyOccasion.casualWalk:
            return 'Easy Walk Look';
          case DailyOccasion.shopping:
            return 'Shopping Day Look';
          case DailyOccasion.date:
            return 'Date Night Edit';
          case DailyOccasion.dinner:
            return 'Dinner Outfit';
          case DailyOccasion.party:
            return 'Party Ready';
          case DailyOccasion.travel:
            return 'Travel Day Fit';
          case DailyOccasion.home:
            return 'Relaxed Home Look';
          case DailyOccasion.gym:
            return 'Gym-Friendly Edit';
          case DailyOccasion.event:
            return 'Event Styling';
        }
    }
  }

  String _vibeForOccasion(DailyOccasion occasion, bool premium) {
    if (premium) {
      switch (occasion) {
        case DailyOccasion.meeting:
        case DailyOccasion.work:
          return localizedText(
            en: 'Polished and composed',
            ru: 'Собранно и уверенно',
            kk: 'Жинақы әрі сенімді',
          );
        case DailyOccasion.date:
        case DailyOccasion.party:
        case DailyOccasion.event:
          return localizedText(
            en: 'Elevated and expressive',
            ru: 'Выразительно и эффектно',
            kk: 'Айқын әрі сәнді',
          );
        case DailyOccasion.travel:
        case DailyOccasion.college:
          return localizedText(
            en: 'Balanced and practical',
            ru: 'Сбалансированно и практично',
            kk: 'Тепе-тең әрі практикалық',
          );
        default:
          return localizedText(
            en: 'Easy and personal',
            ru: 'Легко и персонально',
            kk: 'Жеңіл әрі жеке стильге жақын',
          );
      }
    }
    switch (occasion) {
      case DailyOccasion.meeting:
      case DailyOccasion.work:
        return localizedText(
          en: 'Smart casual balance',
          ru: 'Баланс смарт-кэжуал',
          kk: 'Смарт-кэжуал тепе-теңдігі',
        );
      case DailyOccasion.college:
      case DailyOccasion.travel:
        return localizedText(
          en: 'Comfortable and styled',
          ru: 'Комфортно и собранно',
          kk: 'Ыңғайлы әрі жинақы',
        );
      default:
        return localizedText(
          en: 'Easy and wearable',
          ru: 'Легко и удобно',
          kk: 'Жеңіл әрі киюге ыңғайлы',
        );
    }
  }

  String _generatedRecipeTitle({
    required int index,
    required DailyOccasion occasion,
  }) {
    switch (index) {
      case 0:
        return localizedText(
          en: 'Signature Outfit',
          ru: 'Базовый вариант',
          kk: 'Негізгі нұсқа',
        );
      case 1:
        return localizedText(
          en: 'Refined Alternative',
          ru: 'Более выверенный вариант',
          kk: 'Нақтырақ альтернатива',
        );
      default:
        return localizedText(
          en: '${formatDailyOccasionLabel(occasion)} Edit',
          ru: 'Вариант с учётом погоды',
          kk: 'Ауа райына сай нұсқа',
        );
    }
  }

  String _generatedRecipeVibe({
    required int index,
    required DailyOccasion occasion,
    required bool premium,
  }) {
    switch (index) {
      case 0:
        return premium
            ? _vibeForOccasion(occasion, true)
            : localizedText(
                en: 'Easy and wearable',
                ru: 'Легко и носибельно',
                kk: 'Жеңіл әрі киюге ыңғайлы',
              );
      case 1:
        return premium
            ? localizedText(
                en: 'Built around your preferences',
                ru: 'С учётом ваших предпочтений',
                kk: 'Сіздің таңдауыңызға сай',
              )
            : localizedText(
                en: 'Smart casual comfort',
                ru: 'Комфортный смарт-кэжуал',
                kk: 'Ыңғайлы смарт-кэжуал',
              );
      default:
        return premium
            ? localizedText(
                en: 'Weather-aware and refined',
                ru: 'С учётом погоды и более выверенно',
                kk: 'Ауа райына сай әрі нақты',
              )
            : localizedText(
                en: 'Relaxed with a styled finish',
                ru: 'Расслабленно, но собранно',
                kk: 'Еркін, бірақ жинақы',
              );
    }
  }

  bool _occasionPrefersDress(DailyOccasion occasion) {
    return occasion == DailyOccasion.date ||
        occasion == DailyOccasion.dinner ||
        occasion == DailyOccasion.party ||
        occasion == DailyOccasion.event;
  }

  bool _needsLayer(WeatherCondition weather, DailyOccasion occasion) {
    if (weather == WeatherCondition.cold ||
        weather == WeatherCondition.rainy ||
        weather == WeatherCondition.windy ||
        weather == WeatherCondition.cloudy) {
      return true;
    }
    return occasion == DailyOccasion.meeting ||
        occasion == DailyOccasion.work ||
        occasion == DailyOccasion.travel;
  }

  List<StyleTag> _preferredStylesForOccasion(DailyOccasion occasion) {
    switch (occasion) {
      case DailyOccasion.college:
      case DailyOccasion.casualWalk:
      case DailyOccasion.shopping:
      case DailyOccasion.home:
      case DailyOccasion.gym:
      case DailyOccasion.travel:
        return const [StyleTag.casual, StyleTag.minimal, StyleTag.smartCasual];
      case DailyOccasion.work:
      case DailyOccasion.meeting:
        return const [StyleTag.smartCasual, StyleTag.formal, StyleTag.chic];
      case DailyOccasion.date:
      case DailyOccasion.dinner:
      case DailyOccasion.party:
      case DailyOccasion.event:
        return const [StyleTag.chic, StyleTag.formal, StyleTag.smartCasual];
    }
  }

  List<ClothingCategory> _preferredCategoriesForOccasion(
      DailyOccasion occasion) {
    switch (occasion) {
      case DailyOccasion.college:
      case DailyOccasion.work:
      case DailyOccasion.meeting:
      case DailyOccasion.travel:
        return const [
          ClothingCategory.outerwear,
          ClothingCategory.bags,
          ClothingCategory.shoes
        ];
      case DailyOccasion.date:
      case DailyOccasion.dinner:
      case DailyOccasion.party:
      case DailyOccasion.event:
        return const [
          ClothingCategory.dresses,
          ClothingCategory.accessories,
          ClothingCategory.shoes
        ];
      default:
        return const [
          ClothingCategory.tops,
          ClothingCategory.bottoms,
          ClothingCategory.shoes
        ];
    }
  }

  DailyOccasion _occasionFromLabel(String occasion) {
    final normalized = occasion.toLowerCase();
    if (normalized.contains('college') ||
        normalized.contains('class') ||
        normalized.contains('уч') ||
        normalized.contains('оқу')) {
      return DailyOccasion.college;
    }
    if (normalized.contains('work') ||
        normalized.contains('office') ||
        normalized.contains('работ') ||
        normalized.contains('жұмыс')) {
      return DailyOccasion.work;
    }
    if (normalized.contains('meeting') ||
        normalized.contains('встр') ||
        normalized.contains('кезд')) {
      return DailyOccasion.meeting;
    }
    if (normalized.contains('shopping') ||
        normalized.contains('шоп') ||
        normalized.contains('дүкен')) {
      return DailyOccasion.shopping;
    }
    if (normalized.contains('date') ||
        normalized.contains('свид') ||
        normalized.contains('роман') ||
        normalized.contains('кездесу')) {
      return DailyOccasion.date;
    }
    if (normalized.contains('dinner') ||
        normalized.contains('ужин') ||
        normalized.contains('кешкі ас')) {
      return DailyOccasion.dinner;
    }
    if (normalized.contains('party') ||
        normalized.contains('вечерин') ||
        normalized.contains('кеш')) {
      return DailyOccasion.party;
    }
    if (normalized.contains('travel') ||
        normalized.contains('поезд') ||
        normalized.contains('сапар')) {
      return DailyOccasion.travel;
    }
    if (normalized.contains('gym') ||
        normalized.contains('зал') ||
        normalized.contains('спорт')) {
      return DailyOccasion.gym;
    }
    if (normalized.contains('event') ||
        normalized.contains('событ') ||
        normalized.contains('іс-шара')) {
      return DailyOccasion.event;
    }
    if (normalized.contains('walk') ||
        normalized.contains('прогул') ||
        normalized.contains('серуен')) {
      return DailyOccasion.casualWalk;
    }
    if (normalized.contains('home') ||
        normalized.contains('relaxed') ||
        normalized.contains('дом') ||
        normalized.contains('үй')) {
      return DailyOccasion.home;
    }
    return DailyOccasion.casualWalk;
  }

  static bool _hasCategory(
      List<WardrobeItem> wardrobe, ClothingCategory category) {
    return wardrobe.any((item) => item.category == category);
  }
}

class _LookRecipe {
  const _LookRecipe({
    required this.title,
    required this.vibe,
    required this.useDress,
    required this.preferLayers,
  });

  final String title;
  final String vibe;
  final bool useDress;
  final bool preferLayers;
}
