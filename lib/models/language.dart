import 'dart:ui';

class Language {
  final String code;
  final String name;
  final String flag;

  const Language({required this.code, required this.name, required this.flag});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      code: json['code'] as String,
      name: json['name'] as String,
      flag: json['flag'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'name': name, 'flag': flag};

  static const List<Language> list = [
    Language(code: 'en-US', name: 'English (US)', flag: '🇺🇸'),
    Language(code: 'en-GB', name: 'English (UK)', flag: '🇬🇧'),
    Language(code: 'es-ES', name: 'Spanish (Spain)', flag: '🇪🇸'),
    Language(code: 'es-MX', name: 'Spanish (Mexico)', flag: '🇲🇽'),
    Language(code: 'fr-FR', name: 'French', flag: '🇫🇷'),
    Language(code: 'de-DE', name: 'German', flag: '🇩🇪'),
    Language(code: 'it-IT', name: 'Italian', flag: '🇮🇹'),
    Language(code: 'pt-BR', name: 'Portuguese (Brazil)', flag: '🇧🇷'),
    Language(code: 'pt-PT', name: 'Portuguese (Portugal)', flag: '🇵🇹'),
    Language(code: 'ru-RU', name: 'Russian', flag: '🇷🇺'),
    Language(code: 'zh-CN', name: 'Chinese (Simplified)', flag: '🇨🇳'),
    Language(code: 'zh-TW', name: 'Chinese (Traditional)', flag: '🇹🇼'),
    Language(code: 'ja-JP', name: 'Japanese', flag: '🇯🇵'),
    Language(code: 'ko-KR', name: 'Korean', flag: '🇰🇷'),
    Language(code: 'ar-SA', name: 'Arabic', flag: '🇸🇦'),
    Language(code: 'hi-IN', name: 'Hindi', flag: '🇮🇳'),
    Language(code: 'th-TH', name: 'Thai', flag: '🇹🇭'),
    Language(code: 'vi-VN', name: 'Vietnamese', flag: '🇻🇳'),
    Language(code: 'id-ID', name: 'Indonesian', flag: '🇮🇩'),
    Language(code: 'ms-MY', name: 'Malay', flag: '🇲🇾'),
  ];

  static Language? findByCode(String code) {
    return list.firstWhere(
      (lang) => lang.code == code,
      orElse: () => list.first,
    );
  }

  static Language findByLocale(Locale locale) {
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;
    final localeString = countryCode != null
        ? '$languageCode-$countryCode'
        : languageCode;

    return list.firstWhere(
      (lang) => lang.code == localeString,
      orElse: () {
        // Fallback to language code only (e.g., "en")
        return list.firstWhere(
          (lang) => lang.code.startsWith('$languageCode-'),
          orElse: () => list.first,
        );
      },
    );
  }
}
