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





//------------------------------------------------------------------------------
// Includes
//------------------------------------------------------------------------------
        .nolist
#include "p8_sbe.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

	// Helper macro to check state of control bits
        .macro ifcntrbitclr, bitmask:req, target:req
        ldandi  D1, 0, A0, \bitmask
        braz    D1, \target
        .endm

        // Helper macro to check state of control bits
        .macro ifcntrbitset, bitmask:req, target:req
        ldandi  D1, 0, A0, \bitmask
        branz	D1, \target
        .endm

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

	// callproc_prologue
	//
	// At entry:
	//
	// A0 :	 The address of the control word for the procedure
	// D0 :	 The istep number.  This is 0 for procedures that
	//       don't set the SBEVITAL or virtual slw_vital register.
	//
	// At exit:
	//
	// D0 :	 Either 0 or 1.  If 1, then the actual call of the
	//       procedure should be skipped.
	// D1 :	 Scratched
	// P1 :	 Scratched
	//
	// All other registers preserved

	.subroutine callproc_prologue, ipl, "$Revision: 1.13 $"

	// Perform optional entry control.  Since entry halt updates the SBE
	// Vital halt code to indicate success, it must be reset to the fatal
	// error code if execution continues after the halt.

        ifcntrbitclr PROC_CONTROL_ENTRY_HALT, 1f

        // Unlock seeprom access before halting
        POREVE_DBG("Unlocking SEEPROM access before halting\n") ;
        lpcs    P1, MBOX_FSIGP4_0x00050013
        ldandi  D1, MBOX_FSIGP4_0x00050013, P1, ~BIT(20)
        std     D1, MBOX_FSIGP4_0x00050013, P1

	reqhalt	RC_SBE_PROC_ENTRY_HALT, D1, P1
	updatehalt PROC_SBE_HC_FATAL, D1, P1
1:
        ifcntrbitclr PROC_CONTROL_ENTRY_TRAP, 1f
        trap
1:
        ifcntrbitclr PROC_CONTROL_SKIP, 1f
	ls	D0, 1
	bra	prologue_done
1:
	// Set SBE Vital (SBE_PROC_AREA || SBE_PROC_ID) or virtual slw_vital
        // if requested.

	braz	D0, no_skip

#ifndef __SBE_ONLY__

        tebsbe D1, sbe

        // Virtual slw_vital update for PORE-SLW

        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)

	lpcs    P1, PIBMEM0_0x00080000
	ldandi	D1, slw_vital, P1, ~BITS(12,20)
	insrdi	D1, D0, 12, 16
        POREVE_DBG(".callproc: SLW VITAL virtual register update for " \
                   "procedure area/id 0x%016llx", \
                   io_pore.d1.read());
	std     D1, slw_vital, P1
        bra     no_skip

#endif

sbe:
        // SBEVITAL update for PORE-SBE

	lpcs    P1, MBOX_SBEVITAL_0x0005001C
	ldandi	D1, MBOX_SBEVITAL_0x0005001C, P1, ~BITS(12,20)
	insrdi	D1, D0, 12, 16
        POREVE_DBG(".callproc: SBEVITAL register update for " \
                   "procedure area/id 0x%016llx", \
                    io_pore.d1.read());
	std     D1, MBOX_SBEVITAL_0x0005001C, P1

no_skip:
	// Procedure will not be skipped
	ls	D0, 0

prologue_done:
	.end_subroutine callproc_prologue


	// callproc_epilogue
	//
	// At entry:
	//
	// A0 :	 The address of the control word for the procedure
	// D0 :	 1/0 indicating to skip (or not) post-procedure error checking
	//
	// At exit:
	//
	// D0 :	 Scratched
	// D1 :	 Scratched
	// P1 :	 Scratched
	//
	// All other registers preserved

	.subroutine callproc_epilogue, ipl, "$Revision: 1.13 $"

	branz	D0, 2f

        ifcntrbitset PROC_CONTROL_EXIT_XSTOP_HALT_DISABLE, 1f
	lpcs	P1, MASTER_PCB_INT_0x000F001A
	ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P1, 2, 1f
	POREVE_ERR("Checkstop detected via bit 2 in register F001A.  Halting\n");
	reqhalt	RC_SBE_PROC_CHECKSTOP
1:
        ifcntrbitclr PROC_CONTROL_EXIT_RECOV_HALT_ENABLE, 1f
	lpcs	P1, MASTER_PCB_INT_0x000F001A
        ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P1, 1, 1f
	POREVE_ERR("Recoverable error detected via bit 1 in register F001A.  Halting\n");
	reqhalt	RC_SBE_PROC_RECOVERABLE
1:
        ifcntrbitset PROC_CONTROL_EXIT_SPATTN_HALT_DISABLE, 1f
	lpcs	P1, MASTER_PCB_INT_0x000F001A
        ifbitclrscom D0, D0, MASTER_PCB_INT_0x000F001A, P1, 0, 1f
	POREVE_ERR("Special Attention detected via bit 0 in register F001A.  Halting\n");
	reqhalt	RC_SBE_PROC_SPATTN
1:
2:
	// Since exit halt updates the SBE Vital halt code to indicate success,
	// it must be reset to the fatal error code if execution continues
	// after the halt.

        ifcntrbitclr PROC_CONTROL_EXIT_HALT, 1f

        // Unlock seeprom access before halting
        POREVE_DBG("Unlocking SEEPROM access before halting\n") ;
        lpcs    P1, MBOX_FSIGP4_0x00050013
        ldandi  D1, MBOX_FSIGP4_0x00050013, P1, ~BIT(20)
        std     D1, MBOX_FSIGP4_0x00050013, P1

	reqhalt RC_SBE_PROC_EXIT_HALT, D1, P1
	updatehalt PROC_SBE_HC_FATAL, D1, P1
1:
        ifcntrbitclr PROC_CONTROL_EXIT_TRAP, 1f
        trap
1:
epilogue_done:
	.end_subroutine callproc_epilogue

	// scan_d0
	//
	// At entry:
	//
	// D0 :	 Address of the ring to scan
	//
	// At exit:
	//
	// P0 :	 Preserved
	//
	// All other registers destroyed

        .subroutine scan_d0, ipl, "$Revision"
	// Zero indicates no ring data available to load, so return without scanning
	braz    D0, 99f

        // Skip past the metadata and call the ring scan routine
	mr	A0, D0
	ld      D1, 0, A0
        add     D0, D0, D1
        brad    D0
99:
        ret
        .end_subroutine scan_d0


        .set RING_TBL_OFFSET_DDx, 0x0
        .set RING_TBL_OFFSET_OVR, 0x8

	// scan_a0
	//
	// At entry:
	//
	// A0 :	 Address of the TOC entry for the base ring to scan
	//
	// At exit:
	//
	// P0 :	 Preserved
	//
	// All other registers destroyed

        .subroutine scan_a0, ipl, "$Revision"
	ld      D0, RING_TBL_OFFSET_DDx, A0

	// Zero indicates no ring data available to load, so return without scanning
	braz    D0, 99f

        // Skip past the metadata and call the ring scan routine
	mr	A0, D0
	ld      D1, 0, A0
        add     D0, D0, D1
        brad    D0
99:
        ret
        .end_subroutine scan_a0

	// scan_a0_override
	//
	// At entry:
	//
	// A0 :	 Address of the TOC entry for the base ring to scan
	//
	// At exit:
	//
	// P0 :	 Preserved
	//
	// All other registers destroyed

        .subroutine scan_a0_override, ipl, "$Revision"
	ld      D0, RING_TBL_OFFSET_OVR, A0

	// Zero indicates no ring data available to load, so return without scanning
	braz    D0, 99f

        // Skip past the metadata and call the ring scan routine
	mr	A0, D0
	ld      D1, 0, A0
        add     D0, D0, D1
        brad    D0
99:
        ret
        .end_subroutine scan_a0_override

//Centaur doesn't support pibmem, so don't compile the subroutines that use it
#ifndef CENTAUR

     // store CTR, A0 and D0 module
     //
     // At entry:
     //
     //    CTR : Original CTR state that's supposed to be safely stored to PIBMEM
     //    A0  : Original  A0 state that's supposed to be safely stored to PIBMEM
     //    D0  : Original  D0 state that's supposed to be safely stored to PIBMEM
     //
     // At exit:
     //
     //    P0               : destroyed
     //    all other regs   : maintained


        .subroutine store_ctr_a0_d0_module, ipl, "$Revision"
        POREVE_INF("<subroutine: store CTR, A0, D0> : *** Subroutine Store CTR, A0, D0 was called ***\n")
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)
        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Write current content of D0 to PIBMEM
        POREVE_INF("<subroutine: store CTR, A0, D0> : Store D0 to PIBMEM ...\n")
        std     D0, sbe_scan_state_memory2, P0

     // Write current content of CTR to PIBMEM
        POREVE_INF("<subroutine: store CTR, A0, D0> : Store CTR to PIBMEM ...\n")
        mr      D0, CTR
        std     D0, sbe_scan_state_memory0, P0

     // Write current content of A0 to PIBMEM
        POREVE_INF("<subroutine: store CTR, A0, D0> : Store A0 to PIBMEM ...\n")
        mr      D0, A0
        std     D0, sbe_scan_state_memory1, P0

     // Restore D0 from PIBMEM
        ld      D0, sbe_scan_state_memory2, P0

        POREVE_INF("<subroutine: store CTR, A0, D0> : *** Subroutine Store CTR, A0, D0 ends ***\n")

        .end_subroutine store_ctr_a0_d0_module


     // restore CTR, A0 and D0 module
     //
     // At entry:
     //
     //    no entry requirement
     //
     // At exit:
     //
     //    P0               : destroyed
     //    CTR, A0, D0      : restored from PIBMEM
     //    all other regs   : maintained


        .subroutine restore_ctr_a0_d0_module, ipl, "$Revision"
        POREVE_INF("<subroutine: restore CTR, A0, D0> : *** Subroutine Re-Store CTR, A0, D0 was called ***\n")
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)
     // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    P0, STBY_CHIPLET_0x00000000

     // Read new content of CTR from PIBMEM
        POREVE_INF("<subroutine: restore CTR, A0, D0> : Re-Store CTR from PIBMEM ...\n")
        ld      D0, sbe_scan_state_memory0, P0
        mr      CTR, D0

     // Read new content of A0 from PIBMEM
        POREVE_INF("<subroutine: restore CTR, A0, D0> : Re-Store A0 from PIBMEM ...\n")
        ld      D0, sbe_scan_state_memory1, P0
        mr      A0, D0

     // Read new content of D0 from PIBMEM
        POREVE_INF("<subroutine: restore CTR, A0, D0> : Re-Store D0 from PIBMEM ...\n")
        ld      D0, sbe_scan_state_memory2, P0

        POREVE_INF("<subroutine: restore CTR, A0, D0> : *** Subroutine Re-Store CTR, A0, D0 ends ***\n")

        .end_subroutine restore_ctr_a0_d0_module

     // updatestep to the value in D1
     //
     // At entry:
     //
     //    P1: Pibmem chiplet
     //    D1: the step number
     //
     // At exit:
     //
     //    D0               : destroyed
     //    all other regs   : maintained


        .subroutine updatestep_D0_P1_step_D1, ipl, "$Revision"
#ifndef __SBE_ONLY__
        tebsbe D0, 873283f

        // Virtual slw_vital update for PORE-SLW

        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)
        ld      D0, slw_vital, P1
        insrdi  D0, D1, 4, 28

        POREVE_DBG("updatestep: SLW Vital virtual register update : " \
                   "%016llX", \
                   io_pore.d0.read())

        std     D0, slw_vital, P1
        bra     873284f
#endif

873283:
        // SBEVITAL update for PORE-SBE

	ld	D0, MBOX_SBEVITAL_0x0005001C, P1
        insrdi  D0, D1, 4, 28

	POREVE_DBG("updatestep:	SBE Vital register update : %016llX",
        	io_pore.d0.read())

	std	D0, MBOX_SBEVITAL_0x0005001C, P1

873284:
        .end_subroutine updatestep_D0_P1_step_D1
#endif

        // set_scan_ratio - This procedure sets the scan ratio to the value
        //                  in the control word, if the enable bit in the
        //                  control word is set
        //
        // set_scan_ratio_d0 - Alternate entry point that assumes D0 is
        //                  already set with the control word value
        //
        //Assumes:
        //  A1 contains the address of the control word to use
        //  P0 contains the chiplet to update
        //
        //Destroys:
        //  D0, D1
        .subroutine set_scan_ratio, ipl, "$Revision: 1.13 $"
        ld      D0, 0x0, A1
        .global set_scan_ratio_d0
set_scan_ratio_d0:
        ifbitset D1, D0, SCAN_RATIO_ENABLE_BIT, override_scan_ratio

        //Hard code the scan ratio to 8:1 when not overriding it
        sti     GENERIC_OPCG_CNTL0_0x00030002, P0, BITS(6,3)
        ret

override_scan_ratio:
        //Rotate the ratio into place and OR it into the register
        rldinm  D0, D0, SCAN_RATIO_ROTATE_COUNT,SCAN_RATIO_START_BIT,SCAN_RATIO_END_BIT
        ##@ uint32_t raw_value = io_pore.d0.extractToRight(4, 5);
        ##@ int32_t ratio = 0                                   ;
        ##@ switch(raw_value) {
        ##@   case 16:
        ##@     ratio = 24      ; break;
        ##@   case 17:
        ##@     ratio = 32      ; break;
        ##@   case 18:
        ##@     ratio = 48      ; break;
        ##@   case 19:
        ##@     ratio = 64      ; break;
        ##@   case 20:
        ##@     ratio = 128      ; break;
        ##@   default:
        ##@     if( raw_value < 16 ) {
        ##@       ratio = raw_value+1 ;
        ##@     } else {
        ##@       FAPI_ERR("Unable to determine the scan ratio for raw value %i", raw_value) ;
        ##@       ratio = -1    ;
        ##@     }
        ##@ }
        ##@ FAPI_INF("Setting scan ratio for chiplet ID 0x%02X to %i:1", (uint32_t)io_pore.p0.read(), ratio) ;
        ##@ return hookOk       ;
        std     D0, GENERIC_OPCG_CNTL0_0x00030002, P0

        .end_subroutine set_scan_ratio
