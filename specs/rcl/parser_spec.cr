# RCL Parser Specs

require "../spec_helper"

describe XrayRCL::Parser do
  describe "#parse - simple blocks" do
    it "parses single block" do
      content = "xray do\n  server_port = 32185\nend"

      program = XrayRCL.parse_string(content)
      program.blocks.size.should eq(1)
      program.blocks[0].name.should eq("xray")
      program.blocks[0].properties["server_port"].should_not be_nil
    end

    it "parses block with multiple properties" do
      content = "xray do\n  server_port = 32185\n  server_address = \"test.com\"\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      block.properties.size.should eq(2)
    end

    it "parses property with string value" do
      content = "xray do\n  server_address = \"example.com\"\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      addr = block.properties["server_address"]
      addr.as(XrayRCL::StringNode).value.should eq("example.com")
    end

    it "parses property with number value" do
      content = "xray do\n  server_port = 32185\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      port = block.properties["server_port"]
      port.as(XrayRCL::NumberNode).value.should eq(32185)
    end
  end

  describe "#parse - nested blocks" do
    it "parses single nested block" do
      content = "xray do\n  akash do\n    deployment_name = \"service-1\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      xray_block = program.blocks[0]
      xray_block.blocks["akash"].should_not be_nil
    end

    it "parses multiple nested blocks" do
      content = "xray do\n  server do\n    port = 443\n  end\n  akash do\n    name = \"test\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      xray_block = program.blocks[0]
      xray_block.blocks.keys.should eq(["server", "akash"])
    end

    it "parses nested blocks with arbitrary names" do
      content = "xray do\n  custom_block do\n    some_value = 123\n  end\n  another_one do\n    name = \"test\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      xray_block = program.blocks[0]
      xray_block.blocks["custom_block"].should_not be_nil
      xray_block.blocks["another_one"].should_not be_nil
    end

    it "parses deeply nested blocks" do
      content = "xray do\n  level1 do\n    level2 do\n      value = 1\n    end\n  end\nend"

      program = XrayRCL.parse_string(content)
      level1 = program.blocks[0].blocks["level1"]
      level1.blocks["level2"].should_not be_nil
    end
  end

  describe "#parse - arrays" do
    it "parses array of strings" do
      content = "xray do\n  users = [\"a@b.com\", \"c@d.com\"]\nend"

      program = XrayRCL.parse_string(content)
      users = program.blocks[0].properties["users"]
      users.as(XrayRCL::ArrayNode).elements.size.should eq(2)
    end

    it "parses empty array" do
      content = "xray do\n  items = []\nend"

      program = XrayRCL.parse_string(content)
      items = program.blocks[0].properties["items"]
      items.as(XrayRCL::ArrayNode).elements.size.should eq(0)
    end

    it "parses array with single element" do
      content = "xray do\n  single = [\"one\"]\nend"

      program = XrayRCL.parse_string(content)
      single = program.blocks[0].properties["single"]
      single.as(XrayRCL::ArrayNode).elements.size.should eq(1)
    end
  end

  describe "#parse - large numbers" do
    it "parses large port number" do
      content = "xray do\n  server_port = 12598959\nend"

      program = XrayRCL.parse_string(content)
      port = program.blocks[0].properties["server_port"]
      port.as(XrayRCL::NumberNode).value.should eq(12598959)
    end

    it "parses very large pricing amount" do
      content = "xray do\n  pricing_amount = 987654321\nend"

      program = XrayRCL.parse_string(content)
      amount = program.blocks[0].properties["pricing_amount"]
      amount.as(XrayRCL::NumberNode).value.should eq(987654321)
    end
  end

  describe "#parse - comments" do
    it "ignores hash comments in blocks" do
      content = "xray do\n  # This is a comment\n  server_port = 32185\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      block.properties["server_port"].should_not be_nil
    end
  end

  describe "#parse - complex config" do
    it "parses full xray config" do
      content = "xray do\n  server_address = \"provider.boogle.cloud\"\n  server_port = 32185\n  users = [\"love@xray.com\", \"love1@xray.com\"]\n  akash do\n    deployment_name = \"service-1\"\n    pricing_amount = 18\n    cpu_units = 1\n  end\nend"

      program = XrayRCL.parse_string(content)
      program.blocks.size.should eq(1)

      block = program.blocks[0]
      block.name.should eq("xray")
      block.properties["server_address"].should_not be_nil
      block.properties["users"].should_not be_nil
      block.blocks["akash"].should_not be_nil
    end
  end

  describe "#parse - boolean values" do
    it "parses true value" do
      content = "xray do\n  enabled = true\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      enabled = block.properties["enabled"]
      enabled.should_not be_nil
      enabled.as(XrayRCL::BooleanNode).value.should eq(true)
    end

    it "parses false value" do
      content = "xray do\n  enabled = false\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      enabled = block.properties["enabled"]
      enabled.should_not be_nil
      enabled.as(XrayRCL::BooleanNode).value.should eq(false)
    end

    it "parses mixed boolean and other values" do
      content = "xray do\n  enabled = true\n  disabled = false\n  port = 8080\n  name = \"test\"\nend"

      program = XrayRCL.parse_string(content)
      block = program.blocks[0]
      block.properties["enabled"].as(XrayRCL::BooleanNode).value.should eq(true)
      block.properties["disabled"].as(XrayRCL::BooleanNode).value.should eq(false)
      block.properties["port"].as(XrayRCL::NumberNode).value.should eq(8080)
      block.properties["name"].as(XrayRCL::StringNode).value.should eq("test")
    end
  end
end
