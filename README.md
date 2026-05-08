# BootInvaders

A functional Space Invaders clone implemented entirely within a 512-byte x86
boot sector. Written in assembly (FASM) for the BIOS real mode.

> [!IMPORTANT]
> This is for educational purposes, demonstrating how to make a bootloader do
> interesting stuff.

## Technical Specifications

- **Architecture:** x86 (16-bit Real Mode)
- **Memory Address:** Loaded at `0x0000:0x7C00` by the BIOS.
- **Display:** VGA Mode 13h (320x200, 256-color linear framebuffer).
- **Video Memory:** Direct writes to segment `0xA000`.
- **I/O & Interrupts:**
    - `int 0x10`: Video services for mode setting and character output.
    - `int 0x16`: Keyboard services for polling and reading scan codes.
    - `int 0x1A`: Clock services used for frame timing and pseudo-random seed.
    - `0x3DA`: VGA Status Register polling for vertical retrace synchronization.

## Features

- **Double Buffering Simulation:** Clears and redraws every frame synchronized
  with the vertical retrace to prevent flickering.
- **Physics & Collision:** AABB (Axis-Aligned Bounding Box) collision detection
  for bullets, enemies, and player.
- **Procedural Respawn:** Uses the system timer's lower bits to calculate the
  next enemy X-coordinate.
- **Score Tracking:** Real-time score display using a custom decimal-to-string
  conversion routine.

## Building and Running

### Prerequisites
- [FASM](https://flatassembler.net/) (Flat Assembler)
- [QEMU](https://www.qemu.org/) (for emulation)

### Commands
```bash
# Compile the source to a 512-byte binary
make

# Run the binary in QEMU as a raw disk image
make run
```

## Controls
- **Left Arrow:** Move Left
- **Right Arrow:** Move Right
- **Space Bar:** Fire Bullet
- **Any Key:** Restart (on Game Over)

## Resources

- [x86 Instruction Set Reference](https://c9x.me/x86/)
- [OS Dev Wiki](https://wiki.osdev.org/Expanded_Main_Page)
- [Interrupt Jump Table (Ralf Brown's List)](https://www.ctyme.com/intr/int.htm)
