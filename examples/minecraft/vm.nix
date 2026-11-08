# Only for the virtual machine, which changes nothing on a real one:
#   nix build .#nixosConfigurations.minecraft.config.system.build.vm && ./result/bin/run-minecraft-vm
# It has the memory for the servers, and this computer's ports 25565 and 25570 lead to its own, so a
# Minecraft client here joins localhost (the proxy) or localhost:25570 (creative). The first start
# downloads the servers, which takes a few minutes.
{
  virtualisation.vmVariant.virtualisation = {
    memorySize = 12288;                 # the servers' 9G of heap, and the rest
    cores = 4;
    diskSize = 8192;
    forwardPorts = [
      { from = "host"; host.port = 25565; guest.port = 25565; }
      { from = "host"; host.port = 25570; guest.port = 25570; }
    ];
  };
}
