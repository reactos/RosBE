#!/usr/bin/env bash

if [ "$(which play)" ]; then
    # attempt to play a sound if sox is installed, otherwise fail...
    play -d -q $1 2> /dev/null
fi
