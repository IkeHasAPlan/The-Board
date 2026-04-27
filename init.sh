#!/usr/bin/env bash
set -e

echo " Installing dependencies"
npm install
cd client/board-frontend || exit
npm install

echo " Building client"
npm run build
cd ../..

if [ "$1" == "y" ]; then
    # TODO: add this as a optional startup parameter
    echo " Initializing DB"
    echo " TODO"
fi

echo " Starting"
npm start
