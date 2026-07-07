{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    # keep-sorted start
    iperf
    pciutils
    usbutils
    # keep-sorted end
  ];

  presets.git.enable = true;
}
