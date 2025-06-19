{ lib, stdenv, squashfsTools, contents ? {} }:

let
  packFile = path: content:
    ''
      TMP_FILE=$TMP_DIR/${lib.escapeShellArg path}
      mkdir -p "$(dirname "$TMP_FILE")"
    '' +
    (
      if builtins.hasAttr "text" content then ''
        TEXT=${lib.escapeShellArg content.text}
        echo -n "$TEXT" > "$TMP_FILE"
      '' else ''
        cp -r '${content.source}' "$TMP_FILE"
      ''
    )
  ;
in stdenv.mkDerivation {
  name = "fake-vault";
  nativeBuildInputs = [ squashfsTools ];
  buildCommand = ''
    TMP_DIR=$(mktemp -d)
    TMP_FS=$(mktemp -u --suffix .squashfs)
  ''
  + lib.concatStringsSep "\n"
    (lib.mapAttrsToList packFile contents)
  + ''
    mksquashfs \
      $TMP_DIR/* $TMP_DIR/.* $TMP_FS \
      -keep-as-directory -no-recovery -comp lz4 -Xhc
    base64 -w78 < "$TMP_FS" > $out
    rm -rf $TMP_DIR $TMP_FS
  '';
}
