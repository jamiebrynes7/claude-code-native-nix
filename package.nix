{ lib, stdenv, fetchurl, autoPatchelfHook, makeWrapper, stdenv_glibc ? stdenv }:

let
  # Read version and hashes from version.json
  versionData = builtins.fromJSON (builtins.readFile ./version.json);
  version = versionData.version;
  hashes = versionData.hashes;

  # Map Nix system to Claude platform identifiers
  platformMap = {
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
    "x86_64-darwin" = "darwin-x64";
    "aarch64-darwin" = "darwin-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or (throw
    "Unsupported system: ${stdenv.hostPlatform.system}");
  hash = hashes.${platform} or (throw "No hash for platform: ${platform}");

  gcsBase =
    "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  src = fetchurl {
    url = "${gcsBase}/${version}/${platform}/claude";
    sha256 = hash;
  };

in stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  inherit src;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec $out/bin

    # Install the actual binary to libexec
    cp $src $out/libexec/claude
    chmod +x $out/libexec/claude

    # Create wrapper script that sets environment variables
    makeWrapper $out/libexec/claude $out/bin/claude \
      --set CLAUDE_EXECUTABLE_PATH '$HOME/.local/bin/claude' \
      --set DISABLE_AUTOUPDATER 1

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code - AI-powered command line interface";
    homepage = "https://code.claude.com";
    license = licenses.unfree;
    maintainers = [ ];
    platforms =
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "claude";
  };
}
