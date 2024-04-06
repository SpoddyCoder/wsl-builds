# `resource-ai`
Install AI Projects & Tools.

* Build Options;
  * `sg3`
    * Clone stylegan3 & stylegan3-fun and initialise the `stylegan3` conda environment 
    * Setup pkl & pytorch cache on host: `STYLEGAN3_PKL_CACHE` & `STYLEGAN3_PYTORCH_CACHE` in `wsl-builds.conf`
    * This can save time re-donwloading pkls you may use between builds
  * `lsd`
    * Clone nerdy rodent's lucid-sonic-dreams fork (most recently maintained, python 3.9 compat) and initialise the `lucid-sonic-dreams` conda environment
    * Fix the deps to make it run for our build
  * `spleeter`
    * Clone Deezer spleeter repo and initialise the `spleeter` conda environment
  * `rudalle`
    * Clone ru-dalle repo and initialise the `spleeter` conda environment
* Build Arguments
  * No additional arguments for this build
* Requires
  * `./build biscuit-ai conda,cuda124`


## StyleGan3
* https://github.com/NVlabs/stylegan3
* https://github.com/PDillis/stylegan3-fun
* Original repo is not maintained
  * Copy the environments.yml from the maintained repo into the original
  * https://github.com/PDillis/stylegan3-fun/blob/main/environment.yml

### Tests
```
conda activate stylegan3
python gen_video.py --output ../ai-music-viz/expt-renders/lerp.mp4 --trunc=1 --seeds=0-31 --grid=1x1 --network=https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan3/versions/1/files/stylegan3-r-afhqv2-512x512.pkl
```


## Lucid Sonic Dreams
* Original: https://github.com/mikael-alafriz-deel/lucid-sonic-dreams
  * Respected fork: https://github.com/NotNANtoN/lucid-sonic-dreams
  * Parameter Notebook: https://colab.research.google.com/drive/1Y5i50xSFIuN3V4Md8TB30_GOAtts7RQD?usp=sharing
* Nerdy Rodent
  * https://github.com/nerdyrodent/lucid-sonic-dreams
  * https://www.youtube.com/watch?v=tdhiTL2NWSo
* Useful description of how LSD works: https://towardsdatascience.com/introducing-lucid-sonic-dreams-sync-gan-art-to-music-with-a-few-lines-of-python-code-b04f88722de1
* See also: https://github.com/SpoddyCoder/visualizing-music


## Spleeter
* https://github.com/deezer/spleeter
* See also: https://github.com/SpoddyCoder/visualizing-music
