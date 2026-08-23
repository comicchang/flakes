{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let

  inherit (lib)
    # keep-sorted start
    mkEnableOption
    mkOption
    types
    # keep-sorted end
    ;

  cfg = config.presets.smartdnsChinaList;

  chinaListRaw =
    (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/accelerated-domains.china.conf")
    + (builtins.readFile "${inputs.dnsmasq-china-list.outPath}/apple.china.conf");
  chinaList = pkgs.writeText "china-list" (
    builtins.replaceStrings
      [
        "server="
        "114.114.114.114"
      ]
      [
        "nameserver "
        "china"
      ]
      chinaListRaw
  );

in
{
  options.presets.smartdnsChinaList = {

    enable = mkEnableOption "Whether to enable smartdns-china-list";

    chinaDns = mkOption {
      type = with types; listOf str;
      default = [
        "[2400:3200::1]"
        "[2402:4e00::]"
        "223.5.5.5"
        "119.29.29.29"
      ];
    };

    nonChinaDns = mkOption {
      type = with types; listOf str;
      default = [
        "[2606:4700:4700::1111]"
        "[2001:4860:4860::8888]"
      ];
    };

  };

  config = lib.mkIf cfg.enable {

    services.resolved.enable = false;
    networking.resolvconf.enable = false;

    environment.etc."resolv.conf".text = ''
      nameserver ::1
    '';

    presets.smartdns.china-list.settings = {
      conf-file = chinaList.outPath;
      server = (map (i: "${i} -group china -exclude-default-group") cfg.chinaDns) ++ cfg.nonChinaDns;
    };

  };
}
