#!/bin/bash
# This is deploy.sh

export MIX_ENV=prod
export PORT=4801
export SECRET_KEY_BASE=insecure

mix deps.get --only prod
mix compile

CFGD=$(readlink -f ~/.config/bulls)

if [ ! -d "$CFGD" ]; then
    mkdir -p $CFGD
fi

if [ ! -e "$CFGD/base" ]; then
    mix phx.gen.secret > "$CFGD/base"
fi

SECRET_KEY_BASE=$(cat "$CFGD/base")
export SECRET_KEY_BASE

npm install --prefix ./assets
npm run deploy --prefix ./assets
mix phx.digest

mix release

echo "Starting app..."

PROD=t ./start.sh