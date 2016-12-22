# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
# gnu-efi
.extern BS

# Exports
.global efi_lip_init

# Routines for locating and handling the Loaded Image Protocol.
.text
# The GUID for the EFI Loaded Image Protocol (LIP) which consists of a 32 bit
# unsigned integer, two 16 bit unsigned integers, and 8 unsigned 8 bit integers.
LIP_GUID:
        .long   0x5B1B31A1
        .word   0x9562, 0x11d2
        .byte   0x8E, 0x3F, 0x00, 0xA0, 0xC9, 0x69, 0x72, 0x3B

# Locate the EFI Loaded Image Protocol (LIP).
#
# parameters:
#       - %rcx: the image handle to use.
#       - %rdx: the pointer to the memory where we store the result.
# returns: 
#       - %rax: the return status code.
efi_lip_init:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space
        
        mov     BS(%rip), %rax          # get boot services
        mov     %rdx, %r8               # load the address where to store the reference to LIP
        mov     $LIP_GUID, %rdx         # load the address to the LIP GUID.
        call    *152(%rax)              # locate the protocol (BS->HandleProtocol)

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
