import 'package:flutter_test/flutter_test.dart';
import 'package:pi_hole_client/ui/core/l10n/app_localizations_extensions.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations_de.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations_en.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations_es.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations_ja.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations_pl.dart';

void main() {
  group('GroupInUseLocalizations', () {
    test('uses translated messages for supported locales', () {
      final expected = <AppLocalizations, String>{
        AppLocalizationsEn():
            'This group is used by clients, domains or adlists. '
            'Remove it from them first, then delete the group',
        AppLocalizationsDe():
            'Diese Gruppe wird von Clients, Domains oder Adlisten verwendet. '
            'Entfernen Sie sie zuerst dort und löschen Sie dann die Gruppe',
        AppLocalizationsEs():
            'Este grupo lo usan clientes, dominios o listas. '
            'Quítelo de ellos primero y luego elimine el grupo',
        AppLocalizationsJa():
            'このグループはクライアント、ドメイン、またはリストで使われています。'
            '先に所属を外してから削除してください',
        AppLocalizationsPl():
            'Ta grupa jest używana przez klientów, domeny lub listy. '
            'Najpierw usuń ją z nich, a potem usuń grupę',
      };

      for (final entry in expected.entries) {
        expect(entry.key.groupInUse, entry.value);
      }
    });

    test('falls back to English for another locale name', () {
      final localizations = AppLocalizationsEn('fr');

      expect(
        localizations.groupInUse,
        'This group is used by clients, domains or adlists. '
        'Remove it from them first, then delete the group',
      );
    });
  });
}
