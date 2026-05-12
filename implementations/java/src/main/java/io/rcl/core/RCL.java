package io.rcl.core;

import io.rcl.DocumentNode;
import java.util.Map;

public final class RCL {
  private RCL() {}

  public static DocumentNode parse(String text) { return io.rcl.RCL.parse(text); }
  public static Map<String, Object> toObject(String text) { return io.rcl.RCL.toObject(text); }
  public static Map<String, Object> toObject(DocumentNode doc) { return io.rcl.RCL.toObject(doc); }
}
