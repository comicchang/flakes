{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    # keep-sorted start
    generators
    getExe
    isBool
    mapAttrs'
    mkDefault
    mkEnableOption
    mkOption
    nameValuePair
    optionalAttrs
    toList
    types
    # keep-sorted end
    ;

  cfg = config.presets.smartdns;

  smartdnsOptions = { config, name, ... }: {
    options = {
      enable = mkEnableOption "Whether to enable this instance" // {
        default = true;
      };

      bindAddress = mkOption {
        type = types.str;
        default = "[::]";
      };

      bindPort = mkOption {
        type = types.port;
        default = 53;
      };

      settings = mkOption {
        type =
          with types;
          let
            atom = oneOf [
              str
              int
              bool
            ];
          in
          attrsOf (coercedTo atom toList (listOf atom));
      };
    };

    config = {
      settings = {
        bind = mkDefault [ "${config.bindAddress}:${toString config.bindPort}" ];
        response-mode = mkDefault "fastest-response";
        cache-persist = mkDefault true;
        cache-file = mkDefault "/var/cache/smartdns-${name}/smartdns.cache";
        log-file = mkDefault "/dev/null";
        log-console = mkDefault true;
        dualstack-ip-selection = mkDefault false;
      };
    };
  };

  toConfFile =
    settings:
    pkgs.writeText "smartdns.conf" (
      with generators;
      toKeyValue {
        mkKeyValue = mkKeyValueDefault {
          mkValueString = v: if isBool v then if v then "yes" else "no" else mkValueStringDefault { } v;
        } " ";
        listsAsDuplicateKeys = true;
      } settings
    );
in
{
  options = {

    presets.smartdns = mkOption {
      type = types.attrsOf (types.submodule smartdnsOptions);
      default = { };
    };

  };

  config = {

    systemd.services = mapAttrs' (
      name: iCfg:
      nameValuePair "smartdns-${name}" {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig =
          self.data.systemdHarden
          // {
            ExecStart = "${getExe pkgs.smartdns} -f -x -p - -c ${toConfFile iCfg.settings}";
            CacheDirectory = "%N";
            PrivateNetwork = false;
          }
          // (optionalAttrs (iCfg.bindPort < 1024) {
            PrivateUsers = false;
            AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
            CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
            SocketBindAllow = iCfg.bindPort;
          });
      }
    ) cfg;

  };
}
