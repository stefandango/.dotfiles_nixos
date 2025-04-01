# .dotfiles_nixos

My first nixos setup.. still needs cleanup.

## Guide to install NixOS

// TODO..

## Nix-Darwin

Very usefull install guide her: <https://www.youtube.com/watch?v=LE5JR4JcvMg>

## Installation

1. Install NIXOS(<https://nixos.org/download/>)
2. Install Homebrew (<https://brew.sh>)
3. Start terminal
4. Get git and clone config

> nix-shell -p git
> git clone <https://github.com/stefandango/.dotfiles_nixos.git> .dotfiles

5. Exit nix-shell

>exit

6. Go to the new directory and execute

> nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake .

7. Setup raycast (replace Spotlight)
8. Start hiddenbar

### Apps i dont use nix for

- Magnet
- Safari extensions
- Editors (Rider, VSCode etc)
- Obsidian
- Insync
- Docker
- Homebrew
- Little Snitch
- Spotify
- Arc

### GUI Apps i *do* use nix for

- Kitty
- Meld
- Raycast*
- Hiddenbar*
- CleanMyMac X*

\**Homebrew (via nix)*

// TODO...

1. Update flake.nix to new setup...
