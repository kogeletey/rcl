/**
 * Treesitter Grammar for RCL (Ray Configuration Language)
 *
 * Install:
 *   npm install -g tree-sitter-cli
 *   tree-sitter generate
 *   tree-sitter test
 */

module.exports = grammar({
  name: 'rcl',

  extras: $ => [
    /\s/,
    $.comment
  ],

  conflicts: $ => [
    [$.block],
  ],

  rules: {
    source_file: $ => repeat($._statement),

    _statement: $ => choice(
      $.block,
      $.assignment
    ),

    // Block: name do ... end
    block: $ => seq(
      $.identifier,
      'do',
      repeat($._statement),
      'end'
    ),

    // Assignment: name = value
    assignment: $ => seq(
      $.identifier,
      '=',
      $._value
    ),

    _value: $ => choice(
      $.string,
      $.number,
      $.array
    ),

    // String: "..."
    string: $ => seq(
      '"',
      repeat(choice(
        /[^"\\]/,
        seq('\\', '"')
      )),
      '"'
    ),

    // Number: integers and floats
    number: $ => /\d+(\.\d+)?/,

    // Array: [a, b, c]
    array: $ => seq(
      '[',
      optional(seq(
        $._value,
        repeat(seq(',', $._value)),
        optional(',')
      )),
      ']'
    ),

    // Identifier: alphanumeric with underscores
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    // Comment: # or //
    comment: $ => token(
      seq('#', /.*/)
    )
  }
});
