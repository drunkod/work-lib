{
  description = "Kiro, Chromium, VSCode, and Antigravity wrappers for OAuth flow";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3de8f8d73e35724bf9abef41f1bdbedda1e14a31";
    nixpkgs-kiro.url = "github:NixOS/nixpkgs/nixos-unstable";
    antigravity = {
      url = "path:../antigravity";  # or "github:user/antigravity-flake" if published
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-kiro, antigravity }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-kiro = import nixpkgs-kiro {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {
        
        # Package 1: Chromium wrapper with custom xdg-open
        chromium-wrapped = pkgs.stdenv.mkDerivation {
          pname = "chromium-wrapped";
          version = pkgs.chromium.version;

          dontUnpack = true;
          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin

            # Create custom xdg-open for chromium
            cat > $out/bin/xdg-open <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: xdg-open <url>" >&2
  exit 1
fi

if [[ "$1" == kiro://* ]]; then
  echo "[chromium xdg-open] Opening Kiro link: $1" >&2
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
  exec ${pkgs-kiro.kiro}/bin/kiro --disable-gpu --no-sandbox --open-url "$1"
else
  echo "[chromium xdg-open] Falling back to default handler: $1" >&2
  exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
fi
EOF
            chmod +x $out/bin/xdg-open

            # Wrap Chromium
            makeWrapper ${pkgs.chromium}/bin/chromium $out/bin/chromium \
              --prefix PATH : "$out/bin" \
              --set BROWSER "$out/bin/xdg-open" \
              --unset XDG_CURRENT_DESKTOP \
              --unset DESKTOP_SESSION \
              --unset GIO_LAUNCHED_DESKTOP_FILE_PID \
              --add-flags "--new-window --no-sandbox"
          '';

          meta = {
            description = "Chromium with custom xdg-open for Kiro links";
            mainProgram = "chromium";
          };
        };

        # Package 2: Kiro wrapper with custom xdg-open
        kiro-wrapped = pkgs.stdenv.mkDerivation {
          pname = "kiro-wrapped";
          version = pkgs-kiro.kiro.version or "unknown";

          dontUnpack = true;
          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin

            # Create custom xdg-open for kiro
            cat > $out/bin/xdg-open <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY

echo "[kiro xdg-open] Opening browser: $1" >&2
exec ${self.packages.${system}.chromium-wrapped}/bin/chromium "$@"
EOF
            chmod +x $out/bin/xdg-open

            # Wrap Kiro
            makeWrapper ${pkgs-kiro.kiro}/bin/kiro $out/bin/kiro \
              --prefix PATH : "$out/bin:${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.gnupg}/bin" \
              --set BROWSER "$out/bin/xdg-open" \
              --unset XDG_CURRENT_DESKTOP \
              --unset DESKTOP_SESSION \
              --unset GIO_LAUNCHED_DESKTOP_FILE_PID \
              --add-flags "--disable-gpu --no-sandbox"
          '';

          meta = {
            description = "Kiro with custom browser launcher";
            mainProgram = "kiro";
          };
        };

        # Package 3: VSCode wrapper with custom xdg-open
        vscode-wrapped = pkgs.stdenv.mkDerivation {
          pname = "vscode-wrapped";
          version = pkgs.vscode.version;

          dontUnpack = true;
          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin

            # Create custom xdg-open for vscode
            cat > $out/bin/xdg-open <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY

echo "[vscode xdg-open] Opening browser: $1" >&2
exec ${self.packages.${system}.chromium-wrapped}/bin/chromium "$@"
EOF
            chmod +x $out/bin/xdg-open

            # Wrap VSCode with git and other dev tools in PATH
            makeWrapper ${pkgs.vscode}/bin/code $out/bin/code \
              --prefix PATH : "$out/bin:${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.gnupg}/bin" \
              --set BROWSER "$out/bin/xdg-open" \
              --unset XDG_CURRENT_DESKTOP \
              --unset DESKTOP_SESSION \
              --unset GIO_LAUNCHED_DESKTOP_FILE_PID \
              --add-flags "--disable-gpu --no-sandbox"
          '';

          meta = {
            description = "VSCode with chromium as default browser and git support";
            mainProgram = "code";
          };
        };

        # Package 4: Antigravity wrapper with custom xdg-open
        antigravity-wrapped = pkgs.stdenv.mkDerivation {
          pname = "antigravity-wrapped";
          version = antigravity.packages.${system}.default.version or "unknown";

          dontUnpack = true;
          dontBuild = true;

          nativeBuildInputs = [ pkgs.makeWrapper ];

          installPhase = ''
            mkdir -p $out/bin

            # Create custom xdg-open for antigravity
            cat > $out/bin/xdg-open <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY

echo "[antigravity xdg-open] Opening browser: $1" >&2
exec ${self.packages.${system}.chromium-wrapped}/bin/chromium "$@"
EOF
            chmod +x $out/bin/xdg-open

            # Wrap Antigravity
            makeWrapper ${antigravity.packages.${system}.default}/bin/antigravity $out/bin/antigravity \
              --prefix PATH : "$out/bin:${pkgs.git}/bin:${pkgs.openssh}/bin:${pkgs.gnupg}/bin" \
              --set BROWSER "$out/bin/xdg-open" \
              --unset XDG_CURRENT_DESKTOP \
              --unset DESKTOP_SESSION \
              --unset GIO_LAUNCHED_DESKTOP_FILE_PID \
              --add-flags "--disable-gpu --no-sandbox"
          '';

          meta = {
            description = "Antigravity with custom OAuth-aware browser launcher";
            mainProgram = "antigravity";
          };
        };

        # Default package
        default = self.packages.${system}.kiro-wrapped;
      };

      # Apps
      apps.${system} = {
        kiro = {
          type = "app";
          program = "${self.packages.${system}.kiro-wrapped}/bin/kiro";
        };
        
        chromium = {
          type = "app";
          program = "${self.packages.${system}.chromium-wrapped}/bin/chromium";
        };

        vscode = {
          type = "app";
          program = "${self.packages.${system}.vscode-wrapped}/bin/code";
        };

        antigravity = {
          type = "app";
          program = "${self.packages.${system}.antigravity-wrapped}/bin/antigravity";
        };
        
        default = self.apps.${system}.kiro;
      };
    };
}