import 'lexer.dart';
import 'parser.dart';

class RclCore {
  static Map<String, dynamic> parse(String text) => Parser(Lexer(text)).program();

  static String formatAst(Map<String, dynamic> ast) {
    final sb = StringBuffer();
    for (final b in ast['blocks'] as List<dynamic>) {
      sb.write(_fmtBlock((b as Map).cast<String, dynamic>(), 0));
    }
    return sb.toString();
  }

  static Map<String, dynamic> projectAst(Map<String, dynamic> ast) {
    final out = <String, dynamic>{};
    for (final b in ast['blocks'] as List<dynamic>) {
      _mergeBlock(out, (b as Map).cast<String, dynamic>());
    }
    return out;
  }

  static String _fmtBlock(Map<String, dynamic> b, int n) {
    final i = ' ' * n;
    final sb = StringBuffer();
    sb.write(i);
    sb.write(b['name']);
    if (b['arg'] != null) sb.write(' "${_esc(b['arg'] as String)}"');
    sb.write(' do\n');
    for (final s in b['statements'] as List<dynamic>) {
      final st = (s as Map).cast<String, dynamic>();
      if (st['type'] == 'property') {
        sb.write('$i  ${(st['key'] as List<dynamic>).join('.')} = ${_fmtVal(st['value'] as Map<String, dynamic>)}\n');
      } else {
        sb.write(_fmtBlock(st, n + 2));
      }
    }
    sb.write('${i}end\n');
    return sb.toString();
  }

  static String _fmtVal(Map<String, dynamic> v) {
    if (v['type'] == 'string') return '"${_esc(v['value'] as String)}"';
    if (v['type'] == 'number') return v['raw'] as String;
    if (v['type'] == 'boolean') return (v['value'] as bool) ? 'true' : 'false';
    return '[${(v['items'] as List<dynamic>).map((e) => _fmtVal((e as Map).cast<String, dynamic>())).join(', ')}]';
  }

  static String _esc(String s) => s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n').replaceAll('\t', '\\t');

  static void _mergeBlock(Map<String, dynamic> dst, Map<String, dynamic> b) {
    final obj = _projectBlock(b);
    final arg = b['arg'] as String?;
    if (arg == null) {
      _mergeAt(dst, b['name'] as String, obj);
    } else {
      final base = _base(b['name'] as String);
      dst.putIfAbsent(base, () => <String, dynamic>{});
      _mergeAt((dst[base] as Map).cast<String, dynamic>(), arg, obj);
    }
  }

  static Map<String, dynamic> _projectBlock(Map<String, dynamic> b) {
    final out = <String, dynamic>{};
    for (final s in b['statements'] as List<dynamic>) {
      final st = (s as Map).cast<String, dynamic>();
      if (st['type'] == 'property') {
        _setPath(out, (st['key'] as List<dynamic>).cast<String>(), _val((st['value'] as Map).cast<String, dynamic>()));
      } else {
        final child = _projectBlock(st);
        final arg = st['arg'] as String?;
        if (arg == null) {
          _mergeAt(out, st['name'] as String, child);
        } else {
          final base = _base(st['name'] as String);
          out.putIfAbsent(base, () => <String, dynamic>{});
          _mergeAt((out[base] as Map).cast<String, dynamic>(), arg, child);
        }
      }
    }
    return out;
  }

  static dynamic _val(Map<String, dynamic> v) {
    if (v['type'] != 'array') return v['value'];
    return (v['items'] as List<dynamic>).map((e) => _val((e as Map).cast<String, dynamic>())).toList();
  }

  static void _setPath(Map<String, dynamic> m, List<String> path, dynamic v) {
    final k = path.first;
    if (path.length == 1) {
      m[k] = v;
      return;
    }
    m.putIfAbsent(k, () => <String, dynamic>{});
    _setPath((m[k] as Map).cast<String, dynamic>(), path.sublist(1), v);
  }

  static void _mergeAt(Map<String, dynamic> m, String key, Map<String, dynamic> val) {
    m.putIfAbsent(key, () => <String, dynamic>{});
    _deepMerge((m[key] as Map).cast<String, dynamic>(), val);
  }

  static void _deepMerge(Map<String, dynamic> a, Map<String, dynamic> b) {
    for (final e in b.entries) {
      final av = a[e.key], bv = e.value;
      if (av is Map && bv is Map) {
        _deepMerge(av.cast<String, dynamic>(), bv.cast<String, dynamic>());
      } else {
        a[e.key] = bv;
      }
    }
  }

  static String _base(String n) => n.endsWith('s') ? n : '${n}s';
}
