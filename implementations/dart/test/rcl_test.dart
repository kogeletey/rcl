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
    expectFail('do [1] end\n', 'unexpected token after root array');
    expectFail('x do\n  arr do [1]\n  y = 1\nend\n', 'unexpected token');
  });

  test('named array root array and anonymous block array elements', () {
    const namedSrc = 'config do\n  tests do [\n    do\n      name = "case-1"\n    end,\n    "string"\n  ] end\nend\n';
    final namedObj = RCL.toObject(namedSrc);
    expect(namedObj['config']['tests'][0]['name'], 'case-1');
    expect(namedObj['config']['tests'][1], 'string');

    const rootSrc = 'do [\n  do\n    name = "root-item"\n  end,\n  "x"\n]\n';
    final rootObj = RCL.toObject(rootSrc);
    expect(rootObj['root'][0]['name'], 'root-item');
    expect(rootObj['root'][1], 'x');
  });
}
