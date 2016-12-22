# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
# gnu-efi
.extern APrint
.extern ST

# Exports
.global efi_console_init
.global efi_console_print
.global efi_console_print_ok
.global efi_console_print_wait
.global efi_console_print_fail
.global efi_console_print_info
.global efi_console_print_warn
.global efi_console_clear
.global efi_console_clear_input
.global efi_console_read
.global efi_console_set_foreground
.global efi_console_set_background
.global efi_console_enable_cursor
.global efi_console_set_cursor
.global efi_console_move_cursor
.global STDOUT
.global STDERR
.global STDIN

# Routines for printing to the EFI console
.bss
STDOUT: .quad   0xCAFEBABE              # pointer to ST->ConOut
STDERR: .quad   0xCAFEBABE              # pointer to ST->StdErr
STDIN:  .quad   0xCAFEBABE              # pointer to ST->ConIn
.text
OK:     .asciz  "  OK  "
FAIL:   .asciz  " FAIL "
WAIT:   .asciz  " WAIT "
WARN:   .asciz  " WARN "
PREFIX: .asciz  "["
SUFFIX: .asciz  "%N] "   

# Initialize the EFI console for this application.
efi_console_init:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp

        mov     ST(%rip), %rax          # get the system table
        mov     48(%rax), %rcx          # ST->ConIn
        mov     %rcx, STDIN             # save that pointer to STDIN

        mov     64(%rax), %rcx          # ST->ConOut
        mov     %rcx, STDOUT            # save that pointer to STDOUT

        mov     80(%rax), %rcx          # ST->StdErr
        mov     %rcx, STDERR            # save that pointer to STDERR

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Print the given formatted string, with an indication that the result is
# ok.
#
# parameters:
#       - %rcx: the ascii format string.
#       - %rdx, %r8, %r9, stack: the arguments to format the string with.
# returns: the printed characters in %rax.
efi_console_print_ok:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $40, %rsp                       # allocate 32 bytes of shadow space
        
        mov     %rcx, 16(%rbp)                  # save %rcx register
        mov     %rax, 24(%rbp)                  # save %rax register
        movq    %rdx, 32(%rbp)                  # save %rdx register
        mov     %r8, 40(%rbp)                   # save %r8 register
        mov     %r9, -8(%rbp)                   # save %r9 register

        mov     $PREFIX, %rcx                   # prefix as first argument
        call    efi_console_print               # print the prefix

        mov     $0x2, %rcx                      # foreground color to green
        call    efi_console_set_foreground      # set the foreground color

        mov     $OK, %rcx                       # first argument of print
        call    efi_console_print               # print the string

        mov     $SUFFIX, %rcx                   # suffix as first argument
        call    efi_console_print               # print the suffix

        mov     16(%rbp), %rcx                  # restore %rcx register
        mov     24(%rbp), %rax                  # restore %rax register
        mov     32(%rbp), %rdx                  # restore %rdx register
        mov     40(%rbp), %r8                   # restore %r8 register
        mov     -8(%rbp), %r9                   # restore %r9 register

        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        jmp     efi_console_print               # print the message given.

# Print the given formatted string, with an indication that the result is
# a failure.
#
# parameters:
#       - %rcx: the ascii format string.
#       - %rdx, %r8, %r9, stack: the arguments to format the string with.
# returns: the printed characters in %rax.
efi_console_print_fail:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $40, %rsp                       # allocate 32 bytes of shadow space
        
        mov     %rcx, 16(%rbp)                  # save %rcx register
        mov     %rax, 24(%rbp)                  # save %rax register
        mov     %rdx, 32(%rbp)                  # save %rdx register
        mov     %r8, 40(%rbp)                   # save %r8 register
        mov     %r9, -8(%rbp)                   # save %r9 register

        mov     $PREFIX, %rcx                   # prefix as first argument
        call    efi_console_print               # print the prefix
        
        mov     $0x4, %rcx                      # foreground color to red
        call    efi_console_set_foreground      # set the foreground

        mov     $FAIL, %rcx                     # first argument of print
        call    efi_console_print               # print the string

        mov     $SUFFIX, %rcx                   # the suffix to print
        call    efi_console_print               # print the suffix

        mov     16(%rbp), %rcx                  # restore %rcx register
        mov     24(%rbp), %rax                  # restore %rax register
        mov     32(%rbp), %rdx                  # restore %rdx register
        mov     40(%rbp), %r8                   # restore %r8 register
        mov     -8(%rbp), %r9                   # restore %r9 register
        
        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        jmp     efi_console_print               # print the message given.
        
# Print the given formatted string indicating that we are waiting.
#
# parameters:
#       - %rcx: the ascii format string.
#       - %rdx, %r8, %r9, stack: the arguments to format the string with.
# returns: the printed characters in %rax.
efi_console_print_wait:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $40, %rsp                       # allocate 32 bytes of shadow space
        
        mov     %rcx, 16(%rbp)                  # save %rcx register
        mov     %rax, 24(%rbp)                  # save %rax register
        mov     %rdx, 32(%rbp)                  # save %rdx register
        mov     %r8, 40(%rbp)                   # save %r8 register
        mov     %r9, -8(%rbp)                   # save %r9 register

        mov     $PREFIX, %rcx                   # prefix as first argument
        call    efi_console_print               # print the prefix
        
        mov     $0x1, %rcx                      # foreground color to blue
        call    efi_console_set_foreground      # set the foreground

        mov     $WAIT, %rcx                     # first argument of print
        call    efi_console_print               # print the string

        mov     $SUFFIX, %rcx                   # the suffix to print
        call    efi_console_print               # print the suffix

        mov     16(%rbp), %rcx                  # restore %rcx register
        mov     24(%rbp), %rax                  # restore %rax register
        mov     32(%rbp), %rdx                  # restore %rdx register
        mov     40(%rbp), %r8                   # restore %r8 register
        mov     -8(%rbp), %r9                   # restore %r9 register
        
        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        jmp     efi_console_print               # print the message given.

# Print the given formatted string as informational message.
#
# parameters:
#       - %rcx: the ascii format string.
#       - %rdx, %r8, %r9, stack: the arguments to format the string with.
# returns: the printed characters in %rax.
efi_console_print_info:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $40, %rsp                       # allocate 32 bytes of shadow space

        mov     %rcx, 16(%rbp)                  # save %rcx register
        mov     %rax, 24(%rbp)                  # save %rax register
        mov     %rdx, 32(%rbp)                  # save %rdx register
        mov     %r8, 40(%rbp)                   # save %r8 register
        mov     %r9, -8(%rbp)                   # save %r9 register
        
        mov     $0, %rdx                        # don't move in rows
        mov     $9, %rcx                        # move 9 columns further
        call    efi_console_move_cursor         # move the cursor

        mov     16(%rbp), %rcx                  # restore %rcx register
        mov     24(%rbp), %rax                  # restore %rax register
        mov     32(%rbp), %rdx                  # restore %rdx register
        mov     40(%rbp), %r8                   # restore %r8 register
        mov     -8(%rbp), %r9                   # restore %r9 register

        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        jmp     efi_console_print               # print the message given.
        
# Print the given formatted string as a warning message.
#
# parameters:
#       - %rcx: the ascii format string.
#       - %rdx, %r8, %r9, stack: the arguments to format the string with.
# returns: the printed characters in %rax.
efi_console_print_warn:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $40, %rsp                       # allocate 32 bytes of shadow space
        
        mov     %rcx, 16(%rbp)                  # save %rcx register
        mov     %rax, 24(%rbp)                  # save %rax register
        mov     %rdx, 32(%rbp)                  # save %rdx register
        mov     %r8, 40(%rbp)                   # save %r8 register
        mov     %r9, -8(%rbp)                   # save %r9 register

        mov     $PREFIX, %rcx                   # prefix as first argument
        call    efi_console_print               # print the prefix
        
        mov     $0x0E, %rcx                     # foreground color to yellow
        call    efi_console_set_foreground      # set the foreground

        mov     $WARN, %rcx                     # first argument of print
        call    efi_console_print               # print the string

        mov     $SUFFIX, %rcx                   # the suffix to print
        call    efi_console_print               # print the suffix

        mov     16(%rbp), %rcx                  # restore %rcx register
        mov     24(%rbp), %rax                  # restore %rax register
        mov     32(%rbp), %rdx                  # restore %rdx register
        mov     40(%rbp), %r8                   # restore %r8 register
        mov     -8(%rbp), %r9                   # restore %r9 register
        
        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        jmp     efi_console_print               # print the message given.

# Print the given formatted string to the EFI console.
#
# parameters:
#     - %rcx: The ascii format string.
#     - %rdx, %r8, %r9, stack: the arguments to print.
# returns: the number of characters that have been printed in %rax.
efi_console_print:
        jmp     APrint                  # APrint does the dirty job

# Clear the console screen.
efi_console_clear:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space

        mov     STDOUT(%rip), %rcx      # get the STDOUT pointer
        call    *48(%rcx)               # clear the screen
        
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Clear the standard input buffer.
efi_console_clear_input:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space
       
        mov     $0, %rdx                # the flag is false 
        mov     STDIN(%rip), %rcx       # get the standard input
        call    *(%rcx)                 # reset the buffer

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Read a character from the standard input buffer.
#
# parameters:
#       - %rcx: the address to store the key read.
# returns:
#       - %rax: the status code.
efi_console_read:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space

        mov     %rcx, %rdx              # the address to store the key read
        mov     STDIN(%rip), %rcx       # get the standard input
        call    *8(%rcx)                # read the key code

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Set the given attribute to the console.
#
# parameters:
#       - %rcx: the attribute to set.
efi_console_set_attribute:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space
       
        mov     %rcx, %rdx              # move first argument to %rdx
        mov     STDOUT(%rip), %rcx      # get the STDOUT pointer
        call    *40(%rcx)               # set the attribute

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
        
# Enable the cursor for the console.
#
# parameters:
#       - %rcx: the flag to indicate whether to enable the cursor.
# returns:
#       - %rax: the status code.
efi_console_enable_cursor:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space

        mov     %rcx, %rdx              # move first argument to %rdx
        mov     STDOUT(%rip), %rcx      # get the STDOUT pointer
        call    *64(%rcx)               # enable the cursor

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
        
# Set the cursor for the console.
#
# parameters:
#       - %rcx: the column to place the cursor at.
#       - %rdx: the row to place the cursor at.
# returns:
#       - %rax: the status code.
efi_console_set_cursor:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space

        mov     %rdx, %r8               # move the second argument to %r8
        mov     %rcx, %rdx              # move first argument to %rdx
        mov     STDOUT(%rip), %rcx      # get the STDOUT pointer
        call    *56(%rcx)               # enable the cursor

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
        

# Move the cursor in the console.
#
# parameters:
#       - %rcx: the delta to add to the current column
#       - %rdx: the delta to add to the current row.
# returns:
#       - %rax: the status code.
efi_console_move_cursor:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space

        mov     STDOUT(%rip), %rax      # get the STDOUT pointer
        mov     72(%rax), %rax          # get the mode
        add     12(%rax), %ecx          # get the current column
        add     16(%rax), %edx          # get the current row
        call    efi_console_set_cursor  # set the cursor

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Set the foreground of the console.
#
# parameters:
#       - %rcx: the color to set the foreground to.
efi_console_set_foreground:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $32, %rsp                       # allocate 32 bytes of shadow space
        
        mov     STDOUT(%rip), %rax              # get the STDOUT pointer
        mov     72(%rax), %rax                  # STDOUT->Mode
        mov     8(%rax), %eax                   # STDOUT->Mode->Attribute
        cltq                                    # convert long to quad

        shr     $4, %rax                        # Attr >> 4
        and     $0xFF, %eax                     # (Attr >> 4) & 0xFF
        sal     $4, %rax                        # ((Attr >> 4) & 0xFF) << 4)
        or      %rcx, %rax                      # %rcx | %rax
        mov     %rax, %rcx                      # move result in %rcx
        call    efi_console_set_attribute       # set the attribute        

        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        ret                                     # return to caller

# Set the background of the console.
#
# parameters:
#       - %rcx: the color to set the background to.
efi_console_set_background:
        push    %rbp                            # prologue: push the base pointer
        mov     %rsp, %rbp                      # copy the stack pointer to %rbp
        sub     $32, %rsp                       # allocate 32 bytes of shadow space
        
        mov     STDOUT(%rip), %rax              # get the STDOUT pointer
        mov     72(%rax), %rax                  # STDOUT->Mode
        mov     8(%rax), %eax                   # STDOUT->Mode->Attribute
        cltq                                    # convert long to quad

        and     $0xFF, %eax                     # Attr & 0xFF
        shl     $4, %rcx                        # %rcx << 4
        or      %rax, %rcx                      # %rax | %rcx
        call    efi_console_set_attribute       # set the attribute 

        mov     %rbp, %rsp                      # epilogue: clear stack
        pop     %rbp                            # restore caller's base pointer
        ret                                     # return to caller 
