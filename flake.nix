{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages.default = pkgs.rustPlatform.buildRustPackage {
            pname = "easyshort_backend";
            version = "1";
            src = ./.;
            useFetchCargoVendor = true;
            cargoHash = "sha256-F0gSBgOft7c2OlkINtDU1/LdfmGjMjYnLb7XlBDYGx8=";
          };

        }
      );
}

