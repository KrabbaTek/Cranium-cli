#!/usr/bin/env bash


# This Bash script installs the Cranium package manager onto your machine
# It will:
# - Install Elixir (unless you already have it installed)
# - Git clone https://github.com/KrabbaTek/Cranium-cli
# - Compile the directory into BEAM bytecode
# - move the directory to ~/.local/bin

# Note: this is for the original Cranium, not Cranium Off the Grid.
# Each project has a unique install script, so if you want to install Cranium Off the Grid then you're in the wrong place.

# Written by Reece Turner

set -euo pipefail

if which cranium &> /dev/null
then
    echo "Looks like you already have Cranium installed!"
    echo "If you need help with Cranium, then run `cranium help`, or `cranium h`."
    exit 0
fi


# Install Elixir
if ! which elixir &> /dev/null
then
    echo "You don't have Elixir installed on this machine."
    echo "You'll have to install that yourself before moving on."
    echo "You can do that here: https://elixir-lang.org/install/"
    echo "Note: if you are on macOS then you can likely just run 'brew install elixir'."
    exit 0
fi

read -p "Are you sure you want to install the Cranium package manager? [Y/n] ~> " install

# Gotta love Bash 3.2
lower_install=$(echo "$install" | tr '[:upper:]' '[:lower:]')

if [[ "$lower_install" != "y" && "$lower_install" != "" ]]
then
    exit 0
fi


# end guard clauses; begin the actual installation process


REPO_URL="https://github.com/KrabbaTek/Cranium-cli"
INSTALL_DIR="$HOME/.local/bin" # remember to add this to your PATH!

# get the source code
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
git clone --depth 1 "$REPO_URL" "$WORKDIR/src"
cd "$WORKDIR/src"

# fetch dependencies and build
mix local.hex --force
mix local.rebar --force
MIX_ENV=prod mix deps.get
MIX_ENV=prod mix escript.build


mkdir -p "$INSTALL_DIR"
cp "cranium" "$INSTALL_DIR/cranium"

echo "Successfully installed Cranium — enjoy!"
echo "You can find documentation here: https://github.com/KrabbaTek/Cranium-cli/blob/main/README.md"

