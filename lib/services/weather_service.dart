import '../core/app_constants.dart';
import '../core/app_enums.dart';
import '../core/app_utils.dart';
import '../models/weather_snapshot.dart';

class WeatherService {
  WeatherSnapshot buildSnapshot({
    required WeatherCondition condition,
    String city = '',
    DateTime? updatedAt,
    int? temperatureCelsius,
  }) {
    final actualTemperature =
        temperatureCelsius ?? _temperatureForCondition(condition);
    return WeatherSnapshot(
      condition: condition,
      temperatureCelsius: actualTemperature,
      feelsLikeCelsius: actualTemperature + _feelsLikeOffset(condition),
      windKph: _windForCondition(condition),
      city: city,
      summary: summaryForCondition(condition),
      styleSuggestion: styleSuggestionForCondition(condition),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  WeatherSnapshot refreshForCity(String city) {
    final now = DateTime.now();
    final cityKey = city.trim().toLowerCase().isEmpty
        ? 'i-closet'
        : city.trim().toLowerCase();
    final hourBucket = now.hour ~/ AppConstants.weatherRefreshWindowHours;
    final key = '$cityKey-${now.year}-${now.month}-${now.day}-$hourBucket';
    final seed = key.hashCode.abs();
    final index = seed % WeatherCondition.values.length;
    final condition = WeatherCondition.values[index];
    final temperature = _temperatureForCondition(condition) + (seed % 3) - 1;
    return buildSnapshot(
      condition: condition,
      city: city,
      updatedAt: now,
      temperatureCelsius: temperature,
    );
  }

  bool shouldRefreshStored(
    WeatherSnapshot? snapshot, {
    required String city,
  }) {
    if (snapshot == null) {
      return true;
    }

    final trimmedCity = city.trim();
    if (trimmedCity.isNotEmpty && snapshot.city.trim() != trimmedCity) {
      return true;
    }

    final now = DateTime.now();
    if (!isToday(snapshot.updatedAt)) {
      return true;
    }

    return now.difference(snapshot.updatedAt).inHours >=
        AppConstants.weatherRefreshWindowHours;
  }

  String summaryForCondition(WeatherCondition condition) {
    return AppConstants.weatherDescriptionFor(condition);
  }

  String styleSuggestionForCondition(WeatherCondition condition) {
    switch (currentLanguageCode()) {
      case 'ru':
        switch (condition) {
          case WeatherCondition.sunny:
            return 'Лучше всего подойдут дышащий верх, лёгкие слои и удобная обувь.';
          case WeatherCondition.cloudy:
            return 'Добавьте лёгкий верхний слой и удобную закрытую обувь.';
          case WeatherCondition.rainy:
            return 'Сделайте ставку на практичные слои, надёжную сумку и обувь, подходящую для мокрых улиц.';
          case WeatherCondition.cold:
            return 'Выберите тёплый слой, закрытую обувь и вещи, которые сохраняют собранный силуэт.';
          case WeatherCondition.hot:
            return 'Подойдут лёгкие ткани, светлые оттенки и минимум слоёв.';
          case WeatherCondition.windy:
            return 'Устойчивые слои и структурные вещи помогут чувствовать себя комфортно на ветру.';
        }
      case 'kk':
        switch (condition) {
          case WeatherCondition.sunny:
            return 'Дем алатын үстіңгі киім, жеңіл қабаттар және ыңғайлы аяқ киім ең жақсы таңдау болады.';
          case WeatherCondition.cloudy:
            return 'Жеңіл сыртқы қабат пен жабық аяқ киім ыңғайлы болады.';
          case WeatherCondition.rainy:
            return 'Практикалық қабаттар, сенімді сөмке және дымқыл көшеге лайық аяқ киім таңдаңыз.';
          case WeatherCondition.cold:
            return 'Жылы қабат, жабық аяқ киім және жинақы силуэтті сақтайтын заттар жақсы жарасады.';
          case WeatherCondition.hot:
            return 'Жеңіл маталар, ашық түстер және аз қабат жақсы жұмыс істейді.';
          case WeatherCondition.windy:
            return 'Бекітілген қабаттар мен құрылымды заттар желде ыңғайлы сақтайды.';
        }
      default:
        switch (condition) {
          case WeatherCondition.sunny:
            return 'A breathable top, relaxed layers, and comfortable shoes will feel best today.';
          case WeatherCondition.cloudy:
            return 'A light outer layer and easy closed shoes would be a smart choice today.';
          case WeatherCondition.rainy:
            return 'Lean into practical layers, a dependable bag, and shoes that handle wet streets well.';
          case WeatherCondition.cold:
            return 'Go for a warmer layer, closed shoes, and pieces that keep the silhouette polished.';
          case WeatherCondition.hot:
            return 'Choose airy fabrics, lighter colors, and a simpler outfit with fewer layers.';
          case WeatherCondition.windy:
            return 'Secure layers and structured pieces will keep the outfit comfortable through the breeze.';
        }
    }
  }

  String buildGuidance({
    required WeatherSnapshot snapshot,
    DailyOccasion? occasion,
  }) {
    final city = snapshot.city.trim();
    final temp = snapshot.temperatureCelsius;

    final weatherLine = switch (currentLanguageCode()) {
      'ru' => _russianGuidance(snapshot.condition, city, temp),
      'kk' => _kazakhGuidance(snapshot.condition, city, temp),
      _ => _englishGuidance(snapshot.condition, city, temp),
    };

    if (occasion == null) {
      return weatherLine;
    }

    final occasionLine = switch (currentLanguageCode()) {
      'ru' => _russianOccasionLine(snapshot.condition, occasion),
      'kk' => _kazakhOccasionLine(snapshot.condition, occasion),
      _ => _englishOccasionLine(snapshot.condition, occasion),
    };

    return '$weatherLine $occasionLine';
  }

  String _englishGuidance(
    WeatherCondition condition,
    String city,
    int temperature,
  ) {
    final prefix = city.isEmpty ? '' : 'In $city, ';
    switch (condition) {
      case WeatherCondition.cloudy:
        return '${prefix}it’s cloudy and $temperature°C, so a light jacket and easy layering make a smart choice.';
      case WeatherCondition.sunny:
        return '${prefix}it’s sunny and $temperature°C, so lighter layers and breathable textures will feel most comfortable.';
      case WeatherCondition.rainy:
        return '${prefix}it’s rainy and $temperature°C, so practical outerwear and dependable shoes are the best call.';
      case WeatherCondition.cold:
        return '${prefix}it feels cold at $temperature°C, so warm layers with structured pieces keep the look polished.';
      case WeatherCondition.hot:
        return '${prefix}it’s hot at $temperature°C, so lighter fabrics and a relaxed silhouette work best.';
      case WeatherCondition.windy:
        return '${prefix}it’s windy and $temperature°C, so secure layers and easy movement are key.';
    }
  }

  String _russianGuidance(
    WeatherCondition condition,
    String city,
    int temperature,
  ) {
    final prefix = city.isEmpty ? '' : '$city — ';
    switch (condition) {
      case WeatherCondition.cloudy:
        return '$prefixоблачно, $temperature°C, поэтому лучше выбрать лёгкую куртку и продуманную многослойность.';
      case WeatherCondition.sunny:
        return '$prefixсолнечно, $temperature°C, поэтому лучше всего подойдут лёгкие слои и дышащие ткани.';
      case WeatherCondition.rainy:
        return '$prefixдождливо, $temperature°C, поэтому стоит выбрать практичную верхнюю одежду и надёжную обувь.';
      case WeatherCondition.cold:
        return '$prefixпрохладно, $temperature°C, поэтому тёплые слои и более собранные вещи будут особенно уместны.';
      case WeatherCondition.hot:
        return '$prefixжарко, $temperature°C, поэтому лучше остановиться на лёгких тканях и более свободном силуэте.';
      case WeatherCondition.windy:
        return '$prefixветрено, $temperature°C, поэтому важны устойчивые слои и удобство в движении.';
    }
  }

  String _kazakhGuidance(
    WeatherCondition condition,
    String city,
    int temperature,
  ) {
    final prefix = city.isEmpty ? '' : '$city — ';
    switch (condition) {
      case WeatherCondition.cloudy:
        return '$prefixбұлтты, $temperature°C, сондықтан жеңіл күрте мен қабаттап киіну жақсы таңдау болады.';
      case WeatherCondition.sunny:
        return '$prefixкүн ашық, $temperature°C, сондықтан жеңіл қабаттар мен дем алатын маталар ыңғайлырақ.';
      case WeatherCondition.rainy:
        return '$prefixжаңбырлы, $temperature°C, сондықтан практикалық сырт киім мен сенімді аяқ киім дұрыс болады.';
      case WeatherCondition.cold:
        return '$prefixсалқын, $temperature°C, сондықтан жылы қабаттар мен жинақы заттар жақсы үйлеседі.';
      case WeatherCondition.hot:
        return '$prefixыстық, $temperature°C, сондықтан жеңіл маталар мен еркіндеу силуэт тиімді.';
      case WeatherCondition.windy:
        return '$prefixжелді, $temperature°C, сондықтан бекітілген қабаттар мен қимылға ыңғайлы заттар маңызды.';
    }
  }

  String _englishOccasionLine(
    WeatherCondition condition,
    DailyOccasion occasion,
  ) {
    return switch ((condition, occasion)) {
      (WeatherCondition.cloudy, DailyOccasion.college) =>
        'Since you’re headed to college, the look should stay layered and effortless.',
      (WeatherCondition.rainy, DailyOccasion.work) =>
        'For work, choose pieces that feel polished while still handling the wet weather.',
      (WeatherCondition.cold, DailyOccasion.meeting) =>
        'For a meeting, a structured outfit will keep you warm and confident.',
      (WeatherCondition.sunny, DailyOccasion.date) =>
        'For a sunny date, lean into lighter pieces with a refined finish.',
      _ =>
        'Because your plan is ${formatDailyOccasionLabel(occasion).toLowerCase()}, the outfit should balance comfort, practicality, and a polished feel.',
    };
  }

  String _russianOccasionLine(
    WeatherCondition condition,
    DailyOccasion occasion,
  ) {
    return switch ((condition, occasion)) {
      (WeatherCondition.cloudy, DailyOccasion.college) =>
        'Для учёбы стоит сохранить лёгкую многослойность и непринуждённое ощущение образа.',
      (WeatherCondition.rainy, DailyOccasion.work) =>
        'Для работы лучше выбрать более собранные вещи, которые спокойно выдержат дождливую погоду.',
      (WeatherCondition.cold, DailyOccasion.meeting) =>
        'Для встречи подойдёт структурный образ, который сохранит тепло и уверенность.',
      (WeatherCondition.sunny, DailyOccasion.date) =>
        'Для солнечного свидания лучше выбрать лёгкие вещи с аккуратным, чуть более изящным настроением.',
      _ =>
        'Так как у вас планируется ${formatDailyOccasionLabel(occasion).toLowerCase()}, образу важно сохранить баланс между комфортом, практичностью и аккуратной подачей.',
    };
  }

  String _kazakhOccasionLine(
    WeatherCondition condition,
    DailyOccasion occasion,
  ) {
    return switch ((condition, occasion)) {
      (WeatherCondition.cloudy, DailyOccasion.college) =>
        'Оқуға бара жатсаңыз, образды қабаттап, бірақ еркін күйде ұстаған дұрыс.',
      (WeatherCondition.rainy, DailyOccasion.work) =>
        'Жұмысқа арналған образ жинақы болып, жаңбырлы ауа райына да сай болуы керек.',
      (WeatherCondition.cold, DailyOccasion.meeting) =>
        'Кездесуге жылы әрі сенімді көрінетін құрылымды образ жақсы жарасады.',
      (WeatherCondition.sunny, DailyOccasion.date) =>
        'Күн ашық кездесуге жеңіл әрі ұқыпты әрленген заттар лайық.',
      _ =>
        '${formatDailyOccasionLabel(occasion).toLowerCase()} жоспарына сай образ жайлылық, практикалық және жинақылықтың тепе-теңдігін сақтауы керек.',
    };
  }

  int _temperatureForCondition(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 24;
      case WeatherCondition.cloudy:
        return 18;
      case WeatherCondition.rainy:
        return 15;
      case WeatherCondition.cold:
        return 8;
      case WeatherCondition.hot:
        return 29;
      case WeatherCondition.windy:
        return 17;
    }
  }

  int _feelsLikeOffset(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
      case WeatherCondition.hot:
        return 1;
      case WeatherCondition.rainy:
      case WeatherCondition.windy:
      case WeatherCondition.cold:
        return -1;
      case WeatherCondition.cloudy:
        return 0;
    }
  }

  int _windForCondition(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 10;
      case WeatherCondition.cloudy:
        return 13;
      case WeatherCondition.rainy:
        return 17;
      case WeatherCondition.cold:
        return 15;
      case WeatherCondition.hot:
        return 9;
      case WeatherCondition.windy:
        return 24;
    }
  }
}
