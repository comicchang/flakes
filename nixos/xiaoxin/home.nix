{ pkgs, self, ... }:
{

  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;

  home.packages = with pkgs; [
    acpi
    brightnessctl
  ];

  services.fusuma = {
    enable = true;
    extraPackages = with pkgs; [
      coreutils
      gnugrep
    ];
    settings = {
      interval.swipe = 0.8;
      swipe."3" = {
        left.command = "${pkgs.wtype}/bin/wtype -P XF86Forward -p XF86Forward";
        right.command = "${pkgs.wtype}/bin/wtype -P XF86Back -p XF86Back";
      };
    };
  };

}
