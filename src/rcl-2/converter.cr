# RCL to XrayDSL Converter

require "./ast"
require "../config"

module XrayRCL
  module Converter
    def self.to_xray_dsl(program : ProgramNode) : XrayDSL
      config = XrayDSL.new

      program.blocks.each do |block|
        next unless block.name == "xray"

        # Direct properties
        apply_direct_properties(config, block)

        # Nested blocks - handle any block name dynamically
        block.blocks.each do |name, nested|
          case name
          when "server" then apply_server_block(config, nested)
          when "akash" then apply_akash_block(config, nested)
          when "client", "clients" then apply_client_block(config, nested)
          when "proxy", "local_proxy" then apply_proxy_block(config, nested)
          when "reality" then apply_reality_block(config, nested)
          # Unknown blocks are ignored but don't cause errors
          end
        end
      end

      config
    end

    private def self.apply_direct_properties(config : XrayDSL, block : BlockNode)
      block.properties.each do |key, node|
        case key
        when "server_address" then config.server_address(node.as(StringNode).value)
        when "server_port" then config.server_port(node.as(NumberNode).value.to_i)
        when "reality_server_name" then config.reality_server_name(node.as(StringNode).value)
        when "fingerprint" then config.fingerprint(node.as(StringNode).value)
        when "flow" then config.flow(node.as(StringNode).value)
        when "socks_port" then config.socks_port(node.as(NumberNode).value.to_i)
        when "http_port" then config.http_port(node.as(NumberNode).value.to_i)
        when "api_port" then config.api_port(node.as(NumberNode).value.to_i)
        when "listen" then config.listen(node.as(StringNode).value)
        when "output" then config.output_dir(node.as(StringNode).value)
        when "users"
          node.as(ArrayNode).elements.each do |elem|
            config.client(elem.as(StringNode).value)
          end
        end
      end
    end

    private def self.apply_server_block(config : XrayDSL, block : BlockNode)
      block.properties.each do |key, node|
        case key
        when "address" then config.server_address(node.as(StringNode).value)
        when "port" then config.server_port(node.as(NumberNode).value.to_i)
        end
      end
    end

    private def self.apply_client_block(config : XrayDSL, block : BlockNode)
      block.properties.each do |key, node|
        case key
        when "fingerprint" then config.fingerprint(node.as(StringNode).value)
        when "flow" then config.flow(node.as(StringNode).value)
        end
      end
    end

    private def self.apply_proxy_block(config : XrayDSL, block : BlockNode)
      block.properties.each do |key, node|
        case key
        when "socks_port" then config.socks_port(node.as(NumberNode).value.to_i)
        when "http_port" then config.http_port(node.as(NumberNode).value.to_i)
        when "api_port" then config.api_port(node.as(NumberNode).value.to_i)
        when "listen" then config.listen(node.as(StringNode).value)
        end
      end
    end

    private def self.apply_reality_block(config : XrayDSL, block : BlockNode)
      block.properties.each do |key, node|
        case key
        when "server_name" then config.reality_server_name(node.as(StringNode).value)
        when "dest" then # dest is derived from server_name
        end
      end
    end

    private def self.apply_akash_block(config : XrayDSL, block : BlockNode)
      akash = config.akash_config
      block.properties.each do |key, node|
        case key
        when "deployment_name" then akash.deployment_name = node.as(StringNode).value
        when "placement_name" then akash.placement_name = node.as(StringNode).value
        when "pricing_amount" then akash.pricing_amount = node.as(NumberNode).value.to_i
        when "pricing_denom" then akash.pricing_denom = node.as(StringNode).value
        when "cpu_units", "cpu" then akash.cpu_units = node.as(NumberNode).value.to_i
        when "memory_size", "memory" then akash.memory_size = node.as(StringNode).value
        when "storage_size", "storage" then akash.storage_size = node.as(StringNode).value
        when "data_storage_size", "data" then akash.data_storage_size = node.as(StringNode).value
        when "storage_class" then akash.storage_class = node.as(StringNode).value
        when "image" then akash.image = node.as(StringNode).value
        when "expose_port" then akash.expose_port = node.as(NumberNode).value.to_i
        when "replicas" then akash.replicas = node.as(NumberNode).value.to_i
        when "enable_ip_lease" then akash.enable_ip_lease = node.as(BooleanNode).value
        when "ip_endpoint_name" then akash.ip_endpoint_name = node.as(StringNode).value
        # Additional placements (sandbox/test)
        when "placement_test_pricing_amount"
          akash.placements << AkashConfig::Placement.new("test", node.as(NumberNode).value.to_i, akash.pricing_denom)
        when "placement_test_pricing_denom"
          # Update the test placement denom if it exists
          test_placement = akash.placements.find(&.name.==("test"))
          if test_placement
            test_placement.pricing_denom = node.as(StringNode).value
          end
        end
      end
    end
  end

  # Parse RCL file
  def self.parse_file(path : String) : ProgramNode
    content = File.read(path)
    parse_string(content)
  end

  def self.parse_string(content : String) : ProgramNode
    lexer = Lexer.new(content)
    parser = Parser.new(lexer)
    parser.parse
  end

  def self.to_xray_dsl(program : ProgramNode) : XrayDSL
    Converter.to_xray_dsl(program)
  end
end
