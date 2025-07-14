# Contributing
Requests, advice and PR's are welcome.

## Things To Note
* Simple by design
* This is not a package manager!
* Ultimately, it is just a collection simple bash scripts to install / configure common components and useful helpers.
  * Saves looking up install instructions
  * Automates the install procedure.
  * Acts as an NB for quality of life additions

## Contributing builds / components
* The `build.sh` tool will exit on any error
  * This is by choice (simple by design)
  * But means you cannot cleanup / handle errors inside the install scripts
* Use the `getFile` helper function to get any installation files
  * This will cache the files and use `/tmp` working directory, so if a subsequent command errors they are cleanued up on restart.
  * Use the partner function `cleanupGetFiles()` to cleanup downloaded files (if desired) after running installers
* Use the `recordComponentSuccess` helper function to record successful component installations
  * This immediately records the component to `~/.wsl-build.info` and sets `BUILD_UPDATED=true`
  * This ensures that successful components are recorded even if later components fail

## FAQ
* Ubuntu only?
    * Yes. Atm this is completely geared for my needs
    * A pattern to support other distributions's will probably never come, unless...
    * I have a need for another base distribution
    * This repo gets lots of followers/stars and requests for such a feature
