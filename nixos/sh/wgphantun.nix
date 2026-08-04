{
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (self.data) systemdHarden;

  phantunTcpPort = 8080;
  phantunTun = "phantun";
  phantunV4Peer = "192.168.201.2";
  phantunV6Peer = "fcc9::2";

  wgPort = 12000;
  routerPubkey = self.data.wg0.peers.router.pubkey;
  wgV4Addr = "10.6.3.1/24";
  wgV6Addr = "fd03::1/120";
  routerV4Addr = "10.6.3.2/32";
  routerV6Addr = "fd03::2/128";
  wgMtu = 1360;
in
{

  sops.secrets.wireguard_key = {
    owner = "systemd-network";
  };

  environment.systemPackages = with pkgs; [ wireguard-tools ];

  networking.firewall.allowedTCPPorts = [ phantunTcpPort ];

  systemd.network.config.networkConfig = {
    IPv4Forwarding = true;
    IPv6Forwarding = true;
  };

  networking.nftables.tables.phantun-dnat = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        tcp dport ${toString phantunTcpPort} dnat ip to ${phantunV4Peer}
        tcp dport ${toString phantunTcpPort} dnat ip6 to ${phantunV6Peer}
      }
    '';
  };

  systemd.network.netdevs."25-wg-phantun" = {
    netdevConfig = {
      Name = "wg-phantun";
      Kind = "wireguard";
      MTUBytes = toString wgMtu;
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets.wireguard_key.path;
      ListenPort = wgPort;
    };
    wireguardPeers = [
      {
        AllowedIPs = [
          routerV4Addr
          routerV6Addr
        ];
        PublicKey = routerPubkey;
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

  systemd.services.phantun-server = {
    description = "Phantun Server (UDP to TCP obfuscator for WireGuard)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment.RUST_LOG = "info";
    serviceConfig = systemdHarden // {
      ExecStart = "${pkgs.phantun}/bin/phantun_server --local ${toString phantunTcpPort} --remote [::1]:${toString wgPort} --tun ${phantunTun}";
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
