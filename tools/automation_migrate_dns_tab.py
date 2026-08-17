from pathlib import Path

screen = Path('lib/ui/statistics/widgets/dns_tab.dart')
text = screen.read_text(encoding='utf-8')

error_import = "import 'package:pi_hole_client/ui/core/ui/components/error_message.dart';\n"
section_import = "import 'package:pi_hole_client/ui/core/ui/components/section_label.dart';\n"
if error_import not in text:
    if section_import not in text:
        raise SystemExit('DnsTab section_label import anchor missing')
    text = text.replace(section_import, error_import + section_import, 1)

old = '''      errorGenerator: () => SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 50),
            Text(
              AppLocalizations.of(context)!.statsNotLoaded,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),'''
new = '''      errorGenerator: () => SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ErrorMessage(
          message: AppLocalizations.of(context)!.statsNotLoaded,
          fontSize: 22,
          fontColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),'''
if old not in text:
    if 'child: ErrorMessage(' not in text:
        raise SystemExit('Expected DnsTab error block missing')
else:
    text = text.replace(old, new, 1)
screen.write_text(text, encoding='utf-8')

roadmap = Path('ROADMAP.md')
r = roadmap.read_text(encoding='utf-8')
entry = '- [x] Migrate `DnsTab` statistics error state to the shared `ErrorMessage` component; `statistics_test.dart` remains green.\n'
if entry not in r:
    lines = r.splitlines(keepends=True)
    anchors = ('StatisticsList', 'statistics error state')
    idx = next((i for i, line in enumerate(lines) if line.startswith('- [x]') and any(a in line for a in anchors)), None)
    if idx is None:
        idx = next((i for i, line in enumerate(lines) if '#638' in line), None)
    if idx is None:
        raise SystemExit('ROADMAP #638 anchor missing')
    lines.insert(idx + 1, entry)
    r = ''.join(lines)
r = r.replace('**Not fully completed.** #604 and #404 are implemented and validated. #638 is the next preferred deterministic item.', '**Not fully completed.** #604 and #404 are implemented and validated. #638 is in progress; `DnsTab` is the latest completed shared error-state migration and the next duplicated statistics error state should be migrated incrementally.')
roadmap.write_text(r, encoding='utf-8')
