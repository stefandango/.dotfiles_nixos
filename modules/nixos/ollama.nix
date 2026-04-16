{ config, lib, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    # acceleration = "rocm";
    # rocmOverrideGfx = "10.3.0";
    environmentVariables = {
      OLLAMA_KEEP_ALIVE = "5m";
    };
  };
}
