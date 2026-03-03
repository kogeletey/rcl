config {
  enabled = true
  port = 8080
  ratio = 3.14
  tls {
    cert_path = "/etc/cert.pem"
  }
  names = ["a", "b", 1, false]
  regions {
    us {
      name = "My Name"
    }
  }
}
