{
  description = "Fake vault for proof of concept";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;

    eachSystem = let
      lp = nixpkgs.legacyPackages;
      zig = lp.x86_64-linux.zig.meta.platforms;
      nix = builtins.attrNames lp;
      systems = lib.intersectLists zig nix;
    in fn: lib.foldl' (
      acc: system: lib.recursiveUpdate
        acc
        (lib.mapAttrs (_: value: {${system} = value;}) (fn system))
    ) {} systems;
  in eachSystem (
    system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.default = with pkgs; mkShell {
        buildInputs = [
          squashfsTools
        ];
      };
      packages.default = pkgs.callPackage ./packages/fake-vault.nix {
        contents = {
          "gh/user".text = "pseudocc";
          "gh/repo".text = "fake-vault";
          "ssh/fake.pub".text = ''
            ssh-ed25519 THISISAFAKEPUBLICKEY pseudocc@fake-vault
          '';
          "ssh/fake".text = ''
            -----BEGIN OPENSSH PRIVATE KEY-----
            THISISAFAKEPRIVATEKEY
            -----END OPENSSH PRIVATE KEY-----
          '';
        };
      };
    }
  );
}
