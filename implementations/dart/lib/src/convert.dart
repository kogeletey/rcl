class RclConvert {
  static String toYaml(Map<String, dynamic> obj) => _yamlMap(obj, 0);

  static String toToml(Map<String, dynamic> obj) {
    final lines = _tomlTable(obj, const []);
    return lines.isEmpty ? '' : '${lines.join('\n')}\n';
  }

  static String toHcl(Map<String, dynamic> obj) {
    if (obj.isEmpty) return '{}\n';
    final b = StringBuffer();
    for (final e in _entries(obj)) {
      b.writeln('${_hclKey(e.key)} = ${_hclVal(e.value, 0)}');
    }
    return b.toString();
  }

  static String _yamlMap(Map<String, dynamic> m, int n) {
    if (m.isEmpty) return '${' ' * n}{}\n';
    final b = StringBuffer();
    for (final e in _entries(m)) {
      final i = ' ' * n;
      if (e.value is Map<String, dynamic>) {
        b.write('$i${_yamlKey(e.key)}:\n${_yamlMap((e.value as Map).cast<String, dynamic>(), n + 2)}');
      } else {
        b.writeln('$i${_yamlKey(e.key)}: ${_scalar(e.value)}');
      }
    }
    return b.toString();
  }

  static List<String> _tomlTable(Map<String, dynamic> m, List<String> path) {
    final lines = <String>[];
    if (path.isNotEmpty) lines.add('[${path.map(_tomlKey).join('.')}]');
    final maps = <MapEntry<String, dynamic>>[];
    for (final e in _entries(m)) {
      if (e.value is Map<String, dynamic>) maps.add(e);
      else lines.add('${_tomlKey(e.key)} = ${_scalar(e.value)}');
    }
    for (final e in maps) {
      if (lines.isNotEmpty) lines.add('');
      lines.addAll(_tomlTable((e.value as Map).cast<String, dynamic>(), [...path, e.key]));
    }
    return lines;
  }

  static String _hclVal(dynamic v, int n) {
    if (v is Map<String, dynamic>) {
      if (v.isEmpty) return '{}';
      final i = ' ' * n;
      final b = StringBuffer('{\n');
      for (final e in _entries(v)) {
        b.writeln('$i  ${_hclKey(e.key)} = ${_hclVal(e.value, n + 2)}');
      }
      b.write('$i}');
      return b.toString();
    }
    return _scalar(v);
  }

  static String _scalar(dynamic v) {
    if (v is String) return '"${_esc(v)}"';
    if (v is bool) return v ? 'true' : 'false';
    if (v is List) return '[${v.map(_scalar).join(', ')}]';
    return '$v';
  }

  static List<MapEntry<String, dynamic>> _entries(Map<String, dynamic> m) {
    final out = m.entries.toList();
    out.sort((a, b) => a.key.compareTo(b.key));
    return out;
  }

  static bool _bare(String k) => RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(k);
  static String _tomlKey(String k) => _bare(k) ? k : '"${_esc(k)}"';
  static String _yamlKey(String k) => _bare(k) ? k : '"${_esc(k)}"';
  static String _hclKey(String k) => _bare(k) ? k : '"${_esc(k)}"';

  static String _esc(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\t', '\\t');
  }
}
