require "../spec_helper"

describe "RCL spec conformance" do
  it "parses core types, dotted keys, named blocks and projects region.arg" do
    source = <<-RCL
    config do
      enabled = true
      port = 8080
      ratio = 3.14
      tls.cert_path = "/etc/cert.pem"
      names = ["a", "b", 1, false]

      region "us" do
        name = "My name"
      end
    end
    RCL

    doc = RCL.parse_string(source)
    h = doc.to_h

    h["enabled"].should eq(true)
    h["port"].should eq(8080)
    h["ratio"].should eq(3.14)
    tls = h["tls"].as(Hash(String, RCL::Value))
    tls["cert_path"].should eq("/etc/cert.pem")

    region = h["region"].as(Hash(String, RCL::Value))
    us = region["us"].as(Hash(String, RCL::Value))
    us["name"].should eq("My name")
  end

  it "supports only # comments and rejects invalid syntax edges" do
    RCL.parse_string("config do\n  # comment\n  a = 1\nend").blocks.size.should eq(1)

    expect_raises(Exception) { RCL.parse_string("config do\n  a = [1, 2\nend") }
    expect_raises(Exception) { RCL.parse_string("config do\n  name = 'bad'\nend") }
    expect_raises(Exception) { RCL.parse_string("config do\n  name = value\nend") }
    expect_raises(Exception) { RCL.parse_string("config do\n  a = [1,]\nend") }
    expect_raises(Exception) { RCL.parse_string("config do\n  a = 1\n  a = 2\nend") }
    expect_raises(Exception) { RCL.parse_string("config do\n  a = 1\n  a.b = 2\nend") }
  end

  it "formats and converts to yaml/toml/hcl with region.us structure" do
    source = <<-RCL
    config do
      region "us" do
        name = "My name"
      end
    end
    RCL

    doc = RCL.parse_string(source)
    RCL.format(doc).should contain("region \"us\" do")
    RCL.to_yaml(doc).should contain("region:")
    RCL.to_toml(doc).should contain("[region.us]")
    RCL.to_hcl(doc).should contain("region {")
    doc.to_json.should contain("\"kind\":\"document\"")
  end
end
