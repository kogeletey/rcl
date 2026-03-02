using System;
using System.Diagnostics;
using System.IO;
namespace RCLImpl {
public static class RCL {
  static string Run(string op, string text) {
    var p = new Process();
    p.StartInfo.FileName = "ruby";
    p.StartInfo.Arguments = "../ruby/lib/rcl/bridge.rb " + op;
    p.StartInfo.RedirectStandardInput = true;
    p.StartInfo.RedirectStandardOutput = true;
    p.StartInfo.RedirectStandardError = true;
    p.StartInfo.UseShellExecute = false;
    p.Start();
    p.StandardInput.Write(text);
    p.StandardInput.Close();
    var o = p.StandardOutput.ReadToEnd();
    var e = p.StandardError.ReadToEnd();
    p.WaitForExit();
    if (p.ExitCode != 0) throw new Exception(string.IsNullOrWhiteSpace(e) ? o : e);
    return o;
  }
  public static string Parse(string s) => Run("parse", s);
  public static string Format(string s) => Run("format", s);
  public static string ToObject(string s) => Run("object", s);
  public static string ToYAML(string s) => Run("yaml", s);
  public static string ToTOML(string s) => Run("toml", s);
  public static string ToHCL(string s) => Run("hcl", s);
}}
