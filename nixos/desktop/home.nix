{ pkgs, self, ... }:
{
  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;

  home.packages = with pkgs; [
    ethtool
  ];
}
