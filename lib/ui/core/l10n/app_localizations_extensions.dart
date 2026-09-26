import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';

extension GroupInUseLocalizations on AppLocalizations {
  String get groupInUse {
    return switch (localeName.split('_').first) {
      'de' =>
        'Diese Gruppe wird von Clients, Domains oder Adlisten verwendet. '
            'Entfernen Sie sie zuerst dort und löschen Sie dann die Gruppe',
      'es' =>
        'Este grupo lo usan clientes, dominios o listas. '
            'Quítelo de ellos primero y luego elimine el grupo',
      'ja' =>
        'このグループはクライアント、ドメイン、またはリストで使われています。'
            '先に所属を外してから削除してください',
      'pl' =>
        'Ta grupa jest używana przez klientów, domeny lub listy. '
            'Najpierw usuń ją z nich, a potem usuń grupę',
      _ =>
        'This group is used by clients, domains or adlists. '
            'Remove it from them first, then delete the group',
    };
  }
}
