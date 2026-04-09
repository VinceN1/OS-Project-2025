$(info DEBUG: Reading the NEW, FIXED Makefile version!)
ASM = nasm
# Define directories for clarity, but use hardcoded path in rules if variables fail
SRC_DIR := src
BUILD_DIR := build

BIN = $(BUILD_DIR)/main.bin
IMG = $(BUILD_DIR)/main.img

# Rule to ensure the build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

all: $(IMG)

# Assemble main.asm into the binary. 
# We hardcode 'src/main.asm' here because the variable $(SRC_DIR) is failing to expand correctly.
$(BIN): src/main.asm | $(BUILD_DIR)
	@echo "Assembling src/main.asm..."
	$(ASM) $< -f bin -o $@

# Create floppy image
$(IMG): $(BIN)
	@echo "Creating floppy image..."
	cp $< $@
	truncate -s 1440k $@

#
#Floppy Image
#

floopy_image: $(BUILD_DIR)/main.img
$(BUILD_DIR)/main.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512
	count=2880
	mkfs.fat -F 12 -n "PAXOS" $(BUILD_DIR)/main.img
	dd if=$(BUILD_DIR)/bootloader.bin of =$(BUILD_DIR)/
	main.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main.img $(BUILD_DIR)/
	kernel.bin "::kernel.bin"
#
#Bootloader
#
bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin:
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $
	(BUILD_DIR)/bootloader.bin

#
#Kernal
#
kernel: $(BUILD_DIR)/kernel.bin
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $
	(BUILD_DIR)/kernel.bin


# Run in QEMU
.PHONY: run
run: $(IMG)
# 	qemu-system-i386 -fda $(IMG)

# Clean only the files this Makefile creates
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(BIN) $(IMG)
	# Safely remove the build directory if it's empty
	-rmdir $(BUILD_DIR) 2> /dev/null || true