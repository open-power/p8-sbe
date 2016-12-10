//------------------------------------------------------------------------------
// IBM_PROLOG_BEGIN_TAG
// This is an automatically generated prolog.
//
// OpenPOWER Project
//
// Contributors Listed Below - COPYRIGHT 2012,2016
// [+] International Business Machines Corp.
//
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// IBM_PROLOG_END_TAG
//------------------------------------------------------------------------------




/// \file pts_pba.S
/// \brief Subroutines and data for PTS applications to access mainstore.  
///
/// For portability between the SLW and OCC/GPE versions of PTS, PTS
/// replicates the standard library routines gpe_pba_reset() and
/// gpe_pba_setup() to reprogram the PBA slaves to support application
/// requirements. The new ptsPbaReset() and ptsPbaSetup() routines load
/// pointers to constant parameter structures and then perform the equivalent
/// of the library functions.
///
/// The parameter structures are defined statically for simplicity. For each
/// of the two modes (normal and atomic add) we define one stucture for the
/// PORE-SLW, and another for the PORE-GPE. This static declaration is simple
/// as long as no changes are made to the PBA slave assignments.  The firmware
/// should be stable enough now such that this is not a problem.

//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------

        .nolist
#include "pts.h"
        .list
        
//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------

        .oci

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

        // We define two static instances of the PTS_PBA_PARMS structure for
        // each mode. The first instance is for SLW, the second for GPE. These
        // structure intializations were created by the PM validation
        // application unsupported/ptsPba.

        .struct 0
        _ptsStructField PTS_PBA_PARMS_SLVCTL_ADDRESS
        _ptsStructField PTS_PBA_PARMS_SLVCTL
        _ptsStructField PTS_PBA_PARMS_MASK
        _ptsStructField PTS_PBA_PARMS_SLVRST
        _ptsStructField PTS_PBA_PARMS_SLVRST_IN_PROGRESS
        _ptsStructField PTS_PBA_PARMS_SLAVE_ID
SIZE_OF_PTS_PBA_PARMS:
        .previous

        .ptsGlobalData ptsPbaDefaultParms
ptsPbaDefaultParms:
        .quad   0x0000000040020030
        .quad   0x8000000000000000
        .quad   0x7f1edff01fffffff
        .quad   0xc000000000000000
        .quad   0x0200000000000000
        .quad   0x0000000000000002
        .quad   0x0000000040020020
        .quad   0x8000000000000000
        .quad   0x7f1edff01fffffff
        .quad   0x8000000000000000
        .quad   0x0800000000000000
        .quad   0x0000000000000000
        .ptsEpilogue ptsPbaDefaultParms

        .ptsGlobalData ptsPbaAtomicAddParms
ptsPbaAtomicAddParms:
        .quad   0x0000000040020030
        .quad   0x8040000060000000
        .quad   0x7f1edff01fffffff
        .quad   0xc000000000000000
        .quad   0x0200000000000000
        .quad   0x0000000000000002
        .quad   0x0000000040020020
        .quad   0x8000000060000000
        .quad   0x7f1edff01fffffff
        .quad   0x8000000000000000
        .quad   0x0800000000000000
        .quad   0x0000000000000000
        .ptsEpilogue ptsPbaAtomicAddParms

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Text
//------------------------------------------------------------------------------

        ////////////////////////////////////////////////////////////
        // ptsPbaReset
        ////////////////////////////////////////////////////////////
        //
        // Reset a PBA slave from a PTS_PBA_PARMS structure.  A setup sequence
        // looks like
        //
        //     ptsPbaReset
        //     ptsPbaSetup
        //
        // The subroutine ptsPbaReset() can also be called by itself to insure
        // that all write data has been flushed to mainstore.  
        //
        // Slave reset for PBA is a complex issue, especially in cases like
        // this where the entity requesting the reset may be executing from
        // main memory - i.e., continuing to read from the slave being
        // reset.  To work around potential issues the code that polls for
        // reset is PowerBus cache-line aligned, and we re-hit the reset
        // button each time we get an unsuccessful poll for the reset being
        // done.  This should guarantee that the slave will go to reset
        // status as soon as any PowerBus blockages (if any) clear.  For
        // details see HW228485.
        //
        // At entry :   
        //
        // A0 :  The (constant) address of the PTS_PBA_PARMS array
        //
        // Clobbered:   
        //
        // D0 :  scratched
        // D1 :  scratched
        // A1 :  Holds PBA_SLVRST

        .ptsGlobalFunction ptsPbaReset
ptsPbaReset:

        tebslw  D0, 1f
        adds    A0, A0, SIZE_OF_PTS_PBA_PARMS
1:
        bra     _ptsPbaReset

        .balign 128
_ptsPbaReset:  
        la      A1, PTS_PBA_SLVRST
        ld      D0, PTS_PBA_PARMS_SLVRST, A0
        std     D0, 0, A1

        ld      D0, PTS_PBA_PARMS_SLVRST_IN_PROGRESS, A0
        ld      D1, 0, A1
        and     D0, D0, D1
        branz   D0, _ptsPbaReset
        
        ret

        .ptsEpilogue ptsPbaReset


        ////////////////////////////////////////////////////////////
        // ptsPbaSetup
        ////////////////////////////////////////////////////////////
        //
        // Set up a PBA slave from a PTS_PBA_PARMS structure.  A setup
        // sequence looks like
        //
        //     gpe_pba_reset
        //     gpe_pba_setup
        //
        // At entry :   
        //
        // A0 :  The (constant) address of the PTS_PBA_PARMS array
        //
        // Clobbered:   
        //
        // D0 :  scratch
        // A1 :  Holds PBA_SLVCTL address for the indicated slave

        .ptsGlobalFunction ptsPbaSetup
ptsPbaSetup:

        tebslw  D0, 1f
        adds    A0, A0, SIZE_OF_PTS_PBA_PARMS
1:
        
        // Write the new SLVCTL value under MASK
        
        ld      D0, PTS_PBA_PARMS_SLVCTL_ADDRESS, A0
        mr      A1, D0

        ld      D0, 0, A1
        ld      D1, PTS_PBA_PARMS_MASK, A0
        and     D0, D0, D1

        ld      D1, PTS_PBA_PARMS_SLVCTL, A0
        or      D0, D0, D1
        
        std     D0, 0, A1

        ret

        .ptsEpilogue ptsPbaSetup
