#!/bin/bash

set -ex

if [ -z "$ZEPHYR_BASE" ]; then
    echo "Please set the ZEPHYR_BASE environment variable to the Zephyr base directory."
    exit 1
fi

# If argument is provided, but not "build" or "flash", exit with error
if [ "$1" != "build" ] && [ "$1" != "flash" ] && [ -n "$1" ]; then
    echo "Usage: $0 <build|flash>"
    echo ""
    echo "Builds and flashes the applications for the Nuvoton NPCX4M8F EVB."
    exit 1
fi

function build_app {
    pushd hello-world

    west build -p -b npcx4m8f_evb . -- \
        -DEXTRA_DTC_OVERLAY_FILE="../boards/npcx4m8f_evb.overlay;boards/npcx4m8f_evb.overlay" \

    popd
}

function flash_app {
    local image_file="hello-world/build/zephyr/zephyr.signed.bin"
    local image_address="0x64020000"

    openocd -s $ZEPHYR_BASE/boards/nuvoton/npcx4m8f_evb/support -f hello-world/boards/support/openocd.cfg \
        "-c init" "-c targets" -c "reset init" -c "npcx_write_image $image_file $image_address" \
        -c "npcx_verify_image $image_file $image_address" -c "reset run" -c shutdown
}

if [ "$1" == "build" -o -z "$1" ]; then
    west build -p -b npcx4m8f_evb ../../boot/zephyr/ -- \
        -DEXTRA_CONF_FILE="$PWD/boards/npcx4m8f_evb.conf" \
        -DEXTRA_DTC_OVERLAY_FILE=$PWD/boards/npcx4m8f_evb.overlay

    build_app
fi

if [ "$1" == "flash" -o -z "$1" ]; then
    flash_app
    sleep 1

    openocd -s $ZEPHYR_BASE/boards/nuvoton/npcx4m8f_evb/support \
        -f $ZEPHYR_BASE/boards/nuvoton/npcx4m8f_evb/support/openocd.cfg '-c init' '-c targets' \
        -c 'reset init' -c 'npcx_write_image build/zephyr/zephyr.npcx.hex' -c 'reset run' \
        -c shutdown
fi
