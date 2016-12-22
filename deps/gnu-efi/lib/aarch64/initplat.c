/*
 * Copright (C) 2014 Linaro Ltd.
 * Author: Ard Biesheuvel <ard.biesheuvel@linaro.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice and this list of conditions, without modification.
 * 2. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * Alternatively, this software may be distributed under the terms of the
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 */

#include "lib.h"

VOID
InitializeLibPlatform (
    IN EFI_HANDLE           ImageHandle __attribute__((__unused__)),
    IN EFI_SYSTEM_TABLE     *SystemTable __attribute__((__unused__))
    )
{
}

/*
 * Calls to these functions may be emitted implicitly by GCC even when
 * -ffreestanding is in effect.
 */
void *memset(void *s, int c, __SIZE_TYPE__ n)
{
    unsigned char *p = s;

    while (n--)
        *p++ = c;

    return s;
}

void *memcpy(void *dest, const void *src, __SIZE_TYPE__ n)
{
    unsigned char *p = dest, *q = src;

    while (n--)
        *p++ = *q++;

    return dest;
}
