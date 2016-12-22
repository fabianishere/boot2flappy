# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
.extern LibLocateProtocol
.extern ST

# core.s
.extern EFI_UNSUPPORTED
.extern efi_core_alloc
.extern efi_core_free

# Exports
.global efi_gop_init
.global efi_gop_identify
.global efi_gop_decode_bmp
.global efi_gop_blt
.global efi_gop_blt_mask
.global efi_gop_fill
.global efi_gop_fill_buffer
.global efi_gop_copy
.global efi_gop_copy_mask
.global GOP
.global GOP_MODE
.global GOP_FRAMEBUFFER
.global GOP_FRAMEBUFFER_SIZE
.global GOP_WIDTH
.global GOP_HEIGHT

# Routines for accessing and modifying the frambuffer given by EFI.
.bss
GOP:                    .quad   0xCAFEBABE      # pointer to EFI Graphics Output Protocol (GOP)
GOP_MODE:               .quad   0xCAFEBABE      # pointer to GOP->Mode
GOP_FRAMEBUFFER:        .quad   0xCAFEBABE      # pointer to the EFI GOP framebuffer
GOP_FRAMEBUFFER_SIZE:   .quad   0               # the size of the framebuffer
GOP_WIDTH:              .long   -1              # the width of the display
GOP_HEIGHT:             .long   -1              # the height of the display

.text
# The GUID for the EFI Graphics Ouput Protocol (GOP) which consists of a 32 bit
# unsigned integer, two 16 bit unsigned integers, and 8 unsigned 8 bit integers.
GOP_GUID:               .long   0x9042a9de
                        .word   0x23dc, 0x4a38
                        .byte   0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a

# Locate the EFI Graphics Output Protocol (GOP) and let the GOP variable point
# to it.
#
# returns: the return status code in %rax.
efi_gop_init:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space
        
        mov     $GOP, %rdx              # load the address where to store the reference to GOP
        mov     $GOP_GUID, %rcx         # load the address to the GOP GUID.
        call    LibLocateProtocol       # locate the protocol

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Determine the EFI Graphics Output Protocol mode and thereby setting the
# width and height variables and locating the framebuffer.
#
# returns: the pointer to GOP->Mode.
efi_gop_identify:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space

        mov     GOP(%rip), %rax         # get the GOP address
        mov     24(%rax), %rax          # GOP->Mode
        mov     %rax, GOP_MODE          # GOP_MODE = GOP->Mode

        mov     8(%rax), %rcx           # GOP_MODE->Info 
        mov     4(%rcx), %edx           # get the width
        mov     %edx, GOP_WIDTH         # GOP_WIDTH = GOP_INFO->HorizontalResolution

        mov     8(%rcx), %edx           # get the height
        mov     %edx, GOP_HEIGHT        # GOP_WIDTH = GOP_INFO->VerticalResolution

        mov     GOP_MODE(%rip), %rcx    # get GOP_MODE
        mov     24(%rcx), %rdx          # get the framebuffer address
        mov     %rdx, GOP_FRAMEBUFFER   # save the address to GOP_FRAMEUBUFFER
        mov     32(%rcx), %rdx          # get and size the size of the framebuffer
        mov     %rdx, GOP_FRAMEBUFFER_SIZE

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Decode the given BMP sprite buffer and convert it to a Blt buffer.
#
# parameters:
#       - %rcx: the pointer to the memory block that contains the BMP sprite.
#       - %rdx: the size of the BMP image.
#       - %r8: the location to store the pointer to the Blt buffer.
#       - %r9: the location to store size of the Blt buffer.
#       - 48(%rbp): the location to store the height of the image in pixels.
#       - 56(%rbp): the location to store the width of the image in pixels.
# returns: the return status code in %rax.
efi_gop_decode_bmp:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $128, %rsp                      # reserve 128 bytes of stack space

        mov     %rcx, 16(%rbp)                  # place first argument in shadow space
        mov     %rdx, 24(%rbp)                  # place second argument in shadow space
        mov     %r8, 32(%rbp)                   # place third argument in shadow space.
        mov     %r9, 40(%rbp)                   # place fourth argument in shadow space.

        # BMP header
        movzb   (%rcx), %eax                    # get the first byte of the BMP buffer
        cmpb    $0x42, %al                      # is it equal to 'B'?
        mov     EFI_UNSUPPORTED, %rax           # get error code
        mov     %rax, -8(%rbp)                  # save error code
        jne     .exit                           # jump to exit if not

        movzb   1(%rcx), %eax                   # get the second byte of the BMP buffer.
        cmpb    $0x4d, %al                      # is it equal to 'M'?
        mov     EFI_UNSUPPORTED, %rax           # get the error code
        mov     %rax, -8(%rbp)                  # set the error code
        jne     .exit                           # jump to exit

        # We don't support compression
        mov     30(%rcx), %eax                  # get the compression type          
        test    %eax, %eax                      # if it is not 0, then fail
        mov     EFI_UNSUPPORTED, %rax           # get the error code
        mov     %rax, -8(%rbp)                  # set the error code
        jne     .exit                           # jump to exit

        mov     16(%rbp), %rax                  # get the bitmap buffer
        mov     %rax, -16(%rbp)                 # save it on the stack
        add     $54, %rax                       # add 54 bytes to the buffer
        mov     %rax, -24(%rbp)                 # store this as the color map
        
        mov     -16(%rbp), %rax                 # get the image pointer
        mov     10(%rax), %edx                  # get the image offset                  
        add     %rdx, %rax                      # add the offset to the image pointer
        mov     %rax, -16(%rbp)                 # save that new address
        mov     %rax, -32(%rbp)                 # save ImageHeader address

        mov     16(%rbp), %rax                  # get the bitmap buffer
        mov     18(%rax), %edx                  # get the pixel width
        mov     22(%rax), %eax                  # get the pixel height
        mul     %edx                            # calculate the resolution
        shl     $2, %rax                        # a pixel is 4 bytes so multiply by four
        mov     %rax, -40(%rbp)                 # this is the size of our buffer
        mov     %rax, %rcx                      # move the size to %rcx
        mov     40(%rbp), %rax                  # get the address to store the buffer size
        mov     %rcx, (%rax)                    # set the buffer size 
        call    efi_core_alloc                  # allocate the buffer
        mov     32(%rbp), %rcx                  # get the address where to store the address
        mov     %rax, (%rcx)                    # store the address there
        mov     %rax, -48(%rbp)                 # save it on the stack
        test    %rax, %rax                      # is the result of alloc NULL?
        mov     EFI_OUT_OF_RESOURCES, %rcx      # get the error code
        mov     %rcx, -8(%rbp)                  # save the error code.
        je      .exit                           # jump to exit
        
        mov     16(%rbp), %rax                  # get the bitmap buffer
        mov     18(%rax), %edx                  # get the pixel width
        mov     48(%rbp), %rcx                  # get the address to store the width
        mov     %rdx, (%rcx)                    # store the pixel width
        mov     %edx, -52(%rbp)                 # store the pixel width on the stack
        mov     22(%rax), %edx                  # get the pixel height
        mov     56(%rbp), %rax                  # get the address to store the height
        mov     %rdx, (%rax)                    # store the pixel height
        mov     %edx, -56(%rbp)                 # store pixel height on the stack

        movq    $0, -64(%rbp)                   # initialize counter
        jmp     .loop_height_cd                 # jump to loop condition

.loop_height_body:
        mov     -56(%rbp), %eax                 # get the pixel height
        sub     -64(%rbp), %rax                 # subtract the current counter
        dec     %rax                            # decrease by one
        mull    -52(%rbp)                       # multiply by the pixel width
        shl     $2, %rax                        # per 4 bytes so multiply by 4
        mov     -48(%rbp), %rdx                 # get the buffer to write to
        add     %rax, %rdx                      # add to the offset
        mov     %rdx, -72(%rbp)                 # place the current pixel on the stack
        
        movq    $0, -80(%rbp)                   # initialize width counter
        jmp     .loop_width_cd                  # jump to loop condition
.loop_width_body:
        mov     16(%rbp), %rax                  # get the bitmap buffer
        movzwl  28(%rax), %eax                  # get the bits per pixel 
        cmp     $8, %eax                        # either it is 8 bits
        je      .loop_8bit                      # handle 8 bits per pixel
        cmp     $24, %eax                       # or 24 bits
        je      .loop_24bit                     # handle 24 bits per pixel

        mov     -48(%rbp), %rcx                 # get the blt buffer
        call    efi_core_free                   # free the memory
        mov     32(%rbp), %rax                  # get the address to store the blt buffer pointer
        movq    $0, (%rax)                      # set the address to NULL
        mov     EFI_UNSUPPORTED, %rax           # get error code
        mov     %rax, -8(%rbp)                  # place it in the error slot
        jmp     .exit                           # others are not supported
.loop_8bit:
        mov     -16(%rbp), %rax                 # get the image pointer
        movzb   (%rax), %ecx                    # get the byte value as long
        mov     -24(%rbp), %rdx                 # get the color map
        movzb   2(%rdx, %rcx, 4), %r8d          # get a value from the color map
        mov     -48(%rbp), %rax                 # get the blt buffer
        mov     %r8b, 2(%rax)                   # place it into the blt buffer

        mov     -16(%rbp), %rax                 # get the image pointer
        movzb   (%rax), %ecx                    # get the byte value as long
        mov     -24(%rbp), %rdx                 # get the color map
        movzb   1(%rdx, %rcx, 4), %r8d          # get a value from the color map
        mov     -48(%rbp), %rax                 # get the blt buffer
        mov     %r8b, 1(%rax)                   # place it into the blt buffer

        mov     -16(%rbp), %rax                 # get the image pointer
        movzb   (%rax), %ecx                    # get the byte value as long
        mov     -24(%rbp), %rdx                 # get the color map
        movzb   (%rdx, %rcx, 4), %r8d           # get a value from the color map
        mov     -48(%rbp), %rax                 # get the blt buffer
        mov     %r8b, (%rax)                    # place it into the blt buffer

        jmp     .loop_width_next                # goto next loop element
.loop_24bit:
        mov     -16(%rbp), %rax                 # get image pointer
        addq    $2, -16(%rbp)                   # increase address by two
        mov     -72(%rbp), %rcx                 # get the blt buffer
        movzb   (%rax), %edx                    # get the first byte                 
        movb    %dl, (%rcx)                     # place the first byte onto the blt buffer
        movzb   1(%rax), %edx                   # get the second byte
        movb    %dl, 1(%rcx)                    # place the second byte onto the blt buffer
        movzb   2(%rax), %edx                   # get the third byte
        movb    %dl, 2(%rcx)                    # place the third byte onto the blt buffer.
.loop_width_next:
        addq    $1, -80(%rbp)                   # increase counter
        addq    $1, -16(%rbp)                   # increase image pointer
        addq    $4, -72(%rbp)                   # increase pixel address (next pixel)
.loop_width_cd:
        mov     -52(%rbp), %eax                 # get the pixel width
        cmp     -80(%rbp), %rax                 # compare it to the counter
        ja      .loop_width_body                # jump to loop body if not finished
        
        mov     -16(%rbp), %rax                 # get the image pointer
        sub     -32(%rbp), %rax                 # subtract with image header address
        and     $3, %eax                        # bitwise and to test multiply of 4
        test    %rax, %rax                      # is it a multiply of four
        je      .loop_height_next               # jump to next loop element
       
        mov     $4, %edx                        # move 4 in %edx
        sub     %rax, %rdx                      # 4 - (ImageIndex % 4)
        add     -16(%rbp), %rdx                 # add image pointer address to it
        mov     %rdx, -16(%rbp)                 # save it on the stack
.loop_height_next:
        addq    $1, -64(%rbp)                   # increase counter
.loop_height_cd:
        mov     -56(%rbp), %eax                 # get the height from stack
        cmpq    -64(%rbp), %rax                 # compare it to the counter
        ja     .loop_height_body                # if counter has not reached height, jump

        mov     EFI_SUCCESS, %rax               # get the success error code
        mov     %rax, -8(%rbp)                  # set the error code       
.exit:
        mov     -8(%rbp), %rax                  # set error code in %rax.
        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        ret                                     # return to caller

# Write the given bitmap blt buffer to the framebuffer.
#
# parameters:
#       - %rcx: the pointer to the blt buffer 
#       - %rdx: the source x-coordinate in the blt buffer
#       - %r8: the source y-coordinate in the blt buffer
#       - 32(%rsp): the destination x-coordinate in the framebuffer
#       - 40(%rsp): the destination y-coordinate in the framebuffer
#       - 48(%rsp): the width of the sprite to write
#       - 56(%rsp): the height of the sprite to write
#       - 64(%rsp): the length in bytes of a row in the BltBuffer.
# returns: the status code in %rax.
efi_gop_blt:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy stack pointer to %rbp
        sub     $80, %rsp                       # reserve 80 bytes on the stack

        mov     %rcx, 16(%rbp)                  # place the blt buffer pointer in shadow space
        mov     %rdx, 24(%rbp)                  # place the source x-coordinate in shadow space
        mov     %r8, 32(%rbp)                   # place the source y-coordinate in shadow space
        mov     %r9, 40(%rbp)                   # place the destination x-coordinate in shadow space

        mov     72(%rbp), %r9                   # get the delta
        mov     64(%rbp), %r8                   # get the height of the sprite
        mov     56(%rbp), %rax                  # get the width of the sprite

        mov     %r9, 72(%rsp)                   # store delta on stack
        mov     %r8, 64(%rsp)                   # store height on stack
        mov     %rax, 56(%rsp)                  # store width on stack

        mov     48(%rbp), %r9                   # get the destination y-coordinate
        mov     40(%rbp), %r8                   # get the destination x-coordinate
        mov     32(%rbp), %rdx                  # get the source y-coordinate
        mov     24(%rbp), %rax                  # get the source x-coordinate

        mov     %r9, 48(%rsp)                   # destination y
        mov     %r8, 40(%rsp)                   # destination x
        mov     %rdx, 32(%rsp)                  # source y

        # XXX Bug, parameter %r9 gets ignored by OVMF
        # Do it indirect by adding the offset to the Blt address
        mov     $0, %r9                         # empty %r9 for working implementations
        #mov     24(%rbp), %r9                  # source x
        mov     16(%rbp), %rdx                  # get the address of the Blt buffer       
        mov     24(%rbp), %rax                  # get the offset
        shl     $2, %rax                        # multiply it by four
        add     %rax, %rdx                      # add it to the address

        mov     $2, %r8                         # EfiBltBufferToVideo

        mov     GOP(%rip), %rcx                 # get the graphics output protocol
        mov     16(%rcx), %rax                  # get the blit function of GOP
        call    *%rax                           # draw the blt buffer

        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        ret                                     # return to caller

        test:   .string "%d\n"
# Copy a part of the given buffer into another buffer.
#
# parameters:
#       - %rcx: the pointer to the source.
#       - %rdx: the delta of the source
#       - %r8: the pointer to the destination
#       - %r9: the delta of the destination
#       - 32(%rsp): the source x-coordinate in the blt buffer
#       - 40(%rsp): the source y-coordinate in the blt buffer
#       - 48(%rsp): the destination x-coordinate
#       - 56(%rsp): the destination y-coordinate
#       - 64(%rsp): the width of the rectangle to copy
#       - 72(%rsp): the height of the rectangle to copy
efi_gop_copy:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # reserve 128 bytes of stack space

        mov     %r12, -8(%rbp)          # save %r12
        mov     %r13, -16(%rbp)         # save %r13
        mov     %r14, -24(%rbp)         # save %r14
        mov     %r15, -32(%rbp)         # save %r15
        mov     %rdi, -40(%rbp)         # save %rdi
        mov     %rsi, -48(%rbp)         # save %rsi

        mov     48(%rbp), %r12          # get the source x-coordinate
        mov     56(%rbp), %r13          # get the source y-coordinate
        
        imul    %rdx, %r13              # delta times the y-offset
        add     %rcx, %r13              # add source buffer address
        lea     (%r13, %r12, 4), %r13   # add x-offset to it

        mov     64(%rbp), %r14          # get the destination x-coordinate
        mov     72(%rbp), %r15          # get the destination y-coordinate
        
        imul    %r9, %r15               # delta times the y-offset
        add     %r8, %r15               # add the destination buffer address
        lea     (%r15, %r14, 4), %r15   # add x-offset to it

        mov     80(%rbp), %rdi          # the width of the rectangle
        shl     $2, %rdi                # 4 bytes per pixel
        mov     88(%rbp), %rsi          # the height of the rectangle

        mov     %rdx, %r12              # the source delta
        mov     %r9, %r14               # the destination delta

        test    %rdi, %rdi              # test if the width is zero
        je      .gop_copy_exit          # if so, exit
        jmp     .gop_copy_condition     # jump to loop condition
.gop_copy_loop:
        mov     %rdi, %r8               # the amount of bytes to copy
        mov     %r13, %rdx              # the source
        mov     %r15, %rcx              # the destination
        call    CopyMem                 # copy the memory

        add     %r12, %r13              # src = src + delta_src;
        add     %r14, %r15              # dst = dst + delta_dst;
        dec     %rsi                    # decrease height counter
.gop_copy_condition:
        cmp     $0, %rsi                # is the counter zero
        jnz     .gop_copy_loop          # if not, loop

.gop_copy_exit:
        mov     -8(%rbp), %r12          # restore %r12
        mov     -16(%rbp), %r13         # restore %r13
        mov     -24(%rbp), %r14         # restore %r14
        mov     -32(%rbp), %r15         # restore %r15
        mov     -40(%rbp), %rdi         # restore %rdi
        mov     -48(%rbp), %rsi         # restore %rsi

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller
        
# Copy a part of the given buffer into another buffer using the given
# color as mask.
#
# parameters:
#       - %rcx: the pointer to the source.
#       - %rdx: the delta of the source
#       - %r8: the pointer to the destination
#       - %r9: the delta of the destination
#       - 32(%rsp): the source x-coordinate in the blt buffer
#       - 40(%rsp): the source y-coordinate in the blt buffer
#       - 48(%rsp): the destination x-coordinate
#       - 56(%rsp): the destination y-coordinate
#       - 64(%rsp): the width of the rectangle to copy
#       - 72(%rsp): the height of the rectangle to copy
#       - 80(%rsp): the color to use as mask
efi_gop_copy_mask:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # reserve 128 bytes of stack space

        mov     %r12, -8(%rbp)          # save %r12
        mov     %r13, -16(%rbp)         # save %r13
        mov     %r14, -24(%rbp)         # save %r14
        mov     %r15, -32(%rbp)         # save %r15
        mov     %rdi, -40(%rbp)         # save %rdi
        mov     %rsi, -48(%rbp)         # save %rsi

        mov     48(%rbp), %r12          # get the source x-coordinate
        mov     56(%rbp), %r13          # get the source y-coordinate

        imul    %rdx, %r13              # delta times the y-offset
        add     %rcx, %r13              # add source buffer address
        lea     (%r13, %r12, 4), %r13   # add x-offset to it

        mov     64(%rbp), %r14          # get the source x-coordinate
        mov     72(%rbp), %r15          # get the source y-coordinate

        imul    %r9, %r15               # delta times the y-offset
        add     %r8, %r15               # add the destination buffer address
        lea     (%r15, %r14, 4), %r15   # add x-offset to it

        mov     80(%rbp), %rdi          # the width of the rectangle
        mov     88(%rbp), %rsi          # the height of the rectangle

        mov     %rdx, %r12              # the source delta
        mov     %r9, %r14               # the destination delta
        mov     96(%rbp), %r10          # the mask color

        test    %rdi, %rdi              # test if the width is zero
        je      .gop_copy_mask_exit     # if so, exit
        jmp     .gop_copy_mask_hcd      # jump to loop condition
.gop_copy_mask_height:
        mov     %rdi, %rax              # the width counter
.gop_copy_mask_width:
        mov     (%r13, %rax, 4), %edx   # get the source pixel
        mov     %edx, %ecx              # copy the pixel
        and     $0xFFFFFF, %ecx         # clear upper 8 bits
        cmp     %r10, %rcx              # is is equal to the mask
        je      .gop_copy_mask_wn       # jump to next byte
        mov     %edx, (%r15, %rax, 4)   # otherwise, write the pixel
.gop_copy_mask_wn:
        dec     %rax                    # decrease counter
        cmp     $0, %rax                # is the counter zero
        jge     .gop_copy_mask_width
        
        add     %r12, %r13              # src = src + delta_src;
        add     %r14, %r15              # dst = dst + delta_dst;
        dec     %rsi                    # decrease height counter
.gop_copy_mask_hcd:
        cmp     $0, %rsi                # is the counter zero
        jnz     .gop_copy_mask_height   # if not, loop

.gop_copy_mask_exit:
        mov     -8(%rbp), %r12          # restore %r12
        mov     -16(%rbp), %r13         # restore %r13
        mov     -24(%rbp), %r14         # restore %r14
        mov     -32(%rbp), %r15         # restore %r15
        mov     -40(%rbp), %rdi         # restore %rdi
        mov     -48(%rbp), %rsi         # restore %rsi

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller


# Write the given bitmap blt buffer to the framebuffer using the given
# color as transparent.
#
# parameters:
#       - %rcx: the pointer to the blt buffer.
#       - %rdx: the source x-coordinate in the blt buffer
#       - %r8: the source y-coordinate in the blt buffer
#       - %r9: the destination x-coordinate in the framebuffer
#       - 48(%rbp): the destination y-coordinate in the framebuffer
#       - 56(%rbp): the width of the sprite to write
#       - 64(%rbp): the height of the sprite to write
#       - 72(%rbp): the length in bytes of a row in the BltBuffer.
#       - 80(%rbp): the color to use as mask.
# returns: 
#       - %rax: the status code
efi_gop_blt_mask:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy stack pointer to %rbp
        sub     $164, %rsp                      # reserve 164 bytes on the stack
    
        # Save callee saved registers
        mov     %r14, -48(%rbp)                 # save %r14 for restoration
        mov     %r13, -8(%rbp)                  # save %r13 for restoration 
        mov     %r12, -16(%rbp)                 # save %r12 for restoration
        mov     %rdi, -24(%rbp)                 # save %rdi for restoration
        mov     %rsi, -32(%rbp)                 # save %rsi for restoration
        mov     %rbx, -40(%rbp)                 # save %rbx for restoration
   
        mov     72(%rbp), %r12                  # get the delta from the stack 
        mov     64(%rbp), %rsi                  # get the height of the sprite
        mov     56(%rbp), %rdi                  # get the width of the sprite
        mov     80(%rbp), %r10                  # get the color to use as mask

        imul    %r12, %r8                       # multiply the delta by the source y
        lea     (%r8, %rdx, 4), %rdx            # add the source x to the result
 
        mov     GOP_WIDTH(%rip), %r13d          # get the width of the screen
        lea     (%rcx, %rdx, 1), %r8            # calculate the src adddress
        mov     %r13, %rax                      # move the width in %rax
        imul    48(%rbp), %rax                  # multiply it by the destination y
        add     %rax, %r9                       # add the destination x to it
        mov     GOP_FRAMEBUFFER(%rip), %r11     # get the address of the framebuffer
        lea     (%r11, %r9, 4), %r11            # calcalute the framebuffer origin
        test    %rsi, %rsi                      # does the sprite have a height
        je      .blt_mask_exit                  # jump to exit if not
        lea     (, %rdi, 4), %r9                # calculate the width upper limit
        shl     $2, %r13                        # multiply dst delta by 4 (4 bytes per pixel)
        xor     %rbx, %rbx                      # clear the height counter
.blt_mask_height:
        xor     %rax, %rax                      # clear the width counter
        test    %rdi, %rdi                      # does the sprite have a width
        je      .blt_mask_exit                  # jump to exit if not
.blt_mask_width:
        mov     (%r8, %rax), %edx               # get the source pixel
        mov     %edx, %ecx                      # copy the pixel
        and     $0xFFFFFF, %ecx                 # clear upper 8 bits
        cmp     %r10, %rcx                      # is is equal to the mask
        je      .blt_mask_width_next            # jump to next
        mov     %edx, (%r11, %rax)              # otherwise, write the pixel
.blt_mask_width_next:
        add     $4, %rax                        # add 4 to the counter
        cmp     %rax, %r9                       # have we reached the upper limit
        jne     .blt_mask_width                 # if not, loop
.blt_mask_height_next:
        add     $1, %rbx                        # add one to counter
        add     %r12, %r8                       # add delta src to the src address
        add     %r13, %r11                      # add delta dst to the dst address 
        cmp     %rbx, %rsi                      # have we reached the height yet
        jne     .blt_mask_height                # if not, loop

.blt_mask_exit:      
        # Restore callee saved registers
        mov     -48(%rbp), %r14                 # restore %r14
        mov     -8(%rbp), %r13                  # restore %r13
        mov     -16(%rbp), %r12                 # restore %r12
        mov     -24(%rbp), %rdi                 # restore %rdi
        mov     -32(%rbp), %rsi                 # restore %rsi
        mov     -40(%rbp), %rbx                 # restore %rbx
        
        mov     $0, %rax                        # return success
        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        ret                                     # return to caller
    
# Fill the framebuffer with the given pixel.
#
# parameters:
#       - %ecx: the pixel to fill the framebuffer with.
#       - %rdx: the x-coordinate to start filling
#       - %r8: the y-coordinate to start filling.
#       - %r9: the width of the rectangle to fill.
#       - 48(%rbp): the height of the rectangle to fill.
efi_gop_fill:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy stack pointer to %rbp
        sub     $80, %rsp                       # reserve 80 bytes on the stack

        mov     %rcx, 16(%rbp)                  # place the pixel bufferin shadow space
        mov     %rdx, 24(%rbp)                  # place the x-coordinate in shadow space
        mov     %r8, 32(%rbp)                   # place the y-coordinate in shadow space
        mov     %r9, 40(%rbp)                   # place the width in shadow space

        mov     48(%rbp), %r8                   # get the height of the rectangle to fill
        mov     40(%rbp), %rax                  # get the width of the rectangle to fill

        movq    $0, 72(%rsp)                    # store delta on stack
        mov     %r8, 64(%rsp)                   # store height on stack
        mov     %rax, 56(%rsp)                  # store width on stack

        mov     32(%rbp), %r9                   # get the destination y-coordinate
        mov     24(%rbp), %r8                   # get the destination x-coordinate

        mov     %r9, 48(%rsp)                   # destination y
        mov     %r8, 40(%rsp)                   # destination x
        movq    $0, 32(%rsp)                    # source y is zero (start at begin)

        mov     $0, %r9                         # source x is zero (start at begin)
        mov     $0, %r8                         # EfiBltVideoFill
        lea     16(%rbp), %rdx                  # the addres of the pixel is the buffer

        mov     GOP(%rip), %rcx                 # get the graphics output protocol
        mov     16(%rcx), %rax                  # get the blit function of GOP
        call    *%rax                           # draw the blt buffer

        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        ret                                     # return to caller 

# Fill the given Blt buffer with the given pixel.
#
# parameters:
#       - %ecx: the pixel to fill the framebuffer width.
#       - %rdx: the buffer to to fill.
#       - %r8: the x-coordinate to start filling.
#       - %r9: the y-coordinate to start filling.
#       - 32(%rsp): the width of the rectangle to fill.
#       - 40(%rsp): the height of the rectangle to fill.
#       - 48(%rsp): the amount of bytes per row in the buffer
efi_gop_fill_buffer:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the base pointer into %rbp
        sub     $56, %rsp               # reserve 56 bytes of stack space

        # Save callee saved registers
        mov     %rdi, -8(%rbp)          # save %rdi for restoration
        mov     %rsi, -16(%rbp)         # save %rsi for restoration
   
        mov     64(%rbp), %r10          # get the delta from the stack 
        mov     56(%rbp), %rsi          # get the height of the sprite
        mov     48(%rbp), %rdi          # get the width of the sprite
 
        imul    %r10, %r9               # multiply the delta by the y coordinate
        lea     (%r9, %r8, 4), %r9      # add the x coordinate to the result
        add     %rdx, %r9               # calculate the destination pointer

        test    %rdi, %rdi              # test if the width is zero
        je      .fill_exit              # exit if the width is zero
        jmp     .fill_height_condition  # jump to height condition
.fill_height:
        mov     %rdi, %rax              # the counter is the width
.fill_width:
        sub     $1, %rax                # subtract 4 from the counter
        mov     %ecx, (%r9, %rax, 4)    # write the pixel
        cmp     $0, %rax                # have we reached the lower limit
        jnz     .fill_width             # if not, loop
        add     %r10, %r9               # add delta dst to the dst address 
        sub     $1, %rsi                # decrement height counter
.fill_height_condition:
        cmp     $0, %rsi                # have we reached the height yet
        jnz     .fill_height            # if not, loop

.fill_exit:      

        # Restore callee saved registers
        mov     -8(%rbp), %rdi          # restore %rdi
        mov     -16(%rbp), %rsi         # restore %rsi
        
        mov     $0, %rax                # return success
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
        


