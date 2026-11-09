# minecraft

Minecraft servers and Velocity proxies on NixOS, from a [seal-nix](https://github.com/TheLinuxSeal/seal-nix)
configuration. Each server is a systemd service, `minecraft-<name>`, that downloads its loader and its
mods or plugins (from Modrinth or CurseForge) when it starts, and keeps them until the configuration changes.

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
            .modrinthMod("fabric-api")
            .modrinthMod("lithium")
            .property("difficulty", "hard")
            .install();
    }
}
```

| Page | |
| --- | --- |
| [Servers](servers.md) | Loaders, Minecraft and loader versions, mods and plugins, `server.properties`, operators, bans and the whitelist, config files, memory and Java, ports, updates |
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

A Seal file that uses it imports the package, `import sealnix.libs.minecraft.*;`, which has `Server` and
`Proxy` (a Velocity proxy), each a `Service`, whose settings they share, with `Loader` (a server's
loaders), `Forwarding` (a proxy's forwarding modes) and `ConfigFile` (a mod's or plugin's config file).

## Every setting

A server is a `new Server(name)`, and a Velocity proxy a `new Proxy(name)`. Each setting is a method
that returns it, so they chain; `install()` checks them all, and installs it. The name is its service, `minecraft-<name>`, and
its folder, `/var/lib/minecraft/<name>`: letters, digits, `-` and `_`.

| Setting | For | Default | |
| --- | --- | --- | --- |
| `.loader(loader)` | `Server` | none: an error | [Loaders](servers.md#loaders) |
| `.minecraftVersion(version)` | `Server` | none: an error | [Minecraft versions](servers.md#minecraft-versions) |
| `.loaderVersion(version)` | all but vanilla | the newest | [Loader versions](servers.md#loader-versions) |
| `.port(port)` | all | 25565; a proxy, 25577 | [Ports](servers.md#ports-and-the-firewall) |
| `.memory(size)` | all | `"2G"` | [Memory and Java](servers.md#memory-and-java) |
| `.jvmArg(arg)` | all | none | [Memory and Java](servers.md#memory-and-java) |
| `.jdk(package)` | all | the one the version needs | [Memory and Java](servers.md#memory-and-java) |
| `.acceptEula()` | `Server` | not accepted: an error | [server.properties](servers.md#serverproperties-and-the-eula) |
| `.property(key, value)` | `Server` | none | [server.properties](servers.md#serverproperties-and-the-eula) |
| `.op(name, uuid, level)`, `.ban(name, uuid)` | `Server` | none | [Operators and bans](servers.md#operators-and-bans) |
| `.whitelist(name, uuid)` | `Server` | no one; 26.3 has the whitelist on | [The whitelist](servers.md#the-whitelist) |
| `.config(file)` | all | none | [Config files](servers.md#config-files) |
| `.modrinthMod(project)`, `.modrinthMod(project, version)` | `Server`: Fabric, Forge, NeoForge | none | [Mods and plugins](servers.md#mods-and-plugins) |
| `.curseforgeMod(project)`, `.curseforgeMod(project, file)` | `Server`: Fabric, Forge, NeoForge | none | [From CurseForge](servers.md#from-curseforge) |
| `Server.setCurseForgeKeyFile(file)` | once, for all servers | none: through CurseForge's website, by project ID | [From CurseForge](servers.md#from-curseforge) |
| `.plugin(project)`, `.plugin(project, version)` | `Server` on Paper, `Proxy` | none | [Mods and plugins](servers.md#mods-and-plugins) |
| `.openFirewall(open)` | all | `true` | [Ports](servers.md#ports-and-the-firewall) |
| `.autoUpdate()` | all | off | [Updates](servers.md#updates) |
| `.forwarding(mode)` | `Proxy` | `Forwarding.MODERN` | [Forwarding](proxy.md#forwarding) |
| `.forwardingSecretFile(path)` | `Proxy` | made by the proxy | [The secret](proxy.md#the-forwarding-secret) |
| `.generateSecretFile(path)` | `Proxy` | made by the proxy, once | [The secret](proxy.md#the-forwarding-secret): a new one at every rebuild |
| `.server(name, address)` | `Proxy` | none | [Servers](proxy.md#the-proxys-servers) |
| `.server(server)`, `.server(server, name)` | `Proxy` | none | [Servers behind a proxy](proxy.md#servers-behind-a-proxy) |
| `.tryServer(name)` | `Proxy` | every server, in order | [The try list](proxy.md#the-try-list) |
| `.forcedHost(hostname, server)` | `Proxy` | none | [Forced hosts](proxy.md#forced-hosts) |
| `.install()` | all | | checks it and installs it; a proxy's, with the servers behind it |

"all" is a `Server` and a `Proxy`. A setting its type doesn't have (`.modrinthMod()` on a `Proxy`) doesn't compile.
One its loader can't use (a mod on Paper), or a value it can't take, is an error when the configuration
builds; [Errors](errors.md) lists them all.

## What it doesn't do

- **Mod dependencies.** Modrinth's and CurseForge's dependencies aren't followed: name every mod a mod needs, as
  `fabric-api` for most Fabric mods. (A Fabric server behind a proxy gets `fabric-api` with
  FabricProxy-Lite.)
- **Modpacks, datapacks, resource packs**, and mods from anywhere but Modrinth and CurseForge. A file put in `mods/`
  or `plugins/` by hand is kept, and left alone.
- **Backups.** The worlds are in `/var/lib/minecraft/<name>`; back that up as any folder.
