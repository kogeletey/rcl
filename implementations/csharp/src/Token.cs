namespace RCLImpl {
public enum TokenKind { EOF, IDENT, STRING, NUMBER, DO, END, EQ, COMMA, DOT, LBR, RBR }

public sealed class Token {
  public TokenKind Kind;
  public string Text;
  public int Line;
  public int Col;
  public Token(TokenKind k,string t,int l,int c){ Kind=k; Text=t; Line=l; Col=c; }
}

public sealed class ParseException : System.Exception {
  public int Line;
  public int Column;
  public ParseException(string m,int l,int c):base("line "+l+", column "+c+": "+m){ Line=l; Column=c; }
}
}
