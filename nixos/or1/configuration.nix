{ config, ... }:
{
  imports = [
    ./ehforwarderbot
  ];

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    device = "/dev/sda";
  };
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
    "shadowsocks" = { };
  };

  networking.hostName = "or1";

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1400;
  };

  presets.shadowsocks = {
    enable = true;
    settings.server_port = 13926;
    passwordFile = config.sops.secrets.shadowsocks.path;
    openFirewall = true;
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
