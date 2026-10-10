import 'dart:convert';

import 'package:cofre/core/config/app_config.dart';
import 'package:cofre/features/vault/data/dtos/entry_dto.dart';
import 'package:cofre/features/vault/domain/entities/entry.dart';

/// Senhas de exemplo (antes ficavam no código de produção como "seed").
List<Entry> sampleEntries(DateTime now) {
  DateTime daysAgo(int days) => now.subtract(Duration(days: days));
  return [
    Entry(
      id: '1',
      title: 'Gmail',
      username: 'ana.souza@gmail.com',
      password: 'Ve!ra#2024-mar',
      url: 'mail.google.com',
      notes: 'Conta principal.',
      hue: 25,
      updatedAt: daysAgo(0),
    ),
    Entry(
      id: '2',
      title: 'Nubank',
      username: '123.456.789-00',
      password: 'nu8812',
      url: 'nubank.com.br',
      hue: 300,
      updatedAt: daysAgo(4),
    ),
    Entry(
      id: '3',
      title: 'GitHub',
      username: 'anasouza',
      password: 'gH_7tq!Lm9#xP2wz',
      url: 'github.com',
      notes: '2FA ativado no app autenticador.',
      hue: 250,
      updatedAt: daysAgo(9),
    ),
    Entry(
      id: '4',
      title: 'Spotify',
      username: 'ana.souza',
      password: r'Musica$Boa77',
      url: 'spotify.com',
      hue: 150,
      updatedAt: daysAgo(1),
    ),
  ];
}

/// Senhas de exemplo no formato da versão anterior (armazenamento seguro, sem a chave mestre).
Map<String, String> legacyStoredEntries(DateTime now) => {
  AppConfig.legacyEntriesStorageKey: jsonEncode(sampleEntries(now).map(EntryDto.toJson).toList()),
};
