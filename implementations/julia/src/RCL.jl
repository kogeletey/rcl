module RCL
include("rcl/Lexer.jl")
include("rcl/Parser.jl")
include("rcl/Formatter.jl")
include("rcl/Converters.jl")

parse(s::String) = parse_rcl(s)
format(input) = format_rcl(input isa String ? parse_rcl(input) : input)
to_object(input) = to_object_doc(input isa String ? parse_rcl(input) : input)
to_yaml(input) = emit_yaml(to_object(input))
to_toml(input) = emit_toml(to_object(input))
to_hcl(input) = emit_hcl(to_object(input))

end
