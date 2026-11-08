# minecraft

Minecraft servers and Velocity proxies on NixOS, from a [seal-nix](https://github.com/TheLinuxSeal/seal-nix)
configuration. Each server is a systemd service, `minecraft-<name>`, that downloads its loader and its
mods or plugins (from Modrinth) when it starts, and keeps them until the configuration changes.

```java
import sealnix.*;
import sealnix.libs.minecraft.*;

class Main {
    static void main() {
        new Server("survival")
            .loader(Loader.FABRIC)
            .minecraftVersion("26.3")
            .acceptEula()                        // Mojang's EULA: https://aka.ms/MinecraftEULA
            .memory("4G")
            .mod("fabric-api")
            .mod("lithium")
            .property("difficulty", "hard")
            .install();
    }
}
```

| Page | |
| --- | --- |
| [Servers](servers.md) | Loaders, Minecraft and loader versions, mods and plugins, `server.properties`, memory and Java, ports, updates |
| [Velocity proxies](proxy.md) | Forwarding, the forwarding secret, the proxy's servers, try list and forced hosts, servers behind a proxy |
| [Running](running.md) | The systemd service, the folders and files, what a start does, logs, commands, security |
| [Errors](errors.md) | Every error the configuration or a start can give, and what to do |

[`examples/minecraft`](../../examples/minecraft) is a whole machine with a proxy and three servers.

## Setting it up

The library comes with seal-nix-libs's NixOS module, beside seal-nix's (see the
[README](../../README.md#using-them)):

```nix
modules = [
  seal-nix.nixosModules.default
  seal-nix-libs.nixosModules.default
  { seal-nix.src = ./config/Main.seal; }
];
```

A Seal file that uses it imports the package, `import sealnix.libs.minecraft.*;`, which has three types: `Server`,
`Loader` (the loaders) and `Forwarding` (a proxy's forwarding modes).

## Every setting

A server is a `new Server(name)`, and each setting is a method that returns it, so they chain;
`install()` checks them all, and installs it. The name is the server's service, `minecraft-<name>`, and
its folder, `/var/lib/minecraft/<name>`: letters, digits, `-` and `_`.

| Setting | For | Default | |
| --- | --- | --- | --- |
| `.loader(loader)` | all | none: an error | [Loaders](servers.md#loaders) |
| `.minecraftVersion(version)` | all but Velocity | none: an error | [Minecraft versions](servers.md#minecraft-versions) |
| `.loaderVersion(version)` | all but vanilla | the newest | [Loader versions](servers.md#loader-versions) |
| `.port(port)` | all | 25565; a proxy, 25577 | [Ports](servers.md#ports-and-the-firewall) |
| `.memory(size)` | all | `"2G"` | [Memory and Java](servers.md#memory-and-java) |
| `.jvmArg(arg)` | all | none | [Memory and Java](servers.md#memory-and-java) |
| `.jdk(package)` | all | the one the version needs | [Memory and Java](servers.md#memory-and-java) |
| `.acceptEula()` | all but Velocity | not accepted: an error | [server.properties](servers.md#serverproperties-and-the-eula) |
| `.property(key, value)` | all but Velocity | none | [server.properties](servers.md#serverproperties-and-the-eula) |
| `.mod(project)`, `.mod(project, version)` | Fabric, Forge, NeoForge | none | [Mods and plugins](servers.md#mods-and-plugins) |
| `.plugin(project)`, `.plugin(project, version)` | Paper, Velocity | none | [Mods and plugins](servers.md#mods-and-plugins) |
| `.openFirewall(open)` | all | `true` | [Ports](servers.md#ports-and-the-firewall) |
| `.autoUpdate()` | all | off | [Updates](servers.md#updates) |
| `.forwarding(mode)` | Velocity | `Forwarding.MODERN` | [Forwarding](proxy.md#forwarding) |
| `.forwardingSecretFile(path)` | Velocity | made by the proxy | [The secret](proxy.md#the-forwarding-secret) |
| `.server(name, address)` | Velocity | none | [Servers](proxy.md#the-proxys-servers) |
| `.server(server)` | Velocity | none | [Servers behind a proxy](proxy.md#servers-behind-a-proxy) |
| `.tryServer(name)` | Velocity | every server, in order | [The try list](proxy.md#the-try-list) |
| `.forcedHost(hostname, server)` | Velocity | none | [Forced hosts](proxy.md#forced-hosts) |
| `.install()` | all | | checks it and installs it; a proxy's, with the servers behind it |

A setting for another kind of server (a mod on Paper, a forwarding mode on Fabric) is an error when the
configuration builds, as is a value it can't take; [Errors](errors.md) lists them all.

## What it doesn't do

- **Mod dependencies.** Modrinth's dependencies aren't followed: name every mod a mod needs, as
  `fabric-api` for most Fabric mods. (A Fabric server behind a proxy gets `fabric-api` with
  FabricProxy-Lite.)
- **Modpacks, datapacks, resource packs**, and mods from anywhere but Modrinth. A file put in `mods/`
  or `plugins/` by hand is kept, and left alone.
- **Settings files besides `server.properties`** and, for a proxy, `velocity.toml`'s bind, forwarding
  and servers. Others (`bukkit.yml`, a mod's `config/`) are the server's own, to edit on the machine.
- **Backups.** The worlds are in `/var/lib/minecraft/<name>`; back that up as any folder.
