/*++

Copyright (c) 1999  Intel Corporation
    
Module Name:

    initplat.c

Abstract:

    Functions to make SAL and PAL proc calls

Revision History

--*/
#include "lib.h"

//#include "palproc.h"

VOID
InitializeLibPlatform (
    IN EFI_HANDLE           ImageHandle __attribute__((__unused__)),
    IN EFI_SYSTEM_TABLE     *SystemTable __attribute__((__unused__))
    )
{
    PLABEL  SalPlabel;
    UINT64  PalEntry;

    LibInitSalAndPalProc (&SalPlabel, &PalEntry);
}
