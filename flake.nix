{
  description = "IPOPT";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mumps = {
      url = "github:dzmitry-lahoda-forks/mumps/1b56c9295f8cf23ddb20400c44255fa984526977";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        {
          packages = with pkgs;
            rec {
              ipopt-mumps-seq = pkgs.stdenv.mkDerivation {
                name = "ipopt";
                version = "3.14.13";
                src = ./.;
                CXXDEFS = [
                  "-D HAVE_RAND"
                  "-D HAVE_CSTRING"
                  "-D HAVE_CSTDIO"
                ];
                LD_LIBRARY_PATH = with pkgs; lib.strings.makeLibraryPath [
                  "${inputs'.mumps.packages.mumps-32-seq}/lib"
                ];

                configureFlags = [
                  "--with-mumps-cflags=-I${inputs'.mumps.packages.mumps-32-seq}/include"
                  "--with-mumps-lflags=-ldmumps"
                  "--disable-mpiinit"
                  "--without-hsl"
                  "--without-spral"
                  "--with-precision=double"
                  "--disable-java"
                  "--without-asl"
                  #"--prefix=."
                  #"--with-intsize=64" # for MUMPS/METIS/LAPACK 64
                  #"--enable-inexact-solver"

                ];

                nativeBuildInputs = [ pkg-config gfortran ];
                buildInputs = [ blas lapack inputs'.mumps.packages.mumps-32-seq ];

                enableParallelBuilding = true;
              };
              default = ipopt-mumps-seq;

            };
        };
    };
}
