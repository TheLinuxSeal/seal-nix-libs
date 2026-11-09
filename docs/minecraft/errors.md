# Errors

[minecraft](README.md) › Errors

## When the configuration builds

The settings are checked as seal-nix runs the configuration, so a mistake stops `nixos-rebuild` before
anything changes on the machine. The build's log says, after `uncaught IllegalArgumentException` (or
`IllegalStateException`), `Minecraft server <name>` and one of these. Whether a version, a
`loaderVersion()`, a mod or a pin exists is found out only when the server starts
([When a server starts](#when-a-server-starts)).

`Server.setCurseForgeKeyFile()` says what is wrong by itself, naming no server: `the CurseForge API key is
given by the path of a file that holds it`, for what isn't an absolute path, `the CurseForge API key's
file is set twice`, for two different files, and `comes after a server with CurseForge mods was installed
without it`, for setting it too late.

A setting its type doesn't have doesn't compile, and Seal says so, as `Proxy has no method modrinthMod` or
`Server has no method forwarding`. `Loader has no member VELOCITY` means a proxy is a `new Proxy(name)`.

### Any server

| Error | Means |
| --- | --- |
| `a name is letters, digits, - and _` | The server's name has another character, or is empty. |
| `no loader: loader(Loader.FABRIC), say, or Loader.VANILLA, FORGE, NEOFORGE or PAPER; a proxy is a new Proxy(name)` | The server has no `.loader()`. |
| `no Minecraft version: minecraftVersion("26.3"), say, or minecraftVersion("latest")` | The server has no `.minecraftVersion()`. |
| `no Minecraft version "<version>"` | The version has a character a version doesn't, or is empty. |
| `no loader version "<version>"` | `loaderVersion()` has a character a version doesn't. |
| `memory is a size, as "4G" or "512M"` | `memory()` isn't a number and a unit. |
| `no port <port>` | The port isn't between 1 and 65535. |
| `a server runs only once its owner accepts Mojang's EULA (https://aka.ms/MinecraftEULA): acceptEula()` | Every `Server` needs `.acceptEula()`. |
| `<loader> takes no mods; Fabric, Forge and NeoForge do` | `.modrinthMod()` or `.curseforgeMod()` on vanilla or Paper; Paper takes `.plugin()`. |
| `<loader> takes no plugins; Paper and Velocity do` | `.plugin()` on vanilla, Fabric, Forge or NeoForge; those take `.modrinthMod()` or `.curseforgeMod()`. |
| `no Modrinth project "<project>"`, `no CurseForge project "<project>"` | A mod's or plugin's project has a character other than letters, digits, `.`, `-`, `_` and `+`, or is empty. |
| `no Modrinth project "lithium@mc26.3-0.26.3-fabric": a version is modrinthMod's second argument, modrinthMod("lithium", "mc26.3-0.26.3-fabric")` | The old `"project@version"`: the version is an argument of its own now. |
| `no version "<version>" of <project>` | A mod's or plugin's version has a tab or a new line. |
| `without an API key, CurseForge's site can't look up "<slug>": give its project ID, ...` | A `.curseforgeMod()` by slug, with no key. Give the ID, on the project's page, or the key: [From CurseForge](servers.md#from-curseforge). |
| `no property <key>` | A property's key has a character other than letters, digits, `.`, `-` and `_`, or its value a new line. |
| `no operator level <level> for <name>: it is 1 to 4` | `.op()`'s level is outside 1 to 4. |
| `no player "<name>"` | `.op()`, `.ban()` or `.whitelist()` with an empty name, or one with a tab or a new line. |
| `<name>'s UUID "<uuid>" isn't one: 32 hexadecimal digits, as 069a79f4-44e9-4726-a5be-fca90e38aaf5` | Not a UUID, with or without its dashes; or the name and the UUID are the wrong way round. [Operators and bans](servers.md#operators-and-bans) says how to find it. |
| `the player <uuid> (<name>) is given twice: op() or ban(), once` | The same UUID in two `.op()`s or `.ban()`s, or in both an `.op()` and a `.ban()`. |
| `the player <uuid> (<name>) is given twice: whitelist(), once` | The same UUID in two `.whitelist()`s. |
| `is installed twice: install each server once, each with a name of its own` | `install()` twice, or two servers of one name. |

### A config file

These say `the config file "<path>"`, and then:

| Error | Means |
| --- | --- |
| `isn't a path in the server's folder, as "config/mymod.toml"` | The path is empty or absolute, has a `..`, an empty folder, a tab or a new line. |
| `is in .seal-mc, which is this library's own` | `.seal-mc/` is for the library's records. |
| `has both text(), which is the whole file, and set()` | A `ConfigFile` has one or the other. |
| `says nothing: set() a key, or text() the whole file` | A `ConfigFile` with neither. |
| `has no format to set() keys in: .toml, .yaml, .yml, .json, .json5 or .properties; text() writes any other` | `.set()` on a file of another extension. |
| `can't set <key> to NaN or Infinity` | No format has them. |
| `has no key "<key>"` | The key is empty, has a tab or a new line, or an empty part, as in `a..b`. |
| `can't set <key> to a list: a .properties file has none` | A list in a `.properties` file. |
| `sets both <key> and <key>: a value can't also be a section` | One key is a section of the other: `a` and `a.b`. |

And for the server: `two config files are "<path>"; give all its settings to one`.

### A proxy

| Error | Means |
| --- | --- |
| `the forwarding secret file is a path, as "/run/secrets/velocity", not "<path>"` | `forwardingSecretFile()` or `generateSecretFile()` isn't an absolute path, or has a character other than letters, digits, `/`, `.`, `_`, `-`, `+` and `@`. |
| `its forwarding secret is given twice: forwardingSecretFile() or generateSecretFile(), once` | Both on one proxy, or two different files. |
| `generateSecretFile("<path>") is under <folder>, where the services can't read it` | The file would be out of the services' sight: `/home`, `/root`, `/tmp`, `/var/tmp`, `/run/user` or `/nix`. |
| `generateSecretFile() makes a secret that <mode> forwarding doesn't use: MODERN and BUNGEEGUARD do` | `NONE` and `LEGACY` have no secret. |
| `no server name "<name>": a name is letters, digits, - and _, and not try` | `server(name, address)` or `server(server, name)` with another name. |
| `two servers are named <name>` | Two of the proxy's servers have one name. |
| `no address "<address>" for the server <name>: an address is host:port, as "10.0.0.5:25565"` | The address is empty, or has a character an address doesn't. |
| `tryServer("<name>") names no server; server() gives them` | The try list names a server the proxy isn't given. |
| `no hostname "<hostname>" for a forced host` | The hostname is empty, or has a character other than letters, digits, `.`, `-` and `_`. |
| `forcedHost("<hostname>", "<name>") names no server; server() gives them` | A forced host sends players to a server the proxy isn't given. |

### A server behind a proxy

These name the proxy, then the server: `Minecraft server proxy: lobby ...`.

| Error | Means |
| --- | --- |
| `has the proxy's own name` | A server named as its proxy is. |
| `is given to the proxy twice, as <name> and <name>: server(), once` | One `Server` given to `.server()` under two names. |
| `is behind the proxy <proxy> already: a server is behind one proxy` | The server is given to two proxies. This one names the second proxy. |
| `is installed on its own already: the proxy's install() installs it, so leave out its own` | The server's own `install()` came before its proxy's: leave it out. |
| `and the proxy both have port <port>; give one another` | The server and its proxy have one port. |
| `and <server> both have port <port>; give one another` | Two servers behind the proxy have one port. |
| `(<loader>) can't take <mode> forwarding as this sets it up (...)` | The server can't take the proxy's forwarding: [which can](proxy.md#servers-behind-a-proxy). Give the proxy another, or set the server up by hand and give the proxy its address. |
| `is Paper <version>; behind a proxy, Paper is 1.19 or newer, whose config/paper-global.yml this sets` | Paper before 1.19 keeps its forwarding elsewhere: give it by its address, set up by hand. |

And for the server itself: `Minecraft server <name> is behind the proxy <proxy>, whose install()
installs it: leave out <name>'s own`, when its own `install()` comes after it is given to the proxy.

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
| `<project> is from CurseForge, and there is no API key to read in <path>` | The file from `setCurseForgeKeyFile()` is missing, or not the user `minecraft`'s to read. | The file, or its owner. |
| `CurseForge didn't answer about <project>: is the API key in <path> right?` | The key is wrong, or CurseForge or the network is down. | It tries again; or check the key. |
| `CurseForge's site has no project <id>, or refused: its ID is on its page, or give an API key` | Without a key: the site didn't answer. It is undocumented, and can refuse. | It tries again; or give an API key. |
| `<url>: the download isn't the <n> bytes it should be` | Without a key, a download of the wrong size. | It tries again. |
| `CurseForge has no mod <project>` | No Minecraft mod of that slug or ID. | The slug, as in the project's address. |
| `<project> has no file for <loader> <version> on CurseForge` | The mod has no file for that loader and Minecraft version. | Another mod, or another version. |
| `<project> has no file <file> for <loader> <version> on CurseForge` | No file of that name or display name for that loader and Minecraft version. | The whole file name, or its file ID. |
| `CurseForge has no file <id> of <project>` | No file of that ID. | The file ID, as in the file's address. |
| `<project>'s author doesn't allow downloads through CurseForge's API: put it in mods/ by hand` | With a key: the author has opted out. | Download it, and put it in `mods/`. |
| `Modrinth has no project <slug>` | No project of that slug or ID. | The slug, as in the project's address. |
| `<slug> has no version for <loader> <version> on Modrinth` | The project has nothing for that loader and Minecraft version. | Another mod, or another version. |
| `<slug> has no version <version> for <loader> <version> on Modrinth` | The version given isn't one of the project's version numbers or IDs, or isn't for that loader and Minecraft version. | The whole version number, as the project's Versions tab on Modrinth shows it. |
| `<path> can't be read as <format>, so its settings can't be set; text() writes a whole file` | The file isn't what its extension says: a mod's `.json` with comments in it, say. It is left as it was. | Give the whole file with `.text()`. |
| `<path>: can't set <key>, which is under a value that isn't a section` | Part of the key is a value in the file, as `top.sub` where `top = 1`. It is left as it was. | The key as the file has it. |
| `<file> can't be read as a list of players, so its players can't be set: mend it, or delete it` | `ops.json`, `banned-players.json` or `whitelist.json` isn't a JSON list. It is left as it was. | Mend the file, or delete it: the server starts a new one, and the configuration's players go in it. |
| `MODERN forwarding is signed with a secret, and <path> holds none` | The proxy's `forwardingSecretFile()` is missing, empty, or not the user `minecraft`'s to read. (`BUNGEEGUARD` says so too.) | The file, or its owner. |
| `no forwarding secret to read in <path>, which minecraft-<proxy> signs with` | A server behind a proxy started before the proxy made its secret, or can't read the one given. | Start the proxy: `systemctl start minecraft-<proxy>`. |

One line doesn't stop the start: `config: <path>: can't be read, so what is no longer set stays in it`. A
setting was taken out of the configuration, but the file can't be edited, so it stays at its last value.

During `nixos-rebuild`, not a start, a proxy with `generateSecretFile()` can say `minecraft: can't make a new
forwarding secret in <path>`: its folder can't be made, or the user `minecraft` doesn't exist yet. The old
secret stays, and the rebuild reports the failure.

And from the server itself, in the same log:

| Log | Means |
| --- | --- |
| `FAILED TO BIND TO PORT`, `Address already in use` | Another server, or program, has the port: give one of them another. Servers on their own aren't checked for this when the configuration builds. |
| `OutOfMemoryError` | The heap is too small for the world and mods: a bigger `memory()`. |
| A mod's crash, after a start that chose again | A new version of a mod (from `autoUpdate()`, or a new Minecraft version) that doesn't work with the others: give the one that worked as its version, `.modrinthMod("lithium", "mc26.3-0.26.3-fabric")`. |

A player turned away by a server behind a proxy (FabricProxy-Lite says `This server requires you to
connect with Velocity.`) has connected to it without the proxy, or the proxy and the server have
different secrets: connect to the proxy, and after a new secret, restart both.
