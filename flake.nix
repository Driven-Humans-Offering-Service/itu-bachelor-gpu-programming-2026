{
  description = "CUDA Development Shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # Import nixpkgs with config.allowUnfree = true
        # This is REQUIRED for CUDA packages
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "cuda-env";

          buildInputs = with pkgs; [
            # The compiler
            cudaPackages.cuda_nvcc
            # The libraries
            cudaPackages.cudatoolkit

            # Standard C/C++ build tools
            gcc
            gnumake
          ];

          # This is the critical fix for "CUDA driver version is insufficient"
          # It forces the shell to look at the system's currently loaded driver libraries
          # first, ensuring they match the kernel module.
          shellHook = ''
            export LD_LIBRARY_PATH=/run/opengl-driver/lib:$LD_LIBRARY_PATH
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            export EXTRA_CCFLAGS="-I/usr/include"

            echo "CUDA Environment Loaded"
            echo "NVCC Version:"
            nvcc --version
          '';
        };
      }
    );
}
