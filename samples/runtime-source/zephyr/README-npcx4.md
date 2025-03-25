# Runtime chosen image sample application, on npcx4m8f_evb

This sample demonstrates how to choose an arbitrary image to boot at runtime.
It was tested on a npcx4m8f_evb. The image to be booted is selected based on a
button press, although, by default, it will boot the image on first slot,
wait five seconds and reboot into the image on the second slot.

## Build

First, ensure ZEPHYR_SDK_INSTALL_DIR is defined. From the sample directory, run:

```
  source <path-to-zephyr>/zephyr-env.sh

```

Make sure the board is properly [connected to host computer](https://docs.zephyrproject.org/latest/boards/nuvoton/npcx4m8f_evb/doc/index.html).
A conveniece script is provided to build and flash all the images. Just run:

```
  ./build-npcx.sh
```

Optionally, you can only build it by using `build` as argument, or only flash it
by using `flash` as argument.

## Run
Open a serial terminal to see the output and reset the board. It shall boot the
image on the first slot by default. By keeping the SW1 button pressed during reset, the
bootloader will boot the one on the second slot.

Note that the application on the first slot will reboot into the one on the second
slot after five seconds.

## How does it work

Three applications are built: the mcuboot one, with hooks to choose the image to boot,
and two zephyr applications, one for each slot (they are actually the same code
with some defines to change the name of the image).

They are then flashed into the board. The board flash layout is as follows:

```
  +------------------+  0x64000000
  |                  |
  |   mcuboot        |
  |                  |
  +------------------+  0x64020000
  |                  |
  |   zephyr app A   |
  |                  |
  +------------------+  0x64040000
  |                  |
  |   zephyr app B   |
  |                  |
  +------------------+
```

During boot, the board internal bootloader will load the mcuboot image to the
RAM and jump to it. The mcuboot image will then check the button state and
choose the image to boot. It will then load the selected image to RAM and jump
to it. The code RAM layout ends up as follows (with final TAG area):

```
  +------------------+  0x10060000
  |                  |
  |   mcuboot        |
  |                  |
  +------------------+  0x10070000
  |                  |
  |   zephyr app     |
  |                  |
  |                  |
  |                  |
  |                  |
  |                  |
  |                  |
  +------------------+  0x100BFC00
  |                  |
  |   tag            |
  |                  |
  +------------------+
```

(The tag area is used by app A to tell mcuboot to boot app B.)

Check the code, devicetree and Kconfig files for more details on how it was done.
