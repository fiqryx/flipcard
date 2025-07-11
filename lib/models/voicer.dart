import 'package:flutter/material.dart';

class Voicer {
  final String name;
  final String alias;
  final Locale locale;
  final String gender;

  Voicer({
    required this.name,
    this.alias = 'unknown',
    required this.locale,
    this.gender = 'unknown',
  });

  factory Voicer.fromJson(Map<String, dynamic> json) {
    var list = json['locale'].split('-');
    return Voicer(
      name: json['name'],
      alias: json['name'].split('#')[0].split('-').last,
      locale: Locale(list[0], list.length > 1 ? list[1] : null),
      gender: json['name'].contains('female') ? 'female' : 'male',
    );
  }

  Map<String, String> toJson() {
    return {
      'name': name,
      'alias': alias,
      'locale': locale.countryCode != null
          ? '${locale.languageCode}-${locale.countryCode}'
          : locale.languageCode,
      'gender': gender,
    };
  }

  static List<Voicer> toList(List<dynamic> data, {Locale? locale}) {
    Set<String> uniqueVoices = {};

    var result = data
        .map((v) => Voicer.fromJson(Map<String, dynamic>.from(v)))
        .where((v) {
          final key = '${v.alias}_${v.locale.toString()}_${v.gender}';

          return (locale == null ||
                  v.locale.languageCode == locale.languageCode) &&
              uniqueVoices.add(key);
        })
        .toList();

    return result;
  }
}
