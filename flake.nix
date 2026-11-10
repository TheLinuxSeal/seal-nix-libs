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
            # what minecraft.lock is asked to have, for each server
            want = name: builtins.fromJSON set.system.build.minecraftRequests."minecraft-${name}";
          in
          assert set.networking.firewall.allowedTCPPorts == [ 25565 25577 ];
          assert s.minecraft-lobby.serviceConfig.StateDirectoryMode == "0750";
          assert !(s.minecraft-survival.serviceConfig ? StateDirectoryMode);
          assert lib.elem "minecraft-proxy.service" s.minecraft-smp.after;
          assert lib.hasInfix "export PAPER_VELOCITY_SECRET=$secret" s.minecraft-lobby.script;
          assert lib.hasInfix "export FABRIC_PROXY_SECRET=$secret" s.minecraft-smp.script;
          assert lib.hasInfix "MODS=('lithium' 'fabric-api' 'fabricproxy-lite')" s.minecraft-smp.preStart;
          assert lib.hasInfix "MODS=('fabric-api' 'lithium@mc26.3-0.26.3-fabric' 'curseforge:appleskin' 'curseforge:jei@jei-26.3-fabric-31.17.0.109.jar')" s.minecraft-survival.preStart;
          assert lib.hasInfix "CURSEFORGE_KEY='/run/secrets/curseforge'" s.minecraft-survival.preStart;
          assert lib.hasInfix "CURSEFORGE_KEY=''" s.minecraft-smp.preStart;
          assert lib.hasInfix "PLUGINS=('luckperms@v5.5.71-bukkit')" s.minecraft-lobby.preStart;
          assert lib.hasInfix ''{"path":"config/mymod.toml","format":"toml","text":null,"set":[{"key":["general","threads"],"value":4},{"key":["general","fastMath"],"value":true}]}'' s.minecraft-survival.preStart;
          assert lib.hasInfix ''{"key":["a.b","c"],"value":"x"}'' s.minecraft-survival.preStart;
          assert lib.hasInfix ''{"path":"config/lithium.properties","format":"properties","text":null,"set":[{"key":["mixin.ai.pathing"],"value":"false"}]}'' s.minecraft-survival.preStart;
          assert lib.hasInfix ''{"path":"config/whole.conf","format":"","text":"hello\n","set":[]}'' s.minecraft-survival.preStart;
          assert lib.hasInfix ''{"path":"plugins/LuckPerms/config.yml","format":"yaml"'' s.minecraft-lobby.preStart;
          assert lib.hasInfix "CONFIGS='[]'" s.minecraft-smp.preStart;
          assert lib.hasInfix ''OPS='[{"uuid":"11111111-2222-4333-8444-555555555555","name":"seal","level":4},{"uuid":"aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee","name":"mod","level":2}]'' s.minecraft-survival.preStart;
          assert lib.hasInfix ''BANS='[{"uuid":"99999999-8888-4777-8666-555555555555","name":"griefer","expires":"forever"}]'' s.minecraft-survival.preStart;
          assert lib.hasInfix ''WHITELIST='[{"uuid":"11111111-2222-4333-8444-555555555555","name":"seal"},{"uuid":"bbbbbbbb-cccc-4ddd-8eee-ffffffffffff","name":"friend"}]'' s.minecraft-survival.preStart;
          assert lib.hasInfix "PROPERTIES=('white-list=true' 'motd=A Seal server')" s.minecraft-survival.preStart;
          assert lib.hasInfix "WHITELIST='[]'" s.minecraft-smp.preStart;
          assert lib.hasInfix "OPS='[]'" s.minecraft-smp.preStart;
          assert lib.hasInfix "BANS='[]'" s.minecraft-proxy.preStart;
          assert lib.hasInfix "PROPERTIES=('online-mode=false' 'server-ip=127.0.0.1')" s.minecraft-lobby.preStart;
          assert lib.hasInfix ''try = ["lobby", "smp"]'' s.minecraft-proxy.preStart;
          assert lib.hasInfix ''"smp.example.com" = ["smp"]'' s.minecraft-proxy.preStart;
          assert lib.hasInfix ''hub = "127.0.0.1:25568"'' s.minecraft-proxy.preStart;
          assert lib.hasInfix ''"hub.example.com" = ["hub"]'' s.minecraft-proxy.preStart;
          assert lib.elem "minecraft-proxy.service" s.minecraft-hub-server.after;
          assert !(s ? minecraft-hub);
          assert (want "survival").mods == [ "fabric-api" "lithium@mc26.3-0.26.3-fabric" "curseforge:appleskin" "curseforge:jei@jei-26.3-fabric-31.17.0.109.jar" ];
          assert (want "survival").minecraft == "26.3" && (want "survival").loader == "fabric";
          assert (want "survival").curseforgeKey == "/run/secrets/curseforge";
          assert (want "smp").mods == [ "lithium" "fabric-api" "fabricproxy-lite" ];
          assert (want "proxy").plugins == [ "luckperms" ] && (want "proxy").loader == "velocity";
          assert !(set.system.build.minecraftRequests ? minecraft-fresh);         # "latest": its start chooses
          assert !(set.system.build.minecraftRequests ? minecraft-hub-server);    # nothing to download
          assert s.minecraft-survival.environment ? DOWNLOADED;
          assert !(s.minecraft-fresh ? environment);
          assert lib.hasInfix "DOWNLOADED=\${DOWNLOADED:-}" s.minecraft-survival.preStart;
          assert lib.hasInfix "MODS=('neovelocity')" s.minecraft-neo-plain.preStart;
          assert lib.hasInfix "MODS=('CFX9ftUJ' 'RT18TcxA@1.2.5')" s.minecraft-neo.preStart;
          assert lib.hasInfix ''{"path":"config/neovelocity-common.toml","format":"toml","text":null,"set":[{"key":["forwarding","forwarding-secret"],"value":"/var/lib/minecraft/proxy/forwarding.secret"},{"key":["forwarding","forwarding-secret-type"],"value":"FILE"}]}'' s.minecraft-neo-plain.preStart;
          assert lib.hasInfix ''{"key":["forwarding","forwarding-secret-type"],"value":"FILE"},{"key":["compatibility","login-custom-packet-catchall"],"value":false}'' s.minecraft-neo.preStart;
          assert lib.hasInfix "SECRET='/var/lib/minecraft/proxy/forwarding.secret'" s.minecraft-neo.script;
          assert !(lib.hasInfix "export" s.minecraft-neo.script);
          assert lib.hasInfix "PROPERTIES=('online-mode=false' 'server-ip=127.0.0.1')" s.minecraft-neo.preStart;
          assert s.minecraft-neo.serviceConfig.StateDirectoryMode == "0750";
          pkgs.runCommand "minecraft" { } ''
            head -1 ${module} | grep -q "from Main.seal, sealnix/libs/minecraft/ConfigFile.seal, sealnix/libs/minecraft/Forwarding.seal, sealnix/libs/minecraft/Loader.seal, sealnix/libs/minecraft/Proxy.seal, sealnix/libs/minecraft/Server.seal, sealnix/libs/minecraft/Service.seal:"
            test "$(grep -c 'ps.json5' ${module})" = 1
            ${lib.concatStrings (lib.mapAttrsToList (name: unit: parse "${name}-preStart" unit.preStart + parse "${name}-script" unit.script) s)}
            touch $out
          '';

        # a forwarding secret made anew at every rebuild, which restarts the proxy and its servers
        minecraft-secret =
          let
            set = settings (generate system ./tests/minecraft-secret/Main.seal);
            s = set.systemd.services;
            script = set.system.activationScripts.minecraft-proxy-secret;
            file = "/var/lib/minecraft-secrets/proxy";
          in
          assert script.deps == [ "users" ];
          assert lib.hasInfix "secret='${file}'" script.text;
          assert lib.hasInfix "'minecraft-proxy.service' 'minecraft-lobby.service' >> /run/nixos/activation-restart-list" script.text;
          assert lib.hasInfix "OWN_SECRET=0" s.minecraft-proxy.preStart;
          assert lib.hasInfix "SECRET='${file}'" s.minecraft-proxy.preStart;
          assert lib.hasInfix "SECRET='${file}'" s.minecraft-lobby.script;
          pkgs.runCommand "minecraft-secret" { } "bash -n ${pkgs.writeText "secret" script.text}; touch $out";

        # minecraft.lock, as Nix reads it (tests/minecraft-lock), and this library's nixos-rebuild, read by bash
        minecraft-lock =
          let
            src = ./tests/minecraft-lock/Main.seal;
            module = generate system src;
            system' = import module {
              inherit lib pkgs;
              config = {
                seal-nix.src = src;
                system.build = system'.system.build // { nixos-rebuild = pkgs.nixos-rebuild; };
                nix.package = pkgs.nix;
              };
            };
            downloads = name: (system'.system.build.minecraftDownloads name).buildCommand;
            smp = downloads "smp";
            part = downloads "part";
            rebuild = lib.head system'.environment.systemPackages;
          in
          assert lib.hasInfix "/mods/lithium-fabric-0.26.3.jar" smp && lib.hasInfix "/mods/ferritecore-8.0-fabric.jar" smp;
          assert lib.hasInfix "printf '%s\\t%s\\n' lithium lithium-fabric-0.26.3.jar" smp;
          assert lib.hasInfix "echo 'fabric 26.3' > \"$out\"/.seal-mc/mods.for" smp;
          assert !(lib.hasInfix "ln -s" (downloads "old"));                    # another Minecraft version's
          assert lib.hasInfix "/plugins/'LuckPerms-Bukkit 5.5.jar'" part && !(lib.hasInfix "chunky" part);
          assert system'.systemd.services.minecraft-smp.environment ? DOWNLOADED;
          pkgs.runCommand "minecraft-lock" { } ''
            bash -n ${rebuild}/bin/nixos-rebuild
            grep -q 'REAL=${pkgs.nixos-rebuild}/bin/nixos-rebuild' ${rebuild}/bin/nixos-rebuild
            grep -q 'minecraft.lock' ${rebuild}/bin/nixos-rebuild
            touch $out
          '';

        # a CurseForge mod by its project ID, with no API key
        minecraft-nokey =
          let start = (settings (generate system ./tests/minecraft-nokey/Main.seal)).systemd.services.minecraft-survival.preStart; in
          assert lib.hasInfix "MODS=('curseforge:248787')" start;
          assert lib.hasInfix "CURSEFORGE_KEY=''" start;
          pkgs.runCommand "minecraft-nokey" { } "touch $out";
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
