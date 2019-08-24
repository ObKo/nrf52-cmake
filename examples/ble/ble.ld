/* Linker script to configure memory regions. */

SEARCH_DIR(.)
GROUP(-lgcc -lc -lnosys)

MEMORY
{
  /*SOFTDEVICE (rx) : ORIGIN = 0x00000, LENGTH = 0x26000*/
  FLASH (rx) : ORIGIN = 0x26000, LENGTH = 0x5a000
  RAM (rwx) :  ORIGIN = 0x20002210, LENGTH = 0xddf0
}

SECTIONS
{
}

SECTIONS
{
  . = ALIGN(4);
  .mem_section_dummy_ram :
  {
  }

} INSERT AFTER .data;

SECTIONS
{
  .mem_section_dummy_rom :
  {
  }

} INSERT AFTER .text


SECTIONS
{
  .softdevice :
  {
    KEEP(*(.sd.*))
  } > SOFTDEVICE
}

INCLUDE "nrf_common.ld"
