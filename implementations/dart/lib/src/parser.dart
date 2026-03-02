import 'lexer.dart';

class Parser {
  final Lexer lexer;
  late Token t;
  Parser(this.lexer) {
    t = lexer.next();
  }

  Map<String, dynamic> program() {
    final blocks = <Map<String, dynamic>>[];
    while (t.type != 'eof') {
      blocks.add(_block());
    }
    return {'type': 'Document', 'blocks': blocks};
  }

  Map<String, dynamic> _block() {
    final name = _eat('id').value as String;
    String? arg;
    if (t.type == 'string') arg = _eat('string').value as String;
    _eat('do');
    final stmts = <Map<String, dynamic>>[];
    final keys = <List<String>>[];
    while (t.type != 'end') {
      if (t.type == 'eof') _fail('missing end', t);
      stmts.add(_stmt(keys));
    }
    _eat('end');
    return {'type': 'Block', 'name': name, 'arg': arg, 'statements': stmts};
  }

  Map<String, dynamic> _stmt(List<List<String>> keys) {
    final id = _eat('id');
    if (t.type == 'do' || t.type == 'string') {
      String? arg;
      if (t.type == 'string') arg = _eat('string').value as String;
      _eat('do');
      final stmts = <Map<String, dynamic>>[];
      final inner = <List<String>>[];
      while (t.type != 'end') {
        if (t.type == 'eof') _fail('missing end', t);
        stmts.add(_stmt(inner));
      }
      _eat('end');
      return {'type': 'Block', 'name': id.value, 'arg': arg, 'statements': stmts};
    }
    final path = <String>[id.value as String];
    while (t.type == '.') {
      _eat('.');
      path.add(_eat('id').value as String);
    }
    _eat('=');
    _check(keys, path, id);
    return {'type': 'property', 'key': path, 'value': _value()};
  }

  Map<String, dynamic> _value() {
    if (t.type == 'string') {
      final x = _eat('string');
      return {'type': 'string', 'value': x.value};
    }
    if (t.type == 'number') {
      final x = _eat('number');
      return {'type': 'number', 'value': x.value['value'], 'raw': x.value['raw']};
    }
    if (t.type == 'bool') {
      final x = _eat('bool');
      return {'type': 'boolean', 'value': x.value};
    }
    if (t.type == '[') {
      final start = _eat('[');
      final items = <Map<String, dynamic>>[];
      if (t.type != ']') {
        while (true) {
          items.add(_value());
          if (t.type != ',') break;
          _eat(',');
          if (t.type == ']') _fail('trailing comma in array', t);
        }
      }
      if (t.type != ']') _fail('missing ]', start);
      _eat(']');
      return {'type': 'array', 'items': items};
    }
    if (t.type == 'id') _fail('invalid bare identifier value', t);
    _fail('unexpected token', t);
  }

  Token _eat(String type) {
    final x = t;
    if (x.type != type) _fail('unexpected token', x);
    t = lexer.next();
    return x;
  }

  void _check(List<List<String>> keys, List<String> path, Token at) {
    for (final k in keys) {
      if (_eq(k, path) || _pref(k, path) || _pref(path, k)) {
        _fail('duplicate or conflicting key path', at);
      }
    }
    keys.add(path);
  }

  bool _eq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _pref(List<String> a, List<String> b) {
    if (a.length >= b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Never _fail(String msg, Token tok) {
    throw RclError('line ${tok.line}, column ${tok.col}: $msg');
  }
}
