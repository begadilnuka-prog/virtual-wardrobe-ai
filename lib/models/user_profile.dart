import '../core/app_constants.dart';
import '../core/app_enums.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.favoriteStyle,
    required this.preferredColors,
    required this.updatedAt,
    this.profilePhotoPath,
    this.stylePreference = StylePreference.neutral,
    this.city = '',
  });

  final String userId;
  final String name;
  final String email;
  final String? profilePhotoPath;
  final StyleTag favoriteStyle;
  final List<String> preferredColors;
  final StylePreference stylePreference;
  final String city;
  final DateTime updatedAt;

  factory UserProfile.fallback({
    required String userId,
    required String name,
    required String email,
  }) {
    return UserProfile(
      userId: userId,
      name: name,
      email: email,
      favoriteStyle: StyleTag.smartCasual,
      preferredColors: AppConstants.preferredColorDefaults,
      updatedAt: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? profilePhotoPath,
    bool clearProfilePhoto = false,
    StyleTag? favoriteStyle,
    List<String>? preferredColors,
    StylePreference? stylePreference,
    String? city,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhotoPath:
          clearProfilePhoto ? null : profilePhotoPath ?? this.profilePhotoPath,
      favoriteStyle: favoriteStyle ?? this.favoriteStyle,
      preferredColors: preferredColors ?? this.preferredColors,
      stylePreference: stylePreference ?? this.stylePreference,
      city: city ?? this.city,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'profilePhotoPath': profilePhotoPath,
      'favoriteStyle': favoriteStyle.name,
      'preferredColors': preferredColors,
      'stylePreference': stylePreference.name,
      'city': city,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      profilePhotoPath: map['profilePhotoPath'] as String?,
      favoriteStyle: StyleTag.values.byName(
        map['favoriteStyle'] as String? ?? StyleTag.smartCasual.name,
      ),
      preferredColors: (map['preferredColors'] as List<dynamic>? ??
              AppConstants.preferredColorDefaults)
          .map((entry) => entry.toString())
          .toList(),
      stylePreference: StylePreference.values.byName(
        map['stylePreference'] as String? ?? StylePreference.neutral.name,
      ),
      city: map['city'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
