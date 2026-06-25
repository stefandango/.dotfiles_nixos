{ config, lib, pkgs, ... }:

let
  modelsDir = "/var/lib/llama-cpp/models";
  modelFile = "${modelsDir}/Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf";
  mmprojFile = "${modelsDir}/mmproj-F16.gguf";   # unused for text-only models; kept for future vision swaps
  modelExists = builtins.pathExists modelFile;
in
{
  services.llama-cpp = {
    enable = modelExists;
    package = pkgs.llama-cpp.override { vulkanSupport = true; };
    # nixpkgs dropped extraFlags/model/host/port in favour of a single freeform
    # `settings` attrset that llama-server consumes as CLI flags.
    settings = {
      model = modelFile;
      host = "127.0.0.1";
      port = 8080;
      gpu-layers = 999;   # was -ngl 999
      ctx-size = 32768;   # was -c 32768
      flash-attn = "on";
    } // lib.optionalAttrs (builtins.pathExists mmprojFile) {
      mmproj = mmprojFile;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
