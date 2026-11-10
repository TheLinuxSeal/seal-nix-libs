# Running

[minecraft](README.md) › Running

## The service

Each server is a systemd service, `minecraft-<name>`:

| | |
| --- | --- |
| Description | `Minecraft server <name> (<loader> <version>)`, and `, behind <proxy>` |
| Starts | at boot (`multi-user.target`), once the network is up (`network-online.target`); behind a proxy, after the proxy, which it wants |
| Runs as | the user and group `minecraft`, a system user whose home is `/var/lib/minecraft` |
| In | `/var/lib/minecraft/<name>`, its state directory: `0755`, or `0750` behind a proxy |
| Restarts | when it fails, 10 seconds after |
| Start time | up to 20 minutes, for the first start's downloads and Forge's installer |
| Stop time | up to 120 seconds, to save the worlds; it ends with 143 (SIGTERM), which counts as success |
| Sandbox | `ProtectSystem=strict` (all but its folder read-only), `ProtectHome`, `PrivateTmp`, `NoNewPrivileges` |
| Tools | curl, jq, coreutils, gawk, grep, yq and its Java; Velocity's unzip; Python, if it `.set()`s keys in a `.json5` file |

```sh
systemctl status minecraft-survival
systemctl restart minecraft-survival
systemctl stop minecraft-survival             # saves the worlds, and stops
journalctl -u minecraft-survival -f           # the start, and the server's console
```

`nixos-rebuild switch` restarts a server whose configuration changed, which disconnects its players;
the others keep running. A server taken out of the configuration stops, and its service goes; its
folder, with its worlds, stays.

## A rebuild

Each mod and plugin is in `minecraft.lock`, beside the configuration's `Main.seal`: its file, where it
comes from, and its sha512. Nix downloads them from there, by that hash, as it builds the system, so
they are in the Nix store, and a start copies them into the server's folder.

The library's `nixos-rebuild` keeps the lock up to date. It takes the place of NixOS's own, and before
running it, with the same arguments, it reads the configuration:

- a mod or plugin it doesn't have yet is chosen, as [Servers](servers.md#mods-and-plugins) says;
- one no longer named goes;
- one already there stays as it is, unless its server's loader or Minecraft version changed: then
  every one of that server's is chosen again.

```sh
sudo nixos-rebuild switch --flake .
```

A rebuild with nothing new asks no one, and needs no network for the lock. One that can't be had stops
the rebuild there, before Nix builds anything, with the running system and the lock as they were:

```
minecraft survival: neovelocity has no version for neoforge 26.3 on Modrinth
```

A new `minecraft.lock` is added to git (`git add --intent-to-add`), as a flake sees only the files git
knows of; commit it with the configuration. As root, under `sudo`, the file is the flake owner's. It
is written for a flake on the machine: `--flake .`, a path, or `/etc/nixos/flake.nix`. A flake from
elsewhere (`github:...`) is built with the lock it has.

The first rebuild with this library installs its `nixos-rebuild`, and the lock is written from the
next one. Until then, and for what the lock doesn't have, Nix says so, and the start downloads it:

```
evaluation warning: minecraft survival: its start will download lithium, which minecraft.lock doesn't have yet; ...
```

The start also downloads:

- for `.autoUpdate()`, and a Minecraft version of `"latest"`: what to take is only known then;
- a CurseForge mod whose API key isn't on the machine yet: a new secret, from sops-nix or agenix,
  appears later in the same rebuild;
- the server's jar and its loader, when they change: Forge's and NeoForge's installers are programs
  to run.

`nixos-rebuild switch --rollback` goes back to a system and its mods, from the Nix store, with no
network.

## A start

The service's `preStart` runs first, as `minecraft`, in the server's folder:

1. **The loader**, if the configuration asks for another one than last time (another loader,
   Minecraft version or `loaderVersion`), or `autoUpdate()` is on, or there is none yet: it chooses
   the Minecraft version (for `"latest"`) and the loader's version, downloads it, and for Forge and
   NeoForge runs the installer.
2. **The mods or plugins**, copied from the Nix store, as [the rebuild](#a-rebuild) downloaded them,
   and the ones no longer named removed.
3. **The settings.** For a server: `eula.txt`, `server.properties`, and behind a proxy, its forwarding
   ([Servers behind a proxy](proxy.md#servers-behind-a-proxy)). For a proxy: its forwarding secret, if
   it makes it, and `velocity.toml` ([velocity.toml](proxy.md#velocitytoml)).
4. **The config files**: what the configuration no longer sets is taken out, and then each
   [`ConfigFile`](servers.md#config-files) is applied, after the settings, so that it has the last word
   on them.
5. **[Operators, bans and the whitelist](servers.md#operators-and-bans)**: each player given goes in
   `ops.json`, `banned-players.json` or `whitelist.json`, and those no longer given come out.

Then the server itself: `java -Xms<memory> -Xmx<memory> <jvmArgs> <the loader's arguments>`, with
the forwarding secret in its environment behind a proxy.

A start that has everything downloads nothing and asks no one, so a server restarts without the
network, unless `autoUpdate()` is on.

## Downloads

| What | From | Checked against |
| --- | --- | --- |
| Mojang's server (vanilla) | Mojang | its sha1 |
| Fabric's server launcher | meta.fabricmc.net | nothing: Fabric gives no hash |
| Forge's and NeoForge's installers | their Maven repositories | the repository's sha1, when it has one |
| Paper, Velocity | PaperMC | its sha256 |
| Mods and plugins | Modrinth | its sha512 |
| Mods | CurseForge, with an API key | its sha1, or md5 |
| Mods | CurseForge's website, without one | its size alone: the site gives no hash |

A download goes to a `.part` file, and takes the file's place only once it is whole and checked; a
failed one is tried three times, then the start fails, and the service tries again 10 seconds later.
Nix downloads what the lock names itself, and checks each file against its sha512.
The requests say who they are from, as Modrinth asks: `seal-nix-libs minecraft
(github.com/TheLinuxSeal/seal-nix-libs)`.

## The folder

```
/var/lib/minecraft/<name>/
├── server.jar               the loader: server.jar, fabric-server.jar, paper.jar or velocity.jar;
│                            Forge's and NeoForge's in libraries/
├── mods/  or  plugins/
├── server.properties, eula.txt          a server's
├── world/, logs/, ops.json, ...         the server's own
├── config/paper-global.yml, spigot.yml  Paper's
├── velocity.toml, forwarding.secret     a proxy's
└── .seal-mc/                            this library's
    ├── requested            the loader, Minecraft version and loader version asked for
    ├── minecraft            the Minecraft version chosen: what "latest" became
    ├── launch               the loader's arguments for java
    ├── mods.lock            each mod given, and its file (plugins.lock for plugins)
    ├── mods.for             the loader and Minecraft version they were chosen for (plugins.for)
    ├── behind               the forwarding of the proxy this is behind; empty for none
    ├── installer.log        Forge's or NeoForge's installer's output
    ├── configs              the config files of the last start, to know what no longer is
    └── ops, bans, whitelist the players they named, for the same reason
```

Deleting `.seal-mc/requested` chooses the loader again at the next start. Taking a mod out of
`minecraft.lock` (or a server, or the whole file) chooses it again at the next rebuild.

## Commands and RCON

A service has no console to type in. Commands go through RCON, or the game. Operators, bans and the
whitelist can be [in the configuration](servers.md#operators-and-bans), and `ops.json` and the others
can also be edited, with the server stopped.

```java
.property("enable-rcon", "true")
```

and the password in `server.properties` on the machine, by hand: `rcon.password=...`. A property
given here is in the Nix store, which every user of the machine can read, and a line of
`server.properties` that isn't given here is kept. RCON's port (`rcon.port`, 25575) isn't in the
firewall, so an RCON client on the machine reaches it: `mcrcon -P 25575 -p <password> "op seal"`.

## Security

- **The Nix store is public to the machine.** Everything the configuration says (properties, config
  files, JVM arguments, names, addresses) is in it, readable by every user. Passwords and secrets go in files on
  the machine, as the forwarding secret does.
- **The CurseForge API key** is never in the store, and on no command line: it is read from its file
  when a server has something to ask, and only CurseForge's API gets it, not its download servers.
- **The forwarding secret** is never in the store: the proxy's own, and a generated one, is `0600`, a given one is the
  file it is, and the servers behind a proxy read it as they start. Paper writes it into its config,
  so those servers' folders are `0750`.
- **Mods and plugins** are downloaded by Nix, and checked against the sha512 in `minecraft.lock`:
  the same file every time, or none. The lock's own choices are checked as a start's would be
  (Modrinth's sha512, CurseForge's sha1 or md5, or its size alone without a key).
- **The sandbox**: each server runs as `minecraft`, can write only its own folder, and can't see
  `/home`.
- **The downloads** are checked against the hashes their sources give (but Fabric's launcher, which
  has none), over HTTPS.
- **The firewall** opens the ports of proxies and of servers on their own, unless
  `.openFirewall(false)`; never a server behind a proxy, or RCON.
- **Behind a proxy**, a server listens on 127.0.0.1 and is offline. With `MODERN` forwarding it takes
  players from the proxy alone; with `LEGACY` or `NONE`, anyone on the machine can join it as anyone
  ([Forwarding](proxy.md#forwarding)).
