{
  description = "Flake utils demo";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = flake-utils.lib.flattenTree {
          libusb = pkgs.stdenv.mkDerivation rec {
            name = "libusb";
            src = pkgs.fetchFromGitHub {
              owner = name;
              repo = name;
              rev = "1a906274a66dd58bf81836db1306902d4a7dc185";
              sha256 = "sha256-nqhzu5oxQ2jXd9Nbb5OzGKe4cVgg+CbJXIWuhp56pWY=";
            };
            buildInputs = with pkgs; [ libudev ];
            nativeBuildInputs = with pkgs; [ autoreconfHook ];
          };
          xow = pkgs.stdenv.mkDerivation rec {
            name = "xow";
            version = "unstable-2021-08-25";
            src = ./.;
            buildInputs = with packages; [ libusb ];
            nativeBuildInputs = with pkgs; [ cabextract git ];
            firmware = pkgs.fetchurl {
              url = "http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2017/07/1cd6a87c-623f-4407-a52d-c31be49e925c_e19f60808bdcbfbd3c3df6be3e71ffc52e43261e.cab";
              sha256 = "sha256-ZXNqhP9ANmRbj47GAr7ZGrY1MBnJyzIz3sq5/uwPbwQ=";
            };

            makeFlags = [
              "BUILD=RELEASE"
              "VERSION=${version}"
              "BINDIR=${placeholder "out"}/bin"
              "UDEVDIR=${placeholder "out"}/lib/udev/rules.d"
              "MODLDIR=${placeholder "out"}/lib/modules-load.d"
              "MODPDIR=${placeholder "out"}/lib/modprobe.d"
              "SYSDDIR=${placeholder "out"}/lib/systemd/system"
            ];
            preBuild = ''
              cabextract -F FW_ACC_00U.bin ${firmware}
              mv FW_ACC_00U.bin firmware.bin
            '';
          };
        };
        defaultPackage = packages.xow;
        apps.xow = flake-utils.lib.mkApp { drv = packages.xow; };
        defaultApp = apps.xow;

        nixosModules.xow = { config, ... }: {
          environment.systemPackages = [ defaultPackage ];
          systemd.packages = [ defaultPackage ];

          systemd.services."xow@" = {
            path = [ defaultPackage ];
            description = "xow xbox usb wireless dongle daemon";

            serviceConfig = {
              Type = "simple";
              ExecStart = "${defaultPackage}/bin/xow";
            };
            wantedBy = [ "default.target" ];
          };
        };
      });
}
