{ ... }:
{

  presets.nogui.enable = true;
  presets.disko = {
    enable = true;
    biosBoot = true;
    device = "/dev/sda";
  };
  presets.nginx.enable = true;
  presets.users.hashedPasswordFile = null;

  networking.hostName = "g2";

  systemd.network.networks."10-enp3s0" = {
    name = "enp3s0";
    address = [
      "2a12:a303:11e:25::a/64"
      "176.119.148.40/24"
    ];
    dns = [
      "2001:4860:4860::8888"
      "2606:4700:4700::1111"
      "8.8.8.8"
      "1.1.1.1"
    ];
    networkConfig.IPv6AcceptRA = false;
    routes = [
      {
        Gateway = "2a12:a303:11e::1";
        GatewayOnLink = true;
      }
      {
        Gateway = "176.119.148.1";
        GatewayOnLink = true;
      }
    ];
  };

  home-manager.users.rvfg = import ./home.nix;

}
