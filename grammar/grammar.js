module.exports = grammar({
  name: 'rcl',

  extras: $ => [
    /\s/,
    $.comment
  ],

  rules: {
    source_file: $ => repeat($._statement),

    _statement: $ => choice(
      $.block,
      $.assignment
    ),

    block: $ => seq(
      $.identifier,
      optional($.string),
      'do',
      repeat($._statement),
      'end'
    ),

    assignment: $ => seq(
      $.property_key,
      '=',
      $._value
    ),

    property_key: $ => seq(
      $.identifier,
      repeat(seq('.', $.identifier))
    ),

    _value: $ => choice(
      $.string,
      $.number,
      $.boolean,
      $.array
    ),

    string: $ => seq(
      '"',
      repeat(choice(
        token.immediate(/[^"\\\n]+/),
        $.escape_sequence
      )),
      '"'
    ),

    escape_sequence: $ => token.immediate(seq('\\', /["\\nt]/)),

    number: $ => /-?\d+(\.\d+)?/,

    boolean: $ => choice('true', 'false'),

    array: $ => seq(
      '[',
      optional(seq(
        $._value,
        repeat(seq(',', $._value))
      )),
      ']'
    ),

    identifier: $ => /[A-Za-z_][A-Za-z0-9_]*/,

    comment: $ => token(
      seq('#', /.*/)
    )
  }
});
