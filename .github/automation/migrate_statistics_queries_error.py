from pathlib import Path
import re
import sys

TARGET = Path('lib/ui/statistics/widgets/statistics_queries_servers_tab.dart')
ROADMAP = Path('ROADMAP.md')
IMPORT = "import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';\n"
IMPORT_ANCHOR = "import 'package:pi_hole_client/ui/core/l10n/generated/app_localizations.dart';\n"
ROADMAP_ENTRY = '- [x] Migrate `QueriesServersTab` to the shared `ErrorMessage` component and keep `statistics_test.dart` green.\n'
ROADMAP_ANCHOR = '- [x] Migrate the StatisticsList error state to the shared `ErrorMessage` component and keep `statistics_test.dart` green.\n'


def migrate() -> None:
    source = TARGET.read_text()
    if IMPORT not in source:
        if IMPORT_ANCHOR not in source:
            raise SystemExit('localization import anchor not found')
        source = source.replace(IMPORT_ANCHOR, IMPORT_ANCHOR + IMPORT, 1)

    pattern = re.compile(
        r"      errorGenerator: \(\) => SizedBox\(\n"
        r"        width: double\.maxFinite,\n"
        r"        height: 300,\n"
        r"        child: Column\(\n"
        r".*?"
        r"        \),\n"
        r"      \),\n"
        r"      loadStatus: statusLoading,",
        re.S,
    )
    matches = list(pattern.finditer(source))
    if len(matches) != 1:
        raise SystemExit(f'expected one legacy error block, found {len(matches)}')
    legacy = matches[0].group(0)
    if 'statsNotLoaded' not in legacy or 'Icon(Icons.error' not in legacy:
        raise SystemExit('legacy error block does not match expected semantics')

    replacement = """      errorGenerator: () => SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ErrorMessage(
          message: AppLocalizations.of(context)!.statsNotLoaded,
        ),
      ),
      loadStatus: statusLoading,"""
    TARGET.write_text(pattern.sub(replacement, source, count=1))


def roadmap() -> None:
    source = ROADMAP.read_text()
    if ROADMAP_ENTRY in source:
        return
    if ROADMAP_ANCHOR not in source:
        raise SystemExit('StatisticsList roadmap anchor not found')
    ROADMAP.write_text(source.replace(ROADMAP_ANCHOR, ROADMAP_ANCHOR + ROADMAP_ENTRY, 1))


if len(sys.argv) != 2 or sys.argv[1] not in {'migrate', 'roadmap'}:
    raise SystemExit('usage: migrate_statistics_queries_error.py migrate|roadmap')

if sys.argv[1] == 'migrate':
    migrate()
else:
    roadmap()
