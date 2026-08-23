{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    concatStringsSep
    ;

  dnsPortCN = 5300;

  updateDnsScript = pkgs.writeShellScript "update-run-dns-resolv-conf" ''
    set -eu -o pipefail
    umask 0022
    DNS=$(cat /run/dns/{networkd,ppp} 2>/dev/null || true)
    DNS_RESOLV_CONF=$(echo "$DNS" | sed 's/^/nameserver /')
    RESOLV_CONF_PATH="/run/dns/resolv.conf"
    DNS_SMARTDNS_CONF=$(echo "$DNS" | sed 's/^/server /')
    SMARTDNS_CONF_PATH="/run/dns/smartdns.conf"
    function atomic_write() {
      NAME="$1"
      TARGET="$2"
      CONTENT="$3"
      echo "Writing $TARGET"
      echo "$CONTENT"
      TMP_FILE="$(mktemp -p /run/dns "$NAME".XXXXXXXXXX.conf)"
      chmod 644 "$TMP_FILE"
      echo "$CONTENT" > "$TMP_FILE"
      mv "$TMP_FILE" "$TARGET"
    }
    if [[ ! -z "$DNS" ]]; then
      atomic_write resolv "$RESOLV_CONF_PATH" "$DNS_RESOLV_CONF"
      atomic_write smartdns "$SMARTDNS_CONF_PATH" "$DNS_SMARTDNS_CONF"
    elif [[ ! -f "$RESOLV_CONF_PATH" ]]; then
      echo "Creating empty $RESOLV_CONF_PATH"
      touch "$RESOLV_CONF_PATH"
    elif [[ ! -f "$SMARTDNS_CONF_PATH" ]]; then
      echo "Creating empty $SMARTDNS_CONF_PATH"
      touch "$SMARTDNS_CONF_PATH"
    fi
  '';
in
{

  options.router.dnsEnabledIfs = mkOption {
    type = types.listOf types.str;
    default = [ ];
  };

  options.router.dnsPorts = mkOption {
    type = types.listOf types.port;
    default = [ ];
  };

  config = {

    router.dnsPorts = [
      53
      dnsPortCN
    ];

    networking.nftables.tables."nixos-fw".content = ''
      set dns_enabled_ifs {
        type ifname
        flags interval
        elements = { ${concatStringsSep ", " (map (x: ''"${x}"'') config.router.dnsEnabledIfs)} }
      }
    '';
    networking.firewall = {
      extraInputRules = ''
        iifname @dns_enabled_ifs meta l4proto { tcp, udp } th dport { ${concatStringsSep ", " (map toString config.router.dnsPorts)} } accept
      '';
    };

    presets.adguardhome = {
      enable = true;
      chinaDns = [ "[::1]:5300" ];
    };

    systemd.tmpfiles.rules = [
      "d /run/dns 777 - - -"
    ];

    systemd.services.reload-dns.serviceConfig = {
      Type = "oneshot";
      ExecStart = updateDnsScript;
    };

    systemd.paths.reload-dns = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = [
        "/run/dns/networkd"
        "/run/dns/ppp"
      ];
    };

    presets.smartdns.cn = {
      bindPort = dnsPortCN;
      settings = {
        conf-file = "/run/dns/smartdns.conf";
        serve-expired = false;
      };
    };
    systemd.services.smartdns-cn = {
      before = [ "adguardhome.service" ];
      serviceConfig.ExecStartPre = "+${updateDnsScript}";
    };

  };

}
