import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/wardrobe_item.dart';
import '../models/weather_snapshot.dart';

abstract class AiService {
  String intro({String? name});

  Future<String> buildReply({
    required String userId,
    required String prompt,
    required List<ChatMessage> history,
    required List<WardrobeItem> items,
    required bool premium,
    required bool plus,
    UserProfile? profile,
    WeatherSnapshot? weather,
  });
}
