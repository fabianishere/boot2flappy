cmake_minimum_required(VERSION 2.6)

# Cross compiling options
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_CROSSCOMPILING 1)
set(TOOLCHAIN_PREFIX x86_64-w64-mingw32)
set(ARCH x86_64)

# Find the cross compilers
set(CMAKE_RC_COMPILER ${TOOLCHAIN_PREFIX}-windres)
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}-gcc)

# Set root path
set(CMAKE_FIND_ROOT_PATH  /usr/${TOOLCHAIN_PREFIX})

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

project(flappy C ASM)

# Set output
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

# Set paths for dependencies
set(EFI_PATH ${CMAKE_SOURCE_DIR}/deps/gnu-efi)
set(EFI_INC ${EFI_PATH}/inc ${EFI_PATH}/inc/x86_64 ${EFI_PATH}/inc/protocol ${EFI_PATH}/lib)
set(EFI_OBJS ${EFI_PATH}/gnuefi/crt0-efi-${ARCH}.o)
set(EFI_LDS ${EFI_PATH}/gnuefi/elf_${ARCH}_efi.lds)
set(EFI_SOURCES ${EFI_PATH}/lib/init.c ${EFI_PATH}/lib/data.c ${EFI_PATH}/lib/str.c ${EFI_PATH}/lib/sread.c ${EFI_PATH}/lib/print.c ${EFI_PATH}/lib/misc.c ${EFI_PATH}/lib/error.c ${EFI_PATH}/lib/hand.c ${EFI_PATH}/lib/x86_64/math.c ${EFI_PATH}/lib/x86_64/initplat.c ${EFI_PATH}/lib/guid.c ${EFI_PATH}/lib/runtime/efirtlib.c  ${EFI_PATH}/lib/console.c  ${EFI_PATH}/lib/event.c  ${EFI_PATH}/lib/runtime/rtdata.c ${EFI_PATH}/lib/runtime/rtstr.c ${EFI_PATH}/lib/runtime/efirtlib.c ${EFI_PATH}/lib/dpath.c)

# Compiler definitions
set(CMAKE_C_FLAGS "-DGNU_EFI_USE_MS_ABI -m64 -ffreestanding -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -O3")
set(CMAKE_EXE_LINKER_FLAGS "-nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main -lgcc -Wl,-Bsymbolic")

# Include headers
include_directories(include/ ${EFI_INC})

add_library(gnu-efi ${EFI_SOURCES})
add_library(efi-x86_64 src/efi-x86_64/core.s src/efi-x86_64/console.s src/efi-x86_64/graphics.s src/efi-x86_64/image.s src/efi-x86_64/fs.s src/efi-x86_64/event.s)
target_link_libraries(efi-x86_64 gnu-efi)
add_executable(game src/game/main.s src/game/sprites.s)
target_link_libraries(game efi-x86_64)
add_custom_command(TARGET game
	POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_BINARY_DIR}/vm
	COMMAND ${CMAKE_COMMAND} -E make_directory ${PROJECT_BINARY_DIR}/vm/hda-contents   
	COMMAND ${CMAKE_COMMAND} -E copy ${PROJECT_BINARY_DIR}/bin/game.exe ${PROJECT_BINARY_DIR}/vm/hda-contents/EFI/BOOT/BOOTX64.EFI
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/deps/bios/bios.bin ${PROJECT_BINARY_DIR}/vm
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/resources/sprites.bmp ${PROJECT_BINARY_DIR}/vm/hda-contents/EFI/BOOT/SPRITES.BMP
	COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/tools/qemu/start.sh ${PROJECT_BINARY_DIR}/vm
	COMMENT "Run 'vm/start.sh' to start the virtual machine."
)

add_custom_target(img DEPENDS game)
add_custom_command(TARGET img
	COMMAND dd if=/dev/zero of=${PROJECT_BINARY_DIR}/bin/game.iso bs=1M count=16
	COMMAND mkfs.vfat ${PROJECT_BINARY_DIR}/bin/game.iso -F 16 -n BOOT2FLAPPY
	COMMAND mmd -i ${PROJECT_BINARY_DIR}/bin/game.iso ::/EFI
	COMMAND mmd -i ${PROJECT_BINARY_DIR}/bin/game.iso ::/EFI/BOOT
	COMMAND mcopy -i ${PROJECT_BINARY_DIR}/bin/game.iso ${PROJECT_BINARY_DIR}/bin/game.exe ::/EFI/BOOT/BOOTX64.EFI
    COMMAND mcopy -i ${PROJECT_BINARY_DIR}/bin/game.iso ${PROJECT_SOURCE_DIR}/resources/sprites.bmp ::/EFI/BOOT/SPRITES.BMP
	COMMENT "Creating image file for EFI executable"
)

add_custom_target(qemu DEPENDS game)
add_custom_command(TARGET qemu
	COMMAND qemu-system-x86_64 -bios ${PROJECT_BINARY_DIR}/vm/bios.bin -drive format=raw,file=fat:rw:${PROJECT_BINARY_DIR}/vm/hda-contents
	COMMENT "Running EFI executable in qemu"
)

