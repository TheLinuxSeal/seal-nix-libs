{
  description = "A NixOS machine running a Minecraft network, configured in Seal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    seal-nix = {
      url = "github:TheLinuxSeal/seal-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    seal-nix-libs = {
      url = "github:TheLinuxSeal/seal-nix-libs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.seal-nix.follows = "seal-nix";
    };
  };

  outputs = { nixpkgs, seal-nix, seal-nix-libs, ... }: {
    # sudo nixos-rebuild switch --flake .#minecraft
    nixosConfigurations.minecraft = nixpkgs.lib.nixosSystem {
      modules = [
        ./hardware-configuration.nix
        ./vm.nix
        seal-nix.nixosModules.default
        seal-nix-libs.nixosModules.default                  # import sealnix.libs.minecraft.*;
        { seal-nix.src = ./config/Main.seal; }
      ];
    };
  };
}
