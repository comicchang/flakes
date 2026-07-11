{
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib) getExe;

  ports = "4500, 11111";
in
{

  networking.nftables.tables.fakesip = {
    family = "inet";
    content = ''
      chain pre {
        type filter hook prerouting priority mangle - 8;
        meta mark 8 accept
        iifname ppp0 goto inbound
      }
      chain inbound {
        icmp type time-exceeded ct reply protocol udp ct reply proto-dst { ${ports} } counter drop
        icmp type time-exceeded ct original protocol udp ct original proto-dst { ${ports} } counter drop
        icmpv6 type time-exceeded ct reply protocol udp ct reply proto-dst { ${ports} } counter drop
        icmpv6 type time-exceeded ct original protocol udp ct original proto-dst { ${ports} } counter drop
        fib daddr type local udp dport { ${ports} } goto do-queue
      }
      chain post {
        type filter hook postrouting priority mangle - 8;
        meta mark 8 accept
        oifname ppp0 goto outbound
      }
      chain outbound {
        fib saddr type local udp sport { ${ports} } goto do-queue
      }
      chain do-queue {
        ct packets 1-5 counter queue num 513
      }
    '';
  };

  systemd.services.fakesip = {
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = self.data.systemdHarden // {
      ExecStart = "${getExe pkgs.fakesip} -i ppp0 -n 513 -f -m 8";
      PrivateUsers = false;
      PrivateNetwork = false;
      AmbientCapabilities = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
      CapabilityBoundingSet = [
        "CAP_NET_ADMIN"
        "CAP_NET_RAW"
      ];
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
        "AF_PACKET"
        "AF_NETLINK"
      ];
    };
  };

}
