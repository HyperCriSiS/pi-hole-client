import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pi_hole_client/domain/model/enums.dart';
import 'package:pi_hole_client/domain/model/metrics/queries.dart';
import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/formats.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/responsive.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/snackbar.dart';
import 'package:pi_hole_client/ui/core/ui/helpers/urls.dart';
import 'package:pi_hole_client/ui/core/ui/modals/process_modal.dart';
import 'package:pi_hole_client/ui/core/view_models/app_config_viewmodel.dart';
import 'package:pi_hole_client/ui/domains/view_models/domains_viewmodel.dart';
import 'package:pi_hole_client/ui/domains/widgets/add_domain_modal.dart';
import 'package:pi_hole_client/ui/logs/view_models/logs_viewmodel.dart';
import 'package:pi_hole_client/ui/logs/widgets/log_status.dart';
import 'package:pi_hole_client/utils/format.dart';
import 'package:pi_hole_client/utils/math.dart';
import 'package:pi_hole_client/utils/open_url.dart';
import 'package:provider/provider.dart';

class LogDetailsScreen extends StatelessWidget {
  const LogDetailsScreen({
    required this.log,
    required this.whiteBlackList,
    super.key,
  });

  final Log log;
  final void Function(String, Log) whiteBlackList;

  @override
  Widget build(BuildContext context) {
    final logsViewModel = Provider.of<LogsViewModel>(context);

    Widget item(IconData icon, String label, Widget value) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                value,
              ],
            ),
          ],
        ),
      );
    }

    Future<void> addDomain(
      DomainType type,
      DomainKind kind,
      String domain,
    ) async {
      final domainsViewModel = context.read<DomainsViewModel>();
      final appConfigViewModel = context.read<AppConfigViewModel>();
      final process = ProcessModal(context: context);
      process.open(AppLocalizations.of(context)!.domainAdding);

      try {
        await domainsViewModel.addDomain.runAsync((
          type: type,
          kind: kind,
          domain: domain,
        ));
        if (!context.mounted) return;
        process.close();

        showSuccessSnackBar(
          context: context,
          appConfigViewModel: appConfigViewModel,
          label: AppLocalizations.of(context)!.domainAdded,
        );
      } catch (e) {
        if (!context.mounted) return;
        process.close();

        showSaveFailedSnackBar(
          context: context,
          appConfigViewModel: appConfigViewModel,
          error: e,
          alreadyExistsLabel: AppLocalizations.of(context)!.domainAlreadyAdded,
          failedLabel: AppLocalizations.of(context)!.domainAddFailed,
        );
      }
    }

    void openEditAndAdd() {
      final mediaQuery = MediaQuery.of(context);
      final isSmallLandscape =
          mediaQuery.size.width > mediaQuery.size.height &&
          mediaQuery.size.height < ResponsiveConstants.medium;
      final selectedList = logsViewModel.isAllowedOrRetried(log.status)
          ? 'blacklist'
          : 'whitelist';

      Widget buildModal(BuildContext _) => AddDomainModal(
        selectedlist: selectedList,
        addDomain: addDomain,
        initialDomain: log.url,
        window: mediaQuery.size.width > ResponsiveConstants.medium,
      );

      if (mediaQuery.size.width > ResponsiveConstants.medium) {
        showDialog(
          context: context,
          useSafeArea: !isSmallLandscape,
          useRootNavigator: false,
          builder: buildModal,
        );
      } else {
        showModalBottomSheet(
          context: context,
          builder: buildModal,
          isScrollControlled: true,
        );
      }
    }

    Widget blackWhiteListButton() {
      if (logsViewModel.isAllowedOrRetried(log.status)) {
        return IconButton(
          onPressed: () {
            if (context.canPop()) context.pop();
            whiteBlackList('black', log);
          },
          icon: const Icon(Icons.gpp_bad_rounded),
          tooltip: AppLocalizations.of(context)!.blacklist,
        );
      } else {
        return IconButton(
          onPressed: () {
            if (context.canPop()) context.pop();
            whiteBlackList('white', log);
          },
          icon: const Icon(Icons.verified_user_rounded),
          tooltip: AppLocalizations.of(context)!.whitelist,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logDetails),
        actions: [
          IconButton(
            onPressed: () {
              logsViewModel.setSelectedDomain(log.url);
              if (context.canPop()) context.pop();
            },
            icon: const Icon(Icons.filter_alt_rounded),
          ),
          IconButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: log.url)),
            icon: const Icon(Icons.content_copy_rounded),
          ),
          IconButton(
            onPressed: () => openUrl('${Urls.googleSearch}${log.url}'),
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: AppLocalizations.of(context)!.domainSearchOnline,
          ),
          IconButton(
            onPressed: openEditAndAdd,
            icon: const Icon(Icons.edit_rounded),
            tooltip:
                '${AppLocalizations.of(context)!.edit} & ${AppLocalizations.of(context)!.add}',
          ),
          blackWhiteListButton(),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(AppLocalizations.of(context)!.url),
              subtitle: Text(log.url),
            ),
            ListTile(
              leading: const Icon(Icons.http_rounded),
              title: Text(AppLocalizations.of(context)!.type),
              subtitle: Text(log.type.name.toUpperCase()),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android_rounded),
              title: Text(AppLocalizations.of(context)!.device),
              subtitle: Text(log.device),
            ),
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: Text(AppLocalizations.of(context)!.time),
              subtitle: Text(
                formatTimestamp(log.dateTime, kUnifiedDateTimeLogFormat),
              ),
            ),
            if (log.status != null)
              item(
                Icons.shield_outlined,
                AppLocalizations.of(context)!.status,
                LogStatus(status: log.status!, showIcon: false),
              ),
            if (log.status == QueryStatusType.forwarded &&
                log.answeredBy != null)
              ListTile(
                leading: const Icon(Icons.domain),
                title: Text(AppLocalizations.of(context)!.answeredBy),
                subtitle: Text(log.answeredBy!),
              ),
            ListTile(
              leading: const Icon(Icons.system_update_alt_outlined),
              title: Text(AppLocalizations.of(context)!.reply),
              subtitle: Text(
                '${log.replyType?.name.toUpperCase() ?? 'N/A'} (${prettyReplyTimeWithUnit(log.replyTime)})',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
