class RclError extends FormatException {
  RclError(String message) : super(message);
  static Never at(int line, int col, String message) {
    throw RclError('line $line, column $col: $message');
  }
}

class Token {
  final String type;
  final dynamic value;
  final int line;
  final int col;
  Token(this.type, this.value, this.line, this.col);
}

class Lexer {
  final String src;
  int i = 0, line = 1, col = 1;
  Lexer(this.src);

  Token next() {
    _skip();
    if (i >= src.length) return Token('eof', null, line, col);
    final c = src[i], l = line, p = col;
    if (_idStart(c)) return _id();
    if (c == '-' || _digit(c)) return _num();
    if (c == '"') return _str();
    if (c == "'") RclError.at(l, p, 'single-quoted string usage');
    if (c == '/' && i + 1 < src.length && src[i + 1] == '/') RclError.at(l, p, 'unexpected character');
    if ('=.,[]'.contains(c)) {
      _adv();
      return Token(c, c, l, p);
    }
    RclError.at(l, p, 'unexpected character');
  }

  void _skip() {
    while (i < src.length) {
      final c = src[i];
      if (c == '#') {
        while (i < src.length && src[i] != '\n') _adv();
        continue;
      }
      if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
        _adv();
        continue;
      }
      break;
    }
  }

  Token _id() {
    final l = line, p = col;
    var s = '';
    while (i < src.length && _idChar(src[i])) {
      s += src[i];
      _adv();
    }
    if (s == 'do') return Token('do', s, l, p);
    if (s == 'end') return Token('end', s, l, p);
    if (s == 'true') return Token('bool', true, l, p);
    if (s == 'false') return Token('bool', false, l, p);
    return Token('id', s, l, p);
  }

  Token _num() {
    final l = line, p = col;
    var s = '';
    var dot = false;
    if (src[i] == '-') {
      s += '-';
      _adv();
    }
    if (i >= src.length || !_digit(src[i])) RclError.at(l, p, 'unexpected token');
    while (i < src.length) {
      final c = src[i];
      if (_digit(c)) {
        s += c;
        _adv();
        continue;
      }
      if (c == '.' && !dot) {
        dot = true;
        s += '.';
        _adv();
        if (i >= src.length || !_digit(src[i])) RclError.at(l, p, 'unexpected token');
        continue;
      }
      break;
    }
    return Token('number', {'value': num.parse(s), 'raw': s}, l, p);
  }

  Token _str() {
    final l = line, p = col;
    _adv();
    var s = '';
    while (i < src.length) {
      final c = src[i];
      if (c == '"') {
        _adv();
        return Token('string', s, l, p);
      }
      if (c == '\\') {
        if (i + 1 >= src.length) RclError.at(l, p, 'unterminated string');
        final e = src[i + 1];
        if (e == '"') s += '"';
        else if (e == '\\') s += '\\';
        else if (e == 'n') s += '\n';
        else if (e == 't') s += '\t';
        else RclError.at(line, col, 'invalid escape');
        _adv();
        _adv();
        continue;
      }
      if (c == '\n') RclError.at(l, p, 'unterminated string');
      s += c;
      _adv();
    }
    RclError.at(l, p, 'unterminated string');
  }

  void _adv() {
    if (src[i] == '\n') {
      i++;
      line++;
      col = 1;
    } else {
      i++;
      col++;
    }
  }

  bool _digit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _idStart(String c) {
    final n = c.codeUnitAt(0);
    return (n >= 65 && n <= 90) || (n >= 97 && n <= 122) || c == '_';
  }

  bool _idChar(String c) => _idStart(c) || _digit(c);
}
