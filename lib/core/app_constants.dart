import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_enums.dart';

class AppConstants {
  static const freeDailyOutfitLimit = 3;
  static const freeDailyChatLimit = 6;
  static const freeDailySmartPlanLimit = 2;
  static const weatherRefreshWindowHours = 4;

  static List<String> wardrobePromptSuggestions() {
    return _localizedList(
      en: const [
        'What should I wear today?',
        'Suggest an outfit for college',
        'What should I wear for college if it is rainy?',
        'Create a look for a meeting in cold weather.',
        'Suggest an outfit for a sunny date.',
        'What matches with black pants?',
        'What should I wear in rainy weather?',
        'I want a smart casual look',
        'Build me a weekend outfit',
        'What can I wear with white sneakers?',
      ],
      ru: const [
        'Что мне надеть сегодня?',
        'Подбери образ для учёбы',
        'Что надеть на учёбу, если идёт дождь?',
        'Собери образ для встречи в холодную погоду',
        'Предложи образ для солнечного свидания',
        'Что сочетается с чёрными брюками?',
        'Что надеть в дождливую погоду?',
        'Хочу образ в стиле смарт-кэжуал',
        'Собери образ на выходные',
        'Что можно надеть с белыми кроссовками?',
      ],
      kk: const [
        'Бүгін не кисем болады?',
        'Оқуға арналған образ ұсын',
        'Жаңбырлы күні оқуға не кисем болады?',
        'Суық ауа райында кездесуге образ құрастыр',
        'Күн ашық күнге лайық образ ұсын',
        'Қара шалбармен не үйлеседі?',
        'Жаңбырлы күні не киген дұрыс?',
        'Смарт-кэжуал образ қалаймын',
        'Демалыс күніне образ құрастыр',
        'Ақ кроссовкамен не киюге болады?',
      ],
    );
  }

  static List<String> advancedPromptSuggestions() {
    return _localizedList(
      en: const [
        'Plan my outfits for a packed week with classes and coffee meetings',
        'Build a polished event outfit around my favorite color palette',
        'Give me a mood-based outfit that feels elevated but comfortable',
      ],
      ru: const [
        'Распланируй мои образы на насыщенную неделю с учёбой и встречами',
        'Собери образ для события в моей любимой палитре',
        'Предложи образ по настроению: элегантно, но удобно',
      ],
      kk: const [
        'Сабақтар мен кездесулерге толы аптаға образдарымды жоспарла',
        'Сүйікті түстеріме сай шараға арналған образ құрастыр',
        'Көңіл күйге сай, ыңғайлы әрі сәнді образ ұсын',
      ],
    );
  }

  static List<String> stylistFollowUpSuggestions() {
    return _localizedList(
      en: const [
        'What about shoes?',
        'Can you make it more formal?',
        'Give another option',
        'Something more casual',
      ],
      ru: const [
        'А что насчёт обуви?',
        'Сделай образ более формальным',
        'Покажи другой вариант',
        'Хочется чего-то более повседневного',
      ],
      kk: const [
        'Аяқ киім бойынша не ұсынасың?',
        'Мұны ресмилеу етіп бере аласың ба?',
        'Тағы бір нұсқа көрсет',
        'Сәл күнделіктірек нәрсе керек',
      ],
    );
  }

  static const generatorOccasionValues = <DailyOccasion>[
    DailyOccasion.casualWalk,
    DailyOccasion.college,
    DailyOccasion.work,
    DailyOccasion.shopping,
    DailyOccasion.date,
    DailyOccasion.dinner,
    DailyOccasion.travel,
    DailyOccasion.event,
  ];

  static const generatorTags = [
    'casual',
    'office',
    'college',
    'weekend',
    'rainy day',
    'hot weather',
    'smart casual',
    'cozy',
  ];

  static const dailyPlanOccasions = DailyOccasion.values;

  static List<String> styleMoods() {
    return _localizedList(
      en: const [
        'Effortless',
        'Polished',
        'Relaxed',
        'Confident',
        'Modern',
        'Cozy',
      ],
      ru: const [
        'Легко',
        'Собранно',
        'Расслабленно',
        'Уверенно',
        'Современно',
        'Уютно',
      ],
      kk: const [
        'Жеңіл',
        'Жинақы',
        'Еркін',
        'Сенімді',
        'Заманауи',
        'Жайлы',
      ],
    );
  }

  static const defaultCategoryOrder = [
    ClothingCategory.tops,
    ClothingCategory.bottoms,
    ClothingCategory.outerwear,
    ClothingCategory.dresses,
    ClothingCategory.shoes,
    ClothingCategory.bags,
    ClothingCategory.accessories,
  ];

  static const demoColors = [
    'Soft Navy',
    'Muted Blue',
    'Powder Blue',
    'White',
    'Warm White',
    'Cool Gray',
    'Lavender Gray',
    'Black',
    'Denim',
    'Camel',
    'Olive',
    'Blush',
  ];

  static const wardrobeTags = [
    'casual',
    'formal',
    'sporty',
    'cozy',
    'college',
    'weekend',
    'smart casual',
    'rainy day',
    'minimal',
    'layering',
  ];

  static const preferredStyles = StyleTag.values;
  static const preferredColorDefaults = [
    'Soft Navy',
    'Muted Blue',
    'Warm White',
  ];
  static const weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const colorMap = <String, Color>{
    'Soft Navy': Color(0xFF2E476E),
    'Muted Blue': Color(0xFF6F87AE),
    'Powder Blue': Color(0xFFC8D8F2),
    'White': Color(0xFFFFFFFF),
    'Warm White': Color(0xFFF7F4EF),
    'Cool Gray': Color(0xFFB5BFCE),
    'Lavender Gray': Color(0xFFD9DDEB),
    'Black': Color(0xFF212633),
    'Denim': Color(0xFF4F6A94),
    'Camel': Color(0xFFC49B73),
    'Olive': Color(0xFF77856C),
    'Blush': Color(0xFFE8CBD3),
  };

  static String weatherDescriptionFor(WeatherCondition condition) {
    switch (_languageCode()) {
      case 'ru':
        switch (condition) {
          case WeatherCondition.sunny:
            return 'Ясное небо и комфортная видимость. Лучше всего работают лёгкие слои.';
          case WeatherCondition.cloudy:
            return 'Лёгкая облачность и более прохладный воздух. Идеально подойдёт многослойность.';
          case WeatherCondition.rainy:
            return 'Дождливо, поэтому пригодятся практичная верхняя одежда и закрытая обувь.';
          case WeatherCondition.cold:
            return 'Прохладный день, в который особенно важны тепло, структура и закрытая обувь.';
          case WeatherCondition.hot:
            return 'Жарко, поэтому лучше выбирать дышащие ткани и лёгкие вещи.';
          case WeatherCondition.windy:
            return 'Ветрено, поэтому подойдут надёжные слои и практичная обувь.';
        }
      case 'kk':
        switch (condition) {
          case WeatherCondition.sunny:
            return 'Аспан ашық, ауа райы жайлы. Жеңіл қабаттар жақсы үйлеседі.';
          case WeatherCondition.cloudy:
            return 'Бұлтты әрі салқындау. Қабаттап киіну ыңғайлы болады.';
          case WeatherCondition.rainy:
            return 'Жаңбырлы күн, сондықтан практикалық сырт киім мен жабық аяқ киім қажет.';
          case WeatherCondition.cold:
            return 'Салқын күн, сондықтан жылылық, құрылым және жабық аяқ киім маңызды.';
          case WeatherCondition.hot:
            return 'Ыстық ауа райында дем алатын маталар мен жеңіл киімдер жақсы.';
          case WeatherCondition.windy:
            return 'Желді күні бекітілген қабаттар мен ыңғайлы аяқ киім жақсы жұмыс істейді.';
        }
      default:
        switch (condition) {
          case WeatherCondition.sunny:
            return 'Bright skies with comfortable visibility and lighter layers.';
          case WeatherCondition.cloudy:
            return 'Gentle cloud cover with cooler air and easy layering.';
          case WeatherCondition.rainy:
            return 'Light to steady rain with a need for practical outerwear.';
          case WeatherCondition.cold:
            return 'A crisp day that calls for warmth, structure, and closed shoes.';
          case WeatherCondition.hot:
            return 'High temperatures that favor breathable fabrics and lighter pieces.';
          case WeatherCondition.windy:
            return 'A breezy day where secure layers and practical shoes work best.';
        }
    }
  }

  static const planPrices = <SubscriptionTier, String>{
    SubscriptionTier.free: '\$0',
    SubscriptionTier.premium: '\$9.99 / month',
    SubscriptionTier.plus: '\$19.99 / month',
  };

  static Map<WeatherCondition, String> get weatherDescriptions => {
        for (final condition in WeatherCondition.values)
          condition: weatherDescriptionFor(condition),
      };

  static String planTaglineFor(SubscriptionTier tier) {
    switch (_languageCode()) {
      case 'ru':
        switch (tier) {
          case SubscriptionTier.free:
            return 'Соберите гардероб и откройте базовые возможности.';
          case SubscriptionTier.premium:
            return 'Откройте полный опыт ИИ-стилиста.';
          case SubscriptionTier.plus:
            return 'Сочетайте гардероб с товарами партнёров и рекомендациями для дополнения образа.';
        }
      case 'kk':
        switch (tier) {
          case SubscriptionTier.free:
            return 'Гардеробты жинап, негізгі мүмкіндіктерді ашыңыз.';
          case SubscriptionTier.premium:
            return 'ЖИ стилисттің толық мүмкіндігін ашыңыз.';
          case SubscriptionTier.plus:
            return 'Гардеробты серіктес өнімдермен және образды толықтыратын ұсыныстармен біріктіріңіз.';
        }
      default:
        switch (tier) {
          case SubscriptionTier.free:
            return 'Build your wardrobe and explore the basics.';
          case SubscriptionTier.premium:
            return 'Unlock the full AI stylist experience.';
          case SubscriptionTier.plus:
            return 'Blend your wardrobe with partner products and shop-the-look styling.';
        }
    }
  }

  static List<String> planFeatureBulletsFor(SubscriptionTier tier) {
    switch (_languageCode()) {
      case 'ru':
        switch (tier) {
          case SubscriptionTier.free:
            return const [
              'Загрузка и организация гардероба',
              'Базовая помощь с погодой и планером',
              'Ограниченный ИИ-стилист и генерация образов',
            ];
          case SubscriptionTier.premium:
            return const [
              'Безлимитная генерация образов',
              'Безлимитный чат с ИИ-стилистом',
              'Более умные рекомендации по погоде, планам и событиям',
            ];
          case SubscriptionTier.plus:
            return const [
              'Всё из Premium',
              'Доступ к маркетплейсу и партнёрским предложениям',
              'Подбор покупок к образу и сочетание гардероба с товарами магазина',
            ];
        }
      case 'kk':
        switch (tier) {
          case SubscriptionTier.free:
            return const [
              'Гардеробты жүктеу және реттеу',
              'Ауа райы мен жоспарлауға арналған базалық көмек',
              'Шектеулі ЖИ стилист және образ генерациясы',
            ];
          case SubscriptionTier.premium:
            return const [
              'Шексіз образ генерациясы',
              'Шексіз ЖИ стилист чаты',
              'Ауа райы, жоспар және оқиғаға сай ақылдырақ ұсыныстар',
            ];
          case SubscriptionTier.plus:
            return const [
              'Premium ішіндегі барлық мүмкіндік',
              'Маркетплейс пен серіктес ұсыныстарға қолжеткізу',
              'Образды толықтыратын сатып алу ұсыныстары және гардеробты дүкен тауарларымен үйлестіру',
            ];
        }
      default:
        switch (tier) {
          case SubscriptionTier.free:
            return const [
              'Wardrobe upload and organization',
              'Basic weather and planner help',
              'Limited AI stylist and outfit generations',
            ];
          case SubscriptionTier.premium:
            return const [
              'Unlimited outfit generation',
              'Unlimited AI stylist chat',
              'Smarter weather, planner, and occasion matching',
            ];
          case SubscriptionTier.plus:
            return const [
              'Everything in Premium',
              'Brand partnership and marketplace access',
              'Shop-the-look recommendations and wardrobe + store mix',
            ];
        }
    }
  }

  static const stylePreferenceLabels = <StylePreference, String>{
    StylePreference.feminine: 'Feminine',
    StylePreference.masculine: 'Masculine',
    StylePreference.neutral: 'Neutral',
    StylePreference.modest: 'Modest',
    StylePreference.expressive: 'Expressive',
  };

  static Map<SubscriptionTier, String> get planTaglines => {
        for (final tier in SubscriptionTier.values) tier: planTaglineFor(tier),
      };

  static Map<SubscriptionTier, List<String>> get planFeatureBullets => {
        for (final tier in SubscriptionTier.values)
          tier: planFeatureBulletsFor(tier),
      };

  static List<String> _localizedList({
    required List<String> en,
    required List<String> ru,
    required List<String> kk,
  }) {
    switch (_languageCode()) {
      case 'ru':
        return ru;
      case 'kk':
        return kk;
      default:
        return en;
    }
  }

  static String _languageCode() {
    final locale = Intl.getCurrentLocale();
    if (locale.isEmpty) {
      return 'en';
    }
    return locale.split(RegExp('[_-]')).first.toLowerCase();
  }
}
