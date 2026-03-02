import 'package:rcl/rcl.dart';
import 'package:test/test.dart';

void expectFail(String src, String msg) {
  try {
    RCL.parse(src);
    fail('expected parse failure: $msg');
  } on FormatException catch (e) {
    expect(e.message, contains(msg));
    expect(e.message, contains('line'));
  }
}

void main() {
  test('ast projection converters and format', () {
    const src = 'root do\n  widget "blue" do\n    title = "My Name"\n    enabled = true\n    nums = [1, -2, 3.5]\n  end\nend\n';
    final ast = RCL.parse(src);
    expect(ast['type'], 'Document');
    expect(RCL.format(src), src);
    final obj = RCL.toObject(src);
    expect(obj['root']['widgets']['blue']['title'], 'My Name');
    expect(obj['root']['widgets']['blue']['enabled'], true);
    expect(RCL.toYAML(src), isNotEmpty);
    expect(RCL.toTOML(src), isNotEmpty);
    expect(RCL.toHCL(src), isNotEmpty);
  });

  test('root named block and edge errors', () {
    const src = 'env "prod" do\n  region "us" do\n    a.b = 1\n  end\nend\n';
    final obj = RCL.toObject(src);
    expect(obj['envs']['prod']['regions']['us']['a']['b'], 1);

    expectFail('x do\n  name = value\nend\n', 'invalid bare identifier value');
    expectFail('x do\n  arr = [1,]\nend\n', 'trailing comma in array');
    expectFail('x do\n  a = 1\n  a = 2\nend\n', 'duplicate or conflicting key path');
    expectFail('x do\n  a = 1\n  a.b = 2\nend\n', 'duplicate or conflicting key path');
    expectFail('x do\n  a.b = 1\n  a = 2\nend\n', 'duplicate or conflicting key path');
    expectFail('x do\n  s = "bad\\q"\nend\n', 'invalid escape');
    expectFail('x do\n  s = "ok"\n', 'missing end');
    expectFail('x do\n  a = [1,2\nend\n', 'missing ]');
    expectFail('x do\n  s = "bad\nend\n', 'unterminated string');
    expectFail('x do\n  s = \'bad\'\nend\n', 'single-quoted string usage');
    expectFail('x do\n  @ = 1\nend\n', 'unexpected character');
  });
}
