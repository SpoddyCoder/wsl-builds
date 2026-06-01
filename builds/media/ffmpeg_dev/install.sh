#!/usr/bin/env bash

printInfo "Installing ffmpeg dev toolchain"

aptUpdateIfStale
sudo apt install -y \
    ffmpeg \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    libavfilter-dev \
    libx264-dev

printInfo "ffmpeg dev toolchain installed"
