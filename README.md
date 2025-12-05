# Claude Code Nix Flake

A Nix flake for [Claude Code](https://code.claude.com) using the official statically compiled binaries.

## Features

- Uses official statically compiled binaries from Anthropic
- Provides a Nix overlay for easy integration into NixOS/Home Manager
- Update script to easily bump to the latest version

## Usage

### Direct Installation

Run Claude Code directly with:

```bash
nix run github:jamiebrynes/claude-code-native-nix
```

### Using the Overlay

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-code.url = "github:jamiebrynes/claude-code-native-nix";
  };

  outputs = { self, nixpkgs, claude-code }: {
    # Example NixOS configuration
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [ claude-code.overlays.default ];
          environment.systemPackages = [ pkgs.claude-code ];
        }
      ];
    };
  };
}
```

### Home Manager

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    claude-code.url = "github:jamiebrynes/claude-code-native-nix";
  };

  outputs = { self, nixpkgs, home-manager, claude-code }: {
    homeConfigurations.your-username = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ claude-code.overlays.default ];
      };

      modules = [
        {
          home.packages = [ pkgs.claude-code ];
        }
      ];
    };
  };
}
```

## Updating

To update to the latest version of Claude Code:

```bash
./scripts/update-version.sh
```

This script will:

1. Fetch the latest stable version from Google Cloud Storage
2. Download the manifest with checksums for all platforms
3. Convert checksums to Nix SRI format
4. Update `version.json` with the new version and hashes

After running the update script, test the build:

```bash
nix flake check
nix build
```

## Supported Platforms

- `x86_64-linux` (Linux x64)
- `aarch64-linux` (Linux ARM64)
- `x86_64-darwin` (macOS Intel)
- `aarch64-darwin` (macOS Apple Silicon)

## Environment Variables

The wrapper sets the following environment variables:

- `CLAUDE_EXECUTABLE_PATH`: Set to `$HOME/.local/bin/claude` for consistent executable path
- `DISABLE_AUTOUPDATER`: Set to `1` to disable automatic updates

## Credits

Inspired by and based on the work from [sadjow/claude-code-nix](https://github.com/sadjow/claude-code-nix).

## License

Claude Code is proprietary software. This flake merely packages the official binaries.
