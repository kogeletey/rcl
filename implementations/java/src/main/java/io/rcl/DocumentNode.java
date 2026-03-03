package io.rcl;

import java.util.ArrayList;
import java.util.List;

public final class DocumentNode implements AstNode {
  public final List<BlockNode> blocks = new ArrayList<>();
  public AstNode rootValue;
  public String kind() { return "document"; }
}
