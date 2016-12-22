# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
# core.s
.extern efi_core_alloc
.extern efi_core_free

# fs.s
.extern efi_fs_open
.extern efi_fs_close

# graphics.s
.extern efi_gop_decode_bmp

# Exports
.global sprites_open
.global sprites_close
.global sprites_load_bmp
.global sprites_unload

# Routines for loading and drawing the game's sprites.
.text

# Open the sprite file located at the given path.
#
# parameters:
#       - %rcx: the handle of the device on which the file is located.
#       - %rdx: the pointer to the char16 string which represents the path to the file
# returns:
#       - %rax: the status code
#       - %rdx: the pointer to the file
sprites_open:
        push    %rbp            # prologue: push the base pointer
        mov     %rsp, %rbp      # move the stack pointer to %rbp
        sub     $32, %rsp       # allocate 32 bytes of shadow space

        mov     $1, %r8         # the mode to open the file in (READ)
        call    efi_fs_open     # open the file

        mov     %rbp, %rsp      # epilogue: clear stack
        pop     %rbp            # restore the caller's base pointer
        ret                     # return to caller

# Close the given file handle to a sprite.
#
# parameters:
#       - %rcx: the handle to the sprite.
# returns:
#       - %rax: the status code.
sprites_close:
        jmp     efi_fs_close    # efi_fs_close does the job

# Load the given sprite file as a BMP sprite and convert it into a
# Blt buffer.
#
# parameters:
#       - %rcx: the handle of the file to load.
#       - %rdx: the location to store the pointer to the Blt buffer.
#       - %r8: the location to store size of the Blt buffer.
#       - %r9: the location to store the height of the image in pixels.
#       - 48(%rbp): the location to store the width of the image in pixels.
# return:
#       - %rax: the status code
sprites_load_bmp:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $128, %rsp                      # reserve 128 bytes of stack space

        mov     %rcx, 16(%rbp)                  # place first argument in shadow space
        mov     %rdx, 24(%rbp)                  # place second argument in shadow space
        mov     %r8, 32(%rbp)                   # place third argument in shadow space.
        mov     %r9, 40(%rbp)                   # place fourth argument in shadow space.

        # Get sprite file information
        mov     16(%rbp), %rcx                  # get the file pointer
        call    efi_fs_info                     # get the file information
        mov     %rax, -16(%rbp)                 # save the pointer on the stack
        test    %rax, %rax                      # did the operation fail
        mov     EFI_NOT_FOUND, %rax             # get the error code
        mov     %rax, -8(%rbp)                  # save the error code
        js      .exit                           # exit the procedure if error

        # Allocate a buffer for the file
        mov     -16(%rbp), %rax                 # get file informaiton
        mov     8(%rax), %rcx                   # get the file size
        mov     %rcx, -32(%rbp)                 # save it on the stack
        mov     %rcx, -40(%rbp)                 # and again
        call    efi_core_alloc                  # allocate the memory to store the file
        mov     %rax, -48(%rbp)                 # store pointer on the stack
        test    %rax, %rax                      # is the result of alloc NULL?
        mov     EFI_OUT_OF_RESOURCES, %rcx      # get the error code
        mov     %rcx, -8(%rbp)                  # save the error code
        js      .exit                           # exit the procedure if error

        # Read the file into the buffer
        mov     -48(%rbp), %r8                  # the addess to write the bytes to
        lea     -40(%rbp), %rdx                 # the address to store the bytes read
        mov     16(%rbp), %rcx                  # get the file pointer
        mov     32(%rcx), %rax                  # file->Read
        call    *%rax                           # read from the file.
        mov     %rax, -8(%rbp)                  # save the result code
        test    %rax, %rax                      # did the operation fail
        js      .exit_dealloc                   # if so, jump to exit

        # Convert the BMP buffer into a Blt buffer
        mov     -48(%rbp), %rcx                 # get the pointer to the bitmap buffer
        mov     -32(%rbp), %rdx                 # get the total amount of bytes.
        mov     24(%rbp), %r8                   # address to store the address to the blt buffer
        mov     32(%rbp), %r9                   # address to store the size of the blt buffer
        mov     40(%rbp), %rax                  # address to store the width
        mov     %rax, 32(%rsp)                  # place it on the stack to for the procedure
        mov     48(%rbp), %rax                  # address to store the height
        mov     %rax, 40(%rsp)                  # place it on the stack for the procedure
        call    efi_gop_decode_bmp              # decode bitmap buffer.
        mov     %rax, -24(%rbp)                 # save the result code
        test    %rax, %rax                      # did the operation fail?
        js      .exit_dealloc                   # if so, jump to exit

        mov     EFI_SUCCESS, %rax               # get the success code
        mov     %rax, -8(%rbp)                  # set the status code
.exit_dealloc:
        # Deallocate the file buffer
        mov     -48(%rbp), %rcx                 # get the pointer to the buffer
        call    efi_core_free                   # deallocate the memory
.exit:
        mov     -8(%rbp), %rax                  # set the status code
        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore the caller's base pointer
        ret                                     # return to caller

# Unload the given sprite buffer.
#
# parameters:
#       - %rcx: the pointer to the sprite buffer.
# returns:
#       - %rax: the status code.
sprites_unload:
        jmp     efi_core_free                    # deallocate the buffer

