{ config, ... }:
{

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/sda";
  };
  presets.swanctl-gfw.enableServer = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "pki/ca".mode = "0444";
    "pki/ybk".mode = "0444";
    "pki/de2-bundle" = { };
    "pki/de2-pkcs8-key" = { };
    warp_key.owner = "systemd-network";
  };

  boot.kernel.sysctl = {
    "net.core.wmem_max" = 33554432;
    "net.ipv4.tcp_wmem" = "4096 65536 33554432";
  };

  networking.hostName = "de2";

  systemd.network.networks."10-ens3" = {
    name = "ens3";
    address = [
      "82.115.30.220/24"
    ];
    dns = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "82.115.30.1";
        GatewayOnLink = true;
      }
    ];
  };

  networking.warp = {
    enable = true;
    endpointAddr = "162.159.192.1";
    mtu = 1400;
    routingId = "0x2a7b63";
    keyFile = config.sops.secrets.warp_key.path;
    address = [
      "172.16.0.2/32"
      "2606:4700:110:869b:7086:6af0:c2ba:d279/128"
    ];
    table = 20;
  };
  #systemd.network.networks."25-warp".routes = [ { Source = "::/0"; } ];

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;
}
