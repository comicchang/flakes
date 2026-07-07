{ pkgs, self, ... }:
{

  imports = [
    self.nixosModules.myHomeModules
  ];

  presets.workstation.enable = true;

  home.packages = with pkgs; [
    # keep-sorted start
    acpi
    brightnessctl
    # keep-sorted end
  ];

  services.fusuma = {
    enable = true;
    extraPackages = with pkgs; [
      # keep-sorted start
      coreutils
      gnugrep
      # keep-sorted end
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
