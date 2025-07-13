# `ai-resources`
Install AI Projects & Tools. Creates an `~/ai-resources` directory containing project repos / files etc.

## Requires
* `./build ai-basics conda,cuda124`

## Build Components
### `sg3`
* Clone stylegan3 & stylegan3-fun and initialise the `stylegan3` conda environment 
* Setup pkl & pytorch cache on host (see below)
  * This can save time re-donwloading pkls you may use between builds
* You can optionally add these to your `wsl-builds.conf` and they will be used during installations...
```
STYLEGAN3_PKL_CACHE=/mnt/c/cached-pkls/stylegan3            # cache pkls on Windows host
STYLEGAN3_PYTORCH_CACHE=/mnt/c/cached-pytorch/stylegan3     # cache pytorch extensions on Windows host
```
* Test everything installed OK...
```
conda activate stylegan3
python gen_video.py --output ../ai-music-viz/expt-renders/lerp.mp4 --trunc=1 --seeds=0-31 --grid=1x1 --network=https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan3/versions/1/files/stylegan3-r-afhqv2-512x512.pkl
```

#### Extra Info
* https://github.com/NVlabs/stylegan3
* https://github.com/PDillis/stylegan3-fun
* Original repo is not maintained
  * Copy the environments.yml from the maintained repo into the original
  * https://github.com/PDillis/stylegan3-fun/blob/main/environment.yml

### `lsd`
* Clone nerdy rodent's lucid-sonic-dreams fork (most recently maintained, python 3.9 compat) and initialise the `lucid-sonic-dreams` conda environment
* Fix the deps to make it run for our build

#### Extra Info
* Original: https://github.com/mikael-alafriz-deel/lucid-sonic-dreams
  * Respected fork: https://github.com/NotNANtoN/lucid-sonic-dreams
  * Parameter Notebook: https://colab.research.google.com/drive/1Y5i50xSFIuN3V4Md8TB30_GOAtts7RQD?usp=sharing
* Nerdy Rodent
  * https://github.com/nerdyrodent/lucid-sonic-dreams
  * https://www.youtube.com/watch?v=tdhiTL2NWSo
* Useful description of how LSD works: https://towardsdatascience.com/introducing-lucid-sonic-dreams-sync-gan-art-to-music-with-a-few-lines-of-python-code-b04f88722de1
* See also: https://github.com/SpoddyCoder/visualizing-music

### `spleeter`
* Clone Deezer spleeter repo and initialise the `spleeter` conda environment

#### Extra Info
* https://github.com/deezer/spleeter
* See also: https://github.com/SpoddyCoder/visualizing-music

### `rudalle`
* Clone ru-dalle repo and initialise the `ru-dalle` conda environment
* https://github.com/ai-forever/ru-dalle

## Build Arguments
* No additional arguments for this build
