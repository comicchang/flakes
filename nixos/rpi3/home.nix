{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  home.packages = with pkgs; [
    # keep-sorted start
    iperf
    usbutils
    # keep-sorted end
  ];
}
