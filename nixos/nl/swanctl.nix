{
  config,
  lib,
  self,
  ...
}:
let

  inherit (import ../../modules/swanctl-gfw/common.nix { inherit config lib self; })
    # keep-sorted start
    proposals
    # keep-sorted end
    ;

  interface = "xfrm-de2-nl";
  ifId = 4;
  mark = 256;
  table = 256;

  ipv4 = "10.5.0.133";
  ipv6 = "fdc0::85";

in
{

  networking.firewall.extraForwardRules = ''
    iifname ${interface} accept
  '';
  networking.nftables.masquerade = [ "iifname ${interface}" ];
  networking.nftables.tables."${interface}-mark" = {
    family = "inet";
    content = ''
      chain ${interface}-mark {
        type filter hook prerouting priority mangle;
        iifname ${interface} ct state new ct mark set ${toString mark}
        ct direction reply ct mark ${toString mark} meta mark set ct mark
      }
      chain ${interface}-mark-output {
        type route hook output priority mangle;
        ct direction reply ct mark ${toString mark} meta mark set ct mark
      }
    '';
  };

  systemd.network = {
    config.routeTables.${interface} = table;
    netdevs."25-${interface}" = {
      netdevConfig = {
        Name = interface;
        Kind = "xfrm";
      };
      xfrmConfig = {
        InterfaceId = ifId;
        Independent = true;
      };
    };
    networks."25-${interface}" = {
      name = interface;
      address = [
        "${ipv4}/30"
        "${ipv6}/126"
      ];
      routes = [
        {
          Source = "0.0.0.0/0";
          Table = interface;
        }
        {
          Source = "::/0";
          Table = interface;
        }
      ];
      routingPolicyRules = [
        {
          FirewallMark = mark;
          Priority = 64;
          Family = "both";
          Table = interface;
        }
      ];
    };
  };

  services.strongswan-swanctl.swanctl.connections.de2 = {
    inherit proposals;
    remote_addrs = [ self.data.dns.de2.ipv4 ];
    local.nl = {
      auth = "pubkey";
      id = "nl.rvf6.com";
      certs = [ config.sops.secrets."pki/nl-bundle".path ];
    };
    remote.de2 = {
      auth = "pubkey";
      id = "de2.rvf6.com";
      cacerts = [
        config.sops.secrets."pki/ca".path
        config.sops.secrets."pki/ybk".path
      ];
    };
    children.de2 = {
      local_ts = [
        "0.0.0.0/0"
        "::/0"
      ];
      remote_ts = [
        "0.0.0.0/0"
        "::/0"
      ];
      esp_proposals = proposals;
      start_action = "trap|start";
    };
    encap = false;
    mobike = false;
    version = 2;
    if_id_in = toString ifId;
    if_id_out = toString ifId;
  };

}
