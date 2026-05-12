library rcl_core;

import 'src/core.dart';

class RCLCore {
  static Map<String, dynamic> parse(String text) => RclCore.parse(text);
  static Map<String, dynamic> toObject(String text) => RclCore.projectAst(parse(text));
}
