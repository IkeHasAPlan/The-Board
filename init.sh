#!/usr/bin/env bash
set -e

echo " Installing root dependencies"
npm install

echo " Initializing DB"
if [ "$1" == "y" ]; then
    # TODO: add this as a optional startup parameter
    echo " TODO"
fi

echo " Installing client dependencies"
cd client || exit
npm install
cd ..

echo " Starting both API and React client"
#npm run dev
