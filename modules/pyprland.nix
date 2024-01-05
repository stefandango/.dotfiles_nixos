
{ config, lib, pkgs, home-manager, vars, ...  }:

let
inherit (config.home-manager.users.${vars.user}.lib.formats.rasi) mkLiteral;
colors = import ../theme/colors.nix;
in
{
	home-manager.users.${vars.user} = {
		home = {
			packages = with pkgs; [
				(pkgs.python3Packages.buildPythonPackage rec {
				 pname = "pyprland";
				 version = "1.6.9";
				 src = pkgs.fetchPypi {
				 inherit pname version;
				 sha256 = "sha256-HAsiOvNCluxY/nV9PtwaC0s9auZUB6I82arsMEpW5Ic=";
				 };
				 format = "pyproject";
				 propagatedBuildInputs = with pkgs; [
				 python3Packages.setuptools
				 python3Packages.poetry-core
				 poetry
				 ];
				 doCheck = false;
				 })

			];
			file = {
				".config/hypr/pyprland.json" = {
					text = ''
					{
						"pyprland": {
							"plugins": ["scratchpads", "magnify"]
						},
						"scratchpads": {
							"term": {
								"command": "kitty --class scratchpad",
								"margin": 50,
								"unfocus": "hide",
								"animation": "fromTop",
								"lazy": true,
								"size": "60% 80%"

							},
							"systeminfo": {
								"command": "kitty --class scratchpad -e btop",
								"margin": 50,
								"unfocus": "hide",
								"animation": "fromTop",
								"lazy": true,
								"size": "60% 80%"
							},
							"lazydocker": {
								"command": "kitty --class scratchpad -e lazydocker",
								"margin": 50,
								"unfocus": "hide",
								"animation": "fromTop",
								"lazy": true,
								"size": "60% 80%"
							},
							"pavucontrol": {
								"command": "pavucontrol",
								"margin": 50,
								"unfocus": "hide",
								"animation": "fromTop",
								"lazy": true
							},
							"files": {
								"command": "thunar",
								"margin": 50,
								"unfocus": "hide",
								"animation": "fromTop",
								"lazy": true
							}
						}
					}
					'';
				};
			};
		};

	};
}
