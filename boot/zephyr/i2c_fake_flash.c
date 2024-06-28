#include <flash_map_backend/flash_map_backend.h>

#include <zephyr/drivers/i2c.h>

#define I2C_ADDR	0x20

static const struct device *const i2c_bus = DEVICE_DT_GET(DT_ALIAS(i2c0));
static const struct flash_area area;

static uint8_t data[64];
static uint8_t write_data[16];

static int aardvark_read(const struct device *dev, uint8_t *buf, size_t buf_len, uint32_t addr, uint8_t len)
{
	int ret;

	if (len > 64 || buf_len < len) {
		return -EINVAL;
	}

	write_data[0] = 0x02;
	write_data[1] = (addr >> 24) & 0xFF;
	write_data[2] = (addr >> 16) & 0xFF;
	write_data[3] = (addr >> 8) & 0xFF;
	write_data[4] = addr & 0xFF;

	write_data[5] = len;

	i2c_write(i2c_bus, &write_data, 6, I2C_ADDR);

	k_busy_wait(USEC_PER_MSEC);
	ret = i2c_read(i2c_bus, data, len, I2C_ADDR);

	/* On esp32s3, I can't just i2c_read directly into buf if it's
	 * in IRAM, as IRAM access needs 4-byte alignment. Hence, the memcpy
	 * below. */
	memcpy(buf, data, len);

	return 0;
}

static void aardvark_get_size(const struct device *dev, uint32_t *size)
{
	write_data[0] = 0x01;
	i2c_write(i2c_bus, &write_data, 1, I2C_ADDR);
	k_busy_wait(USEC_PER_MSEC);
	i2c_read(i2c_bus, &data, 4, I2C_ADDR);
	*size = data[0] << 24 | data[1] << 16 | data[2] << 8 | data[3];

	return 0;
}

int flash_area_read(const struct flash_area *fa, off_t off, void *dst_v, size_t len)
{
	size_t to_read;
	uint8_t *dst = dst_v;

	if (off < 0 || (off + len > fa->fa_size)) {
		return -EINVAL;
	}

	while (len > 0) {
		to_read = MIN(len, 64);
		aardvark_read(i2c_bus, dst, len, off, to_read);
		off += to_read;
		len -= to_read;
		dst += to_read;
	}

	return 0;
}

void flash_area_close(const struct flash_area *fa)
{
}

int flash_area_open(uint8_t id, const struct flash_area **fa)
{
	if (!device_is_ready(i2c_bus))
		return -ENODEV;

	aardvark_get_size(i2c_bus, &area.fa_size);

	*fa = &area;

	return 0;
}

uint32_t flash_area_align(const struct flash_area *fa)
{
    return 1;
}
