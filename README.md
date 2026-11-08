# seal-nix-libs

Seal libraries for [seal-nix](https://github.com/TheLinuxSeal/seal-nix) configurations: classes that
set up a whole service in a few lines of Seal.

| Library | Import | | Docs | Example |
| --- | --- | --- | --- | --- |
| [`minecraft`](lib/sealnix/libs/minecraft/Server.seal) | `import sealnix.libs.minecraft.*;` | Minecraft servers (vanilla, Fabric, Forge, NeoForge, Paper) and Velocity proxies, with their mods and plugins from Modrinth | [`docs/minecraft`](docs/minecraft) | [`examples/minecraft`](examples/minecraft) |

A library's docs have every setting it has; its file says the gist, at its top. An example is a whole
machine that uses one, as a flake to start from: `nix flake init -t github:TheLinuxSeal/seal-nix-libs#minecraft`.

## Using them

Add the flake beside seal-nix, and its module beside seal-nix's:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    seal-nix = {
      url = "github:TheLinuxSeal/seal-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    seal-nix-libs = {
      url = "github:TheLinuxSeal/seal-nix-libs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.seal-nix.follows = "seal-nix";
    };
  };

  outputs = { nixpkgs, seal-nix, seal-nix-libs, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        seal-nix.nixosModules.default
        seal-nix-libs.nixosModules.default       # seal-nix.libraries = [ this flake's lib/ ]
        { seal-nix.src = ./config/Main.seal; }
      ];
    };
  };
}
```

Then the configuration imports what it uses:

```java
import sealnix.*;
import sealnix.libs.minecraft.*;

class Main {
    static void main() {
        new Server("lobby").loader(Loader.PAPER).minecraftVersion("26.3").acceptEula().install();
    }
}
```

seal-nix compiles only the classes a configuration names, so the libraries it doesn't use cost
nothing. Without the module, `seal-nix.libraries = [ seal-nix-libs.sealLibrary ];` is the same, and in
Nix, `seal-nix.lib.generate { ...; libraries = [ seal-nix-libs.sealLibrary ]; }`.

## Writing a library

A library is a Seal package, `sealnix.libs.<name>`, in its folder, `lib/sealnix/libs/<name>/`:
`package sealnix.libs.minecraft;` is at the top of each of `lib/sealnix/libs/minecraft`'s files
(`Service.seal`, `Server.seal`, `Proxy.seal`, `Loader.seal`, `Forwarding.seal`, `ConfigFile.seal`). It
imports `sealnix.*` for `Config` and `Packages`, as a
configuration does, and its public classes are what configurations import. The package keeps its
names out of theirs.

Each library has a configuration that uses it, `tests/<name>/Main.seal`, and a check in
[`flake.nix`](flake.nix) that makes its module and checks what it sets: `checks.<system>.minecraft`
is the Minecraft library's. `nix flake check` runs them all; `git add` new files first, since a flake
sees only what git tracks. Against a seal-nix of your own, not yet pushed:

```sh
nix flake check --override-input seal-nix path:../SealNix
```

## License

GPL-3.0, as seal-nix's: [`LICENSE`](LICENSE).
