# Mariner build process
Experimental / Spike on getting CBL-Mariner (ARM64) to run on X86 hardware via QEMU

# Generate ARM64 stuff
1. Clone this repo on ARM64 hardware
1. Run `bash build-mariner-arm64.sh`

# Untested stuff below...

# Run ARM on x64
1. Clone this repo
1. Upload the **mariner-arm64.tar.gz** from ARM64 Build to **CBL-Mariner-Run**
1. Run `bash boot-mariner-arm64-via-emulator.sh`
    **Note:** Once the emulator starts it may take a long time on the 'Booting CBL-Mariner' screen.  This is normal and may take 20 mins to boot the first time.
