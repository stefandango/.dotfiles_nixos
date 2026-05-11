{ config, lib, pkgs, ... }:

let
  modelsDir = "/var/lib/llama-cpp/models";
  modelFile = "${modelsDir}/Qwen3.6-27B-Q4_K_M.gguf";
  mmprojFile = "${modelsDir}/mmproj-F16.gguf";
  modelExists = builtins.pathExists modelFile;
in
{
  services.llama-cpp = {
    enable = modelExists;
    package = pkgs.llama-cpp.override { vulkanSupport = true; };
    model = modelFile;
    host = "127.0.0.1";
    port = 8080;
    extraFlags = [
      "-ngl" "999"
      "-c" "32768"
      "--flash-attn" "on"
    ] ++ lib.optionals (builtins.pathExists mmprojFile) [
      "--mmproj" mmprojFile
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
