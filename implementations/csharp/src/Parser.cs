using System;
using System.Collections.Generic;

namespace RCLImpl {
public sealed class Parser {
  readonly List<Token> T;
  int P;
  public Parser(string src){ T=Lexer.Lex(src); P=0; }
  public DocumentNode Parse(){
    var d=new DocumentNode();
    if(Is(TokenKind.DO)){
      Eat(TokenKind.DO,"unexpected token");
      d.RootValue=ParseArray();
      if(!Is(TokenKind.EOF)) throw Err("unexpected token after root array");
      return d;
    }
    while(!Is(TokenKind.EOF)) d.Blocks.Add(ParseBlock());
    return d;
  }

  BlockNode ParseBlock(){
    var n=Eat(TokenKind.IDENT,"unexpected token");
    string arg=null; if(Is(TokenKind.STRING)) arg=Eat(TokenKind.STRING,"unexpected token").Text;
    Eat(TokenKind.DO,"unexpected token");
    var b=ParseBlockBody(n.Text,arg);
    Eat(TokenKind.END,"unexpected token");
    return b;
  }

  BlockNode ParseAnonymousBlock(){
    Eat(TokenKind.DO,"unexpected token");
    var b=ParseBlockBody("",null);
    Eat(TokenKind.END,"unexpected token");
    return b;
  }

  BlockNode ParseBlockBody(string name,string arg){
    var b=new BlockNode(name,arg); var seen=new List<string>();
    while(!Is(TokenKind.END)){
      if(Is(TokenKind.EOF)) throw Err("missing end");
      var cur=Eat(TokenKind.IDENT,"unexpected token"); var nx=PeekAt(1);
      if(nx.Kind==TokenKind.DO){
        var afterDo=PeekAt(2);
        if(afterDo.Kind==TokenKind.LBR){
          var key=cur.Text; ValidateKey(key,seen,cur);
          Eat(TokenKind.DO,"unexpected token");
          var v=ParseArray();
          Eat(TokenKind.END,"unexpected token");
          b.Properties[key]=v; b.PropertyOrder.Add(key);
        } else {
          P--; var c=ParseBlock(); if(c.Argument==null) b.Blocks.Add(c); else b.NamedBlocks.Add(c);
        }
      } else if(nx.Kind==TokenKind.EQ||nx.Kind==TokenKind.DOT){
        var key=ParseKey(cur.Text); ValidateKey(key,seen,cur);
        Eat(TokenKind.EQ,"unexpected token"); var v=ParseValue();
        b.Properties[key]=v; b.PropertyOrder.Add(key);
      } else if(nx.Kind==TokenKind.STRING){
        P--; var c=ParseBlock(); if(c.Argument==null) b.Blocks.Add(c); else b.NamedBlocks.Add(c);
      } else throw Err("unexpected token");
    }
    return b;
  }

  string ParseKey(string f){
    var k=f;
    while(Is(TokenKind.DOT)){ Eat(TokenKind.DOT,"unexpected token"); k+="."+Eat(TokenKind.IDENT,"unexpected token").Text; }
    return k;
  }

  IAstNode ParseValue(){
    if(Is(TokenKind.STRING)) return new StringNode(Eat(TokenKind.STRING,"unexpected token").Text);
    if(Is(TokenKind.NUMBER)) return new NumberNode(double.Parse(Eat(TokenKind.NUMBER,"unexpected token").Text,System.Globalization.CultureInfo.InvariantCulture));
    if(Is(TokenKind.IDENT)){
      var v=Eat(TokenKind.IDENT,"unexpected token").Text;
      if(v=="true"||v=="false") return new BooleanNode(v=="true");
      throw Err("invalid bare identifier value");
    }
    if(Is(TokenKind.LBR)) return ParseArray();
    if(Is(TokenKind.DO)) return ParseAnonymousBlock();
    throw Err("unexpected token");
  }

  IAstNode ParseArray(){
    Eat(TokenKind.LBR,"unexpected token"); var a=new ArrayNode();
    if(Is(TokenKind.RBR)){ Eat(TokenKind.RBR,"unexpected token"); return a; }
    a.Elements.Add(ParseValue());
    while(Is(TokenKind.COMMA)){
      Eat(TokenKind.COMMA,"unexpected token");
      if(Is(TokenKind.RBR)) throw Err("trailing comma in array");
      a.Elements.Add(ParseValue());
    }
    if(!Is(TokenKind.RBR)) throw Err("missing ]");
    Eat(TokenKind.RBR,"unexpected token"); return a;
  }

  void ValidateKey(string key,List<string> seen,Token t0){
    foreach(var ex in seen){
      if(ex==key) throw new ParseException("duplicate key",t0.Line,t0.Col);
      if(IsPrefix(ex,key)||IsPrefix(key,ex)) throw new ParseException("key-path prefix conflict",t0.Line,t0.Col);
    }
    seen.Add(key);
  }

  bool IsPrefix(string a,string b){ return a.Length<b.Length&&b.StartsWith(a+"."); }
  bool Is(TokenKind k){ return T[P].Kind==k; }
  Token PeekAt(int offset){ var idx=P+offset-1; if(idx<0) idx=0; if(idx>=T.Count) idx=T.Count-1; return T[idx]; }
  Token Peek(){ return PeekAt(1); }
  Token Eat(TokenKind k,string m){ if(!Is(k)) throw Err(m); return T[P++]; }
  ParseException Err(string m){ var x=T[Math.Min(P,T.Count-1)]; return new ParseException(m,x.Line,x.Col); }
}
}
