# Velocity proxies

[minecraft](README.md) › Velocity proxies

A Velocity proxy is where players connect. It signs them in with Mojang, and sends them on to its
servers, from one to another with `/server`. A server can be a `Server` of the same configuration,
which is then set up behind the proxy by itself, or one elsewhere, by its address.

```java
var lobby = new Server("lobby").loader(Loader.PAPER).minecraftVersion("26.3")
    .acceptEula().port(25566);
var survival = new Server("survival").loader(Loader.FABRIC).minecraftVersion("26.3")
    .acceptEula().port(25567).mod("lithium");

new Server("proxy")
    .loader(Loader.VELOCITY)
    .port(25565)                                        // where players connect
    .forwarding(Forwarding.MODERN)                      // the default
    .forwardingSecretFile("/run/secrets/velocity")      // or one the proxy makes
    .server(lobby)                                      // a Server: set up behind the proxy
    .server(survival)
    .server("creative", "10.0.0.5:25565")               // elsewhere, set up by hand
    .tryServer("lobby")                                 // where players join
    .tryServer("survival")
    .forcedHost("survival.example.com", "survival")     // who connects by this name joins survival
    .plugin("luckperms")
    .install();                                         // the proxy, lobby and survival
```

A proxy is a `Server` with `.loader(Loader.VELOCITY)`. It takes the settings every server does
([Servers](servers.md)) but `minecraftVersion()`, `property()` and `mod()`, and needs no
`acceptEula()`. It listens on 25577 unless `.port()` says, on every address.
Its Velocity is the newest release unless `.loaderVersion("3.5.1")` names one, and runs on Java 25.

## velocity.toml

The proxy's settings are in `velocity.toml`, in its folder. Its first start makes it from Velocity's
own default, and each start then sets:

| Key | To |
| --- | --- |
| `bind` | `0.0.0.0:<port>` |
| `player-info-forwarding-mode` | the [forwarding](#forwarding) mode |
| `forwarding-secret-file` | the [secret's](#the-forwarding-secret) file |
| `[servers]`, with `try` | the [servers](#the-proxys-servers) and [try list](#the-try-list), when the configuration gives any |
| `[forced-hosts]` | the [forced hosts](#forced-hosts), when the configuration gives any server |

Everything else in it (`motd`, `online-mode`, `show-max-players`, `[advanced]`, ...) is Velocity's, to
edit on the machine, and is kept. A proxy given no server keeps its `[servers]` and `[forced-hosts]`
as they are, so they can be edited by hand; a new `velocity.toml` has Velocity's examples there
(`lobby`, `factions`, `minigames`).

## Forwarding

The servers behind a proxy don't see players sign in, so the proxy tells them who each one is (name,
UUID, skin, address). `.forwarding(mode)` says how, as `velocity.toml`'s `player-info-forwarding-mode`:

| `Forwarding.` | How | Secret |
| --- | --- | --- |
| `MODERN` (the default) | Velocity's own, signed with the secret: a server takes it from the proxy alone. Minecraft 1.13 and newer | yes |
| `LEGACY` | BungeeCord's, unsigned: anyone who reaches a server can claim to be anyone | no |
| `BUNGEEGUARD` | `LEGACY` with the secret as a token, for servers with the BungeeGuard plugin | yes |
| `NONE` | nothing: the servers see every player as offline, with an offline UUID and no skin | no |

Behind a proxy, a server listens on 127.0.0.1 alone, so with `LEGACY` or `NONE`, anyone on the
machine can join it as anyone. `MODERN` is the one to use where it can be.

## The forwarding secret

`MODERN` and `BUNGEEGUARD` sign with a secret, which the proxy and its servers share.

Unless `.forwardingSecretFile(path)` names one, it is `/var/lib/minecraft/<proxy>/forwarding.secret`:
the proxy's first start makes it, 64 random hexadecimal characters, readable by the user `minecraft`
alone, and the next starts keep it.

`.forwardingSecretFile(path)` names a file the proxy doesn't make, as sops-nix or agenix give: an
absolute path (letters, digits, `/`, `.`, `_`, `-`, `+`, `@`), to a file the user `minecraft` can read
(with sops-nix, `owner = "minecraft"`). If it is missing or empty, a `MODERN` or `BUNGEEGUARD` proxy
doesn't start. A new line at its end is no matter.

The servers behind the proxy read the secret each time they start, so it is never in the Nix store.
Paper writes it into its `config/paper-global.yml`, so their folders can be read by the user
`minecraft` alone ([Running](running.md#security)).

To change it: write the new one in the file (or delete `forwarding.secret`, and the proxy makes
another), then restart the proxy and its servers: `systemctl restart minecraft-proxy minecraft-lobby
minecraft-survival`.

## The proxy's servers

```java
.server(lobby)                              // a Server of the configuration
.server("creative", "10.0.0.5:25565")       // a name, and an address
```

`.server(server)` gives a `Server` of the configuration, by its name, at `127.0.0.1:<its port>`,
and sets it up [behind the proxy](#servers-behind-a-proxy).

`.server(name, address)` gives a server this doesn't set up: on another machine, or one set up by hand,
which must [take the proxy's forwarding](#a-server-set-up-by-hand) itself. The name is letters,
digits, `-` and `_`, and not `try`; the address is `host:port` (`"10.0.0.5:25565"`,
`"mc.example.com:25565"`, `"[2001:db8::5]:25565"`).

Each server has a name of its own. Players move between them with `/server <name>`.

## The try list

`.tryServer(name)`, once for each, gives Velocity's `try` list: where a player joins, the first of
them that is up, and where one goes when their server stops under them. Each names a server given.
Without any, it is every server, in the order given.

## Forced hosts

```java
.forcedHost("survival.example.com", "survival")
.forcedHost("survival.example.com", "lobby")        // if survival is down
```

A player who connects by that hostname joins that server, not the try list's. The same hostname
again gives the next to try. The hostname is letters, digits, `.`, `-` and `_`, and its DNS points at
the proxy's machine; the server is one given.

## Servers behind a proxy

A `Server` of the configuration, given to the proxy with `.server(server)`, is set up behind it, with
the settings it has when the proxy is installed:

| | |
| --- | --- |
| `online-mode=false` | the proxy signs players in, not the server |
| `server-ip=127.0.0.1` | only this machine reaches it |
| not in the firewall | whatever `.openFirewall()` says |
| its folder `0750` | the user `minecraft`'s alone, for the secret |
| starts after the proxy, and wants it | `systemctl start minecraft-lobby` starts the proxy too |
| installed by the proxy | the proxy's `install()` installs it |

and takes the proxy's forwarding:

| Server | `NONE` | `LEGACY` | `BUNGEEGUARD` | `MODERN` |
| --- | --- | --- | --- | --- |
| Paper, 1.19 and newer | yes | yes | no | yes |
| Fabric | yes | no | no | yes, with FabricProxy-Lite |
| vanilla, Forge, NeoForge | yes | no | no | no |

A "no" is an error when the configuration builds: give the proxy another forwarding, or set the server
up by hand and give the proxy [its address](#a-server-set-up-by-hand).

**Paper** gets, at each start:

- in `config/paper-global.yml`: `proxies.velocity.enabled`, `true` for `MODERN`, else `false`;
  `proxies.velocity.online-mode` and `proxies.bungee-cord.online-mode`, `true`;
- in `spigot.yml`: `settings.bungeecord`, `true` for `LEGACY`, else `false`;
- for `MODERN`, the secret, in `PAPER_VELOCITY_SECRET`, as it starts.

**Fabric**, for `MODERN`, gets the mods `fabric-api` and `fabricproxy-lite`, if they aren't among its
mods, and the secret in `FABRIC_PROXY_SECRET` as it starts. FabricProxy-Lite's own settings
(`config/FabricProxy-Lite.toml`) are its defaults.

The `online-mode` given to Paper is the proxy's own default. A proxy made offline by hand (`online-mode
= false` in `velocity.toml`) needs Paper's set by hand to match.

A property given to the server comes after the proxy's, so `.property("server-ip", ...)` still says
where it listens.

The rules:

- A server is behind one proxy. A proxy isn't behind another.
- The proxy's `install()` installs it, and its own is an error, before or after.
- The proxy and its servers each have a port of their own, and a name of their own.

A machine can have several proxies, each with its servers, its port and its secret.

## Out from behind a proxy

A server no longer given to a proxy, and installed on its own, is put back at its next start:
`online-mode=true`, `server-ip=` (every address), Paper's forwarding off. Its port is in the firewall
again, unless `.openFirewall(false)`, and its folder stays `0750`. A Fabric server loses
FabricProxy-Lite, and `fabric-api` too unless it names it: give it `.mod("fabric-api")` if its other
mods need it.

## A server set up by hand

A server given by its address takes the proxy's forwarding by its own settings: with `MODERN`, the
same secret, and

- Paper: `online-mode=false` in `server.properties`; `proxies.velocity.enabled: true` and
  `proxies.velocity.secret` in `config/paper-global.yml` (or the secret in `PAPER_VELOCITY_SECRET`);
- Fabric: FabricProxy-Lite, with the secret in its `config/FabricProxy-Lite.toml` (or in
  `FABRIC_PROXY_SECRET`), and `online-mode=false`;
- Forge and NeoForge: a mod for Velocity's modern forwarding, and `online-mode=false`.

For a server on another machine, `.forwardingSecretFile()` on the proxy and the same secret on that
machine (from sops-nix or agenix, on both) keeps them one. A server built with this library on that
machine can be given `.property("online-mode", "false")`; its loader's forwarding settings are its own.
