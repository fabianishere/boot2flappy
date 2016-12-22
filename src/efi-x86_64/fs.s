# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
.extern LibOpenRoot
.extern LibFileInfo

# Exports
.global efi_fs_open
.global efi_fs_close
.global efi_fs_root
.global efi_fs_info

# Routines for accessing and reading from the EFI file system.
.text

# Load the file from the given file system.
#
# parameters:
#       - %rcx: the root file of the file system.
#       - %rdx: the path to the file
#       - %r8: the mode to open the file in 
# returns: the return status in %rax, the file pointer in %rdx.
efi_fs_open:
        push    %rbp            # prologue: push the base pointer
        mov     %rsp, %rbp      # move the stack pointer to %rbp
        sub     $32, %rsp       # allocate 32 bytes of shadow space

        mov     8(%rcx), %rax   # file->Open
        mov     %r8, %r9        # the mode to open the file in as fourth argument
        mov     %rdx, %r8       # the path to the file is the third argument
        lea     16(%rbp), %rdx  # give address to place the file pointer in
        movq    $0, -8(%rbp)    # firth parameter zero
        call    *%rax           # open the file
        mov     16(%rbp), %rdx  # the file pointer in %rbp

        mov     %rbp, %rsp      # epilogue: clear stack
        pop     %rbp            # restore the caller's base pointer
        ret                     # return to caller

# Close the given file handle.
#
# parameters:
#       - %rcx: the pointer to the file handle to close.
# returns: the return status in %rax.
efi_fs_close:
        push    %rbp            # prologue: push the base pointer
        mov     %rsp, %rbp      # move the stack pointer to %rbp
        sub     $32, %rsp       # allocate 32 bytes of shadow space
        
        mov     16(%rcx), %rax  # file->Close        
        call    *%rax

        mov     %rbp, %rsp      # epilogue: clear stack
        pop     %rbp            # restore the caller's base pointer
        ret                     # return to caller

# Get the root file of the file system of the given device image.
#
# parameters:
#       - %rcx: the handle to the device to get the root file of.
# returns: the root file in %rax.
efi_fs_root:
        jmp     LibOpenRoot     # gnu-efi does the work here

# Get the metadata of the given file.
#
# parameters:
#       - %rcx: the pointer to the file to get the information of.
# returns: the pointer to the file info structure in %rax.
efi_fs_info:
        jmp     LibFileInfo     # gnu-efi does the work here
