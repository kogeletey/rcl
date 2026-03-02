require "../spec_helper"

describe "RCL converters and named blocks" do
  it "projects named block to nested key by argument" do
    source = <<-RCL
    config do
      region "us" do
        name = "My name"
      end
    end
    RCL

    doc = RCL.parse_string(source)
    h = doc.to_h
    region = h["region"].as(Hash(String, RCL::Value))
    us = region["us"].as(Hash(String, RCL::Value))
    us["name"].should eq("My name")
  end

  it "converts to yaml/toml/hcl" do
    source = <<-RCL
    config do
      enabled = true
      region "us" do
        name = "My name"
      end
    end
    RCL
    doc = RCL.parse_string(source)

    yaml = RCL.to_yaml(doc)
    toml = RCL.to_toml(doc)
    hcl = RCL.to_hcl(doc)

    yaml.should contain("region:")
    yaml.should contain("us:")
    toml.should contain("[region]")
    toml.should contain("[region.us]")
    hcl.should contain("region {")
    hcl.should contain("us {")
  end
end
