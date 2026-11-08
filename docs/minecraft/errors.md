# Errors

[minecraft](README.md) › Errors

## When the configuration builds

The settings are checked as seal-nix runs the configuration, so a mistake stops `nixos-rebuild` before
anything changes on the machine. The build's log says, after `uncaught IllegalArgumentException` (or
`IllegalStateException`), `Minecraft server <name>` and one of these. Whether a version, a
`loaderVersion()`, a mod or a pin exists is found out only when the server starts
([When a server starts](#when-a-server-starts)).

### Any server

| Error | Means |
| --- | --- |
| `a name is letters, digits, - and _` | The server's name has another character, or is empty. |
| `no Minecraft version "<version>"` | The version has a character a version doesn't, or is empty. |
| `no loader version "<version>"` | `loaderVersion()` has a character a version doesn't. |
| `memory is a size, as "4G" or "512M"` | `memory()` isn't a number and a unit. |
| `no port <port>` | The port isn't between 1 and 65535. |
| `a server runs only once its owner accepts Mojang's EULA (https://aka.ms/MinecraftEULA): acceptEula()` | Every server but a proxy needs `.acceptEula()`. |
| `<loader> takes no mods; Fabric, Forge and NeoForge do` | `.mod()` on vanilla, Paper or Velocity; Paper and Velocity take `.plugin()`. |
| `<loader> takes no plugins; Paper and Velocity do` | `.plugin()` on vanilla, Fabric, Forge or NeoForge; those take `.mod()`. |
| `velocity has no server.properties; a proxy's own settings are its velocity.toml's` | `.property()` on a proxy: [velocity.toml](proxy.md#velocitytoml). |
| `no Modrinth project "<project>"` | A mod's or plugin's project has a character other than letters, digits, `.`, `-`, `_` and `+`, or is empty. |
| `no Modrinth project "lithium@mc26.3-0.26.3-fabric": a version is mod's second argument, mod("lithium", "mc26.3-0.26.3-fabric")` | The old `"project@version"`: the version is an argument of its own now. |
| `no version "<version>" of <project>` | A mod's or plugin's version has a tab or a new line. |
| `no property <key>` | A property's key has a character other than letters, digits, `.`, `-` and `_`, or its value a new line. |
| `<setting>() is a Velocity proxy's, and <loader> is no proxy` | `forwarding()`, `forwardingSecretFile()`, `server()`, `tryServer()` or `forcedHost()` on a server. |
| `is installed twice: install each server once, each with a name of its own` | `install()` twice, or two servers of one name. |

### A proxy

| Error | Means |
| --- | --- |
| `the forwarding secret file is a path, as "/run/secrets/velocity", not "<path>"` | `forwardingSecretFile()` isn't an absolute path, or has a character other than letters, digits, `/`, `.`, `_`, `-`, `+` and `@`. |
| `no server name "<name>": a name is letters, digits, - and _, and not try` | `server(name, address)` with another name. |
| `two servers are named <name>` | Two of the proxy's servers have one name. |
| `no address "<address>" for the server <name>: an address is host:port, as "10.0.0.5:25565"` | The address is empty, or has a character an address doesn't. |
| `tryServer("<name>") names no server; server() gives them` | The try list names a server the proxy isn't given. |
| `no hostname "<hostname>" for a forced host` | The hostname is empty, or has a character other than letters, digits, `.`, `-` and `_`. |
| `forcedHost("<hostname>", "<name>") names no server; server() gives them` | A forced host sends players to a server the proxy isn't given. |

### A server behind a proxy

These name the proxy, then the server: `Minecraft server proxy: lobby ...`.

| Error | Means |
| --- | --- |
| `is a proxy itself` | A proxy given to a proxy. |
| `has the proxy's own name` | A server named as its proxy is. |
| `is behind the proxy <proxy> already: a server is behind one proxy, built once` | The server is given to two proxies, or one proxy's builder is built twice. |
| `is installed on its own already: the proxy's install() installs it, so leave out its own` | The server's own `install()` came before its proxy's: leave it out. |
| `and the proxy both have port <port>; give one another` | The server and its proxy have one port. |
| `and <server> both have port <port>; give one another` | Two servers behind the proxy have one port. |
| `(<loader>) can't take <mode> forwarding as this sets it up (...)` | The server can't take the proxy's forwarding: [which can](proxy.md#servers-behind-a-proxy). Give the proxy another, or set the server up by hand and give the proxy its address. |
| `is Paper <version>; behind a proxy, Paper is 1.19 or newer, whose config/paper-global.yml this sets` | Paper before 1.19 keeps its forwarding elsewhere: give it by its address, set up by hand. |

And for the server itself: `Minecraft server <name> is behind the proxy <proxy>, whose install()
installs it: leave out <name>'s own`, when its own `install()` comes after the proxy is built.

## When a server starts

A start that fails leaves the server stopped, and the service tries again 10 seconds later. The
reason is in its log, `journalctl -u minecraft-<name>`, on a line that starts with `minecraft:`:

| Log | Means | So |
| --- | --- | --- |
| `can't download <url>` | The network, or the source, is down; or a `loaderVersion()` names no version. | It tries again; or check the machine's network, or the version. |
| `<url>: the download's <sha1/sha256/sha512> isn't <hash>` | The file isn't what its source says. | It tries again; if it keeps on, the source has changed. |
| `Minecraft has no version <version>` | Mojang has no such version. | Another version. |
| `Fabric has no loader for Minecraft <version>` | Fabric has no stable loader for that version (yet). | Another version, or wait. |
| `Forge has no version for Minecraft <version>` | Forge has none for that version (yet). | Another version, or `loaderVersion()`. |
| `NeoForge has no version for Minecraft <version>` | The same, for NeoForge. | |
| `Forge's installer failed; .seal-mc/installer.log says why` | The installer stopped; the log, in the server's folder, says why. | |
| `NeoForge's installer failed; .seal-mc/installer.log says why` | The same, for NeoForge. | |
| `PaperMC has no paper <version>, build <build>` | No Paper for that version (yet), or no such build; for a proxy, no such Velocity. | Another version or build. |
| `Modrinth has no project <slug>` | No project of that slug or ID. | The slug, as in the project's address. |
| `<slug> has no version for <loader> <version> on Modrinth` | The project has nothing for that loader and Minecraft version. | Another mod, or another version. |
| `<slug> has no version <version> for <loader> <version> on Modrinth` | The version given isn't one of the project's version numbers or IDs, or isn't for that loader and Minecraft version. | The whole version number, as the project's Versions tab on Modrinth shows it. |
| `MODERN forwarding is signed with a secret, and <path> holds none` | The proxy's `forwardingSecretFile()` is missing, empty, or not the user `minecraft`'s to read. (`BUNGEEGUARD` says so too.) | The file, or its owner. |
| `no forwarding secret to read in <path>, which minecraft-<proxy> signs with` | A server behind a proxy started before the proxy made its secret, or can't read the one given. | Start the proxy: `systemctl start minecraft-<proxy>`. |

And from the server itself, in the same log:

| Log | Means |
| --- | --- |
| `FAILED TO BIND TO PORT`, `Address already in use` | Another server, or program, has the port: give one of them another. Servers on their own aren't checked for this when the configuration builds. |
| `OutOfMemoryError` | The heap is too small for the world and mods: a bigger `memory()`. |
| A mod's crash, after a start that chose again | A new version of a mod (from `autoUpdate()`, or a new Minecraft version) that doesn't work with the others: give the one that worked as its version, `.mod("lithium", "mc26.3-0.26.3-fabric")`. |

A player turned away by a server behind a proxy (FabricProxy-Lite says `This server requires you to
connect with Velocity.`) has connected to it without the proxy, or the proxy and the server have
different secrets: connect to the proxy, and after a new secret, restart both.
