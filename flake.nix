{
  description = "No-nixpkgs standard library for the Nix expression language";

  outputs = { self }:
    let
      std = import ./default.nix;
      defaultSystems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      eachDefaultSystem = f:
        std.list.foldl' std.set.mergeRecursive { }
          (std.list.map
            (system: std.set.map (v: { ${system} = v; }) (f system))
            defaultSystems);
    in
    {
      lib = std;
    } // eachDefaultSystem (system: {
      checks.nix-std-test = import ./test/default.nix { inherit system; };
    });
}
