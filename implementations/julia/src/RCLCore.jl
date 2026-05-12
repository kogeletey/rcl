module RCLCore
include("rcl/Lexer.jl")
include("rcl/Parser.jl")
include("rcl/Converters.jl")

parse(s::String) = parse_rcl(s)
to_object(input) = to_object_doc(input isa String ? parse_rcl(input) : input)

end
