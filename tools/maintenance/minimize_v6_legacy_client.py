from pathlib import Path
import re

METHODS = [
    'getAuth', 'deleteAuth', 'getAuthSessions', 'deleteAuthSession',
    'getHistory', 'getHistoryClient', 'getQueries', 'getStatsSummary',
    'getStatsUpstreams', 'getStatsTopDomains', 'getStatsTopClients',
    'getDnsBlocking', 'postDnsBlocking', 'getGroups', 'deleteGroups',
    'getClients', 'getDomains', 'getLists', 'deleteLists', 'getSearch',
    'getInfoClient', 'getInfoHost', 'getInfoMessages', 'getInfoMetrics',
    'getInfoSensors', 'getInfoSystem', 'getInfoVersion', 'getNetworkDevices',
    'patchConfig', 'getDhcpLeases',
]
KEEP = {'postAuth', 'getInfoFtl', 'getNetworkGateway', 'postActionGravity'}


def find_matching_brace(source: str, brace: int) -> int:
    depth = 0
    quote = None
    escaped = False
    for i in range(brace, len(source)):
        char = source[i]
        if quote:
            if escaped:
                escaped = False
            elif char == '\\':
                escaped = True
            elif char == quote:
                quote = None
        else:
            if char in ("'", '"'):
                quote = char
            elif char == '{':
                depth += 1
            elif char == '}':
                depth -= 1
                if depth == 0:
                    return i
    raise RuntimeError('unclosed brace')


def remove_method(source: str, name: str) -> str:
    match = re.search(
        rf'(?m)^  (?:Future|Stream)<[^\n]+>\s+{re.escape(name)}\s*\(', source
    )
    if match is None:
        raise SystemExit(f'method not found: {name}')
    start = match.start()
    lines = source[:start].splitlines(keepends=True)
    while lines and lines[-1].strip().startswith('@'):
        start -= len(lines.pop())
    body = re.search(r'\)\s+(?:async\*?|sync\*?)\s*\{', source[match.start():])
    if body is None:
        raise SystemExit(f'body not found: {name}')
    brace = match.start() + body.end() - 1
    end = find_matching_brace(source, brace) + 1
    while end < len(source) and source[end] == '\n':
        end += 1
    return source[:start] + source[end:]


def remove_group(source: str, label: str) -> str:
    match = re.search(
        rf"(?m)^  group\('{re.escape(label)}',\s*\(\)\s*\{{", source
    )
    if match is None:
        return source
    brace = source.find('{', match.start(), match.end())
    end_brace = find_matching_brace(source, brace)
    close = source.find(');', end_brace)
    if close < 0:
        raise SystemExit(f'group close not found: {label}')
    end = close + 2
    while end < len(source) and source[end] == '\n':
        end += 1
    return source[:match.start()] + source[end:]


def remove_simple_helper(source: str, name: str) -> str:
    match = re.search(rf'(?m)^  String {re.escape(name)}\s*\(', source)
    if match is None:
        return source
    start = match.start()
    lines = source[:start].splitlines(keepends=True)
    while lines and (lines[-1].lstrip().startswith('///') or not lines[-1].strip()):
        start -= len(lines.pop())
    brace = source.find('{', match.start())
    end = find_matching_brace(source, brace) + 1
    while end < len(source) and source[end] == '\n':
        end += 1
    return source[:start] + source[end:]


client_path = Path('lib/data/services/api/pihole_v6_api_client.dart')
fake_path = Path('testing/fakes/services/fake_pihole_v6_api_client.dart')
test_path = Path('test/data/services/api/pihole_v6_api_client_test.dart')

client = client_path.read_text()
fake = fake_path.read_text()
tests = test_path.read_text()
for name in METHODS:
    client = remove_method(client, name)
    fake = remove_method(fake, name)
    tests = remove_group(tests, name)
tests = remove_group(tests, 'fetInfoVersion')
client = remove_simple_helper(client, '_buildPathString')

client_imports = [
    "import 'dart:async';", "import 'dart:convert';", '',
    "import 'package:http/http.dart' as http;", "import 'package:http/io_client.dart';",
    "import 'package:pi_hole_client/data/model/v6/auth/auth.dart' show Session;",
    "import 'package:pi_hole_client/data/model/v6/ftl/ftl.dart' show InfoFtl;",
    "import 'package:pi_hole_client/data/model/v6/network/gateway.dart' show Gateway;",
    "import 'package:pi_hole_client/data/services/utils/safe_api_call.dart';",
    "import 'package:pi_hole_client/utils/exceptions.dart';",
    "import 'package:pi_hole_client/utils/misc.dart';",
    "import 'package:result_dart/result_dart.dart';", '',
]
client = '\n'.join(client_imports) + client[client.index('enum HttpMethod'):]

fake_imports = [
    "import 'dart:async';", '',
    "import 'package:pi_hole_client/data/model/v6/auth/auth.dart' show Session;",
    "import 'package:pi_hole_client/data/model/v6/ftl/ftl.dart' show InfoFtl;",
    "import 'package:pi_hole_client/data/model/v6/network/gateway.dart' show Gateway;",
    "import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';",
    "import 'package:pi_hole_client/utils/exceptions.dart';",
    "import 'package:result_dart/result_dart.dart';", '',
    "import '../../models/v6/actions.dart';", "import '../../models/v6/auth.dart';",
    "import '../../models/v6/ftl.dart';", "import '../../models/v6/network.dart';", '',
]
fake = '\n'.join(fake_imports) + fake[fake.index('class FakePiholeV6ApiClient'):]
fake = fake.replace(
    '  /// Server-reported 2FA status returned by [getAuth] (`session.totp`).\n',
    '  /// Legacy auth-capability fixture state retained for compatibility tests.\n',
)

test_imports = [
    "import 'dart:convert';", '', "import 'package:flutter_test/flutter_test.dart';",
    "import 'package:http/http.dart' as http;",
    "import 'package:pi_hole_client/data/model/v6/network/gateway.dart';",
    "import 'package:pi_hole_client/data/services/api/pihole_v6_api_client.dart';",
    "import 'package:pi_hole_client/utils/exceptions.dart';",
    "import 'package:result_dart/result_dart.dart';", '',
    "import '../../../../testing/helper/test_helper.dart';",
    "import '../utils/mocks.mocks.dart';", '',
]
tests = '\n'.join(test_imports) + tests[tests.index('void main()'):]

client_path.write_text(client)
fake_path.write_text(fake)
test_path.write_text(tests)

public = []
for line in client.splitlines():
    match = re.match(r'^  (?:Future|Stream)<.*>\s+([A-Za-z_]\w*)\s*\(', line)
    if match and not match.group(1).startswith('_'):
        public.append(match.group(1))
if set(public) != KEEP or len(public) != len(KEEP):
    raise SystemExit(f'unexpected public legacy surface: {public}')
for name in METHODS:
    if re.search(rf'\b{re.escape(name)}\s*\(', fake):
        raise SystemExit(f'stale fake method remains: {name}')
    if re.search(rf'apiClient\.{re.escape(name)}\s*\(', tests):
        raise SystemExit(f'stale direct client call remains: {name}')
print('Remaining public legacy methods:', ', '.join(public))
