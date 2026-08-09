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
  table = 256;

  ipv4 = "10.5.0.134";
  ipv6 = "fdc0::86";
in
{

  networking.firewall = {
    extraForwardRules = ''
      iifname ${interface} accept
    '';
    extraReversePathFilterRules = ''
      iifname xfrm-de2 accept
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
          IncomingInterface = "xfrm-de2";
          Priority = 128;
          Family = "ipv6";
          Table = interface;
        }
        {
          IncomingInterface = interface;
          Priority = 128;
          Family = "both";
          Table = "xfrm-de2";
        }
      ];
    };
  };

  services.strongswan-swanctl.swanctl.connections.nl = {
    inherit proposals;
    remote_addrs = [ self.data.dns.nl.ipv4 ];
    local.de2 = {
      auth = "pubkey";
      id = "de2.rvf6.com";
      certs = [ config.sops.secrets."pki/de2-bundle".path ];
    };
    remote.nl = {
      auth = "pubkey";
      id = "nl.rvf6.com";
      cacerts = [
        config.sops.secrets."pki/ca".path
        config.sops.secrets."pki/ybk".path
      ];
    };
    children.nl = {
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
