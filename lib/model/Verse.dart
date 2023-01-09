import 'package:flutter/foundation.dart' show immutable;

@immutable
class Verse {
  final int id;
  final int sura;
  final int ayah;
  final String text;

  Verse({
    required this.id,
    required this.sura,
    required this.ayah,
    required this.text,
  });

  factory Verse.fromJson(Map<String, dynamic> data) => Verse(
        id: data['rowid'],
        sura: data['sura'],
        ayah: data['ayah'],
        text: data['text'],
      );

  @override
  String toString() {
    return "($sura:$ayah) -> $text";
  }
}
