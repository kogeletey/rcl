# RCL Block Handlers Registry
# Allows registering custom handlers for specific block types
#
# Usage:
#   RCL::Blocks.register("server") do |block, config|
#     config.server_address = block["address"]
#   end

module RCL
  module Blocks
    # Handler type: receives BlockNode and returns processed result
    alias Handler = BlockNode -> NamedTuple(status: Symbol, data: NamedTuple?)

    # Registry of block handlers
    @@handlers = {} of String => Handler

    # Register a handler for a block type
    def self.register(name : String, &block : BlockNode -> NamedTuple(status: Symbol, data: NamedTuple?))
      @@handlers[name] = block
    end

    # Check if handler exists for block type
    def self.registered?(name : String) : Bool
      @@handlers.has_key?(name)
    end

    # Get handler for block type
    def self.handler(name : String) : Handler?
      @@handlers[name]?
    end

    # Process a block with registered handler
    def self.process(block : BlockNode) : NamedTuple(status: Symbol, data: NamedTuple?)
      handler = @@handlers[block.name]?
      if handler
        handler.call(block)
      else
        # Unknown block - return as-is
        {:unknown, {block: block}.named_tuple}
      end
    end

    # Process all blocks from document
    def self.process_document(doc : Document) : Array(NamedTuple(status: Symbol, data: NamedTuple?))
      results = [] of NamedTuple(status: Symbol, data: NamedTuple?)
      doc.blocks.each do |block|
        results << process(block)
      end
      results
    end

    # Clear all handlers (for testing)
    def self.clear
      @@handlers.clear
    end

    # Get all registered handler names
    def self.names : Array(String)
      @@handlers.keys.to_a
    end
  end
end
