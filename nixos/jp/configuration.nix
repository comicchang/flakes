{ config, ... }:
{

  presets.nogui.enable = true;
  presets.disko.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
    pocket-id-encryption-key.owner = config.services.pocket-id.user;
  };

  networking.hostName = "jp";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "2403:71c0:2000:133b::a/64"
      "172.93.220.78/24"
    ];
    dns = [
      "8.8.8.8"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2403:71c0:2000::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "172.93.220.1";
        GatewayOnLink = true;
      }
    ];
  };

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  home-manager.users.rvfg = import ./home.nix;

  services.postgresql = {
    enable = true;
    ensureUsers = [
      {
        name = "pocket-id";
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ "pocket-id" ];
  };

  services.pocket-id = {
    enable = true;
    settings = {
      APP_URL = "https://pocket-id.rvf6.com";
      ENCRYPTION_KEY_FILE = config.sops.secrets.pocket-id-encryption-key.path;
      ALLOW_INSECURE_CALLBACK_URLS = false;
      DB_CONNECTION_STRING = "postgres:///pocket-id";
      UNIX_SOCKET = "/run/pocket-id/sock";
      UNIX_SOCKET_MODE = "0660";
      ANALYTICS_DISABLED = true;
      VERSION_CHECK_DISABLED = true;
    };
  };
  systemd.services.pocket-id = {
    requires = [ "postgresql.target" ];
    after = [ "postgresql.target" ];
    serviceConfig = {
      RuntimeDirectory = "pocket-id";
      RuntimeDirectoryMode = "0750";
    };
  };

  presets.nginx = {
    enable = true;
    virtualHosts = {
      "pocket-id.rvf6.com".locations."/".proxyPass =
        "http://unix:${config.services.pocket-id.settings.UNIX_SOCKET}:/";
    };
  };
  systemd.services.nginx.serviceConfig.SupplementaryGroups = [
    config.services.pocket-id.group
  ];

}
