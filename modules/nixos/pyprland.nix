
{ config, lib, pkgs, home-manager, vars, ...  }:

    let
    inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
    colors = import ../../theme/colors.nix;
in
    {
    environment.systemPackages = [
        pkgs.pyprland
    ];
    # 	home-manager.users.${vars.user} = {
    # 		home = {
    # 			packages = with pkgs; [
    # 				(pkgs.python3Packages.buildPythonPackage rec {
    # 				 pname = "pyprland";
    # 				 version = "1.6.9";
    # 				 src = pkgs.fetchPypi {
    # 				 inherit pname version;
    # 				 sha256 = "sha256-HAsiOvNCluxY/nV9PtwaC0s9auZUB6I82arsMEpW5Ic=";
    # 				 };
    # 				 format = "pyproject";
    # 				 propagatedBuildInputs = with pkgs; [
    # 				 python3Packages.setuptools
    # 				 python3Packages.poetry-core
    # 				 poetry
    # 				 ];
    # 				 doCheck = false;
    # 				 })
    #
    # 			];

    home-manager.users.${vars.user} = {
    home = {
        file = {

            ".config/pypr/config.toml" = {
                text = ''
                    [pyprland]
                    plugins = ["scratchpads", "magnify"]

                    [scratchpads.term]
                    command = "kitty --class scratchpad"
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    lazy = true
                    size = "60% 80%"

                    [scratchpads.systeminfo]
                    command = "kitty --class scratchpad -e btop"
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    lazy = true
                    size = "60% 80%"

                    [scratchpads.lazydocker]
                    command = "kitty --class scratchpad -e lazydocker"
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    lazy = true
                    size = "60% 80%"

                    [scratchpads.nixupdates]
                    command = "kitty --class scratchpad -e bash -c '~/Scripts/waybar-updates.sh --display; read -n1 -s -r -p \"Press any key to close...\"'"
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    lazy = false
                    size = "60% 80%"

                    [scratchpads.pavucontrol]
                    command = "pavucontrol"
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    lazy = true

                    [scratchpads.files]
                    command = "thunar"
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    lazy = true
                    size = "60% 80%"

                    # Firefox PWA scratchpads.
                    # Match by initialClass — each install gets a unique
                    # FFPWA-<ULID> class that's stable for the lifetime of the
                    # install. (initialTitle matching turned out to be flaky in
                    # pyprland 3.3.1 — the rule loaded but never fired.)
                    # ULIDs come from `firefoxpwa profile list`. If you ever
                    # uninstall+reinstall a PWA, update the corresponding ULID
                    # below (or run: nix run nixpkgs#firefoxpwa -- profile list).
                    # process_tracking = false because the launch chain forks
                    # (bash → script → firefoxpwa → runtime) and bash exits
                    # before the window opens.
                    # lazy = false pre-launches at pyprland start so toggles
                    # just show/hide an already-captured window (instant).
                    [scratchpads.chatgpt]
                    command = "firefoxpwa site launch 01KQCCP16HRQ7R2D4WC6M2J8N1"
                    match_by = "initialClass"
                    initialClass = "FFPWA-01KQCCP16HRQ7R2D4WC6M2J8N1"
                    process_tracking = false
                    lazy = false
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    size = "70% 85%"

                    [scratchpads.protonmail]
                    command = "firefoxpwa site launch 01KQC9BCAYC20ZB418F1ETGSZZ"
                    match_by = "initialClass"
                    initialClass = "FFPWA-01KQC9BCAYC20ZB418F1ETGSZZ"
                    process_tracking = false
                    lazy = false
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    size = "75% 85%"

                    [scratchpads.github]
                    command = "firefoxpwa site launch 01KQC9M4R9QRP04EVMA10GAXZZ"
                    match_by = "initialClass"
                    initialClass = "FFPWA-01KQC9M4R9QRP04EVMA10GAXZZ"
                    process_tracking = false
                    lazy = false
                    margin = 50
                    unfocus = "hide"
                    animation = "fromTop"
                    size = "75% 85%"
                '';
            };
        };
        #};
        #
        # 	};
    };
    };
    }
