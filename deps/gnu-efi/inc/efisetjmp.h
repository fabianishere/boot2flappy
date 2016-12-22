#ifndef GNU_EFI_SETJMP_H
#define GNU_EFI_SETJMP_H

#ifdef _MSC_EXTENSIONS
#define ALIGN(x) __declspec(align(x))
#else
#define ALIGN(x) __attribute__((__aligned__(x)))
#endif

#include "efisetjmp_arch.h"

extern UINTN setjmp(jmp_buf *env);
extern VOID longjmp(jmp_buf *env, UINTN value);

#endif /* GNU_EFI_SETJMP_H */
