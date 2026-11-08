{
  description = "seal-nix-libs: Seal libraries for seal-nix configurations, each a whole service in a few lines";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    seal-nix = {
      url = "github:TheLinuxSeal/seal-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, seal-nix }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});

      # The module a test configuration makes, with these libraries, and what it sets.
      generate = system: src: seal-nix.lib.generate { inherit system src; libraries = [ self.sealLibrary ]; };
      settings = module: import module { config = null; lib = null; pkgs = null; };
    in
    {
      # The libraries, for seal-nix.libraries: each a package, sealnix.libs.<name>, in its folder (lib/sealnix/libs/minecraft).
      sealLibrary = ./lib;

      # modules = [ seal-nix.nixosModules.default seal-nix-libs.nixosModules.default ... ]: the
      # libraries, for the system's Seal configuration to import. Add seal-nix's module too.
      nixosModules.default = { seal-nix.libraries = [ self.sealLibrary ]; };
      nixosModules.seal-nix-libs = self.nixosModules.default;

      # nix flake init -t github:TheLinuxSeal/seal-nix-libs#minecraft
      templates.minecraft = {
        path = ./examples/minecraft;
        description = "A NixOS machine running a Minecraft network, configured in Seal";
      };

      checks = forAllSystems (system: pkgs: {
        # tests/minecraft: a server on its own, and a Velocity proxy with servers behind it; and every
        # script the services run, read by bash
        minecraft =
          let
            module = generate system ./tests/minecraft/Main.seal;
            set = settings module;
            s = set.systemd.services;
            parse = name: text: "bash -n ${pkgs.writeText name text}\n";
          in
          assert set.networking.firewall.allowedTCPPorts == [ 25565 25577 ];
          assert s.minecraft-lobby.serviceConfig.StateDirectoryMode == "0750";
          assert !(s.minecraft-survival.serviceConfig ? StateDirectoryMode);
          assert lib.elem "minecraft-proxy.service" s.minecraft-smp.after;
          assert lib.hasInfix "export PAPER_VELOCITY_SECRET=$secret" s.minecraft-lobby.script;
          assert lib.hasInfix "export FABRIC_PROXY_SECRET=$secret" s.minecraft-smp.script;
          assert lib.hasInfix "MODS=('lithium' 'fabric-api' 'fabricproxy-lite')" s.minecraft-smp.preStart;
          assert lib.hasInfix "MODS=('fabric-api' 'lithium@mc26.3-0.26.3-fabric')" s.minecraft-survival.preStart;
          assert lib.hasInfix "PLUGINS=('luckperms@v5.5.71-bukkit')" s.minecraft-lobby.preStart;
          assert lib.hasInfix "PROPERTIES=('online-mode=false' 'server-ip=127.0.0.1')" s.minecraft-lobby.preStart;
          assert lib.hasInfix ''try = ["lobby", "smp"]'' s.minecraft-proxy.preStart;
          assert lib.hasInfix ''"smp.example.com" = ["smp"]'' s.minecraft-proxy.preStart;
          pkgs.runCommand "minecraft" { } ''
            head -1 ${module} | grep -q "from Main.seal, sealnix/libs/minecraft/Forwarding.seal, sealnix/libs/minecraft/Loader.seal, sealnix/libs/minecraft/Server.seal:"
            ${lib.concatStrings (lib.mapAttrsToList (name: unit: parse "${name}-preStart" unit.preStart + parse "${name}-script" unit.script) s)}
            touch $out
          '';
      } // lib.optionalAttrs (system == "x86_64-linux") {
        # examples/minecraft, as its flake makes it but with this flake's libraries: the whole system,
        # and its virtual machine, evaluated
        example-minecraft =
          let
            machine = lib.nixosSystem {
              modules = [
                ./examples/minecraft/hardware-configuration.nix
                ./examples/minecraft/vm.nix
                seal-nix.nixosModules.default
                self.nixosModules.default
                { seal-nix.src = ./examples/minecraft/config/Main.seal; }
              ];
            };
            build = machine.config.system.build;
          in
          pkgs.writeText "example-minecraft"
            (builtins.unsafeDiscardStringContext "${build.toplevel.drvPath}\n${build.vm.drvPath}\n");
      });
    };
}
