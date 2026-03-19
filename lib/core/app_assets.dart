import '../models/marketplace_suggestion.dart';
import 'app_enums.dart';
import 'app_utils.dart';

class AppAssets {
  AppAssets._();

  static const logo = 'assets/images/logo.png';

  static const _clothes = 'assets/images/clothes';
  static const _marketplace = 'assets/images/marketplace';

  static const ivoryBlazer = '$_clothes/top_portrait.jpg';
  static const blackFittedTop = '$_clothes/top_profile.jpg';
  static const weekendTee = '$_clothes/top_summer.jpg';
  static const whiteTailoredPants = '$_clothes/pants_white.jpg';
  static const charcoalTrousers = '$_clothes/pants_paris_week.jpg';
  static const cityLeatherJacket = '$_clothes/jacket_emmanuelle.jpg';
  static const sculpturalJacket = '$_clothes/jacket_rick_owens.jpg';
  static const emeraldDress = '$_clothes/dress_green.jpg';
  static const whiteSneakers = '$_clothes/shoes_sneakers.jpg';
  static const oliveBag = '$_clothes/bag_kelly.jpg';
  static const blackSunglasses = '$_clothes/accessory_sunglasses.jpg';
  static const goldNecklace = '$_clothes/accessory_necklace.jpg';

  static const partnerBlazer = '$_marketplace/blazer_partner.jpg';
  static const partnerDress = '$_marketplace/dress_partner.jpg';
  static const partnerBag = '$_marketplace/bag_partner.jpg';
  static const partnerSneakers = '$_marketplace/sneakers_partner.jpg';
  static const partnerNecklace = '$_marketplace/necklace_partner.jpg';
  static const partnerLayer = '$_marketplace/layer_partner.jpg';
  static const partnerTop = '$_marketplace/top_partner.jpg';
  static const partnerTrousers = '$_marketplace/trouser_partner.jpg';

  static List<MarketplaceSuggestion> get partnerPreviewItems {
    return [
      MarketplaceSuggestion(
        brand: 'COS',
        title: localizedText(
          en: 'Structured Blazer',
          ru: 'Структурный блейзер',
          kk: 'Құрылымды блейзер',
        ),
        priceLabel: '\$190',
        reason: localizedText(
          en: 'Sharpens a meeting or work look without overpowering the rest of the outfit.',
          ru: 'Делает рабочий или деловой образ более собранным, не перегружая его.',
          kk: 'Жұмыс не кездесу образын артық ауырлатпай, жинақы етіп көрсетеді.',
        ),
        imageUrl: partnerBlazer,
      ),
      MarketplaceSuggestion(
        brand: 'Reformation',
        title: localizedText(
          en: 'Soft Satin Slip Dress',
          ru: 'Атласное платье-комбинация',
          kk: 'Жұмсақ атлас комбинация көйлек',
        ),
        priceLabel: '\$218',
        reason: localizedText(
          en: 'Adds an elevated date-night option with a softer, more polished mood.',
          ru: 'Добавляет более утончённый вариант для свидания или вечернего выхода.',
          kk: 'Кездесу не кешкі жоспарға нәзік әрі сәнді нұсқа береді.',
        ),
        imageUrl: partnerDress,
      ),
      MarketplaceSuggestion(
        brand: 'Charles & Keith',
        title: localizedText(
          en: 'Studio Mini Bag',
          ru: 'Студийная мини-сумка',
          kk: 'Студиялық шағын сөмке',
        ),
        priceLabel: '\$79',
        reason: localizedText(
          en: 'Gives everyday looks a cleaner finish when your wardrobe needs a sharper bag.',
          ru: 'Освежает повседневный образ, когда нужен более собранный акцент в виде сумки.',
          kk: 'Гардеробқа жинақырақ сөмке керек кезде күнделікті образды толықтырады.',
        ),
        imageUrl: partnerBag,
      ),
      MarketplaceSuggestion(
        brand: 'Veja',
        title: localizedText(
          en: 'Water-Friendly Sneakers',
          ru: 'Кроссовки для влажной погоды',
          kk: 'Ылғалды ауа райына арналған кроссовка',
        ),
        priceLabel: '\$140',
        reason: localizedText(
          en: 'A practical add-in for rainy or travel days when comfort matters most.',
          ru: 'Практичная пара для дождливых дней и поездок, когда особенно важен комфорт.',
          kk: 'Жаңбырлы не жолға шыққан күнге ыңғайлы, жайлылық маңызды болғанда жақсы таңдау.',
        ),
        imageUrl: partnerSneakers,
      ),
      MarketplaceSuggestion(
        brand: 'Mejuri',
        title: localizedText(
          en: 'Gold Chain Necklace',
          ru: 'Золотая цепочка',
          kk: 'Алтын түсті тізбек алқа',
        ),
        priceLabel: '\$98',
        reason: localizedText(
          en: 'Adds a quiet premium accent when the outfit needs a little more finish.',
          ru: 'Добавляет деликатный премиальный акцент, когда образу не хватает завершённости.',
          kk: 'Образға аздап айқындық керек кезде нәзік премиум акцент қосады.',
        ),
        imageUrl: partnerNecklace,
      ),
      MarketplaceSuggestion(
        brand: 'Massimo Dutti',
        title: localizedText(
          en: 'Utility Layer Jacket',
          ru: 'Лёгкая утилитарная куртка',
          kk: 'Жеңіл утилитарлық қабат күртесі',
        ),
        priceLabel: '\$128',
        reason: localizedText(
          en: 'Fills layering gaps for cooler weather or mixed-temperature travel plans.',
          ru: 'Закрывает потребность в слоях для прохладной погоды и поездок с переменной температурой.',
          kk: 'Салқын күндерге не ауа райы құбылмалы сапарларға қабат ретінде жақсы жарайды.',
        ),
        imageUrl: partnerLayer,
      ),
    ];
  }

  static List<String> categoryAssets(ClothingCategory category) {
    switch (category) {
      case ClothingCategory.tops:
        return const [blackFittedTop, weekendTee];
      case ClothingCategory.bottoms:
        return const [charcoalTrousers, whiteTailoredPants];
      case ClothingCategory.outerwear:
        return const [ivoryBlazer, cityLeatherJacket, sculpturalJacket];
      case ClothingCategory.dresses:
        return const [emeraldDress];
      case ClothingCategory.shoes:
        return const [whiteSneakers];
      case ClothingCategory.bags:
        return const [oliveBag];
      case ClothingCategory.accessories:
        return const [blackSunglasses, goldNecklace];
    }
  }

  static String fallbackAssetForCategory(
    ClothingCategory category, {
    int seed = 0,
  }) {
    final options = categoryAssets(category);
    return options[seed % options.length];
  }
}
