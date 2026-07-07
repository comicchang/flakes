{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    # keep-sorted start
    ethtool
    iperf
    lm_sensors
    pciutils
    powertop
    usbutils
    wol
    # keep-sorted end
  ];

  presets.git.enable = true;
  presets.ssh.enable = true;
  presets.python.enable = true;
}
