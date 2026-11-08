# A Minecraft network

A NixOS machine configured in Seal, running a Minecraft network with
the [`minecraft`](../../docs/minecraft) library's [`Server`](../../lib/sealnix/libs/minecraft/Server.seal):

- **proxy**, Velocity on 25565, where players connect. It signs them in and sends them on.
- **lobby**, Paper, behind the proxy: where players join.
- **survival**, Fabric with Lithium and FerriteCore, behind the proxy: `/server survival`, or
  connect as `survival.example.com`.
- **creative**, vanilla, on its own on 25570.

The servers behind the proxy listen on 127.0.0.1 alone, and take its modern forwarding; only 22,
25565 and 25570 are open. [`config/Servers.seal`](config/Servers.seal) is all of it, and
[`config/Main.seal`](config/Main.seal) the rest of the machine.

```sh
nix flake init -t github:TheLinuxSeal/seal-nix-libs#minecraft
```

**In a virtual machine** (KVM, and 12 GiB of memory for it), whose ports 25565 and 25570 are this
computer's: a Minecraft client here joins `localhost`, or `localhost:25570` for creative. The first
start downloads the servers, which takes a few minutes; log in as seal, password seal.

```sh
nix build .#nixosConfigurations.minecraft.config.system.build.vm && ./result/bin/run-minecraft-vm
```

**On a machine:** replace `hardware-configuration.nix` with its own (`/etc/nixos/hardware-configuration.nix`),
set `Config.networking.hostName` and the flake's `nixosConfigurations.<name>` to its name, and
`sudo nixos-rebuild switch --flake .#<name>`. `git add` the files first if the folder is a git
repository: a flake sees only what git tracks. `systemctl status minecraft-proxy` and
`journalctl -u minecraft-survival` say how the servers are; they live in `/var/lib/minecraft/<name>`.
