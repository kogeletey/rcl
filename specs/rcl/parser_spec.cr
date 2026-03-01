require "spec_helper"

describe RCL::Parser do
  describe "#parse - simple blocks" do
    it "parses single block" do
      content = "xray do\n  server_port = 32185\nend"
      doc = RCL.parse_string(content)
      doc.blocks.size.should eq(1)
      doc.blocks[0].name.should eq("xray")
      doc.blocks[0].properties["server_port"].should_not be_nil
    end

    it "parses block with multiple properties" do
      content = "xray do\n  server_port = 32185\n  server_address = \"test.com\"\nend"
      doc = RCL.parse_string(content)
      block = doc.blocks[0]
      block.properties.size.should eq(2)
    end

    it "parses property with string value" do
      content = "xray do\n  server_address = \"example.com\"\nend"
      doc = RCL.parse_string(content)
      block = doc.blocks[0]
      addr = block.properties["server_address"]
      addr.as(RCL::StringNode).value.should eq("example.com")
    end

    it "parses property with number value" do
      content = "xray do\n  server_port = 32185\nend"
      doc = RCL.parse_string(content)
      block = doc.blocks[0]
      port = block.properties["server_port"]
      port.as(RCL::NumberNode).value.should eq(32185)
    end
  end

  describe "#parse - nested blocks" do
    it "parses single nested block" do
      content = "xray do\n  akash do\n    deployment_name = \"service-1\"\n  end\nend"
      doc = RCL.parse_string(content)
      xray_block = doc.blocks[0]
      xray_block.blocks["akash"].should_not be_nil
    end

    it "parses multiple nested blocks" do
      content = "xray do\n  server do\n    port = 443\n  end\n  akash do\n    name = \"test\"\n  end\nend"
      doc = RCL.parse_string(content)
      xray_block = doc.blocks[0]
      xray_block.blocks.keys.should eq(["server", "akash"])
    end

    it "parses deeply nested blocks" do
      content = "xray do\n  level1 do\n    level2 do\n      value = 1\n    end\n  end\nend"
      doc = RCL.parse_string(content)
      level1 = doc.blocks[0].blocks["level1"]
      level1.blocks["level2"].should_not be_nil
    end
  end

  describe "#parse - arrays" do
    it "parses array of strings" do
      content = "xray do\n  users = [\"a@b.com\", \"c@d.com\"]\nend"
      doc = RCL.parse_string(content)
      users = doc.blocks[0].properties["users"]
      users.as(RCL::ArrayNode).elements.size.should eq(2)
    end

    it "parses empty array" do
      content = "xray do\n  items = []\nend"
      doc = RCL.parse_string(content)
      items = doc.blocks[0].properties["items"]
      items.as(RCL::ArrayNode).elements.size.should eq(0)
    end
  end

  describe "#parse - boolean values" do
    it "parses true value" do
      content = "xray do\n  enabled = true\nend"
      doc = RCL.parse_string(content)
      block = doc.blocks[0]
      enabled = block.properties["enabled"]
      enabled.as(RCL::BooleanNode).value.should eq(true)
    end

    it "parses false value" do
      content = "xray do\n  enabled = false\nend"
      doc = RCL.parse_string(content)
      block = doc.blocks[0]
      enabled = block.properties["enabled"]
      enabled.as(RCL::BooleanNode).value.should eq(false)
    end
  end
end
