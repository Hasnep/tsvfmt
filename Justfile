default: fmt test build

fmt:
    zig fmt **/*.zig
    nixfmt flake.nix

test:
    zig build test

build:
    zig build
