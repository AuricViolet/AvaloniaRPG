{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      eachSystem = with nixpkgs.lib;
        systems: f:
        foldAttrs mergeAttrs { }
          (map (s: mapAttrs (_: v: { ${s} = v; }) (f s)) systems);
    in eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };
        dotnet = pkgs.dotnetCorePackages.sdk_8_0.overrideAttrs
              (finalAttrs: prevAttrs: {
                # Currently `dotnet workload` does not work (due to the store being
                # readonly). There is a bug tracking this [^1], but it is not ready.
                #
                # I tried seeing if I could add the workload in an overlay using a
                # postInstall I found in a discourse post[^2], but it errored with a
                # message about not being able to execute dotnet (in a way that
                # indicated it couldn't seem to find it, even though I could see it in
                # the folder). Could be an overlay thing...
                #
                # Instead I opted for flagging that workloads should be installed in
                # the users directory[^3]. Not pure, but at least is also not likely
                # to break.
                #
                # The workload folder is the SDK version, but with the last two digits
                # as 00[^4], and a full list can be found on MSDN[^5]
                #
                # [^1]: https://github.com/NixOS/nixpkgs/issues/226107
                # [^2]: https://discourse.nixos.org/t/dotnet-maui-workload/20370
                # [^3]: https://learn.microsoft.com/en-us/dotnet/core/distribution-packaging
                # [^4]: https://github.com/dotnet/sdk/pull/18823#issuecomment-1943095243
                # [^5]: https://learn.microsoft.com/en-us/dotnet/core/porting/versioning-sdk-msbuild-vs#targeting-and-support-rules
                postInstall = (prevAttrs.postInstall or "") + ''
                # Flag that workloads should be installed in the users folder
                for sdk in $out/sdk/*
                do
                  sdk=$(basename $sdk)
                  # Chop off the last two characters and hardcode 00
                  version=''${version%??}00
                  mkdir -p "$out/metadata/workloads/$version"
                  touch "$out/metadata/workloads/$version/userlocal"
                done
              '';
              });
        androidComposition = (pkgs.androidenv.composeAndroidPackages {
          includeNDK = true;
          includeEmulator = true;
          platformVersions = [ "30" "31" "32" "33" "34" ];
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        });
        jdk = pkgs.openjdk17;
        deps = [
          dotnet
        ];
      in
        {
          devShells = {
            default = pkgs.mkShell {
              nativeBuildInputs = with pkgs; [
                # aot
                nix-ld
              ] ++ deps;

              NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath ([
                # aot
                stdenv.cc.cc
              ] ++ deps);
              LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath ([
                # aot
                stdenv.cc.cc
                # libskiasharp
                fontconfig
                xorg.libX11
                xorg.libICE
                xorg.libSM
              ] ++ deps);
              NIX_LD = "${pkgs.stdenv.cc.libc_bin}/bin/ld.so";
              ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
              ANDROID_NDK_HOME = "${androidComposition.ndk-bundle}/libexec/android-sdk/ndk/${builtins.head (pkgs.lib.lists.reverseList (builtins.split "-" "${androidComposition.ndk-bundle}"))}";
              JAVA_HOME = "${jdk}";
            };
          };
        });
}
