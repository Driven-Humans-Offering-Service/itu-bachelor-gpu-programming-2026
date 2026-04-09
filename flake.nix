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

            # System libraries needed by Python packages
            zlib
            cudaPackages.nsight_compute
            cudaPackages.nsight_systems
          ];

          # This is the critical fix for "CUDA driver version is insufficient"
          # It forces the shell to look at the system's currently loaded driver libraries
          # first, ensuring they match the kernel module.
          # Also includes GCC and zlib libraries needed by Python packages with C extensions.
          shellHook = ''
            export LD_LIBRARY_PATH=/run/opengl-driver/lib:${pkgs.gcc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            export EXTRA_CCFLAGS="-I/usr/include"
            export NCU_SECTION_FOLDER="${pkgs.cudaPackages.nsight_compute}/sections"

            echo "CUDA Environment Loaded"
            echo "NVCC Version:"
            nvcc --version
          '';
        };
      }
    );
}
