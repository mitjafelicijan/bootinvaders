AS = fasm
QEMU = qemu-system-i386
SRC = invaders.asm
BIN = invaders.bin

all: $(BIN)

$(BIN): $(SRC)
	$(AS) $(SRC) $(BIN)

run: $(BIN)
	$(QEMU) -drive format=raw,file=$(BIN)

clean:
	rm -f $(BIN)

.PHONY: all run clean
