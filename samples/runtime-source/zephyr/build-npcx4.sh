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
    local extra_cfg="-DAPP_A=1"

    if [ "$1" == "app_b" ]; then
        extra_cfg="-DAPP_B=1"
    fi

    pushd app

    west build -p -b npcx4m8f_evb . -- \
        -DEXTRA_DTC_OVERLAY_FILE="../boards/npcx4m8f_evb.overlay;boards/npcx4m8f_evb.overlay" \
        -DEXTRA_CFLAGS="$extra_cfg"

    rm -rf build_$1
    mv build "build_$1"

    popd
}

function flash_app {
    local image_file="app/build_$1/zephyr/zephyr.signed.bin"
    local image_address="0x64020000"

    if [ "$1" == "app_b" ]; then
        image_address="0x64040000"
    fi

    openocd -s $ZEPHYR_BASE/boards/nuvoton/npcx4m8f_evb/support -f app/boards/support/openocd.cfg \
        "-c init" "-c targets" -c "reset init" -c "npcx_write_image $image_file $image_address" \
        -c "npcx_verify_image $image_file $image_address" -c "reset run" -c shutdown
}

if [ "$1" == "build" -o -z "$1" ]; then
    west build -p -b npcx4m8f_evb ../../../boot/zephyr/ -- -DEXTRA_ZEPHYR_MODULES=$PWD/hooks \
        -DEXTRA_CONF_FILE="$PWD/sample.conf;$PWD/boards/npcx4m8f_evb.conf" \
        -DEXTRA_DTC_OVERLAY_FILE=$PWD/boards/npcx4m8f_evb.overlay

    build_app app_a
    build_app app_b
fi

if [ "$1" == "flash" -o -z "$1" ]; then
    flash_app app_a
    sleep 1
    flash_app app_b
    sleep 1

    openocd -s $ZEPHYR_BASE/boards/nuvoton/npcx4m8f_evb/support \
        -f $ZEPHYR_BASE/boards/nuvoton/npcx4m8f_evb/support/openocd.cfg '-c init' '-c targets' \
        -c 'reset init' -c 'npcx_write_image build/zephyr/zephyr.npcx.hex' -c 'reset run' \
        -c shutdown
fi
