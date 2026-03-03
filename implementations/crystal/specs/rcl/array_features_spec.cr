require "../spec_helper"

describe "RCL array features" do
  it "parses named array assignment with anonymous blocks in elements" do
    source = <<-RCL
    config do
      tests do [
        do
          name = "case-1"
        end,
        "string"
      ] end
    end
    RCL

    doc = RCL.parse_string(source)
    cfg = doc.to_h["config"].as(Hash(String, RCL::Value))
    tests = cfg["tests"].as(Array(RCL::Value))

    tests.size.should eq(2)
    tests[0].as(Hash(String, RCL::Value))["name"].should eq("case-1")
    tests[1].should eq("string")
    RCL.format(doc).should contain("tests do [do name = \"case-1\" end, \"string\"] end")
  end

  it "parses unnamed root array document" do
    source = <<-RCL
    do [
      do
        name = "block-item"
      end,
      "string"
    ]
    RCL

    doc = RCL.parse_string(source)
    root = doc.to_value.as(Array(RCL::Value))
    root.size.should eq(2)
    root[0].as(Hash(String, RCL::Value))["name"].should eq("block-item")
    root[1].should eq("string")

    RCL.to_yaml(doc).should contain("-")
    RCL.to_toml(doc).should contain("root =")
    RCL.to_hcl(doc).should contain("root =")
  end
end
