# Servers

[minecraft](README.md) › Servers

## Loaders

```java
new Server("survival").loader(Loader.FABRIC).minecraftVersion("26.3")
```

Every server has a loader, `.loader()`; without one, the configuration doesn't build.

| `Loader.` | Loader | Takes | From |
| --- | --- | --- | --- |
| `VANILLA` | Mojang's server | nothing | Mojang's version manifest |
| `FABRIC` | Fabric | mods | meta.fabricmc.net |
| `FORGE` | Forge | mods | maven.minecraftforge.net |
| `NEOFORGE` | NeoForge | mods | maven.neoforged.net |
| `PAPER` | Paper | plugins | PaperMC (fill.papermc.io) |
| `VELOCITY` | Velocity, a proxy | plugins | PaperMC (fill.papermc.io); see [Velocity proxies](proxy.md) |

The name, `new Server(name)`, is the server's service (`minecraft-<name>`) and folder
(`/var/lib/minecraft/<name>`): letters, digits, `-` and `_`. Each server installed has a name of its own.

## Minecraft versions

`.minecraftVersion(version)` is every server's but a proxy's, which takes none (its Velocity's own
version is [`loaderVersion()`](#loader-versions)); without it, the configuration doesn't build.

The version is Mojang's: `"26.3"`, `"1.21.1"`, `"1.20.4"`. It has letters, digits, `.`, `-`, `_` and
`+`; one Mojang, or the loader, doesn't have is an error when the server starts
([Errors](errors.md#when-a-server-starts)).

`"latest"` is the newest release when the loader is chosen: Mojang's newest for vanilla, Fabric,
Forge and NeoForge, and PaperMC's newest stable version for Paper (which can be a little behind
Mojang's). It is chosen at the first start, and kept: a later release changes nothing until the
configuration changes or [`autoUpdate()`](#updates) asks. A proxy takes no Minecraft version.

## Loader versions

`.loaderVersion(version)` chooses the loader's own version; without it, the newest is chosen, at the
first start, and kept.

| Loader | `loaderVersion` is | Without it |
| --- | --- | --- |
| vanilla | not used | |
| Fabric | the Fabric loader's version, `"0.16.14"` | the newest stable loader for the Minecraft version, with the newest stable installer |
| Forge | Forge's version, without Minecraft's: `"52.0.16"` | the version Forge recommends for the Minecraft version, or else its latest |
| NeoForge | NeoForge's whole version, `"21.1.77"` | the newest NeoForge release for the Minecraft version (not alpha or beta, unless there is no other) |
| Paper | a build number, `"120"` | the latest build of the Minecraft version |
| Velocity | Velocity's version, `"3.5.1"` | the newest release (not a snapshot); always its latest build |

Forge and NeoForge run their installer at the first start, and again when their version changes: it
takes a few minutes, and writes `.seal-mc/installer.log`.

## Mods and plugins

```java
.mod("fabric-api")                          // the newest release for this loader and Minecraft version
.mod("lithium", "mc26.3-0.26.3-fabric")     // that version of it, by its version number
.plugin("luckperms")
.plugin("luckperms", "v5.5.71-bukkit")
```

A project is a Modrinth project, by its slug (the name in its address, modrinth.com/mod/**lithium**)
or its ID. A second argument pins one version: its version number, whole, as the project's Versions
tab on Modrinth shows it (each project writes its own: `mc26.3-0.26.3-fabric`, `0.165.2+26.3`,
`v2.12.0`), or its version ID. Modrinth keeps no version of the mod apart from that, so `"0.26.3"`
isn't Lithium's `mc26.3-0.26.3-fabric`.

| Server | Takes | Chosen among Modrinth's versions for |
| --- | --- | --- |
| Fabric, Forge, NeoForge | `.mod()`, into `mods/` | that loader, and that Minecraft version |
| Paper | `.plugin()`, into `plugins/` | Paper, Spigot or Bukkit, and that Minecraft version |
| Velocity | `.plugin()`, into `plugins/` | Velocity, any Minecraft version |

Without a pin, the newest release is chosen, or, if the project has none for that version, the newest
beta or alpha. The version's primary file is downloaded and checked against Modrinth's sha512.

The files chosen are kept from one start to the next, in `.seal-mc/mods.lock` or `plugins.lock`, so a
start asks Modrinth nothing. They are chosen again:

- at every start, with [`autoUpdate()`](#updates);
- all of them, when the loader or the Minecraft version changes;
- one, when its entry changes (a pin added, or changed) or its file is gone.

A mod or plugin the configuration no longer names is removed, if this put it there. One put in
`mods/` or `plugins/` by hand isn't, and is never touched.

Modrinth's dependencies aren't followed: name every mod a mod needs. A server behind a Velocity proxy
gets what its forwarding needs by itself: [Servers behind a proxy](proxy.md#servers-behind-a-proxy).

## server.properties and the EULA

```java
.acceptEula()
.property("motd", "A Seal server")
.property("max-players", "20")
.property("difficulty", "hard")
```

Every server but a proxy needs `.acceptEula()`, the owner's acceptance of Mojang's EULA
(https://aka.ms/MinecraftEULA): without it, the configuration doesn't build. It writes `eula=true` to
`eula.txt`.

Each `.property(key, value)` is a line of `server.properties`, set at every start: in place of the
line with that key, or added. The same key again replaces the value. Other lines are left as they are,
so the ones the server writes, and ones edited by hand, stay. `server-port` is always the
[port](#ports-and-the-firewall). A key has letters, digits, `.`, `-` and `_`; a value has no new line.

Behind a proxy, a server's `online-mode` is `false` and its `server-ip` `127.0.0.1`, before the
properties given, so a property can still change them ([Servers behind a proxy](proxy.md#servers-behind-a-proxy)).

The values are in the Nix store, which every user of the machine can read: no passwords, as
`rcon.password` ([Running](running.md#commands-and-rcon)).

A proxy has no `server.properties`: `.property()` on one is an error. Its settings are in
`velocity.toml` ([Velocity proxies](proxy.md#velocitytoml)).

## Memory and Java

```java
.memory("6G")                           // -Xms6G -Xmx6G
.jvmArg("-XX:+UseZGC")
.jvmArg("-XX:+ZGenerational")
.jdk(Packages.jdk21_headless)
```

`.memory(size)` is the Java heap, both its start and its most (`-Xms` and `-Xmx`): a size as Java
writes it, `"4G"`, `"512M"`. It is `"2G"` unless given. The machine needs more than the heap: Java and
the server use some besides.

`.jvmArg(arg)` adds an argument for `java`, after the heap's and before the server's own, in the order
given.

The Java is the one the Minecraft version needs, unless `.jdk(package)` gives another:

| Minecraft | Java |
| --- | --- |
| 26.1 and newer, and `"latest"` | 25 |
| 1.20.5 to 1.21.x | 21 |
| 1.17 to 1.20.4 | 17 |
| older | 8 |
| a Velocity proxy | 25 |

## Ports and the firewall

`.port(port)` is the port the server listens on: `server-port` in `server.properties`, or a proxy's
`bind` in `velocity.toml`. It is 25565 unless given, and 25577 for a proxy. Two servers on one machine
need two ports.

`.openFirewall(false)` leaves the port out of `networking.firewall.allowedTCPPorts`; it is in it
unless so. A server behind a proxy never is, whatever this says: it listens on 127.0.0.1, and only the
proxy reaches it.

## Updates

Without `.autoUpdate()`, a server keeps what its first start chose, until the configuration changes:

| What changes | What a start chooses again |
| --- | --- |
| the loader, the Minecraft version, or `loaderVersion` | the loader, and, if the loader or the Minecraft version is another, every mod and plugin |
| a mod's or plugin's entry | that mod or plugin |
| nothing | nothing; the start downloads nothing, and asks no one |

With `.autoUpdate()`, every start chooses the newest of everything given: the Minecraft version, if
it is `"latest"`, the loader, unless `loaderVersion` pins it, and each mod and plugin that isn't pinned. A start then needs the
network, and an update can bring a mod that doesn't work with the others; pins keep the ones that
must stay.

`nixos-rebuild switch` restarts a server whose configuration changed, which is when it chooses again.
To choose again without a change, delete `.seal-mc/requested` (the loader) or `.seal-mc/mods.for`
and `.seal-mc/plugins.for` (the mods and plugins) in its folder, and restart it.

## Installing

```java
var lobby = new Server("lobby").loader(Loader.PAPER).minecraftVersion("26.3").acceptEula();
lobby.port(25566);                                  // a Server can be set in steps
lobby.install();                                    // checked, then installed
```

`install()` checks every setting, and makes the server's service, its user and its port; until then,
a `Server` is only its settings, which can change. A server is installed once. A server given to a
proxy, `.server(server)`, is installed by the proxy's `install()`, with the settings it has then, and
its own `install()` is an error ([Servers behind a proxy](proxy.md#servers-behind-a-proxy)).
