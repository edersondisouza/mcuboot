/*
 * Copyright (c) 2024 Intel Corporation
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

#ifdef APP_A
#define APP_NAME "App A"
#else
#define APP_NAME "App B"
#endif


#if DT_NODE_HAS_STATUS(DT_NODELABEL(sram_tag), okay)
#define SRAM_TAG DT_NODELABEL(sram_tag)
#endif

int main(void)
{
	printk("Hello World from %s on %s, application %s!\n",
		   MCUBOOT_HELLO_WORLD_FROM, CONFIG_BOARD,
		   APP_NAME);

#ifdef SRAM_TAG
#if defined(APP_A)
	uintptr_t sram_tag = DT_REG_ADDR(SRAM_TAG);

	/* Set the tag to 42 so that mcuboot knows it should load the B application */
	printk("Setting SRAM tag to 42\n");
	*((uint32_t *)sram_tag) = 42;

	printk("Will reset the device in 5 seconds...\n");
	k_msleep(5000);

	SCB->AIRCR = 0x5FA0004; /* reset the device */
#else
	/* Set tag back to zero. */
	printk("Setting SRAM tag to 0\n");
	*((uint32_t *)DT_REG_ADDR(SRAM_TAG)) = 0;
#endif /* defined(APP_A) */
#endif /* SRAM_TAG */

    return 0;
}
