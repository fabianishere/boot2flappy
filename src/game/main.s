# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# External dependencies
# core.s
.extern efi_core_init
.extern efi_core_stall
.extern efi_core_alloc
.extern efi_core_free

# console.s
.extern efi_console_init
.extern efi_console_print_ok
.extern efi_console_print_err
.extern efi_console_print_info
.extern efi_console_print
.extern efi_console_clear
.extern efi_console_move_cursor

# graphics.s
.extern efi_gop_init
.extern efi_gop_identify
.extern efi_gop_decode_bmp
.extern efi_gop_blt
.extern efi_gop_blt_mask
.extern efi_gop_fill
.extern GOP
.extern GOP_FRAMEBUFFER
.extern GOP_FRAMEBUFFER_SIZE
.extern GOP_WIDTH
.extern GOP_HEIGHT

# image.s
.extern efi_lip_init

# fs.s
.extern efi_fs_root
.extern efi_fs_info

# event.s
.extern efi_event_create_timer
.extern efi_event_wait
.extern efi_event_close

# sprites.s
.extern sprites_open
.extern sprites_close
.extern sprites_load_bmp
.extern sprites_unload

# Exports
.global efi_main

# Main file of the Flappy Bird clone as an UEFI application, written in
# x86-64 assembly (AT&T syntax).
# Please note that Microsoft x64 calling conventions are used in this application.
.text
msg_welcome:            .asciz  "Welcome to %EFlappy Alexandru%N!\n"
msg_init_lib:           .asciz  "Initialize EFI library\n"
msg_init_console:       .asciz  "Initialize EFI console\n"
msg_init_gop:           .asciz  "Locate EFI Graphics Output Protocol\n"
msg_init_lip:           .asciz  "Locate EFI Loaded Image Protocol\n"
msg_watchdog_disable:   .asciz  "Disable Watchdog Timer\n"
msg_gop_identify:       .asciz  "Framebuffer of %dx%d located at 0x%x\n"
msg_fs_root:            .asciz  "Obtain root directory of file system\n"
msg_sprite_open:        .asciz  "Locate sprite bitmap on file system\n"
msg_sprite_load:        .asciz  "Load %s of %d bytes with dimensions %dx%d\n"
msg_err:                .asciz  "%r (%d)\n"

# Path to the sprite as a 16 bit character array
sprite_path:            .ascii "\\\0E\0F\0I\0\\\0B\0O\0O\0T\0\\\0S\0P\0R\0I\0T\0E\0S\0.\0B\0M\0P\0\0\0"

test:   .string "%d %d\n"

# The main entry point of the EFI application.
#
# parameters:
#      %rcx: the handle to the EFI image.
#      %rdx: pointer to the EFI system table.
# returns: the EFI status in %rax
efi_main:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $664, %rsp              # allocate 512 bytes on the stack
        
        mov     %r12, -8(%rbp)          # save %r12
        mov     %r13, -16(%rbp)         # save %r13
        mov     %r14, -24(%rbp)         # save %r14
        mov     %r15, -32(%rbp)         # save %r15
        mov     %rdi, -40(%rbp)         # save %rdi
        mov     %rsi, -48(%rbp)         # save %rsi
        mov     %rbx, -56(%rbp)         # save %rbx     

        mov     %rcx, 16(%rbp)          # place the image handle in schadow space
        mov     %rdx, 24(%rbp)          # place the system table in shadow space
 
        call    efi_core_init           # initialize the EFI library
        call    efi_console_init        # initialize the EFI console.
        call    efi_console_clear       # clear the EFI console
 
        mov     $msg_welcome, %rcx      # pass the welcome message
        call    efi_console_print       # print the message

        mov     $msg_init_lib, %rcx     # pass the library init message
        call    efi_console_print_ok    # print that message
        
        mov     $msg_init_console, %rcx # pass the console init message.
        call    efi_console_print_ok    # print the message

        # Disable Watchdog Timer, otherwise EFI will reset after 5 minutes
        mov     $msg_watchdog_disable, %rcx     # the message to print
        call    print_progress_before           # print the progress before
        mov     BS(%rip), %rax                  # get the boot services
        mov     $0, %r9d                        # set all arguments to 0 to 
        mov     $0, %r8d                        # disable the watchdog timer
        mov     $0, %edx
        mov     $0, %ecx              
        call    *256(%rax)                      # set the timer
        mov     %rax, -64(%rbp)                 # store the result code
        test    %rax, %rax                      # test if the operation failed
        mov     $msg_watchdog_disable, %rcx     # put the message in %rcx.
        js      .failure                        # jump to failure
        call    efi_console_print_ok            # print success message

        # Locate Graphics Output Protocol (GOP)
        mov     $msg_init_gop, %rcx     # the message to print
        call    print_progress_before   # print the progress
        call    efi_gop_init            # locate GOP
        mov     %rax, -64(%rbp)         # store the result code.
        test    %rax, %rax              # test if the operation failed
        mov     $msg_init_gop, %rcx     # put the message in %rcx
        js      .failure                # jump to failure.
        call    efi_console_print_ok    # print success message.

        # Identify the Graphics Output Protocol.
        call    efi_gop_identify                # identify the protocol
        mov     GOP_FRAMEBUFFER(%rip), %r9      # get the framebuffer address
        mov     GOP_HEIGHT(%rip), %r8d          # get the display height
        mov     GOP_WIDTH(%rip), %edx           # get display width
        mov     $msg_gop_identify, %rcx         # pass the message
        call    efi_console_print_info          # print the info message
        
        # Locate Loaded Image Protocol (LIP)
        mov     $msg_init_lip, %rcx     # the message to print
        call    print_progress_before   # print the progress
        lea     32(%rbp), %rdx          # location to place the pointer
        mov     16(%rbp), %rcx          # this image
        call    efi_lip_init            # locate LIP
        mov     %rax, -64(%rbp)         # store the result code.
        test    %rax, %rax              # test if the operation failed
        mov     $msg_init_lip, %rcx     # put the message in %rcx
        js      .failure                # jump to failure.
        call    efi_console_print_ok    # print success message.
        
        # Obtain root directory of file system
        mov     32(%rbp), %rcx          # get the loaded image
        mov     24(%rcx), %rcx          # get the device handle
        call    efi_fs_root             # obtain root directory
        mov     %rax, -72(%rbp)         # save file pointer on the stack
        mov     $msg_fs_root, %rcx      # pass the message
        call    efi_console_print_ok    # print the message

        # Locate sprite file
        mov     $msg_sprite_open, %rcx  # the message to print
        call    print_progress_before   # print the progress
        mov     -72(%rbp), %rcx         # the device handle
        mov     $sprite_path, %rdx      # the path to the file
        call    sprites_open            # open the sprite
        mov     %rdx, -80(%rbp)         # save the file pointer
        mov     %rax, -64(%rbp)         # save the result code
        test    %rax, %rax              # did the operation fail
        mov     $msg_sprite_open, %rcx  # put the message in %rcx
        js      .failure                # jump to failure
        call    efi_console_print_ok    # print success message

        # Get sprite file information
        mov     -80(%rbp), %rcx         # get the file pointer
        call    efi_fs_info             # get the file information
        mov     %rax, -88(%rbp)         # save the pointer on the stack

        # Load the BMP sprite into a Blt buffer
        lea     -120(%rbp), %rax        # address to store the height
        mov     %rax, 32(%rsp)          # place it on the stack for the procedure
        lea     -112(%rbp), %r9         # address to store the width
        lea     -104(%rbp), %r8         # place the size of the buffer on the stack
        lea     -96(%rbp), %rdx         # place the address to the blt buffer on the stack
        mov     -80(%rbp), %rcx         # the file handle as first argument
        call    sprites_load_bmp        # load the bmp sprite.
        mov     %rax, -64(%rbp)         # save the result code
        test    %rax, %rax              # did the operation fail?
        
        mov     -120(%rbp), %rax        # get the height of the sprite
        mov     %rax, 32(%rsp)          # write last argument to stack
        mov     -112(%rbp), %r9         # width as fourth argument
        mov     -88(%rbp), %rdx         # get file information
        mov     8(%rdx), %r8            # file size as third argument
        lea     80(%rdx), %rdx          # file name as second argument
        mov     $msg_sprite_load, %rcx  # put the message in %rcx.
        
        js      .failure                # jump to failure
        call    efi_console_print_ok    # print success
        
        # Close the sprite file
        mov     -80(%rbp), %rcx         # get the file handle
        call    sprites_close           # close the sprite file
        
        # Close the root file
        mov     -72(%rbp), %rcx         # the root file to close
        call    efi_fs_close            # close the file
      
        # Calculate the delta of the sprite buffer
        mov     -112(%rbp), %rax        # get the with of the sprite buffer
        shl     $2, %rax                # calculate the size of a row
        mov     %rax, -128(%rbp)        # store the delta on the stack

        # Create a new timer to control the FPS
        # efi_event_create_timer(TimerPeriodic, 10000000, &TimerEvent);
        lea     -136(%rbp), %r8         # the location to store the timer
        mov     $500000, %rdx           # the time to wait per tick
        mov     EVT_TIMER_PERIODIC, %rcx# the type of timer
        call    efi_event_create_timer  # create the timer
        test    %rax, %rax              # test if it failed
        js      .failure                # jump to failure if so
          
        # Create a frame buffer to enable double buffering
        call    create_frame_buffer     # allocate a buffer
        mov     %rax, -144(%rbp)        # store the buffer on the stack
        mov     %rdx, -152(%rbp)        # store delta on the stack
        
        # Create a background frame
        lea     -168(%rbp), %r9         # the location to store the delta
        lea     -160(%rbp), %r8         # the location to store the buffer address
        mov     -128(%rbp), %rdx        # the delta of the sprite buffer
        mov     -96(%rbp), %rcx         # pointer to the sprite buffer
        call    create_background       # create the background frame
        
        # Create a floor frame
        lea     -184(%rbp), %r9         # the location to store the delta
        lea     -176(%rbp), %r8         # the location to store the buffer address
        mov     -128(%rbp), %rdx        # the delta of the sprite buffer
        mov     -96(%rbp), %rcx         # pointer to the sprite buffer
        call    create_floor            # create the floor frame
        
        movq    $0, -192(%rbp)          # set the counter to zero
        movq    $0, -216(%rbp)          # set the last score to zero
.start_loop:        
        # Draw the background to the buffer
        mov     -192(%rbp), %rax        # get the offset
        shr     $5, %rax                # slow down this offset
        mov     %rax, 32(%rsp)          # the background offset
        mov     -168(%rbp), %r9         # the background buffer delta
        mov     -160(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_background         # draw the background
                
        # Draw the logo
        movq    $0, 48(%rsp)            # the image to draw 
        movq    $100, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the logo
        
        # Draw the bird to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shr     $2, %rax                # slow bird down
        mov     %rax, 48(%rsp)          # the bird to draw
        movq    $250, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_bird               # draw the bird
        
        # Draw the score to the buffer
        #mov     -192(%rbp), %rax        # get the counter
        #movq    %rax, 48(%rsp)          # the decimal to draw 
        #movq    $150, 40(%rsp)          # the y-coordinate
        #movq    $400, 32(%rsp)          # the x-coordinate
        #mov     -128(%rbp), %r9         # the sprite buffer delta
        #mov     -96(%rbp), %r8          # the sprite buffer 
        #mov     -152(%rbp), %rdx        # the delta of the buffer
        #mov     -144(%rbp), %rcx        # the buffer to draw to
        #call    draw_integer            # draw the score
        
        # Draw the floor to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shl     $1, %rax                # should be going faster
        mov     %rax, 32(%rsp)          # the background offset
        mov     -184(%rbp), %r9         # the background buffer delta
        mov     -176(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_floor              # draw the floor
 
        mov     -152(%rbp), %rax        # the delta of that buffer
        mov     %rax, 56(%rsp)          # the delta of the blt buffer
        movq    $600, 48(%rsp)          # the height to draw
        movq    $800, 40(%rsp)          # the width to draw
        movq    $0, 32(%rsp)            # the destination y-coordinate 
        mov     $0, %r9                 # the destination x-coordinate
        mov     $0, %r8                 # the source y-coordinate 
        mov     $0, %rdx                # the source x-coordinate
        mov     -144(%rbp), %rcx        # the buffer to read from
        call    efi_gop_blt             # blit the buffer to screen
        
        # Wait for the tick
        # efi_event_wait(1, &TimerEvent, &index);
        lea     -200(%rbp), %r8         # the location to store the event index
        lea     -136(%rbp), %rdx        # get the timer event
        mov     $1, %rcx                # the amount 
        call    efi_event_wait          # wait for the event
        
        add     $1, -192(%rbp)          # add one to the counter
        
        # Read the input
        lea     -208(%rbp), %rcx        # the location to store the key code
        call    efi_console_read        # read the key code
        
        # Test the input 
        cmpb    $0x20, -206(%rbp)       # do we want to start (space)
        jne     .start_loop             # loop otherwise
.get_ready:
        movq    $0, -224(%rbp)          # reset the score
        mov     $96, %r12               # set counter to 5 * 16
.ready_loop:
        # Draw the background to the buffer
        mov     -192(%rbp), %rax        # get the offset
        shr     $5, %rax                # slow down this offset
        mov     %rax, 32(%rsp)          # the background offset
        mov     -168(%rbp), %r9         # the background buffer delta
        mov     -160(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_background         # draw the background
        
        # Draw the get ready image
        movq    $2, 48(%rsp)            # the image to draw 
        movq    $100, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the image

        # Draw the bird to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shr     $2, %rax                # slow bird down
        mov     %rax, 48(%rsp)          # the bird to draw
        movq    $250, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_bird               # draw the bird

        # Draw the timer to the buffer
        mov     %r12, %rax              # get the timer
        shr     $4, %rax                # slow it down
        mov     %rax, 48(%rsp)          # the decimal to draw
        movq    $175, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_integer            # draw the timer

        # Draw the floor to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shl     $1, %rax                # should be going faster
        mov     %rax, 32(%rsp)          # the background offset
        mov     -184(%rbp), %r9         # the background buffer delta
        mov     -176(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_floor              # draw the floor

        mov     -152(%rbp), %rax        # the delta of that buffer
        mov     %rax, 56(%rsp)          # the delta of the blt buffer
        movq    $600, 48(%rsp)          # the height to draw
        movq    $800, 40(%rsp)          # the width to draw
        movq    $0, 32(%rsp)            # the destination y-coordinate 
        mov     $0, %r9                 # the destination x-coordinate
        mov     $0, %r8                 # the source y-coordinate 
        mov     $0, %rdx                # the source x-coordinate
        mov     -144(%rbp), %rcx        # the buffer to read from
        call    efi_gop_blt             # blit the buffer to screen

        # Wait for the tick
        # efi_event_wait(1, &TimerEvent, &index);
        lea     -200(%rbp), %r8         # the location to store the event index
        lea     -136(%rbp), %rdx        # get the timer event
        mov     $1, %rcx                # the amount 
        call    efi_event_wait          # wait for the event

        add     $1, -192(%rbp)          # add one to the counter
        sub     $1, %r12                # subtract one to the other counter
        
        cmp     $0, %r12                # test if %r12 has reached zero
        jge     .ready_loop             # jump back if zero or not yet
        
        call    efi_console_clear_input # clear the input
        mov     %rax, -64(%rbp)         # save the result
        test    %rax, %rax              # did the operation fail?
        js      .failure                # jump to exit if it did
        
        mov     GOP_HEIGHT(%rip), %r12d # the y at which the bird dies
        sub     $112, %r12              # subtract the height of the floor
        sub     $16, %r12               # subtract half the bird height
        mov     GOP_WIDTH(%rip), %r15d  # put the width in %r15d
        shr     $1, %r15                # half the width 
        mov     $1, %rdi                # the acceleration
        mov     $0, %rsi                # the velocity
        mov     $250, %rbx              # the y-coordinate
        
        mov     $0, %r13                # the last pipe counter
        mov     $0, %r14                # the middle pipe counter
        movw    $234, -230(%rbp)        # the height of the downwards pipe
        movw    $1430, -232(%rbp)       # the x-offset of the pipe
        movw    $270, -234(%rbp)        # the height of the downwards pipe
        movw    $1279, -236(%rbp)       # the x-offset of the pipe
        movw    $230, -238(%rbp)        # the height of the downwards pipe
        movw    $1092, -240(%rbp)       # the x-offset of the pipe
        movw    $247, -242(%rbp)        # the height of the downwards pipe
        movw    $852, -244(%rbp)        # the x-offset of the pipe
.game_loop:
        add     %rdi, %rsi              # v(n) = v(n - 1) + a(n)
        add     %rsi, %rbx              # y(n) = y(n - 1) + v(n)
        
        # Draw the background to the buffer
        mov     -192(%rbp), %rax        # get the offset
        shr     $5, %rax                # slow down this offset
        mov     %rax, 32(%rsp)          # the background offset
        mov     -168(%rbp), %r9         # the background buffer delta
        mov     -160(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_background         # draw the background
        
        cmp     $-16, %rbx              # don't draw the bird if
        jl      .no_bird_game           # it is out of bounds
        
        # Draw the bird to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shr     $2, %rax                # slow bird down
        mov     %rax, 48(%rsp)          # the bird to draw
        movq    %rbx, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_bird               # draw the bird
.no_bird_game:
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        movw    -230(%rbp), %r9w        # get the y-coordinate
        mov     %r9, 224(%rbp)      
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        movw    -232(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -230(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -232(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        mov     -234(%rbp), %r9w        # get the y-coordinate
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -236(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -234(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -236(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        movw    -238(%rbp), %r9w        # get the y-coordinate
        mov     %r9, 224(%rbp)      
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        movw    -240(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -238(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -240(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        movw    -242(%rbp), %r9w        # get the y-coordinate
        mov     %r9, 224(%rbp)      
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        movw    -244(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -242(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -244(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        
        # Draw the score to the buffer
        mov     -224(%rbp), %rax        # get the counter
        mov     %rax, 48(%rsp)          # the decimal to draw 
        movq    $175, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_integer            # draw the score

        # Draw the floor to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shl     $1, %rax                # should be going faster
        mov     %rax, 32(%rsp)          # the background offset
        mov     -184(%rbp), %r9         # the background buffer delta
        mov     -176(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_floor              # draw the floor

        # Blit the buffer to screen
        mov     -152(%rbp), %rax        # the delta of that buffer
        mov     %rax, 56(%rsp)          # the delta of the blt buffer
        movq    $600, 48(%rsp)          # the height to draw
        movq    $800, 40(%rsp)          # the width to draw
        movq    $0, 32(%rsp)            # the destination y-coordinate 
        mov     $0, %r9                 # the destination x-coordinate
        mov     $0, %r8                 # the source y-coordinate 
        mov     $0, %rdx                # the source x-coordinate
        mov     -144(%rbp), %rcx        # the buffer to read from
        call    efi_gop_blt             # blit the buffer to screen

        # Wait for the tick
        # efi_event_wait(1, &TimerEvent, &index);
        lea     -200(%rbp), %r8         # the location to store the event index
        lea     -136(%rbp), %rdx        # get the timer event
        mov     $1, %rcx                # the amount 
        call    efi_event_wait          # wait for the event

        add     $1, -192(%rbp)          # add one to the counter

        # Read the input
        lea     -208(%rbp), %rcx        # the location to store the key code
        call    efi_console_read        # read the key code

        # The new acceleration
        mov     $1, %rdi                # set the new acceleration
        
        # Test the input 
        cmpb    $0x20, -206(%rbp)       # do we want to jump
        jne     .test_die               # jump to the die test
        mov     $-7, %rdi               # accelerate up
.test_die:  
        # Test if we hit the floor
        cmp     %rbx, %r12              # did we die
        jle     .die                    # if so, go to dead screen
        
        # Test if we hit the pipes
        xor     %rdx, %rdx              # clear %rdx
        lea     -244(%rbp), %rax        # the base pointer
        lea     (%rax, %r14, 4), %rax   # the current middle pipe
        mov     %r15, %rcx              # get the bird x-offset
        sub     $17, %rcx               # subtract half the bird width.
        xor     %r9, %r9                # clear %r9
        mov     (%rax), %r9w            # get the current x-offset of the pipe
        add     $26, %r9                # add half the width of the pipe
        cmp     %rcx, %r9               # has the pipe passed the bird
        jl      .score                  # then loop
        add     $34, %rcx               # add 32 to the bird x-coordinate
        sub     $52, %r9                # subtract 52 from pipe coordinate
        cmp     %rcx, %r9               # test if the x-coordinate of the pipe is greater
        jg      .prepare_game_next      # then loop
        
        xor     %r9, %r9                # clear %r9
        mov     2(%rax), %r9w           # get the height of the downward pipe
        mov     %rbx, %rax              # copy %rbx to %rax
        #sub     $16, %rax              # subtract half the height of the bird to %rax.
        cmp     %r9, %rax               # the bird should be lower than the pipe y-bound
        jle     .die                    # die if the bird touches the pipe
        add     $80, %r9                # an offset of 80 pixels
        #add     $32, %rax              # add the height of the bird to %rax
        cmp     %r9, %rax               # the bird should be higher then the lower pipe upper y-bound
        jge     .die                    # die if the bird touches the pipe
        
        jmp     .prepare_game_next      # loop
.score:
        xor     %rdx, %rdx              # clear %rdx
        add     $1, %r14                # add one to the middle pipe index
        and     $3, %r14                # index % 4
        add     $1, -224(%rbp)          # score a point!
.prepare_game_next:
        # Move the pipes to the left
        subw    $2, -232(%rbp)        # the x-offset of the pipe
        subw    $2, -236(%rbp)        # the x-offset of the pipe
        subw    $2, -240(%rbp)        # the x-offset of the pipe
        subw    $2, -244(%rbp)        # the x-offset of the pipe
        
        # Test if the pipe goes out of bounds.
        xor     %rdx, %rdx              # clear %rdx
        lea     -244(%rbp), %rax        # the base pointer
        lea     (%rax, %r13, 4), %rax   # the current first pipe
        xor     %r9, %r9                # clear %r9
        mov     (%rax), %r9w            # get the x-offset
        cmp     $-26, %r9w              # check if the pipe goes out of bounds
        jg      .game_loop              # loop if not out of bounds
        movw    $1000, (%rax)           # reset the pipe
        add     $1, %r13                # add one to the first pipe index
        and     $3, %r13                # index % 4
        jmp     .game_loop              # loop
.die:
        mov     -224(%rbp), %rax        # get the score
        mov     -216(%rbp), %rcx        # get the highscore
        cmp     %rcx, %rax              # is it a new highscore
        cmovg   %rax, %rcx              # set the new highscore
        mov     %rcx, -216(%rbp)        # save it on stack
.died:
        # Draw the background to the buffer
        mov     -192(%rbp), %rax        # get the offset
        shr     $5, %rax                # slow down this offset
        mov     %rax, 32(%rsp)          # the background offset
        mov     -168(%rbp), %r9         # the background buffer delta
        mov     -160(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_background         # draw the background

        cmp     $-16, %rbx              # don't draw the bird if
        jl      .no_bird_died           # it is out of bounds
        
        # Draw the bird to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shr     $2, %rax                # slow bird down
        mov     %rax, 48(%rsp)          # the bird to draw
        movq    %rbx, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_bird               # draw the bird
.no_bird_died:
        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        movw    -230(%rbp), %r9w        # get the y-coordinate
        mov     %r9, 224(%rbp)      
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        movw    -232(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -230(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -232(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        mov     -234(%rbp), %r9w        # get the y-coordinate
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -236(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -234(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -236(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        movw    -238(%rbp), %r9w        # get the y-coordinate
        mov     %r9, 224(%rbp)      
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        movw    -240(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -238(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -240(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $4, 48(%rsp)            # the image to draw
        movw    -242(%rbp), %r9w        # get the y-coordinate
        mov     %r9, 224(%rbp)      
        sub     $135, %r9               # subtract half the height
        mov     %r9, 40(%rsp)           # set the y-coordinate
        movw    -244(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe

        # Draw the pipes
        xor     %r9, %r9                # clear %r9
        movq    $5, 48(%rsp)            # the image to draw
        mov     -242(%rbp), %r9w        # get the y-coordinate
        add     $121, %r9               # subtract half the height
        add     $80, %r9                # add the offset between the pipes
        mov     %r9, 40(%rsp)           # set the y-coordinate
        mov     -244(%rbp), %r9w        # get the x-coordinate
        mov     %r9, 32(%rsp)           # set the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the downward pipe
        # Draw the game over image
        movq    $1, 48(%rsp)            # the image to draw 
        movq    $100, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the image
        
        # Draw the scoreboard image
        movq    $3, 48(%rsp)            # the image to draw 
        movq    $250, 40(%rsp)          # the y-coordinate
        movq    $400, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the image
        
        # Draw the score to the buffer
        mov     -224(%rbp), %rax        # get the counter
        mov     %rax, 48(%rsp)          # the decimal to draw 
        movq    $236, 40(%rsp)          # the y-coordinate
        movq    $470, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_integer            # draw the score
        
        # Draw the highscore to the buffer
        mov     -216(%rbp), %rax        # get the counter
        mov     %rax, 48(%rsp)          # the decimal to draw 
        movq    $279, 40(%rsp)          # the y-coordinate
        movq    $474, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_integer            # draw the score
        
        # Draw the coin image
        movq    $12, 48(%rsp)           # the image to draw 
        movq    $257, 40(%rsp)          # the y-coordinate
        movq    $335, 32(%rsp)          # the x-coordinate
        mov     -128(%rbp), %r9         # the sprite buffer delta
        mov     -96(%rbp), %r8          # the sprite buffer 
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_image              # draw the image
        
        # Draw the floor to the buffer
        mov     -192(%rbp), %rax        # get the counter
        shl     $1, %rax                # should be going faster
        mov     %rax, 32(%rsp)          # the background offset
        mov     -184(%rbp), %r9         # the background buffer delta
        mov     -176(%rbp), %r8         # the background to draw
        mov     -152(%rbp), %rdx        # the delta of the buffer
        mov     -144(%rbp), %rcx        # the buffer to draw to
        call    draw_floor              # draw the floor

        # Blit the buffer to screen
        mov     -152(%rbp), %rax        # the delta of that buffer
        mov     %rax, 56(%rsp)          # the delta of the blt buffer
        movq    $600, 48(%rsp)          # the height to draw
        movq    $800, 40(%rsp)          # the width to draw
        movq    $0, 32(%rsp)            # the destination y-coordinate 
        mov     $0, %r9                 # the destination x-coordinate
        mov     $0, %r8                 # the source y-coordinate 
        mov     $0, %rdx                # the source x-coordinate
        mov     -144(%rbp), %rcx        # the buffer to read from
        call    efi_gop_blt             # blit the buffer to screen
        
        # Now wait for a keystroke before continuing, otherwise your
        # message will flash off the screen before you see it.
        #
        # First, we need to empty the console input buffer to flush
        # out any keystrokes entered before this point 
        call    efi_console_clear_input # clear the input
        mov     %rax, -64(%rbp)         # save the result
        test    %rax, %rax              # did the operation fail?
        js      .failure                # jump to exit if it did
        
        # Wait for a key event.
        mov     $0, %edx                # timeout of the event. 0 means no timeout.
        mov     STDIN(%rip), %rcx       # get the standard input
        mov     16(%rcx), %rcx          # the STDIN->WaitForKey event
        call    efi_event_wait_single   # wait for that event
        
        jmp     .get_ready              # go again!
        
        # Unload the sprite buffer
        mov     -96(%rbp), %rcx         # get the address of the blt buffer
        call    sprites_unload          # unload the sprite
.failure:
        call    efi_console_print_fail  # print the message.
        mov     -64(%rbp), %r8          # load the error code in %r8
        mov     %r8, %rdx               # also load it in %rdx
        mov     $msg_err, %rcx          # load the message
        call    efi_console_print       # print the error code.
        
       
        # Now wait for a keystroke before continuing, otherwise your
        # message will flash off the screen before you see it.
        #
        # First, we need to empty the console input buffer to flush
        # out any keystrokes entered before this point 
        call    efi_console_clear_input # clear the input
        mov     %rax, -64(%rbp)         # save the result
        test    %rax, %rax              # did the operation fail?
        js      .failure                # jump to exit if it did
        
        # Wait for a key event.
        mov     $0, %edx                # timeout of the event. 0 means no timeout.
        mov     ST(%rip), %rcx          # get the system table
        mov     48(%rcx), %rcx          # table->ConIn
        mov     16(%rcx), %rcx          # table->ConIn->WaitForKey event
        call    efi_event_wait_single   # wait for that event
.exit:
        mov     -8(%rbp), %r12          # restore %r12
        mov     -16(%rbp), %r13         # restore %r13
        mov     -24(%rbp), %r14         # restore %r14
        mov     -32(%rbp), %r15         # restore %r15
        mov     -40(%rbp), %rdi         # restore %rdi
        mov     -48(%rbp), %rsi         # restore %rsi
        mov     -56(%rbp), %rbx         # restore %rbx
        mov     -64(%rbp), %rax         # return the result
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
        
# Print the progress before a step, indicating that we are waiting on this step to finish.
#
# parameters:
#       - %rcx: The ascii format string.
#       - %rdx, %r8, %r9: the arguments to print.
# returns:
#       - %rax: the status code.
print_progress_before:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space
         
        call    efi_console_print_wait  # print the message given
        
        mov     $-1, %rdx               # move the cursor one up
        mov     $0, %rcx                # don't mover the cursor vertically
        call    efi_console_move_cursor # move the cursor
    
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
        
# Allocate a framebuffer to draw to
#
# returns:
#       - %rax: the pointer to the allocated framebuffer.
#       - %rdx: the bytes per row in the buffer
create_frame_buffer:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $32, %rsp               # allocate 32 bytes of shadow space
        
        mov     GOP_WIDTH(%rip), %edx   # get the width of the screen
        shl     $2, %rdx                # double the width
        shl     $2, %rdx                # 4 bytes per pixel
        mov     %rdx, 16(%rbp)          # save result in shadow space
        mov     GOP_HEIGHT(%rip), %ecx  # get the height of the screen
        imul    %edx, %ecx              # multiply both
        call    efi_core_alloc          # allocate the buffer
        
        mov     16(%rbp), %rdx          # also return delta
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Create a background blt buffer.
#
# parameters:
#       - %rcx: the pointer to the sprite buffer.
#       - %rdx: the delta of a row in the sprite buffer.
#       - %r8: the location to store the buffer.
#       - %r9: the location to store the delta
# returns:
#       - %rax: the status code.
create_background:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $288, %rsp              # reserve 288 bytes of stack space
        
        mov     %rcx, 16(%rbp)          # save the blt buffer pointer in shadow space
        mov     %rdx, 24(%rbp)          # save the width of the sprite in shadow space
        mov     %r8, 32(%rbp)           # save the location to store the result

        mov     %r12, -8(%rbp)          # save %r12
        mov     %r13, -16(%rbp)         # save %r13
        mov     %r14, -24(%rbp)         # save %r14
        mov     %r15, -32(%rbp)         # save %r15
        mov     %rdi, -40(%rbp)         # save %rdi
        mov     %rsi, -48(%rbp)         # save %rsi
        mov     %rbx, -56(%rbp)         # save %rbx

        mov     $288, %rdi              # the width of the background
        mov     $202, %rsi              # the height of the background
        mov     GOP_WIDTH(%rip), %r14d  # the width of the screen.
        mov     GOP_HEIGHT(%rip), %r15d # the height of the screen

        xor     %rdx, %rdx              # clear upper bits
        mov     %r14, %rax              # the number to divide
        idiv    %rdi                    # divide by the width of the sprite
        mov     %rax, -80(%rbp)         # save the amount of parts to draw
        sub     %rdi, %rdx              # subtract the width of the background from it
        neg     %rdx                    # negate result

        mov     %r14, %rax              # get the width of the screen
        add     %rdx, %rax              # add remainder to it.
        add     %rdi, %rax              # add the width of the background to it
        mov     %rax, -88(%rbp)         # save the width on the stack
        mov     %rax, %r14              # save the width
        shl     $2, %rax                # 4 bytes per pixel
        mov     %rax, (%r9)             # store the result for the user
        mov     %rax, %r13              # save the delta in %r13
        mov     %r15, %rcx              # get the height of the screen
        imul    %rcx, %rax              # multiply the two
        mov     %rax, -88(%rbp)         # save the result on the stack
        mov     %rax, %rcx              # move %rax in %rcx
        call    efi_core_alloc          # allocate the buffer
        mov     32(%rbp), %r8           # get the location to store the result
        mov     %rax, (%r8)             # store the pointer
        mov     %rax, %r12              # move %rax to %r12

        # Draw the background color
        mov     %r13, 48(%rsp)          # the delta of the buffer to fill
        mov     %r15, 40(%rsp)          # set the height of the rectangle to fill
        mov     %r14, 32(%rsp)          # set the width of the rectangle to fill
        mov     $0, %r9                 # the start y-coordinate
        mov     $0, %r8                 # the start x-coordinate
        mov     %r12, %rdx              # the buffer to fill
        mov     $0x0073b7c4, %rcx       # the pixel to fill the rectangle with
        call    efi_gop_fill_buffer     # fill the background

        # Draw the pieces
        mov     $0, %rbx                # initialize the counter
.bg_loop:
        movq    $206, 72(%rsp)          # the height to draw
        mov     %rdi, 64(%rsp)          # the width to draw
        mov     %r15, %rax              # get the y-coordinate
        sub     $206, %rax              # subtract the sprite height from it
        mov     %rax, 56(%rsp)          # the destination y-coordinate 
        mov     %rbx, 48(%rsp)          # the destination x-coordinate
        movq    $306, 40(%rsp)          # the source y-coordinate
        movq    $0, 32(%rsp)            # the source x-coordinate
        mov     %r13, %r9               # the destination delta 
        mov     %r12, %r8               # the destination buffer
        mov     24(%rbp), %rdx          # the delta of the sprite buffer
        mov     16(%rbp), %rcx          # the sprite buffer
        call    efi_gop_copy            # copy the sprite to the buffer
.bg_next:
        add     %rdi, %rbx              # add width to the counter
.bg_condition:
        cmp     %r14, %rbx              # compare the counter to the upper limit
        jl      .bg_loop                # if smaller, then loop.

        mov     -8(%rbp), %r12          # restore %r12
        mov     -16(%rbp), %r13         # restore %r13
        mov     -24(%rbp), %r14         # restore %r14
        mov     -32(%rbp), %r15         # restore %r15
        mov     -40(%rbp), %rdi         # restore %rdi
        mov     -48(%rbp), %rsi         # restore %rsi
        mov     -56(%rbp), %rbx         # restore %rbx
 
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller
        
# Copy a part of the background buffer into our framebuffer.
#
# parameters:
#       - %rcx: the framebuffer to copy the background to.
#       - %rdx: the delta of the framebuffer
#       - %r8: the background buffer
#       - %r9: the background buffer delta
#       - 32(%rsp): the x-offset for the background
draw_background:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # allocate 128 bytes of stack space
        
        mov     %rcx, 16(%rbp)          # save the framebuffer address on the stack
        mov     %rdx, 24(%rbp)          # save the framebuffer delta on the stack
        mov     %r8, 32(%rbp)           # save the background buffer in shadow space
        mov     %r9, 40(%rbp)           # save the background delta in shadow space
        
        
        xor     %rdx, %rdx              # clear upper bits
        mov     48(%rbp), %rax          # get the x-offset for the background
        mov     $288, %rcx              # the divisor
        idiv    %rcx                    # divide the offset by the width
        
        mov     GOP_HEIGHT(%rip), %eax  # get the screen height
        mov     %rax, 72(%rsp)          # the height to draw
        mov     GOP_WIDTH(%rip), %eax   # get the screen width
        mov     %rax, 64(%rsp)          # the width to draw
        movq    $0, 56(%rsp)            # the destination y-coordinate 
        movq    $0, 48(%rsp)            # the destination x-coordinate
        movq    $0, 40(%rsp)            # the source y-coordinate
        mov     %rdx, 32(%rsp)          # the source x-coordinate
        mov     24(%rbp), %r9           # the destination delta 
        mov     16(%rbp), %r8           # the destination buffer
        mov     40(%rbp), %rdx          # the delta of the sprite buffer
        mov     32(%rbp), %rcx          # the sprite buffer
        call    efi_gop_copy            # copy the sprite to the buffer
        
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller
        
# Create the floor buffer.
#
# parameters:
#       - %rcx: the pointer to the sprite buffer.
#       - %rdx: the size of a row in the buffer
#       - %r8: the location to store the buffer address
#       - %r9: the location to store the buffer delta
# returns:
#       - %rax: the status code.
create_floor:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $288, %rsp              # reserve 288 bytes of stack space
    
        mov     %rcx, 16(%rbp)          # save the blt buffer pointer in shadow space
        mov     %rdx, 24(%rbp)          # save the width of the sprite in shadow space
        mov     %r8, 32(%rbp)           # save the location to store the result

        mov     %r12, -8(%rbp)          # save %r12
        mov     %r13, -16(%rbp)         # save %r13
        mov     %r14, -24(%rbp)         # save %r14
        mov     %r15, -32(%rbp)         # save %r15
        mov     %rdi, -40(%rbp)         # save %rdi
        mov     %rsi, -48(%rbp)         # save %rsi
        mov     %rbx, -56(%rbp)         # save %rbx

        mov     $308, %rdi              # the width of the background
        mov     $112, %rsi              # the height of the background
        mov     GOP_WIDTH(%rip), %r14d  # the width of the screen.

        xor     %rdx, %rdx              # clear upper bits
        mov     %r14, %rax              # the number to divide
        idiv    %rdi                    # divide by the width of the sprite
        mov     %rax, -80(%rbp)         # save the amount of parts to draw
        sub     %rdi, %rdx              # subtract the width of the background from it
        neg     %rdx                    # negate result

        mov     %r14, %rax              # get the width of the screen
        add     %rdx, %rax              # add remainder to it.
        add     %rdi, %rax              # add the width of the background to it
        mov     %rax, -88(%rbp)         # save the width on the stack
        mov     %rax, %r14              # save the width
        shl     $2, %rax                # 4 bytes per pixel
        mov     %rax, (%r9)             # store the result for the user
        mov     %rax, %r13              # save the delta in %r13
        mov     %rsi, %rcx              # get the height of the sprite
        imul    %rcx, %rax              # multiply the two
        mov     %rax, -88(%rbp)         # save the result on the stack
        mov     %rax, %rcx              # move %rax in %rcx
        call    efi_core_alloc          # allocate the buffer
        mov     32(%rbp), %r8           # get the location to store the result
        mov     %rax, (%r8)             # store the pointer
        mov     %rax, %r12              # move %rax to %r12

        # Draw remaining pieces
        mov     $0, %rbx                # initialize the counter
.floor_loop:
        movq    %rsi, 72(%rsp)          # the height to draw
        mov     %rdi, 64(%rsp)          # the width to draw
        movq    $0, 56(%rsp)            # the destination y-coordinate 
        mov     %rbx, 48(%rsp)          # the destination x-coordinate
        movq    $0, 40(%rsp)            # the source y-coordinate
        movq    $580, 32(%rsp)          # the source x-coordinate
        mov     %r13, %r9               # the destination delta 
        mov     %r12, %r8               # the destination buffer
        mov     24(%rbp), %rdx          # the delta of the sprite buffer
        mov     16(%rbp), %rcx          # the sprite buffer
        call    efi_gop_copy            # copy the sprite to the buffer
.floor_next:
        add     %rdi, %rbx              # add width to the counter
.floor_condition:
        cmp     %r14, %rbx              # compare the counter to the upper limit
        jl      .floor_loop             # if bigger or equal, then loop.

        mov     -8(%rbp), %r12          # restore %r12
        mov     -16(%rbp), %r13         # restore %r13
        mov     -24(%rbp), %r14         # restore %r14
        mov     -32(%rbp), %r15         # restore %r15
        mov     -40(%rbp), %rdi         # restore %rdi
        mov     -48(%rbp), %rsi         # restore %rsi
        mov     -56(%rbp), %rbx         # restore %rbx

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller
        
# Copy a part of the floor buffer into our framebuffer.
#
# parameters:
#       - %rcx: the framebuffer to copy the background to.
#       - %rdx: the delta of the framebuffer
#       - %r8: the floor buffer
#       - %r9: the floor buffer delta
#       - 32(%rsp): the x-offset for the floor.
draw_floor:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # allocate 128 bytes of stack space

        mov     %rcx, 16(%rbp)          # save the framebuffer address on the stack
        mov     %rdx, 24(%rbp)          # save the framebuffer delta on the stack
        mov     %r8, 32(%rbp)           # save the floor buffer in shadow space
        mov     %r9, 40(%rbp)           # save the floor delta in shadow space

        xor     %rdx, %rdx              # clear upper bits
        mov     48(%rbp), %rax          # get the x-offset for the floor
        mov     $308, %rcx              # the divisor
        idiv    %rcx                    # divide the offset by the width

        movq    $112, 72(%rsp)          # the height to draw
        mov     GOP_WIDTH(%rip), %eax   # get the screen width
        mov     %rax, 64(%rsp)          # the width to draw
        mov     GOP_HEIGHT(%rip), %eax  # get the screen height
        sub     $112, %rax              # subtract the height of the floor
        mov     %rax, 56(%rsp)          # the destination y-coordinate 
        movq    $0, 48(%rsp)            # the destination x-coordinate
        movq    $0, 40(%rsp)            # the source y-coordinate
        mov     %rdx, 32(%rsp)          # the source x-coordinate
        mov     24(%rbp), %r9           # the destination delta 
        mov     16(%rbp), %r8           # the destination buffer
        mov     40(%rbp), %rdx          # the delta of the sprite buffer
        mov     32(%rbp), %rcx          # the sprite buffer
        call    efi_gop_copy            # copy the sprite to the buffer

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller

# Draw an image to the framebuffer.
#
# parameters:
#       - %rcx: the framebuffer to copy the image to.
#       - %rdx: the delta of the framebuffer.
#       - %r8: the pointer to the sprite buffer.
#       - %r9: the size of a row in the buffer.
#       - 32(%rsp): the x-coordinate to draw it.
#       - 40(%rsp): the y-coordinate to draw it.
#       - 48(%rsp): the image to draw.
# returns:
#       - %rax: the status code.
draw_image:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # reserve 128 bytes of stack space

        mov     %rcx, 16(%rbp)          # save the framebuffer pointer in shadow space
        mov     %rdx, 24(%rbp)          # save the width of the buffer in shadow space
        mov     %r8, 32(%rbp)           # save the sprite buffer in shadow space
        mov     %r9, 40(%rbp)           # save the sprite buffer delta in shadow space

        mov     64(%rbp), %r10          # get the image to draw
        shl     $1, %r10                # multiply by 2

        # Draw the image
        movq    $0xFF00FF, 80(%rsp)     # set the mask color
        mov     $images, %rcx           # the array of coordinates and size
        mov     4(%rcx, %r10, 8), %eax  # the height of the image
        mov     %rax, 72(%rsp)          # set the height of the image
        mov     (%rcx, %r10, 8), %edx   # the width of the image
        mov     %rdx, 64(%rsp)          # the width of the sprite to display
        shr     $1, %rax                # half the height of the image
        mov     56(%rbp), %r8           # get the destination y-coordinate
        sub     %rax, %r8               # subtract half the height from it
        mov     %r8, 56(%rsp)           # the destination y-coordinate
        shr     $1, %rdx                # half the width
        mov     48(%rbp), %rax          # the destination x-coordinate
        sub     %rdx, %rax              # subtract half the width from it
        mov     %rax, 48(%rsp)          # write it to stack
        mov     12(%rcx, %r10, 8), %eax # get the source y-coordinate
        mov     %rax, 40(%rsp)          # write it to the stack
        mov     8(%rcx, %r10, 8), %eax  # get the source x-coordinate
        mov     %rax, 32(%rsp)          # write it to the stack
        mov     24(%rbp), %r9           # the destination delta 
        mov     16(%rbp), %r8           # the destination buffer
        mov     40(%rbp), %rdx          # the delta of the sprite buffer
        mov     32(%rbp), %rcx          # the sprite buffer
        call    efi_gop_copy_mask       # do a masked copy
        
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller

images:
        # The Flappy Bird logo
        .long   192                     # the width of the logo
        .long   44                      # the height of the logo
        .long   580                     # the x-offset of the logo
        .long   346                     # the y-offset of the logo
        # The Game Over image
        .long   188                     # the width of the image
        .long   38                      # the height of the image
        .long   580                     # the x-offset of the image
        .long   398                     # the y-offset of the image
        # The Get Ready image
        .long   174                     # the width of the image
        .long   45                      # the height of the image
        .long   580                     # the x-offset of the image
        .long   442                     # the y-offset of the image
        # The scoreboard image
        .long   226                     # the width of the image
        .long   116                     # the height of the image
        .long   580                     # the x-offset of the image
        .long   116                     # the y-offset of the image
        # The downward pipe
        .long   52                      # the width of the image
        .long   270                     # the height of the image
        .long   892                     # the x-offset of the image
        .long   0                       # the y-offset of the image
        # The upward pipe
        .long   52                      # the width of the image
        .long   242                     # the height of the image
        .long   948                     # the x-offset of the image
        .long   0                       # the y-offset of the image
        # The bird state 1
        .long   34                      # the width of the bird
        .long   32                      # the height of the bird
        .long   816                     # the source x-coordinate
        .long   180                     # the source y-coordinate
        # The bird state 2
        .long   34                      # the width of the bird
        .long   32                      # the height of the bird
        .long   816                     # the source x-coordinate
        .long   128                     # the source y-coordinate
        # The bird state 3
        .long   34                      # the width of the bird
        .long   32                      # the height of the bird
        .long   734                     # the source x-coordinate
        .long   248                     # the source y-coordinate
        # The bird state 4
        .long   34                      # the width of the bird
        .long   32                      # the height of the bird
        .long   816                     # the source x-coordinate
        .long   180                     # the source y-coordinate
        # The bronze coin
        .long   44                      # the width of the coin
        .long   44                      # the height of the coin
        .long   892                     # the source x-coordinate
        .long   274                     # the source y-coordinate
        # The silver coin
        .long   44                      # the width of the coin
        .long   44                      # the height of the coin
        .long   820                     # the source x-coordinate
        .long   458                     # the source y-coordinate
        # The gold coin                 
        .long   44                      # the width of the coin
        .long   44                      # the height of the coin
        .long   772                     # the source x-coordinate
        .long   458                     # the source y-coordinate
        # The platina coin
        .long   44                      # the width of the coin
        .long   44                      # the height of the coin
        .long   728                     # the source x-coordinate
        .long   288                     # the source y-coordinate

# Draw the bird to the given framebuffer.
#
# parameters:
#       - %rcx: the framebuffer to copy the image to.
#       - %rdx: the delta of the framebuffer.
#       - %r8: the pointer to the sprite buffer.
#       - %r9: the size of a row in the buffer.
#       - 32(%rsp): the x-coordinate to draw it.
#       - 40(%rsp): the y-coordinate to draw it.
#       - 48(%rsp): the state of the bird.
# returns:
#       - %rax: the status code.
draw_bird:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $96, %rsp               # reserve 96 bytes of stack space

        mov     64(%rbp), %r10          # get the state of the bird
        and     $1, %r10                # 2 possible states
        add     $6, %r10                # the first bird is at location 6
        mov     %r10, 48(%rsp)          # the bird state to draw
        mov     56(%rbp), %rax          # get the y-offset
        mov     %rax, 40(%rsp)          # write it to the stack
        mov     48(%rbp), %rax          # get the x-offset
        mov     %rax, 32(%rsp)          # write it to the stack
        call    draw_image              # draw the bird image

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller

# Draw a decimal value to a framebuffer.
#
# parameters:
#       - %rcx: the framebuffer to copy the image to.
#       - %rdx: the delta of the framebuffer.
#       - %r8: the pointer to the sprite buffer.
#       - %r9: the size of a row in the buffer.
#       - 32(%rsp): the x-coordinate to draw it.
#       - 40(%rsp): the y-coordinate to draw it.
#       - 48(%rsp): the decimal value to draw.
draw_decimal:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # reserve 128 bytes of stack space

        mov     %rcx, 16(%rbp)          # save the blt buffer pointer in shadow space
        mov     %rdx, 24(%rbp)          # save the width of the sprite in shadow space
        mov     %r8, 32(%rbp)           # save the x-coordinate in shadow space
        mov     %r9, 40(%rbp)           # save the y-coordinate in shadow space
        
        mov     64(%rbp), %r10          # the decimal to draw
        cmp     $9, %r10                # test whether the value is between 0-9
        jg      .draw_decimal_exit      # jump to exit otherwise
        
        # Draw the decimal
        movq    $0xFF00FF, 80(%rsp)     # set the mask color
        movq    $20, 72(%rsp)           # set the height of the decimal
        movq    $14, 64(%rsp)           # the width of the decimal
        mov     56(%rbp), %rax          # get the destination y-coordinate
        sub     $10, %rax               # subtract half the height from it
        mov     %rax, 56(%rsp)          # the destination y-coordinate
        mov     48(%rbp), %rax          # the destination x-coordinate
        sub     $7, %rax                # subtract half the width from it
        mov     %rax, 48(%rsp)          # write it to stack
        mov     $decimals, %rcx         # the array of coordinates and size
        mov     4(%rcx, %r10, 8), %eax  # the height of the image
        mov     %rax, 40(%rsp)          # write it to the stack
        mov     (%rcx, %r10, 8), %eax   # get the source x-coordinate
        mov     %rax, 32(%rsp)          # write it to the stack
        mov     24(%rbp), %r9           # the destination delta 
        mov     16(%rbp), %r8           # the destination buffer
        mov     40(%rbp), %rdx          # the delta of the sprite buffer
        mov     32(%rbp), %rcx          # the sprite buffer
        call    efi_gop_copy_mask       # do a masked copy
        
.draw_decimal_exit:
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore the caller's base pointer
        ret                             # return to caller

decimals:
        # The offset (x, y) for the decimal 0
        .long   864
        .long   200
        # The offset (x, y) for the decimal 1
        .long   868
        .long   236
        # The offset (x, y) for the decimal 2
        .long   866
        .long   268
        # The offset (x, y) for the decimal 3
        .long   866
        .long   300
        # The offset (x, y) for the decimal 4
        .long   862
        .long   346
        # The offset (x, y) for the decimal 5
        .long   862
        .long   370
        # The offset (x, y) for the decimal 6
        .long   618
        .long   490
        # The offset (x, y) for the decimal 7
        .long   638
        .long   490
        # The offset (x, y) for the decimal 8
        .long   658
        .long   490
        # The offset (x, y) for the decimal 9
        .long   678
        .long   490

# Draw the given unsigned integer to given framebuffer.
#
# parameters:
#       - %rcx: the framebuffer to copy the image to.
#       - %rdx: the delta of the framebuffer.
#       - %r8: the pointer to the sprite buffer.
#       - %r9: the size of a row in the buffer.
#       - 32(%rsp): the x-coordinate to draw it.
#       - 40(%rsp): the y-coordinate to draw it.
#       - 48(%rsp): the integer value to draw.
draw_integer:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $128, %rsp              # reserve 128 bytes of stack space
        
        mov     %r12, -8(%rbp)          # save %r12
        mov     %r13, -16(%rbp)         # save %r13
        mov     %r14, -24(%rbp)         # save %r14
        mov     %r15, -32(%rbp)         # save %r15
        mov     %rdi, -40(%rbp)         # save %rdi
        
        mov     %rcx, 16(%rbp)          # save the blt buffer pointer in shadow space
        mov     %rdx, 24(%rbp)          # save the width of the sprite in shadow space
        mov     %r8, 32(%rbp)           # save the sprite buffer in shadow space
        mov     %r9, 40(%rbp)           # save the sprite buffer delta in shadow space
        
        mov     48(%rbp), %r14          # get the x-offset in the framebuffer
        mov     56(%rbp), %r15          # get the y-offset in the framebuffer
        mov     64(%rbp), %rax          # get the number from stack
        
        xor     %r10, %r10              # clear total width counter
        
.draw_integer_loop_1:
        add     $14, %r10               # add 14 to the total width
        xor     %rdx, %rdx              # clear upper bits
        mov     $10, %rcx               # the divisor
        div     %rcx                    # divide by 10
        cmp     $0, %rax                # compare the result to zero
        jne     .draw_integer_loop_1    # if not bigger than zero, loop
        mov     %r10, %rdi              # save the result
        shr     $1, %r10                # half the result
        mov     %r14, %r12              # get the x-coordinate
        add     %r10, %r12              # add the result from to the width
        sub     $9, %r12                # minus the width of one decimal
        mov     64(%rbp), %r13          # get the number from stack
.draw_integer_loop_2:
        xor     %rdx, %rdx              # clear upper bits
        mov     $10, %rcx               # the divisor
        mov     %r13, %rax              # the number that should be divided
        div     %rcx                    # divide the number by ten
        mov     %rax, %r13              # move the result in %r13
        movq    %rdx, 48(%rsp)          # the decimal to draw is the remainder
        movq    %r15, 40(%rsp)          # get the base y-coordinate
        movq    %r12, 32(%rsp)          # get the x-coordinate 
        mov     40(%rbp), %r9            # the delta of the sprite buffer
        mov     32(%rbp), %r8            # the sprite buffer
        mov     24(%rbp), %rdx           # the destination delta 
        mov     16(%rbp), %rcx           # the destination buffer
        call    draw_decimal             # draw the decimal

        sub     $13, %r12               # subtract 20 to the x-coordinate
        sub     $14, %rdi               # decrease counter
        cmp     $0, %rdi                # has the counter reached 0 yet?
        ja      .draw_integer_loop_2    # draw the next decimal
.draw_integer_exit:
        mov     -8(%rbp), %r12          # restore %r12
        mov     -16(%rbp), %r13         # restore %r13
        mov     -24(%rbp), %r14         # restore %r14
        mov     -32(%rbp), %r15         # restore %r15
        mov     -40(%rbp), %rdi         # restore %rdi
        
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
