{
  description = "Antigravity with Git support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3de8f8d73e35724bf9abef41f1bdbedda1e14a31";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation rec {
        pname = "antigravity";
        version = "1.11.5";

        src = pkgs.fetchurl {
          url = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/1.11.5-5234145629700096/linux-x64/Antigravity.tar.gz";
          sha256 = "sha256-TgMVGlV0PPMPrFlauzQ8nrWjtqgNJUATbXW06tgHIRI=";
        };

        nativeBuildInputs = with pkgs; [
          autoPatchelfHook
          wrapGAppsHook3
          makeWrapper
        ];

        buildInputs = with pkgs; [
          stdenv.cc.cc.lib
          alsa-lib atk cairo cups dbus expat fontconfig freetype
          gdk-pixbuf glib gtk3 libdrm libnotify libpulseaudio
          libuuid libxkbcommon xorg.libxkbfile mesa nspr nss pango
          systemd xorg.libX11 xorg.libXScrnSaver xorg.libXcomposite
          xorg.libXcursor xorg.libXdamage xorg.libXext xorg.libXfixes
          xorg.libXi xorg.libXrandr xorg.libXrender xorg.libXtst
          xorg.libxcb xorg.libxshmfence
        ];

        sourceRoot = "Antigravity";
        dontBuild = true;
        dontConfigure = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/antigravity
          cp -r . $out/lib/antigravity/
          chmod +x $out/lib/antigravity/antigravity

          mkdir -p $out/bin

          # Chrome wrapper
          cat > $out/bin/google-chrome <<'EOF'
#!/usr/bin/env bash
exec ${pkgs.chromium}/bin/chromium --no-sandbox "$@"
EOF
          chmod +x $out/bin/google-chrome

          # Chrome symlinks
          for name in google-chrome-stable chromium chromium-browser chrome; do
            ln -sf google-chrome $out/bin/$name
          done

          # Git symlink (fix "Git installation not found")
          ln -sf ${pkgs.git}/bin/git $out/bin/git

          # Main wrapper
				makeWrapper $out/lib/antigravity/antigravity $out/bin/antigravity \
				  --prefix PATH : "$out/bin:${pkgs.git}/bin" \
				  --set-default CHROME_PATH "$out/bin/google-chrome" \
				  --set-default CHROME_EXECUTABLE "$out/bin/google-chrome" \
				  --set-default CHROME_BIN "$out/bin/google-chrome" \
				  --set-default BROWSER "$out/bin/google-chrome" \
				  --unset XDG_CURRENT_DESKTOP \
				  --unset DESKTOP_SESSION \
				  --unset GIO_LAUNCHED_DESKTOP_FILE_PID \
				  --add-flags "--disable-gpu --no-sandbox"

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Antigravity with Git and Chrome";
          mainProgram = "antigravity";
        };
      };
    };
}