library rcl;

import 'src/core.dart';
import 'src/convert.dart';

class RCL {
  static Map<String, dynamic> parse(String text) => RclCore.parse(text);
  static String format(String text) => RclCore.formatAst(parse(text));
  static Map<String, dynamic> toObject(String text) => RclCore.projectAst(parse(text));
  static String toYAML(String text) => RclConvert.toYaml(toObject(text));
  static String toTOML(String text) => RclConvert.toToml(toObject(text));
  static String toHCL(String text) => RclConvert.toHcl(toObject(text));
}
