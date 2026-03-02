require "../spec_helper"

describe RCL::Formatter do
  it "formats simple block" do
    source = "xray do\n  port = 8080\n  enabled = true\nend"
    doc = RCL.parse_string(source)

    formatted = RCL.format(doc)

    formatted.should eq(source)
  end

  it "formats nested blocks and arrays" do
    source = "xray do\n  users = [\"a@b.com\", \"c@d.com\"]\n  akash \"cluster-a\" do\n    replicas = 2\n  end\nend"
    formatted = RCL.format(RCL.parse_string(source))

    formatted.should contain("akash \"cluster-a\" do")
    formatted.should contain("users = [\"a@b.com\", \"c@d.com\"]")
  end
end
