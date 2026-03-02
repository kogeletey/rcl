require "../spec_helper"

describe "AST serialization" do
  it "produces stable document ast hash" do
    doc = RCL.parse_string("xray do\n  port = 8080\nend")
    ast = doc.to_ast_h

    ast["kind"].should eq("document")
    blocks = ast["blocks"].as(Array(RCL::Value))
    first_block = blocks.first.as(Hash(String, RCL::Value))
    first_block["kind"].should eq("block")
    first_block["name"].should eq("xray")
  end

  it "serializes to json" do
    doc = RCL.parse_string("xray do\n  enabled = true\nend")
    json = doc.to_json
    json.should contain("\"kind\":\"document\"")
    json.should contain("\"kind\":\"block\"")
    json.should contain("\"kind\":\"boolean\"")
  end
end
