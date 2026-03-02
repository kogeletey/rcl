using System;
using System.Collections.Generic;

namespace RCLImpl {
public static class Lexer {
  public static List<Token> Lex(string src){
    var outp = new List<Token>();
    int i=0,l=1,c=1,n=src.Length;
    while(i<n){
      char ch=src[i];
      if(ch==' '||ch=='\t'||ch=='\r'){ i++; c++; continue; }
      if(ch=='\n'){ i++; l++; c=1; continue; }
      if(ch=='#'){ while(i<n&&src[i]!='\n'){ i++; c++; } continue; }
      if(ch=='\'') throw Err("single-quoted string usage",l,c);
      if(ch=='/'&&i+1<n&&src[i+1]=='/') throw Err("unexpected character",l,c);
      if(IdStart(ch)){
        int s=i,c0=c; while(i<n&&IdPart(src[i])){ i++; c++; }
        string v=src.Substring(s,i-s);
        outp.Add(new Token(v=="do"?TokenKind.DO:v=="end"?TokenKind.END:TokenKind.IDENT,v,l,c0));
        continue;
      }
      if(ch=='-'||char.IsDigit(ch)){
        int s=i,c0=c;
        if(ch=='-'){ if(i+1>=n||!char.IsDigit(src[i+1])) throw Err("unexpected character",l,c); i++; c++; }
        while(i<n&&char.IsDigit(src[i])){ i++; c++; }
        if(i<n&&src[i]=='.'){ if(i+1>=n||!char.IsDigit(src[i+1])) throw Err("unexpected character",l,c); i++; c++; while(i<n&&char.IsDigit(src[i])){ i++; c++; } }
        outp.Add(new Token(TokenKind.NUMBER,src.Substring(s,i-s),l,c0));
        continue;
      }
      if(ch=='"'){
        int c0=c; i++; c++; var s="";
        while(i<n&&src[i]!='"'){
          char x=src[i];
          if(x=='\n') throw Err("unterminated string",l,c0);
          if(x=='\\'){
            i++; c++; if(i>=n) throw Err("unterminated string",l,c0);
            char e=src[i];
            if(e=='"') s+='"'; else if(e=='\\') s+='\\'; else if(e=='n') s+='\n'; else if(e=='t') s+='\t'; else throw Err("invalid escape",l,c);
            i++; c++; continue;
          }
          s+=x; i++; c++;
        }
        if(i>=n) throw Err("unterminated string",l,c0);
        i++; c++; outp.Add(new Token(TokenKind.STRING,s,l,c0)); continue;
      }
      TokenKind k;
      if(ch=='=') k=TokenKind.EQ;
      else if(ch==',') k=TokenKind.COMMA;
      else if(ch=='.') k=TokenKind.DOT;
      else if(ch=='[') k=TokenKind.LBR;
      else if(ch==']') k=TokenKind.RBR;
      else throw Err("unexpected character",l,c);
      outp.Add(new Token(k,ch.ToString(),l,c)); i++; c++;
    }
    outp.Add(new Token(TokenKind.EOF,"",l,c));
    return outp;
  }

  static bool IdStart(char ch){ return char.IsLetter(ch)||ch=='_'; }
  static bool IdPart(char ch){ return char.IsLetterOrDigit(ch)||ch=='_'; }
  static ParseException Err(string m,int l,int c){ return new ParseException(m,l,c); }
}
}
