{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    # keep-sorted start
    mkEnableOption
    mkIf
    mkOption
    optionalString
    optionals
    types
    # keep-sorted end
    ;

  cfg = config.presets.nginx;

  HSTSLine = ''add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;'';
  AltSvcH3Line = ''add_header Alt-Svc 'h3=":$server_port"; ma=86400';'';
in
{
  options = {
    presets.nginx.enable = mkEnableOption "Nginx template";

    presets.nginx.useACMEHost = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    presets.nginx.quic = mkOption {
      type = types.bool;
      default = true;
      description = "Enable HTTP/3 and reserve UDP 443 for preset virtual hosts.";
    };

    presets.nginx.virtualHosts = mkOption {
      type = with types; attrsOf attrs;
      default = { };
    };

    presets.nginx.selfSignedVirtualHosts = mkOption {
      type = with types; attrsOf attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        # keep-sorted start numeric=yes
        80
        443
        # keep-sorted end
      ];
      allowedUDPPorts = optionals cfg.quic [ 443 ];
    };

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "le@rvf6.com";

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedBrotliSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      appendHttpConfig = ''
        access_log syslog:server=unix:/dev/log;
      '';
      virtualHosts =
        builtins.mapAttrs (
          name: value:
          {
            forceSSL = true;
            enableACME = cfg.useACMEHost == null;
            inherit (cfg) useACMEHost;
            quic = cfg.quic;
            http3 = cfg.quic;
            kTLS = true;
          }
          // value
          // {
            extraConfig = ''
              ${optionalString (value ? "extraConfig") value.extraConfig}
              ${HSTSLine}
              ${optionalString cfg.quic AltSvcH3Line}
            '';
          }
        ) cfg.virtualHosts
        // (builtins.mapAttrs (
          name: value:
          {
            forceSSL = true;
            quic = cfg.quic;
            http3 = cfg.quic;
            kTLS = true;
            sslCertificate = config.sops.secrets."pki/rvf6.com.crt".path;
            sslCertificateKey = config.sops.secrets."pki/rvf6.com.key".path;
            sslTrustedCertificate = config.sops.secrets."pki/all-ca".path;
          }
          // value
          // {
            extraConfig = ''
              ${optionalString (value ? "extraConfig") value.extraConfig}
              ssl_verify_client on;
              ${HSTSLine}
              ${optionalString cfg.quic AltSvcH3Line}
            '';
          }
        ) cfg.selfSignedVirtualHosts);
    };

    presets.nginx.virtualHosts."${config.networking.hostName}.rvf6.com" = {
      default = true;
      reuseport = true;
    };
  };
}
