{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.presets.nginx;
in
{
  options = {
    presets.nginx.enable = lib.mkEnableOption "Nginx template";

    presets.nginx.useACMEHost = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
    };

    presets.nginx.quic = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable HTTP/3 and reserve UDP 443 for preset virtual hosts.";
    };

    presets.nginx.virtualHosts = lib.mkOption {
      type = with lib.types; attrsOf attrs;
      default = { };
    };

    presets.nginx.selfSignedVirtualHosts = lib.mkOption {
      type = with lib.types; attrsOf attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [
        # keep-sorted start numeric=yes
        80
        443
        # keep-sorted end
      ];
      allowedUDPPorts = lib.optionals cfg.quic [ 443 ];
    };

    security.acme.acceptTerms = true;
    security.acme.defaults.email = "le@rvf6.com";

    services.nginx = {
      enable = true;
      package = pkgs.nginxMainline;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts =
        builtins.mapAttrs (
          name: value:
          {
            forceSSL = true;
            enableACME = cfg.useACMEHost == null;
            inherit (cfg) useACMEHost;
            quic = cfg.quic;
            http3 = cfg.quic;
          }
          // value
          // {
            extraConfig = ''
              ${if value ? "extraConfig" then value.extraConfig else ""}
              add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
              ${lib.optionalString cfg.quic ''add_header Alt-Svc 'h3=":$server_port"; ma=86400';''}
            '';
          }
        ) cfg.virtualHosts
        // (builtins.mapAttrs (
          name: value:
          {
            forceSSL = true;
            quic = cfg.quic;
            http3 = cfg.quic;
            sslCertificate = config.sops.secrets."pki/rvf6.com.crt".path;
            sslCertificateKey = config.sops.secrets."pki/rvf6.com.key".path;
            sslTrustedCertificate = config.sops.secrets."pki/all-ca".path;
          }
          // value
          // {
            extraConfig = ''
              ${if value ? "extraConfig" then value.extraConfig else ""}
              ssl_verify_client on;
              add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
              ${lib.optionalString cfg.quic ''add_header Alt-Svc 'h3=":$server_port"; ma=86400';''}
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
