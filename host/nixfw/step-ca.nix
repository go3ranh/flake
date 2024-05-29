{ domain, ... }: {
  root = "/var/lib/step-ca/certs/root_ca.crt";
  federatedRoots = null;
  crt = "/var/lib/step-ca/certs/intermediate_ca.crt";
  key = "/var/lib/step-ca/secrets/intermediate_ca_key";
  address = "10.0.0.1:443";
  insecureAddress = "";
  dnsNames = [
    "nixfw.${domain}"
    "10.0.0.1"
  ];
  logger = {
    format = "text";
  };
  db = {
    type = "badgerv2";
    dataSource = "/var/lib/step-ca/db";
    badgerFileLoadingMode = "";
  };
  crl = {
    enabled = false;
  };
  authority = {
    provisioners = [
      {
        type = "JWK";
        name = "admin@${domain}";
        key = {
          use = "sig";
          kty = "EC";
          kid = "wPZnnUaqOAmCuGafhOK0V2uP0mfOME-W0Dv7zUh48nk";
          crv = "P-256";
          alg = "ES256";
          x = "oZo2aQQTmbCr7YG35xefaMe1ZGmiiY9CySNapB1fDRU";
          y = "X5Sl7iWXaExLnBaZljUknFiuPAiYkDoORTFpIJTTfdo";
        };
        encryptedKey = "eyJhbGciOiJQQkVTMi1IUzI1NitBMTI4S1ciLCJjdHkiOiJqd2sranNvbiIsImVuYyI6IkEyNTZHQ00iLCJwMmMiOjYwMDAwMCwicDJzIjoiODI4SlIzd0N3Q2RUc2MwdnR6eUhhQSJ9.avoDKcXPk682WcLrKWNF2oXDljX7PEzIEClF06UlHSi86NkzBOI_uA.CsenoehhYaorgE9S.r5I1PdMGiQP2pdnk2q6915v2xHLCAH__jhieL9uzmuQNKatmidq9WiS4_7h-LBFDt790rnapyhmhLB86K1v1xIOf86-7-5VHJI4VhLQ1WfP7fG9K7Egf5S-Colkupytu6-oe3KYfJOQOwimIJk-hrif_LhaYevh0XjMckThoMYMC_tntOVvrvkdqjmt0NC8lKF1qQ9hHnOAHUxbJQ-CnpfculowQQTGLZI0P8Ivq3DGxyWto0ezpNmqz2WGOEIbdmtTsYUCiToXcsTaK-g_pCgABYM0j18XK8Iebjdr_wwWGSh1Kw3nCQIjiLNx6K1vK70nDF9Bq-kHJIwVk-xQ.6jWqHlZIU0VtIVDBLc1AhQ";
      }
      {
        type = "SSHPOP";
        name = "sshpop-smallstep";
        claims = {
          enableSSHCA = true;
        };
      }
      {
        type = "ACME";
        name = "acme";
        challenges = [
          "http-01"
          "tls-alpn-01"
        ];
      }
    ];
    claims = {
      minTLSCertDuration = "5m";
      maxTLSCertDuration = "168h";
      defaultTLSCertDuration = "24h";
      disableRenewal = false;
      allowRenewalAfterExpiry = false;
      minHostSSHCertDuration = "5m";
      maxHostSSHCertDuration = "1680h";
      defaultHostSSHCertDuration = "720h";
      minUserSSHCertDuration = "5m";
      maxUserSSHCertDuration = "24h";
      defaultUserSSHCertDuration = "16h";
    };
    policy = {
      x509 = {
        allow = {
          dns = [
            "*.${domain}"
          ];
        };
      };
      ssh = {
        user = {
          allow = {
            email = [
              "@${domain}"
            ];
          };
        };
        host = {
          allow = {
            dns = [
              "*.${domain}"
            ];
          };
        };
      };
    };
  };
  tls = {
    cipherSuites = [
      "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
      "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
    ];
    minVersion = 1.2;
    maxVersion = 1.3;
    renegotiation = false;
  };
}
