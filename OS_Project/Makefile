# DEBUG: Reading the NEW, FIXED Makefile version!

ASM = nasm
BUILD_DIR := build

# Define required file names using hardcoded paths for safety
BOOTLOADER_BIN = $(BUILD_DIR)/bootloader.bin
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
IMG = $(BUILD_DIR)/main.img

# --- 1. Top-Level Targets ---

# Rule to ensure the build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

all: $(IMG)

# --- 2. Final Floppy Image Rule ---

# The final image depends on the built bootloader and kernel
$(IMG): $(BOOTLOADER_BIN) $(KERNEL_BIN) | $(BUILD_DIR)
	@echo "Creating FAT12 floppy image..."
	# 1. Create a raw 1.44MB disk image, filling it with zeros and defining the count
	dd if=/dev/zero of=$@ bs=512 count=2880
	# 2. Format the image as FAT12
	mkfs.fat -F 12 -n "PAXOS" $@
	# 3. Write the bootloader to the first sector (conv=notrunc preserves the FAT filesystem)
	dd if=$(BOOTLOADER_BIN) of=$@ conv=notrunc
	# 4. Copy the kernel onto the formatted filesystem
	mcopy -i $@ $(KERNEL_BIN) "::KERNEL.BIN"

# --- 3. Component Build Rules (Hardcoded Paths) ---

# Build the Bootloader
$(BOOTLOADER_BIN): src/bootloader/boot.asm | $(BUILD_DIR)
	@echo "Assembling Bootloader: src/bootloader/boot.asm"
	$(ASM) $< -f bin -o $@

# Build the Kernel
$(KERNEL_BIN): src/kernel/main.asm | $(BUILD_DIR)
	@echo "Assembling Kernel: src/kernel/main.asm"
	$(ASM) $< -f bin -o $@

# --- 4. Utility Targets ---

.PHONY: run
run: $(IMG)
# 	@echo "Starting QEMU..."
# 	qemu-system-i386 -fda $(IMG) -nographic

.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(BOOTLOADER_BIN) $(KERNEL_BIN) $(IMG)
	-rmdir $(BUILD_DIR) 2> /dev/null || true