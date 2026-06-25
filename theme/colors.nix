
#
#  System Themes
#

{
  scheme = {
    # ── Graphite ──────────────────────────────────────────────────────────────
    # Professional near-greyscale dark canvas + a single steel-blue accent, with a
    # disciplined semantic trio (success / warning / danger) used ONLY for state.
    #
    # The legacy slot names (red/green/blue/cyan/orange/yellow/purple…) are kept so
    # every existing consumer keeps building, but their VALUES are remapped:
    #   blue / cyan / active  → accent (steel blue)   purple → neutral slate (disappears)
    #   green → success        yellow / highlight → warning   red → danger
    # New semantic aliases (accent/accentDim/success/warning/danger) are provided for
    # rewritten sections. NOTE: no hyphens in interpolated attr names → `accentDim`.
    default = {
      scheme = "Graphite";
      hex = {
        # neutral ramp (cool-neutral dark)
        black     = "0c0c0e";
        bg        = "131316";
        inactive  = "2a2a30";
        gray      = "4a4a52";
        comment   = "6a6a73";
        text      = "8b8b94";
        fg        = "c6c6cd";
        white     = "c6c6cd";
        # accent (steel blue)
        accent    = "6f8fb3";
        accentDim = "47597a";
        active    = "6f8fb3";
        blue      = "6f8fb3";
        cyan      = "6f8fb3";
        # semantic trio (desaturated, state-only)
        success   = "7d9a6b";
        green     = "7d9a6b";
        warning   = "c2a15c";
        yellow    = "c2a15c";
        highlight = "c2a15c";
        orange    = "bd8b5e";
        danger    = "b56b6b";
        red       = "b56b6b";
        # remapped to neutral slate so old decorative uses fade into the greys
        purple    = "7b8190";
      };
      rgb = {
        black     = "12, 12, 14";
        bg        = "19, 19, 22";
        inactive  = "42, 42, 48";
        gray      = "74, 74, 82";
        comment   = "106, 106, 115";
        text      = "139, 139, 148";
        fg        = "198, 198, 205";
        white     = "198, 198, 205";
        accent    = "111, 143, 179";
        accentDim = "71, 89, 122";
        active    = "111, 143, 179";
        blue      = "111, 143, 179";
        cyan      = "111, 143, 179";
        success   = "125, 154, 107";
        green     = "125, 154, 107";
        warning   = "194, 161, 92";
        yellow    = "194, 161, 92";
        highlight = "194, 161, 92";
        orange    = "189, 139, 94";
        danger    = "181, 107, 107";
        red       = "181, 107, 107";
        purple    = "123, 129, 144";
      };
    };

    doom = {
      scheme    = "Doom One Dark";
      black     = "000000";
      red       = "ff6c6b";
      orange    = "da8548";
      yellow    = "ecbe7b";
      green     = "95be65";
      teal      = "4db5bd";
      blue      = "6eaafb";
      dark-blue = "2257a0";
      magenta   = "c678dd";
      violet    = "a9a1e1";
      cyan      = "6cdcf7";
      dark-cyan = "5699af";
      emphasis  = "50536b";
      text      = "dfdfdf";
      text-alt  = "b2b2b2";
      fg        = "abb2bf";
      bg        = "282c34";
    };

    dracula = {
      scheme = "Dracula";
      base00 = "282936"; #background
      base01 = "3a3c4e";
      base02 = "4d4f68";
      base03 = "626483";
      base04 = "62d6e8";
      base05 = "e9e9f4"; #foreground
      base06 = "f1f2f8";
      base07 = "f7f7fb";
      base08 = "ea51b2";
      base09 = "b45bcf";
      base0A = "00f769";
      base0B = "ebff87";
      base0C = "a1efe4";
      base0D = "62d6e8";
      base0E = "b45bcf";
      base0F = "00f769";
    };
  };
}

