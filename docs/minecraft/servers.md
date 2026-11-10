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

A Velocity proxy isn't a loader: it is a `new Proxy(name)`, in [Velocity proxies](proxy.md).

The name, `new Server(name)`, is the server's service (`minecraft-<name>`) and folder
(`/var/lib/minecraft/<name>`): letters, digits, `-` and `_`. Each server installed has a name of its own.

## Minecraft versions

`.minecraftVersion(version)` is every `Server`'s; a `Proxy` has none (its Velocity's own
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
.modrinthMod("fabric-api")                          // the newest release for this loader and Minecraft version
.modrinthMod("lithium", "mc26.3-0.26.3-fabric")     // that version of it, by its version number
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
| Fabric, Forge, NeoForge | `.modrinthMod()`, into `mods/` | that loader, and that Minecraft version |
| Paper | `.plugin()`, into `plugins/` | Paper, Spigot or Bukkit, and that Minecraft version |
| Velocity | `.plugin()`, into `plugins/` | Velocity, any Minecraft version |

Without a pin, the newest release is chosen, or, if the project has none for that version, the newest
beta or alpha. The version's primary file is downloaded and checked against Modrinth's sha512.

They are chosen as [`nixos-rebuild`](running.md#a-rebuild) runs, and kept in `minecraft.lock`, beside the
configuration's `Main.seal`, for Nix to download, so a rebuild with nothing new asks Modrinth nothing,
and a start never does. They are chosen again:

- at every start, with [`autoUpdate()`](#updates), which then downloads them itself;
- all of them, when the loader or the Minecraft version changes;
- one, when its entry changes (a pin added, or changed) or its file is gone.

A mod or plugin the configuration no longer names is removed at the restart that follows the rebuild,
if this put it there. One put in `mods/` or `plugins/` by hand isn't, and is never touched.

Modrinth's and CurseForge's dependencies aren't followed: name every mod a mod needs. A server behind a Velocity proxy
gets what its forwarding needs by itself: [Servers behind a proxy](proxy.md#servers-behind-a-proxy).

### From CurseForge

```java
Server.setCurseForgeKeyFile("/run/secrets/curseforge");     // once, before the first install()

new Server("survival")
    .loader(Loader.FABRIC)
    .minecraftVersion("26.3")
    .acceptEula()
    .curseforgeMod("appleskin")                             // the newest, by its slug or ID
    .curseforgeMod("jei", "jei-26.3-fabric-31.17.0.109.jar")   // that file of it
    .curseforgeMod("306612")                                // by its project ID, which needs no key
    .install();
```

`.curseforgeMod(project)` takes a mod from CurseForge, by its slug (the name in its address,
curseforge.com/minecraft/mc-mods/**appleskin**) or its project ID: the newest file for the server's loader and
Minecraft version, a release, or else a beta, or else an alpha, as CurseForge's site offers. A second
argument names one file: its file ID, its file name, or its display name, whole. `.modrinthMod()` and
`.curseforgeMod()` can be mixed on one server, and files are kept and chosen again as above. Plugins
come from Modrinth alone.

It works with an API key or without one, and an API key is the better way:

| | With a key | Without one |
| --- | --- | --- |
| Goes through | CurseForge's API | CurseForge's website, whose file lists ask for no key |
| A mod is given by | its slug or its project ID | its project ID alone, as the site can't look up a slug |
| The file is checked against | CurseForge's sha1 (or md5) | its size alone: the site gives no hash |
| An author who opted out of third-party downloads | stops the start, with a message: put the file in `mods/` by hand | can't be seen, and the file is downloaded |
| It lasts | documented | the site's API is undocumented, and can change or refuse at any time |

A key comes from CurseForge's [developer console](https://console.curseforge.com/).
`Server.setCurseForgeKeyFile(file)`, once in the configuration and before the first `install()`, says
where it is: the path of a file that holds it, on the machine, that the user `minecraft` can read. With
sops-nix, `owner = "minecraft"`; not in `/home`, which the services can't see. The key itself never goes
in the configuration, which would put it in the Nix store, and in git. A server only reads it when it
has something to ask CurseForge, so one whose mods are all chosen starts without it.

## server.properties and the EULA

```java
.acceptEula()
.property("motd", "A Seal server")
.property("max-players", "20")
.property("difficulty", "hard")
```

Every `Server` needs `.acceptEula()`, the owner's acceptance of Mojang's EULA
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

A proxy has no `server.properties`, and no `.property()`. Its settings are in
`velocity.toml` ([Velocity proxies](proxy.md#velocitytoml)).

## Operators and bans

```java
.op("seal", "11111111-2222-4333-8444-555555555555", 4)
.op("helper", "aaaaaaaabbbb4ccc8dddeeeeeeeeeeee", 2)
.ban("griefer", "99999999-8888-4777-8666-555555555555")
```

`.op(name, uuid, level)` makes a player an operator, in `ops.json`, and `.ban(name, uuid)` bans them
for good, in `banned-players.json`. The level is from 1 to 4:

| Level | Can |
| --- | --- |
| 1 | Build in the spawn protection area |
| 2 | Also use cheat commands and command blocks |
| 3 | Also manage players: `/ban`, `/kick`, `/op` |
| 4 | Everything, as `/stop` |

A player is known by the UUID, and the name is only what the files and `/banlist` show. Nothing looks
a UUID up: the one given, with or without its dashes, goes in the file, so it works with no network.
It has to be the UUID the server sees, which depends on whether the server signs players in:

| The server | The UUID | To find it |
| --- | --- | --- |
| Online, the default, or behind a proxy with `MODERN` or `LEGACY` forwarding | The account's | `curl https://api.mojang.com/users/profiles/minecraft/<name>` |
| `online-mode=false`, or behind a proxy with `Forwarding.NONE` | Made from the name | The command below |

```sh
python3 -c 'import hashlib,sys,uuid; print(uuid.UUID(bytes=hashlib.md5(b"OfflinePlayer:"+sys.argv[1].encode()).digest(), version=3))' <name>
```

Names are exact here: on an offline server, `Seal` and `seal` are two players with two UUIDs.

Both are set at every start, as `.property()` is:

- **A player given here** is set again at every start, so a `/deop` or `/pardon` in the game lasts only
  until the next one. Take them out of the configuration instead.
- **A player taken out of the configuration** is no longer an operator, or banned, from the next start.
- **Anyone added in the game**, with `/op` or `/ban`, stays: only the players the configuration has
  named are touched.
- **What else an entry says** stays, if it is already in the file: a `bypassesPlayerLimit` or a ban's
  reason edited by hand, or the date of a ban. A new ban's reason is `Banned by an operator.`, and a
  ban given here never expires.

A file that isn't a JSON list stops the start, and is left as it was
([Errors](errors.md#when-a-server-starts)): left to itself, Paper would set it aside and start with an
empty list, letting a banned player in. A server that has never had an `.op()` or `.ban()` has its
files left alone.

Each server has its own lists, so to keep someone off a whole network, give `.ban()` to each server
behind the proxy. A proxy has none of these lists, and no `.op()`, `.ban()` or `.whitelist()`.

### The whitelist

```java
.whitelist("seal", "11111111-2222-4333-8444-555555555555")
.whitelist("friend", "bbbbbbbbcccc4ddd8eeeffffffffffff")
```

A new Minecraft 26.3 server has its whitelist **on**, with no one on it, so a server with no
`.whitelist()` lets in only its operators. To let anyone in, turn it off:

```java
.property("white-list", "false")
```

`.whitelist(name, uuid)` puts a player in `whitelist.json`, and turns the whitelist on. The UUID is
as [above](#operators-and-bans), and it works the same way: set at every start, a player taken out of
the configuration comes off at the next one, anyone added with `/whitelist add` stays, and a file that
isn't a JSON list stops the start.

`.op()` doesn't add anyone to the whitelist, but Minecraft itself lets operators past it, and no
setting changes that. A banned player stays out even if they are on it. A player can be given to
`.op()` and `.whitelist()` both.

Taking out the last `.whitelist()` leaves the whitelist on, so that no change to the configuration
opens a server to everyone by accident. `.property("white-list", "false")` is what turns it off, and
it wins over `.whitelist()`.

## Config files

```java
.config(new ConfigFile("config/mymod.toml")
    .set("general.threads", 4)
    .set("general.fastMath", true)
    .set("worlds", ["overworld", "nether"]))
.config(new ConfigFile("plugins/LuckPerms/config.yml").set("server", "lobby"))
.config(new ConfigFile("config/other.conf").text("enabled = true\n"))
```

A `ConfigFile` is a file in the server's folder, by its path there, and `.config(file)` gives it to a
server of any loader, a proxy too. It can be a mod's, a plugin's, or the loader's own:
`config/paper-global.yml`, or a proxy's `velocity.toml`. One `ConfigFile` can be given to several servers.

**`.set(key, value)`** sets that key at every start, and leaves the rest of the file as it is. The
value is a string, a whole number, `true` or `false`, a decimal, or a list of one of those, and goes
in as that type, so `true` isn't `"true"`. A list takes the place of the one there. The same key
again takes the last value.

| Extension | Format | The file's comments |
| --- | --- | --- |
| `.toml` | TOML | kept |
| `.yaml`, `.yml` | YAML | kept |
| `.json` | JSON | it has none |
| `.json5` | JSON5 | lost: the file comes back as plain JSON, which is JSON5 too |
| `.properties` | Java properties | kept |

A dot in a key goes down a level: `general.threads` is `threads` in the section `general`. `\\.` is a
dot of the key's own: `"a\\.b.c"` is `c` in the section `a.b`. A `.properties` file has no levels, so
there a dot is only a dot, as in `mixin.ai.pathing`, and a list is an error. One key can't be a section
of another (`a` and `a.b`), and a key under what is a value in the file (`top.sub` where `top = 1`)
stops the start, since it can't be set.

A key given here is written over at every start, so an edit of it on the machine doesn't last. Every
other key in the file is left alone.

**`.text(contents)`** is the whole file instead, written at every start, in any format and with any
extension: for what `.set()` can't say, or a mod that needs a complete file. A `ConfigFile` has one or
the other.

**Taking a setting out.** A key the configuration set before, and no longer does, is taken out of the
file at the next start, so the mod is back to its default. A section left with nothing in it stays,
empty. A file that was a `.text()`, and is no longer given, is deleted. Keys that were never given
here aren't touched.

**The first start.** Before a mod's first start its file doesn't exist, so it has only the keys given.
Lithium, FabricProxy-Lite, LuckPerms, Paper and Velocity all take that, and fill in the rest or use
their defaults; a mod that doesn't can have its whole file from `.text()`.

**Forge and NeoForge world configs** are in `world/serverconfig/`, which is made with the world. Give
them as `defaultconfigs/<file>`, which a new world copies.

A server that `.set()`s keys in a `.json5` file also gets Python, about 200 MB, to read it. The values
are in the Nix store, which every user of the machine can read: no passwords.

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

Without `.autoUpdate()`, a server keeps what was first chosen for it, until the configuration changes:

| What changes | What is chosen again |
| --- | --- |
| the loader, the Minecraft version, or `loaderVersion` | the loader, and, if the loader or the Minecraft version is another, every mod and plugin |
| a mod's or plugin's entry | that mod or plugin |
| nothing | nothing; nothing is downloaded, and no one asked |

With `.autoUpdate()`, every start chooses the newest of everything given: the Minecraft version, if
it is `"latest"`, the loader, unless `loaderVersion` pins it, and each mod and plugin that isn't pinned. A start then needs the
network, and an update can bring a mod that doesn't work with the others; pins keep the ones that
must stay.

To choose the loader again without a change, delete `.seal-mc/requested` in the server's folder, and
restart it. For a mod or plugin, take its entry out of `minecraft.lock` (or the server's, for all of
them), and rebuild.

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
