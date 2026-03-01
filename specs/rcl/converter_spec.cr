# RCL Converter Specs

require "../spec_helper"

describe XrayRCL::Converter do
  describe "#to_xray_dsl" do
    it "converts server_address" do
      content = "xray do\n  server_address = \"test.com\"\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.server_address.should eq("test.com")
    end

    it "converts server_port" do
      content = "xray do\n  server_port = 443\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.server_port.should eq(443)
    end

    it "converts reality_server_name" do
      content = "xray do\n  reality_server_name = \"col.pub\"\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.reality_server_name.should eq("col.pub")
    end

    it "converts fingerprint" do
      content = "xray do\n  fingerprint = \"chrome\"\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.fingerprint.should eq("chrome")
    end

    it "converts flow" do
      content = "xray do\n  flow = \"xtls-rprx-vision\"\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.flow.should eq("xtls-rprx-vision")
    end

    it "converts users array" do
      content = "xray do\n  users = [\"a@b.com\", \"c@d.com\"]\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.clients.size.should eq(2)
      config.clients.should eq(["a@b.com", "c@d.com"])
    end

    it "converts output directory" do
      content = "xray do\n  output = \"./custom\"\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.output_dir.should eq("./custom")
    end
  end

  describe "#to_xray_dsl - server block" do
    it "converts server block" do
      content = "xray do\n  server do\n    address = \"example.com\"\n    port = 8080\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.server_address.should eq("example.com")
      config.server_port.should eq(8080)
    end
  end

  describe "#to_xray_dsl - reality block" do
    it "converts reality block" do
      content = "xray do\n  reality do\n    server_name = \"col.pub\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.reality_server_name.should eq("col.pub")
    end
  end

  describe "#to_xray_dsl - client block" do
    it "converts client block" do
      content = "xray do\n  client do\n    fingerprint = \"firefox\"\n    flow = \"xtls-rprx-vision\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.fingerprint.should eq("firefox")
      config.flow.should eq("xtls-rprx-vision")
    end
  end

  describe "#to_xray_dsl - proxy block" do
    it "converts proxy block" do
      content = "xray do\n  proxy do\n    socks_port = 1080\n    http_port = 10010\n    api_port = 10086\n    listen = \"127.0.0.1\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      config.socks_port.should eq(1080)
      config.http_port.should eq(10010)
      config.api_port.should eq(10086)
      config.listen.should eq("127.0.0.1")
    end
  end

  describe "#to_xray_dsl - akash block" do
    it "converts akash deployment_name" do
      content = "xray do\n  akash do\n    deployment_name = \"my-service\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config
      akash.deployment_name.should eq("my-service")
    end

    it "converts akash pricing_amount" do
      content = "xray do\n  akash do\n    pricing_amount = 25\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config
      akash.pricing_amount.should eq(25)
    end

    it "converts akash cpu_units" do
      content = "xray do\n  akash do\n    cpu_units = 2\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config
      akash.cpu_units.should eq(2)
    end

    it "converts akash memory_size" do
      content = "xray do\n  akash do\n    memory_size = \"2048Mi\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config
      akash.memory_size.should eq("2048Mi")
    end

    it "converts akash enable_ip_lease true" do
      content = "xray do\n  akash do\n    enable_ip_lease = true\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config
      akash.enable_ip_lease.should eq(true)
    end

    it "converts akash enable_ip_lease false" do
      content = "xray do\n  akash do\n    enable_ip_lease = false\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config
      akash.enable_ip_lease.should eq(false)
    end

    it "converts full akash block" do
      content = "xray do\n  akash do\n    deployment_name = \"service-1\"\n    placement_name = \"dcloud\"\n    pricing_amount = 18\n    cpu_units = 1\n    memory_size = \"1024Mi\"\n    storage_size = \"1Gi\"\n    data_storage_size = \"10Gi\"\n    storage_class = \"beta3\"\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)
      akash = config.akash_config

      akash.deployment_name.should eq("service-1")
      akash.placement_name.should eq("dcloud")
      akash.pricing_amount.should eq(18)
      akash.cpu_units.should eq(1)
      akash.memory_size.should eq("1024Mi")
    end
  end

  describe "#to_xray_dsl - full config" do
    it "converts complete xray config" do
      content = "xray do\n  server_address = \"provider.boogle.cloud\"\n  server_port = 32185\n  reality_server_name = \"col.pub\"\n  users = [\"love@xray.com\"]\n  akash do\n    deployment_name = \"service-1\"\n    pricing_amount = 18\n  end\nend"

      program = XrayRCL.parse_string(content)
      config = XrayRCL.to_xray_dsl(program)

      config.server_address.should eq("provider.boogle.cloud")
      config.server_port.should eq(32185)
      config.reality_server_name.should eq("col.pub")
      config.clients.size.should eq(1)

      akash = config.akash_config
      akash.deployment_name.should eq("service-1")
      akash.pricing_amount.should eq(18)
    end
  end
end
