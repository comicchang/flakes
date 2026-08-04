{
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (self.data) systemdHarden;

  phantunLocalUdp = 12000;
  phantunRemoteTcp = "[${self.data.dns.sh.ipv6}]:8080";
  phantunTun = "phantun";
  shPubkey = "ai94BdVEM+41NW+r27Ps4ZlWlfYG9oNySAmyFROdcT4=";
  wgV4Addr = "10.6.3.2/24";
  wgV6Addr = "fd03::2/120";
  #shV4Addr = "10.6.3.1/32";
  #shV6Addr = "fd03::1/128";
  wgMtu = 1360;
  table = 30;
in
{

  networking.nftables.masquerade = [
    ''iifname "${phantunTun}" oifname "ppp0"''
  ];

  networking.firewall.extraForwardRules = ''
    iifname ${phantunTun} oifname ppp0 accept
  '';

  systemd.network.config.routeTables.wg-phantun = table;

  systemd.network.netdevs."25-wg-phantun" = {
    netdevConfig = {
      Name = "wg-phantun";
      Kind = "wireguard";
      MTUBytes = toString wgMtu;
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      RouteTable = "wg-phantun";
    };
    wireguardPeers = [
      {
        AllowedIPs = [
          "::/0"
          "0.0.0.0/0"
        ];
        PublicKey = shPubkey;
        Endpoint = "[::1]:${toString phantunLocalUdp}";
        PersistentKeepalive = 25;
      }
    ];
  };

  systemd.network.networks."25-wg-phantun" = {
    name = "wg-phantun";
    address = [
      wgV4Addr
      wgV6Addr
    ];
  };

  systemd.services.phantun-client = {
    description = "Phantun Client (UDP to TCP obfuscator for WireGuard)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment.RUST_LOG = "info";
    serviceConfig = systemdHarden // {
      ExecStart = "${pkgs.phantun}/bin/phantun_client --local [::1]:${toString phantunLocalUdp} --remote ${phantunRemoteTcp} --tun ${phantunTun}";
      Restart = "always";
      RestartSec = "5s";
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      PrivateNetwork = false;
      PrivateUsers = false;
      PrivateDevices = false;
      DeviceAllow = [ "/dev/net/tun rwm" ];
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
      ];
    };
  };
}
