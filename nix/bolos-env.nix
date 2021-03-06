{ pkgs, clangVersion, ... }:
let
  requireCurl = { url, sha256 }: pkgs.lib.overrideDerivation
    (pkgs.requireFile { inherit url sha256; })
    (attrs: {
       builder = pkgs.writeScript "get-the-thing" ''
        #!${pkgs.stdenv.shell}
        '${pkgs.curl}/bin/curl' --cacert '${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt' --url '${url}' -o "$out"
       '';
     });

  clangTar = {
    version7 = requireCurl {
      url = http://releases.llvm.org/7.0.0/clang+llvm-7.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz;
      sha256 = "1lk0qqkrjsjk6dqhzfibvmb9dbd6217lc0j0wd6a13nj7j1mrf39";
    };
    version4 = requireCurl {
      url = http://releases.llvm.org/4.0.0/clang+llvm-4.0.0-x86_64-linux-gnu-ubuntu-16.10.tar.xz;
      sha256 = "0j0kc73xvm2dl84f7gd2kh6a8nxlr7alk91846m0im77mvm631rv";
    };
  };

  gccTar = requireCurl {
    url = https://launchpadlibrarian.net/251687888/gcc-arm-none-eabi-5_3-2016q1-20160330-linux.tar.bz2;
    sha256 = "08x2sv2mhx3l3adw8kgcvmrs10qav99al410wpl18w19yfq50y11";
  };

  clang =
    let
      tarFile =
        if clangVersion == 7 then clangTar.version7
        else if clangVersion == 4 then clangTar.version4
        else throw "clang version ${toString clangVersion} not supported";
    in pkgs.runCommand "bolos-env-clang-${toString clangVersion}" {} ''
      mkdir -p "$out"
      tar xavf '${tarFile}' --strip-components=1 -C "$out"
    '';

  gcc = pkgs.runCommand "bolos-env-gcc" {} ''
    mkdir -p "$out"
    tar xavf '${gccTar}' --strip-components=1 -C "$out"
  '';

in pkgs.runCommand "bolos-env" {} ''
  mkdir -p "$out"
  ln -s '${clang}' "$out/clang-arm-fropi"
  ln -s '${gcc}' "$out/gcc-arm-none-eabi-5_3-2016q1"
'' // {
  inherit clang gcc;
}
