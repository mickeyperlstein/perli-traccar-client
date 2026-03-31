import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

import 'l10n/app_localizations.dart';

// Framework source classes that produce noise at logLevel 5
const _fwPatterns = [
  'StreamHandler',
  'LifecycleManager',
  'LoggerFacade',
  'TSSQLiteAppender',
  'SQLiteLocationDAO',
  'TSGeofenceManager',
  'TSProviderManager',
  'TSConfig',
  'BootReceiver',
  'BackgroundGeolocation a',
];

enum _LogLevel { debug, info, warn, error, fw, other }

_LogLevel _classify(String line) {
  // Framework noise — obfuscated class names or known FW source patterns
  if (_fwPatterns.any((p) => line.contains(p))) return _LogLevel.fw;

  if (line.contains(' DEBUG ')) return _LogLevel.debug;
  if (line.contains(' INFO ')) return _LogLevel.info;
  if (line.contains(' WARN ')) return _LogLevel.warn;
  if (line.contains(' ERROR ')) return _LogLevel.error;

  return _LogLevel.other;
}

Color _colorFor(_LogLevel level, bool dark) {
  switch (level) {
    case _LogLevel.error:
      return Colors.red.shade300;
    case _LogLevel.warn:
      return Colors.orange.shade300;
    case _LogLevel.info:
      return dark ? Colors.white : Colors.black87;
    case _LogLevel.debug:
      return Colors.grey.shade500;
    case _LogLevel.fw:
      return Colors.grey.shade600;
    case _LogLevel.other:
      return Colors.grey.shade400;
  }
}

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

// A log line paired with its resolved level (continuations inherit parent)
typedef _LogEntry = ({String line, _LogLevel level});

List<_LogEntry> _tagLines(List<String> lines) {
  final result = <_LogEntry>[];
  var currentLevel = _LogLevel.other;
  // Date prefix pattern: "MM-DD HH:MM:SS.mmm"
  final datePrefix = RegExp(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}');
  for (final line in lines) {
    if (datePrefix.hasMatch(line)) {
      currentLevel = _classify(line);
    }
    result.add((line: line, level: currentLevel));
  }
  return result;
}

class _StatusScreenState extends State<StatusScreen> {
  List<_LogEntry> _entries = [];

  // Which levels are currently VISIBLE (all on by default)
  final Set<_LogLevel> _visible = {
    _LogLevel.debug,
    _LogLevel.info,
    _LogLevel.warn,
    _LogLevel.error,
    _LogLevel.fw,
    _LogLevel.other,
  };

  List<_LogEntry> get _filtered =>
      _entries.where((e) => _visible.contains(e.level)).toList();

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  Future<void> _refreshLogs() async {
    final logs = await bg.Logger.getLog(
      bg.SQLQuery(order: bg.SQLQuery.ORDER_DESC, limit: 2000),
    );
    setState(() {
      _entries = _tagLines(logs.split('\n'));
    });
  }

  Future<void> _emailLogs() async {
    await bg.Logger.emailLog(
      "support@traccar.org",
      bg.SQLQuery(order: bg.SQLQuery.ORDER_DESC, limit: 25000),
    );
  }

  Future<void> _clearLogs() async {
    await bg.Logger.destroyLog();
    setState(() => _entries = []);
  }

  void _toggleFilter(_LogLevel level) {
    setState(() {
      if (_visible.contains(level)) {
        _visible.remove(level);
      } else {
        _visible.add(level);
      }
    });
  }

  Widget _filterButton(_LogLevel level, String label, Color activeColor) {
    final on = _visible.contains(level);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: on,
        backgroundColor: on ? activeColor.withAlpha(64) : null,
        showCheckmark: false,
        labelStyle: TextStyle(color: on ? activeColor : Colors.grey),
        side: BorderSide(color: on ? activeColor : Colors.grey.shade600),
        onSelected: (_) => _toggleFilter(level),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statusTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshLogs),
          IconButton(icon: const Icon(Icons.share), onPressed: _emailLogs),
          IconButton(icon: const Icon(Icons.delete), onPressed: _clearLogs),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterButton(_LogLevel.fw, 'FW', Colors.grey),
                  _filterButton(_LogLevel.debug, 'DEBUG', Colors.grey.shade400),
                  _filterButton(_LogLevel.info, 'INFO', Colors.blue),
                  _filterButton(_LogLevel.warn, 'WARN', Colors.orange),
                  _filterButton(_LogLevel.error, 'ERROR', Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '${filtered.length}/${_entries.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        reverse: true,
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final entry = filtered[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              entry.line,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: _colorFor(entry.level, dark),
              ),
            ),
          );
        },
      ),
    );
  }
}
