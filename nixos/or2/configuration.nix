{ ... }:
let
  ccKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1a8SSEd+lEdS7VY6XN1YtB9q81c3/hXKACDClphoSE openpgp:0x33333333";
in
{
  presets.nogui.enable = true;
  presets.metrics.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets = {
    "wireguard_key".owner = "systemd-network";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "or2";

  presets.wireguard.wg0 = {
    enable = true;
    mtu = 1320;
  };

  home-manager.users.rvfg = import ./home.nix;

  presets.nginx.enable = true;

  users.users.rvfg.openssh.authorizedKeys.keys = [ ccKey ];
  environment.etc."ssh/pam_rssh_keys.d/rvfg".text = ''
    ${ccKey}
  '';

}
