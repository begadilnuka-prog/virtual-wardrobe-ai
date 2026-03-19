import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_constants.dart';
import 'app_enums.dart';

String titleCase(String value) {
  return value
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
      .split(RegExp(r'[_\s]+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String currentLanguageCode() {
  final locale = Intl.getCurrentLocale();
  if (locale.isEmpty) {
    return 'en';
  }
  return locale.split(RegExp('[_-]')).first.toLowerCase();
}

String localizedText({
  required String en,
  String? ru,
  String? kk,
}) {
  switch (currentLanguageCode()) {
    case 'ru':
      return ru ?? en;
    case 'kk':
      return kk ?? en;
    default:
      return en;
  }
}

List<String> localizedList({
  required List<String> en,
  required List<String> ru,
  required List<String> kk,
}) {
  switch (currentLanguageCode()) {
    case 'ru':
      return ru;
    case 'kk':
      return kk;
    default:
      return en;
  }
}

String formatShortDate(DateTime value) {
  final code = currentLanguageCode();
  final pattern = code == 'en' ? 'MMM d' : 'd MMM';
  return DateFormat(pattern, code).format(value);
}

String formatDateTime(DateTime value) {
  final code = currentLanguageCode();
  final pattern = code == 'en' ? 'MMM d, h:mm a' : 'd MMM, HH:mm';
  return DateFormat(pattern, code).format(value);
}

String formatWeekdayDate(DateTime value) {
  final code = currentLanguageCode();
  final pattern = code == 'en' ? 'EEEE, MMM d' : 'EEEE, d MMM';
  return DateFormat(pattern, code).format(value);
}

String formatTimeOnly(DateTime value) {
  final code = currentLanguageCode();
  return code == 'en'
      ? DateFormat.jm(code).format(value)
      : DateFormat.Hm(code).format(value);
}

String formatCategoryLabel(ClothingCategory category) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (category) {
        case ClothingCategory.tops:
          return 'Верх';
        case ClothingCategory.bottoms:
          return 'Низ';
        case ClothingCategory.outerwear:
          return 'Верхняя одежда';
        case ClothingCategory.dresses:
          return 'Платье';
        case ClothingCategory.shoes:
          return 'Обувь';
        case ClothingCategory.bags:
          return 'Сумка';
        case ClothingCategory.accessories:
          return 'Аксессуар';
      }
    case 'kk':
      switch (category) {
        case ClothingCategory.tops:
          return 'Үстіңгі бөлік';
        case ClothingCategory.bottoms:
          return 'Астыңғы бөлік';
        case ClothingCategory.outerwear:
          return 'Сырт киім';
        case ClothingCategory.dresses:
          return 'Көйлек';
        case ClothingCategory.shoes:
          return 'Аяқ киім';
        case ClothingCategory.bags:
          return 'Сөмке';
        case ClothingCategory.accessories:
          return 'Аксессуар';
      }
    default:
      switch (category) {
        case ClothingCategory.tops:
          return 'Top';
        case ClothingCategory.bottoms:
          return 'Bottom';
        case ClothingCategory.outerwear:
          return 'Outerwear';
        case ClothingCategory.dresses:
          return 'Dress';
        case ClothingCategory.shoes:
          return 'Shoes';
        case ClothingCategory.bags:
          return 'Bag';
        case ClothingCategory.accessories:
          return 'Accessory';
      }
  }
}

String formatWeatherLabel(WeatherCondition condition) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (condition) {
        case WeatherCondition.sunny:
          return 'Солнечно';
        case WeatherCondition.cloudy:
          return 'Облачно';
        case WeatherCondition.rainy:
          return 'Дождливо';
        case WeatherCondition.cold:
          return 'Холодно';
        case WeatherCondition.hot:
          return 'Жарко';
        case WeatherCondition.windy:
          return 'Ветрено';
      }
    case 'kk':
      switch (condition) {
        case WeatherCondition.sunny:
          return 'Күн ашық';
        case WeatherCondition.cloudy:
          return 'Бұлтты';
        case WeatherCondition.rainy:
          return 'Жаңбырлы';
        case WeatherCondition.cold:
          return 'Суық';
        case WeatherCondition.hot:
          return 'Ыстық';
        case WeatherCondition.windy:
          return 'Желді';
      }
    default:
      return titleCase(condition.name);
  }
}

String formatSubscriptionTierLabel(SubscriptionTier tier) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (tier) {
        case SubscriptionTier.free:
          return 'Бесплатный';
        case SubscriptionTier.premium:
          return 'Premium';
        case SubscriptionTier.plus:
          return 'Plus';
      }
    case 'kk':
      switch (tier) {
        case SubscriptionTier.free:
          return 'Тегін';
        case SubscriptionTier.premium:
          return 'Premium';
        case SubscriptionTier.plus:
          return 'Plus';
      }
    default:
      switch (tier) {
        case SubscriptionTier.free:
          return 'Free';
        case SubscriptionTier.premium:
          return 'Premium';
        case SubscriptionTier.plus:
          return 'Plus';
      }
  }
}

String formatSubscriptionPrice(SubscriptionTier tier) {
  return AppConstants.planPrices[tier] ?? '';
}

String formatDailyOccasionLabel(DailyOccasion occasion) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (occasion) {
        case DailyOccasion.college:
          return 'Учёба';
        case DailyOccasion.work:
          return 'Работа';
        case DailyOccasion.meeting:
          return 'Встреча';
        case DailyOccasion.casualWalk:
          return 'Прогулка';
        case DailyOccasion.shopping:
          return 'Шопинг';
        case DailyOccasion.date:
          return 'Свидание';
        case DailyOccasion.dinner:
          return 'Ужин';
        case DailyOccasion.party:
          return 'Вечеринка';
        case DailyOccasion.travel:
          return 'Поездка';
        case DailyOccasion.home:
          return 'Дом';
        case DailyOccasion.gym:
          return 'Зал';
        case DailyOccasion.event:
          return 'Событие';
      }
    case 'kk':
      switch (occasion) {
        case DailyOccasion.college:
          return 'Оқу';
        case DailyOccasion.work:
          return 'Жұмыс';
        case DailyOccasion.meeting:
          return 'Кездесу';
        case DailyOccasion.casualWalk:
          return 'Серуен';
        case DailyOccasion.shopping:
          return 'Шопинг';
        case DailyOccasion.date:
          return 'Кездесу';
        case DailyOccasion.dinner:
          return 'Кешкі ас';
        case DailyOccasion.party:
          return 'Кеш';
        case DailyOccasion.travel:
          return 'Сапар';
        case DailyOccasion.home:
          return 'Үй';
        case DailyOccasion.gym:
          return 'Зал';
        case DailyOccasion.event:
          return 'Іс-шара';
      }
    default:
      switch (occasion) {
        case DailyOccasion.college:
          return 'College';
        case DailyOccasion.work:
          return 'Work';
        case DailyOccasion.meeting:
          return 'Meeting';
        case DailyOccasion.casualWalk:
          return 'Casual Walk';
        case DailyOccasion.shopping:
          return 'Shopping';
        case DailyOccasion.date:
          return 'Date';
        case DailyOccasion.dinner:
          return 'Dinner';
        case DailyOccasion.party:
          return 'Party';
        case DailyOccasion.travel:
          return 'Travel';
        case DailyOccasion.home:
          return 'Home';
        case DailyOccasion.gym:
          return 'Gym';
        case DailyOccasion.event:
          return 'Event';
      }
  }
}

String formatSeasonLabel(SeasonTag season) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (season) {
        case SeasonTag.spring:
          return 'Весна';
        case SeasonTag.summer:
          return 'Лето';
        case SeasonTag.autumn:
          return 'Осень';
        case SeasonTag.winter:
          return 'Зима';
        case SeasonTag.allSeason:
          return 'На все сезоны';
      }
    case 'kk':
      switch (season) {
        case SeasonTag.spring:
          return 'Көктем';
        case SeasonTag.summer:
          return 'Жаз';
        case SeasonTag.autumn:
          return 'Күз';
        case SeasonTag.winter:
          return 'Қыс';
        case SeasonTag.allSeason:
          return 'Барлық маусымға';
      }
    default:
      switch (season) {
        case SeasonTag.spring:
          return 'Spring';
        case SeasonTag.summer:
          return 'Summer';
        case SeasonTag.autumn:
          return 'Autumn';
        case SeasonTag.winter:
          return 'Winter';
        case SeasonTag.allSeason:
          return 'All Season';
      }
  }
}

String formatStyleTagLabel(StyleTag style) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (style) {
        case StyleTag.casual:
          return 'Повседневный';
        case StyleTag.smartCasual:
          return 'Смарт-кэжуал';
        case StyleTag.formal:
          return 'Формальный';
        case StyleTag.modest:
          return 'Сдержанный';
        case StyleTag.minimal:
          return 'Минималистичный';
        case StyleTag.chic:
          return 'Шик';
        case StyleTag.streetwear:
          return 'Стритстайл';
      }
    case 'kk':
      switch (style) {
        case StyleTag.casual:
          return 'Күнделікті';
        case StyleTag.smartCasual:
          return 'Смарт-кэжуал';
        case StyleTag.formal:
          return 'Ресми';
        case StyleTag.modest:
          return 'Ұстамды';
        case StyleTag.minimal:
          return 'Минимал';
        case StyleTag.chic:
          return 'Шик';
        case StyleTag.streetwear:
          return 'Стритстайл';
      }
    default:
      return titleCase(style.name);
  }
}

String formatStylePreferenceLabel(StylePreference preference) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (preference) {
        case StylePreference.feminine:
          return 'Женственный';
        case StylePreference.masculine:
          return 'Маскулинный';
        case StylePreference.neutral:
          return 'Нейтральный';
        case StylePreference.modest:
          return 'Сдержанный';
        case StylePreference.expressive:
          return 'Выразительный';
      }
    case 'kk':
      switch (preference) {
        case StylePreference.feminine:
          return 'Нәзік';
        case StylePreference.masculine:
          return 'Батыл';
        case StylePreference.neutral:
          return 'Бейтарап';
        case StylePreference.modest:
          return 'Ұстамды';
        case StylePreference.expressive:
          return 'Айқын';
      }
    default:
      return AppConstants.stylePreferenceLabels[preference] ??
          titleCase(preference.name);
  }
}

String formatColorLabel(String colorName) {
  switch (colorName) {
    case 'Soft Navy':
      return localizedText(
        en: 'Soft Navy',
        ru: 'Мягкий тёмно-синий',
        kk: 'Жұмсақ қою көк',
      );
    case 'Muted Blue':
      return localizedText(
        en: 'Muted Blue',
        ru: 'Приглушённый синий',
        kk: 'Бәсең көк',
      );
    case 'Powder Blue':
      return localizedText(
        en: 'Powder Blue',
        ru: 'Пудрово-голубой',
        kk: 'Ақшыл көк',
      );
    case 'White':
      return localizedText(en: 'White', ru: 'Белый', kk: 'Ақ');
    case 'Warm White':
      return localizedText(
        en: 'Warm White',
        ru: 'Тёплый белый',
        kk: 'Жылы ақ',
      );
    case 'Cool Gray':
      return localizedText(
        en: 'Cool Gray',
        ru: 'Холодный серый',
        kk: 'Салқын сұр',
      );
    case 'Lavender Gray':
      return localizedText(
        en: 'Lavender Gray',
        ru: 'Лавандово-серый',
        kk: 'Лаванда сұр',
      );
    case 'Black':
    case 'Jet Black':
      return localizedText(en: 'Black', ru: 'Чёрный', kk: 'Қара');
    case 'Denim':
      return localizedText(en: 'Denim', ru: 'Деним', kk: 'Деним');
    case 'Camel':
      return localizedText(en: 'Camel', ru: 'Кэмел', kk: 'Кэмел');
    case 'Olive':
      return localizedText(en: 'Olive', ru: 'Оливковый', kk: 'Зәйтүн');
    case 'Blush':
      return localizedText(
          en: 'Blush', ru: 'Пудровый розовый', kk: 'Ақшыл қызғылт');
    case 'Warm Ivory':
      return localizedText(
          en: 'Warm Ivory', ru: 'Тёплая слоновая кость', kk: 'Жылы піл сүйегі');
    case 'Soft White':
      return localizedText(
          en: 'Soft White', ru: 'Мягкий белый', kk: 'Жұмсақ ақ');
    case 'Charcoal':
      return localizedText(en: 'Charcoal', ru: 'Графитовый', kk: 'Графит');
    case 'Taupe':
      return localizedText(en: 'Taupe', ru: 'Тауп', kk: 'Тауп');
    case 'Emerald':
      return localizedText(en: 'Emerald', ru: 'Изумрудный', kk: 'Зүбәржат');
    case 'Gold':
      return localizedText(en: 'Gold', ru: 'Золотой', kk: 'Алтын');
    default:
      return colorName;
  }
}

String formatWardrobeItemName(String name) {
  switch (name) {
    case 'Ivory Soft Blazer':
      return localizedText(
        en: 'Ivory Soft Blazer',
        ru: 'Мягкий блейзер айвори',
        kk: 'Айвори жұмсақ блейзер',
      );
    case 'Jet Black Fitted Top':
      return localizedText(
        en: 'Jet Black Fitted Top',
        ru: 'Приталенный чёрный топ',
        kk: 'Қынама қара топ',
      );
    case 'White Weekend Tee':
      return localizedText(
        en: 'White Weekend Tee',
        ru: 'Белая футболка на выходные',
        kk: 'Демалысқа арналған ақ футболка',
      );
    case 'White Tailored Pants':
      return localizedText(
        en: 'White Tailored Pants',
        ru: 'Белые брюки строгого кроя',
        kk: 'Ақ классикалық шалбар',
      );
    case 'Charcoal Column Trousers':
      return localizedText(
        en: 'Charcoal Column Trousers',
        ru: 'Графитовые прямые брюки',
        kk: 'Графит түзу шалбар',
      );
    case 'City Leather Jacket':
      return localizedText(
        en: 'City Leather Jacket',
        ru: 'Городская кожаная куртка',
        kk: 'Қалалық былғары күрте',
      );
    case 'Sculptural Taupe Jacket':
      return localizedText(
        en: 'Sculptural Taupe Jacket',
        ru: 'Архитектурная куртка тауп',
        kk: 'Сәулетті тауп күрте',
      );
    case 'Emerald Statement Dress':
      return localizedText(
        en: 'Emerald Statement Dress',
        ru: 'Акцентное изумрудное платье',
        kk: 'Айшықты зүбәржат көйлек',
      );
    case 'White Platform Sneakers':
      return localizedText(
        en: 'White Platform Sneakers',
        ru: 'Белые кеды на платформе',
        kk: 'Ақ платформа кроссовкасы',
      );
    case 'Olive Mini Kelly Bag':
      return localizedText(
        en: 'Olive Mini Kelly Bag',
        ru: 'Оливковая мини-сумка Келли',
        kk: 'Зәйтүн түсті Келли шағын сөмкесі',
      );
    case 'Minimal Black Sunglasses':
      return localizedText(
        en: 'Minimal Black Sunglasses',
        ru: 'Минималистичные чёрные очки',
        kk: 'Минимал қара көзілдірік',
      );
    case 'Gold Chain Necklace':
      return localizedText(
        en: 'Gold Chain Necklace',
        ru: 'Золотая цепочка',
        kk: 'Алтын шынжыр алқа',
      );
    case 'Tailored Camel Blazer':
      return localizedText(
        en: 'Tailored Camel Blazer',
        ru: 'Кэмел-блейзер строгого кроя',
        kk: 'Кэмел классикалық блейзері',
      );
    case 'Soft Satin Slip Dress':
      return localizedText(
        en: 'Soft Satin Slip Dress',
        ru: 'Нежное сатиновое платье-комбинация',
        kk: 'Жұмсақ атлас комбинация көйлек',
      );
    case 'Studio Mini Bag':
      return localizedText(
        en: 'Studio Mini Bag',
        ru: 'Студийная мини-сумка',
        kk: 'Студиялық мини сөмке',
      );
    case 'Rain-Ready Sneakers':
      return localizedText(
        en: 'Rain-Ready Sneakers',
        ru: 'Кроссовки для дождливой погоды',
        kk: 'Жаңбырға лайық кроссовка',
      );
    case 'Everyday Gold Necklace':
      return localizedText(
        en: 'Everyday Gold Necklace',
        ru: 'Золотое колье на каждый день',
        kk: 'Күнделікті алтын алқа',
      );
    case 'Utility Layer Jacket':
      return localizedText(
        en: 'Utility Layer Jacket',
        ru: 'Утилитарная куртка для слоёв',
        kk: 'Қабаттауға арналған утилитарлық күрте',
      );
    case 'Everyday Cotton Shirt':
      return localizedText(
        en: 'Everyday Cotton Shirt',
        ru: 'Хлопковая рубашка на каждый день',
        kk: 'Күнделікті мақта жейде',
      );
    case 'Breathable Linen Trousers':
      return localizedText(
        en: 'Breathable Linen Trousers',
        ru: 'Дышащие льняные брюки',
        kk: 'Ауа өткізетін зығыр шалбар',
      );
    default:
      return name;
  }
}

String canonicalWardrobeItemName(String value) {
  const localizedToCanonical = <String, String>{
    'мягкий блейзер айвори': 'Ivory Soft Blazer',
    'айвори жұмсақ блейзер': 'Ivory Soft Blazer',
    'приталенный чёрный топ': 'Jet Black Fitted Top',
    'қынама қара топ': 'Jet Black Fitted Top',
    'белая футболка на выходные': 'White Weekend Tee',
    'демалысқа арналған ақ футболка': 'White Weekend Tee',
    'белые брюки строгого кроя': 'White Tailored Pants',
    'ақ классикалық шалбар': 'White Tailored Pants',
    'графитовые прямые брюки': 'Charcoal Column Trousers',
    'графит түзу шалбар': 'Charcoal Column Trousers',
    'городская кожаная куртка': 'City Leather Jacket',
    'қалалық былғары күрте': 'City Leather Jacket',
    'архитектурная куртка тауп': 'Sculptural Taupe Jacket',
    'сәулетті тауп күрте': 'Sculptural Taupe Jacket',
    'акцентное изумрудное платье': 'Emerald Statement Dress',
    'айшықты зүбәржат көйлек': 'Emerald Statement Dress',
    'белые кеды на платформе': 'White Platform Sneakers',
    'ақ платформа кроссовкасы': 'White Platform Sneakers',
    'оливковая мини-сумка kelly': 'Olive Mini Kelly Bag',
    'оливковая мини-сумка келли': 'Olive Mini Kelly Bag',
    'зәйтүн түсті kelly мини сөмкесі': 'Olive Mini Kelly Bag',
    'зәйтүн түсті келли шағын сөмкесі': 'Olive Mini Kelly Bag',
    'минималистичные чёрные очки': 'Minimal Black Sunglasses',
    'минимал қара көзілдірік': 'Minimal Black Sunglasses',
    'золотая цепочка': 'Gold Chain Necklace',
    'алтын шынжыр алқа': 'Gold Chain Necklace',
    'кэмел-блейзер строгого кроя': 'Tailored Camel Blazer',
    'кэмел классикалық блейзері': 'Tailored Camel Blazer',
    'нежное сатиновое платье-комбинация': 'Soft Satin Slip Dress',
    'жұмсақ атлас комбинация көйлек': 'Soft Satin Slip Dress',
    'студийная мини-сумка': 'Studio Mini Bag',
    'студиялық мини сөмке': 'Studio Mini Bag',
    'кроссовки для дождливой погоды': 'Rain-Ready Sneakers',
    'жаңбырға лайық кроссовка': 'Rain-Ready Sneakers',
    'золотое колье на каждый день': 'Everyday Gold Necklace',
    'күнделікті алтын алқа': 'Everyday Gold Necklace',
    'утилитарная куртка для слоёв': 'Utility Layer Jacket',
    'қабаттауға арналған утилитарлық күрте': 'Utility Layer Jacket',
    'хлопковая рубашка на каждый день': 'Everyday Cotton Shirt',
    'күнделікті мақта жейде': 'Everyday Cotton Shirt',
    'дышащие льняные брюки': 'Breathable Linen Trousers',
    'ауа өткізетін зығыр шалбар': 'Breathable Linen Trousers',
  };

  return localizedToCanonical[value.trim().toLowerCase()] ?? value;
}

String formatWardrobeTagLabel(String tag) {
  switch (tag.toLowerCase()) {
    case 'casual':
      return localizedText(en: 'Casual', ru: 'Повседневно', kk: 'Күнделікті');
    case 'formal':
      return localizedText(en: 'Formal', ru: 'Формально', kk: 'Ресми');
    case 'sporty':
      return localizedText(en: 'Sporty', ru: 'Спортивно', kk: 'Спорттық');
    case 'cozy':
      return localizedText(en: 'Cozy', ru: 'Уютно', kk: 'Жайлы');
    case 'college':
      return localizedText(en: 'College', ru: 'Учёба', kk: 'Оқу');
    case 'weekend':
      return localizedText(en: 'Weekend', ru: 'Выходные', kk: 'Демалыс');
    case 'office':
      return localizedText(en: 'Office', ru: 'Офис', kk: 'Кеңсе');
    case 'smart casual':
      return localizedText(
          en: 'Smart casual', ru: 'Смарт-кэжуал', kk: 'Смарт-кэжуал');
    case 'rainy day':
      return localizedText(
          en: 'Rainy day', ru: 'Дождливый день', kk: 'Жаңбырлы күн');
    case 'minimal':
      return localizedText(en: 'Minimal', ru: 'Минимализм', kk: 'Минимал');
    case 'layering':
      return localizedText(
          en: 'Layering', ru: 'Многослойность', kk: 'Қабаттау');
    case 'work':
      return localizedText(en: 'Work', ru: 'Работа', kk: 'Жұмыс');
    case 'meeting':
      return localizedText(en: 'Meeting', ru: 'Встреча', kk: 'Кездесу');
    case 'date':
      return localizedText(en: 'Date', ru: 'Свидание', kk: 'Кездесу');
    case 'night out':
      return localizedText(
          en: 'Night out', ru: 'Вечерний выход', kk: 'Кешкі шығу');
    case 'clean look':
      return localizedText(
          en: 'Clean look', ru: 'Чистый образ', kk: 'Таза образ');
    case 'evening':
      return localizedText(en: 'Evening', ru: 'Вечер', kk: 'Кеш');
    case 'travel':
      return localizedText(en: 'Travel', ru: 'Поездка', kk: 'Сапар');
    case 'editorial':
      return localizedText(
          en: 'Editorial', ru: 'Редакционный стиль', kk: 'Редакциялық стиль');
    case 'statement':
      return localizedText(en: 'Statement', ru: 'Акцентный', kk: 'Акцентті');
    case 'party':
      return localizedText(en: 'Party', ru: 'Вечеринка', kk: 'Кеш');
    case 'event':
      return localizedText(en: 'Event', ru: 'Событие', kk: 'Іс-шара');
    case 'sunny':
      return localizedText(en: 'Sunny', ru: 'Солнечно', kk: 'Күн ашық');
    case 'premium':
      return localizedText(en: 'Premium', ru: 'Premium', kk: 'Premium');
    case 'dinner':
      return localizedText(en: 'Dinner', ru: 'Ужин', kk: 'Кешкі ас');
    case 'hot weather':
      return localizedText(
          en: 'Hot weather', ru: 'Жаркая погода', kk: 'Ыстық ауа райы');
    case 'generated':
      return localizedText(
          en: 'Generated', ru: 'Сгенерировано', kk: 'Жасалған');
    default:
      return titleCase(tag);
  }
}

String canonicalWardrobeTag(String value) {
  final normalized = value.trim().toLowerCase();
  const localizedToCanonical = <String, String>{
    'повседневно': 'casual',
    'күнделікті': 'casual',
    'формально': 'formal',
    'ресми': 'formal',
    'спортивно': 'sporty',
    'спорттық': 'sporty',
    'уютно': 'cozy',
    'жайлы': 'cozy',
    'учёба': 'college',
    'оқу': 'college',
    'выходные': 'weekend',
    'демалыс': 'weekend',
    'офис': 'office',
    'кеңсе': 'office',
    'смарт-кэжуал': 'smart casual',
    'дождливый день': 'rainy day',
    'жаңбырлы күн': 'rainy day',
    'минимализм': 'minimal',
    'минимал': 'minimal',
    'многослойность': 'layering',
    'қабаттау': 'layering',
    'работа': 'work',
    'жұмыс': 'work',
    'встреча': 'meeting',
    'кездесу': 'meeting',
    'свидание': 'date',
    'вечерний выход': 'night out',
    'кешкі шығу': 'night out',
    'чистый образ': 'clean look',
    'таза образ': 'clean look',
    'вечер': 'evening',
    'кеш': 'evening',
    'поездка': 'travel',
    'сапар': 'travel',
    'редакционный стиль': 'editorial',
    'редакциялық стиль': 'editorial',
    'акцентный': 'statement',
    'акцентті': 'statement',
    'вечеринка': 'party',
    'событие': 'event',
    'іс-шара': 'event',
    'солнечно': 'sunny',
    'күн ашық': 'sunny',
    'ужин': 'dinner',
    'кешкі ас': 'dinner',
    'жаркая погода': 'hot weather',
    'ыстық ауа райы': 'hot weather',
    'сгенерировано': 'generated',
    'жасалған': 'generated',
  };

  return localizedToCanonical[normalized] ?? value.trim();
}

String formatWeekDayLabel(int dayIndex) {
  const english = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const russian = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];
  const kazakh = [
    'Дүйсенбі',
    'Сейсенбі',
    'Сәрсенбі',
    'Бейсенбі',
    'Жұма',
    'Сенбі',
    'Жексенбі',
  ];

  final values = switch (currentLanguageCode()) {
    'ru' => russian,
    'kk' => kazakh,
    _ => english,
  };

  return values[dayIndex.clamp(0, values.length - 1)];
}

String formatShortWeekDayLabel(int dayIndex) {
  const english = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const russian = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  const kazakh = ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жс'];

  final values = switch (currentLanguageCode()) {
    'ru' => russian,
    'kk' => kazakh,
    _ => english,
  };

  return values[dayIndex.clamp(0, values.length - 1)];
}

String joinWithDot(Iterable<String> values) {
  return values.where((value) => value.trim().isNotEmpty).join(' • ');
}

Color colorFromName(String colorName) {
  return AppConstants.colorMap[colorName] ?? const Color(0xFFD9DDEB);
}

String friendlyRemainingCount(int value, String noun) {
  switch (currentLanguageCode()) {
    case 'ru':
      switch (noun) {
        case 'question':
          if (value <= 0) return 'Сегодня вопросы закончились';
          if (value == 1) return 'Остался 1 вопрос на сегодня';
          return 'Осталось $value вопросов на сегодня';
        case 'generation':
          if (value <= 0) return 'Сегодня генерации закончились';
          if (value == 1) return 'Осталась 1 генерация на сегодня';
          return 'Осталось $value генераций на сегодня';
        case 'smart plan':
          if (value <= 0) return 'Сегодня лимит умного планера исчерпан';
          if (value == 1) return 'Остался 1 умный план на сегодня';
          return 'Осталось $value умных планов на сегодня';
      }
      return _englishRemainingCount(value, noun);
    case 'kk':
      switch (noun) {
        case 'question':
          if (value <= 0) return 'Бүгінгі сұрақ лимиті бітті';
          if (value == 1) return 'Бүгін 1 сұрақ қалды';
          return 'Бүгін $value сұрақ қалды';
        case 'generation':
          if (value <= 0) return 'Бүгінгі генерация лимиті бітті';
          if (value == 1) return 'Бүгін 1 генерация қалды';
          return 'Бүгін $value генерация қалды';
        case 'smart plan':
          if (value <= 0) return 'Бүгінгі ақылды жоспарлау лимиті бітті';
          if (value == 1) return 'Бүгін 1 ақылды жоспар қалды';
          return 'Бүгін $value ақылды жоспар қалды';
      }
      return _englishRemainingCount(value, noun);
    default:
      return _englishRemainingCount(value, noun);
  }
}

String _englishRemainingCount(int value, String noun) {
  if (value <= 0) {
    return 'No $noun left today';
  }
  if (value == 1) {
    return '1 $noun left today';
  }
  return '$value ${noun == 'question' ? 'questions' : noun == 'generation' ? 'generations' : 'smart plans'} left today';
}

bool isToday(DateTime value) {
  final now = DateTime.now();
  return now.year == value.year &&
      now.month == value.month &&
      now.day == value.day;
}

DateTime normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int weekDayIndexForDate(DateTime value) {
  return value.weekday - 1;
}

String initialsForName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'IC';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
