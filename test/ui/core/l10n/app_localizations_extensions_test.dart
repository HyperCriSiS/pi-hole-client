import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/core/l10n/app_localizations_extensions.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

void main() {
  group('GroupInUseLocalizations', () {
    test('uses translated messages for supported locales', () async {
      final expected = <String, String>{
        'en':
            'This group is used by clients, domains or adlists. '
            'Remove it from them first, then delete the group',
        'de':
            'Diese Gruppe wird von Clients, Domains oder Adlisten verwendet. '
            'Entfernen Sie sie zuerst dort und löschen Sie dann die Gruppe',
        'es':
            'Este grupo lo usan clientes, dominios o listas. '
            'Quítelo de ellos primero y luego elimine el grupo',
        'ja':
            'このグループはクライアント、ドメイン、またはリストで使われています。'
            '先に所属を外してから削除してください',
        'pl':
            'Ta grupa jest używana przez klientów, domeny lub listy. '
            'Najpierw usuń ją z nich, a potem usuń grupę',
      };

      for (final entry in expected.entries) {
        final localizations = await AppLocalizations.delegate.load(
          Locale(entry.key),
        );
        expect(localizations.groupInUse, entry.value);
      }
    });

    test('falls back to English for another locale', () async {
      final localizations = await AppLocalizations.delegate.load(
        const Locale('fr'),
      );

      expect(
        localizations.groupInUse,
        'This group is used by clients, domains or adlists. '
        'Remove it from them first, then delete the group',
      );
    });
  });
}
