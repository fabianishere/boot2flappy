# Practical session TI1406 Assignment 8
# Author F.S. Mastenbroek (4552199)
# Flappy Bird clone for UEFI x86-64.

# Dependencies
# gnu-efi
.extern BS
.extern WaitForSingleEvent

# Exports
.global efi_event_create
.global efi_event_close
.global efi_event_wait
.global efi_event_wait_single
.global efi_event_set_timer
.global efi_event_create_timer

.global EVT_TIMER
.global EVT_RUNTIME
.global EVT_RUNTIME_CONTEXT
.global EVT_NOTIFY_WAIT
.global EVT_NOTIFY_SIGNAL
.global EVT_SIGNAL_EXIT_BOOT_SERVICES
.global EVT_SIGNAL_VIRTUAL_ADDRESS_CHANGE
.global EVT_EFI_SIGNAL_MASK
.global EVT_EFI_SIGNAL_MAX
.global EVT_TIMER_CANCEL
.global EVT_TIMER_PERIODIC
.global EVT_TIMER_RELATIVE
.global EVT_TIMER_TYPE_MAX

# Routines for EFI event handling
.text
EVT_TIMER:                              .quad   0x80000000
EVT_RUNTIME:                            .quad   0x40000000
EVT_RUNTIME_CONTEXT:                    .quad   0x20000000

EVT_NOTIFY_WAIT:                        .quad   0x00000100
EVT_NOTIFY_SIGNAL:                      .quad   0x00000200

EVT_SIGNAL_EXIT_BOOT_SERVICES:          .quad   0x00000201
EVT_SIGNAL_VIRTUAL_ADDRESS_CHANGE:      .quad   0x60000202

EVT_EFI_SIGNAL_MASK:                    .quad   0x000000FF
EVT_EFI_SIGNAL_MAX:                     .quad   2

EVT_TIMER_CANCEL:                       .quad   0
EVT_TIMER_PERIODIC:                     .quad   1
EVT_TIMER_RELATIVE:                     .quad   2
EVT_TIMER_TYPE_MAX:                     .quad   3

# Create an EFI event.
#
# parameters:
#       - %rcx: the type of event to create.
#       - %rdx: the task priority level.
#       - %r8:  the pointer to the notify function
#       - %r9: the notify context.
#       - 32(%rsp): the location to store the created event.
# returns:
#       - %rax: the status code.
efi_event_create:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $40, %rsp               # reserve 40 bytes of stack space
        
        mov     48(%rbp), %rax          # get the location to store the event
        mov     %rax, 32(%rsp)          # give it as last argument
        mov     BS(%rip), %rax          # get boot services
        call    *80(%rax)               # BS->CreateEvent

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Close an EFI event.
#
# parameters:
#       - %rcx: the pointer to the event to close.
# returns:
#       - %rax: the status code.
efi_event_close:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space
        
        mov     BS(%rip), %rax          # get boot services
        call    *112(%rax)              # BS->CloseEvent

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Wait for multiple events.
#
# parameters:
#       - %rcx: the amount of events to wait for.
#       - %rdx: the pointer to the array of events to wait for.
#       - %r8: the pointer to the memory where to place the index of the event
#              that occured.
# returns:
#       - %rax: the status code.
efi_event_wait:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space
        
        mov     BS(%rip), %rax          # get boot services
        call    *96(%rax)               # BS->WaitForEvent

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Wait for a single event.
#
# parameters:
#       - %rcx: the pointer to the event to wait for.
#       - %rdx: the time to wait where the value 1 means 100 nanoseconds.
# returns:
#       - %rax: the status code.
efi_event_wait_single:
        jmp     WaitForSingleEvent              # gnu-efi does the work

# Set the timer of a time event.
#
# parameters:
#       - %rcx: the event to set the timer of.
#       - %rdx: the type of timer.
#       - %r8: the trigger time of the timer where 1 means 100 nanoseconds.
# returns:
#       - %rax: the status code.
efi_event_set_timer:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # move the stack pointer to %rbp
        sub     $32, %rsp               # reserve 32 bytes of shadow space
        
        mov     BS(%rip), %rax          # get boot services
        call    *88(%rax)               # BS->SetTimer

        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller

# Create a timer event.
#
# parameters:
#       - %rcx: the type of timer.
#       - %rdx: the trigger time of the timer where 1 means 100 nanoseconds.
#       - %r8: the location to store the event.
# returns:
#       - %rax: the status code:
efi_event_create_timer:
        push    %rbp                    # prologue: push the base pointer
        mov     %rsp, %rbp              # copy the stack pointer to %rbp
        sub     $40, %rsp               # allocate 40 bytes of stack space

        mov     %rcx, 16(%rbp)          # move the timer type to shadow space
        mov     %rdx, 24(%rbp)          # move the trigger time to shadow space
        mov     %r8, 32(%rbp)           # move the event location to shadow space.

        mov     %r8, 32(%rsp)           # the last argument of efi_event_create
        mov     $0, %r9                 # no notify context
        mov     $0, %r8                 # no notify function
        mov     $0, %rdx                # the task priority level
        mov     EVT_TIMER, %rcx         # the type of event
        call    efi_event_create        # create the event

        test    %rax, %rax              # did the operation fail
        js      .evct_exit              # then return

        mov     32(%rbp), %rcx          # the location of event to set the timer of
        mov     (%rcx), %rcx            # get the event
        mov     16(%rbp), %rdx          # the timer type
        mov     24(%rbp), %r8           # the trigger time
        call    efi_event_set_timer     # set the timer of the event

.evct_exit:
        mov     %rbp, %rsp              # epilogue: clear stack
        pop     %rbp                    # restore caller's base pointer
        ret                             # return to caller
