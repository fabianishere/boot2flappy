# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
.extern InitializeLib
.extern AllocatePool
.extern FreePool

# Exports
.global efi_core_init
.global efi_core_stall
.global efi_core_alloc
.global efi_core_free

.global EFI_ERROR_MASK
.global EFI_SUCCESS
.global EFI_LOAD_ERROR
.global EFI_INVALID_PARAMETER
.global EFI_UNSUPPORTED
.global EFI_BAD_BUFFER_SIZE
.global EFI_BUFFER_TOO_SMALL
.global EFI_NOT_READY
.global EFI_DEVICE_ERROR
.global EFI_WRITE_PROTECTED
.global EFI_OUT_OF_RESOURCES
.global EFI_VOLUME_CORRUPTED
.global EFI_VOLUME_FULL
.global EFI_NO_MEDIA
.global EFI_MEDIA_CHANGED
.global EFI_NOT_FOUND
.global EFI_ACCESS_DENIED
.global EFI_NO_RESPONSE
.global EFI_NO_MAPPING
.global EFI_TIMEOUT
.global EFI_NOT_STARTED
.global EFI_ALREADY_STARTED
.global EFI_ABORTED
.global EFI_ICMP_ERROR
.global EFI_TFTP_ERROR
.global EFI_PROTOCOL_ERROR
.global EFI_INCOMPATIBLE_VERSION
.global EFI_SECURITY_VIOLATION
.global EFI_CRC_ERROR
.global EFI_END_OF_MEDIA
.global EFI_END_OF_FILE
.global EFI_INVALID_LANGUAGE
.global EFI_COMPROMISED_DATA


.global EFI_WARN_UNKOWN_GLYPH
.global EFI_WARN_DELETE_FAILURE
.global EFI_WARN_WRITE_FAILURE
.global EFI_WARN_BUFFER_TOO_SMALL

# EFI core library routines and constants..
.text

# The EFI error codes
.equiv EFI_ERROR_MASK,                  0x8000000000000000
EFI_SUCCESS:                    .quad   0
EFI_LOAD_ERROR:                 .quad   (EFI_ERROR_MASK | 1)
EFI_INVALID_PARAMETER:          .quad   (EFI_ERROR_MASK | 2)
EFI_UNSUPPORTED:                .quad   (EFI_ERROR_MASK | 3)
EFI_BAD_BUFFER_SIZE:            .quad   (EFI_ERROR_MASK | 4)
EFI_BUFFER_TOO_SMALL:           .quad   (EFI_ERROR_MASK | 5)
EFI_NOT_READY:                  .quad   (EFI_ERROR_MASK | 6)
EFI_DEVICE_ERROR:               .quad   (EFI_ERROR_MASK | 7)
EFI_WRITE_PROTECTED:            .quad   (EFI_ERROR_MASK | 8)
EFI_OUT_OF_RESOURCES:           .quad   (EFI_ERROR_MASK | 9)
EFI_VOLUME_CORRUPTED:           .quad   (EFI_ERROR_MASK | 10)
EFI_VOLUME_FULL:                .quad   (EFI_ERROR_MASK | 11)
EFI_NO_MEDIA:                   .quad   (EFI_ERROR_MASK | 12)
EFI_MEDIA_CHANGED:              .quad   (EFI_ERROR_MASK | 13)
EFI_NOT_FOUND:                  .quad   (EFI_ERROR_MASK | 14)
EFI_ACCESS_DENIED:              .quad   (EFI_ERROR_MASK | 15)
EFI_NO_RESPONSE:                .quad   (EFI_ERROR_MASK | 16)
EFI_NO_MAPPING:                 .quad   (EFI_ERROR_MASK | 17)
EFI_TIMEOUT:                    .quad   (EFI_ERROR_MASK | 18)
EFI_NOT_STARTED:                .quad   (EFI_ERROR_MASK | 19)
EFI_ALREADY_STARTED:            .quad   (EFI_ERROR_MASK | 20)
EFI_ABORTED:                    .quad   (EFI_ERROR_MASK | 21)
EFI_ICMP_ERROR:                 .quad   (EFI_ERROR_MASK | 22)
EFI_TFTP_ERROR:                 .quad   (EFI_ERROR_MASK | 23)
EFI_PROTOCOL_ERROR:             .quad   (EFI_ERROR_MASK | 24)
EFI_INCOMPATIBLE_VERSION:       .quad   (EFI_ERROR_MASK | 25)
EFI_SECURITY_VIOLATION:         .quad   (EFI_ERROR_MASK | 26)
EFI_CRC_ERROR:                  .quad   (EFI_ERROR_MASK | 27)
EFI_END_OF_MEDIA:               .quad   (EFI_ERROR_MASK | 28)
EFI_END_OF_FILE:                .quad   (EFI_ERROR_MASK | 31)
EFI_INVALID_LANGUAGE:           .quad   (EFI_ERROR_MASK | 32)
EFI_COMPROMISED_DATA:           .quad   (EFI_ERROR_MASK | 33)


EFI_WARN_UNKOWN_GLYPH:          .quad    1
EFI_WARN_DELETE_FAILURE:        .quad    2
EFI_WARN_WRITE_FAILURE:         .quad    3
EFI_WARN_BUFFER_TOO_SMALL:      .quad    4

# Initialize the EFI library.
#
# parameters:
#       - %rcx: the image handle
#       - %rdx: the system table
# returns: the status code in %rax.
efi_core_init:
        jmp     InitializeLib           # gnu-efi does the real work

# Stall the execution for the given amount of time.
#
# parameters:
#       - %rcx: the time to stall in 100 nanoseconds.
# returns:
#       - %rax: the status code
efi_core_stall:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $30, %rsp               # reserve 32 bytes of shadow space

        mov     BS(%rip), %rax          # move boot services to %rax
        call    *248(%rax)              # call BS->Stall     

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller

# Allocate a given number of bytes.
#
# parameters:
#       - %rcx: the amount of bytes to allocate.
# returns: the pointer to the memory address in %rax.
efi_core_alloc:
        jmp     AllocatePool            # gnu-efi does the real work

# Free the given memory from the heap.
#
# parameters:
#       - %rcx: the pointer to the memory to free.
efi_core_free:
        jmp     FreePool                # gnu-efi does the real work
