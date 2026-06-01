#!/usr/bin/env bash

printInfo "Installing ffmpeg"

aptUpdateIfStale
sudo apt install -y ffmpeg

printInfo "ffmpeg version: $(ffmpeg -version 2>&1 | head -n1)"

printInfo "ffmpeg installed"
