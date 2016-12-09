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



        .nolist
#include "p8_sbe.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------

        .pibmem
        .ipl_text

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        .global pibmem_branch_table
pibmem_branch_table:

        // First are the 5 error vector branches

error0:
        braa    proc_sbe_error_handler0
error1:
        braa    proc_sbe_error_handler1
error2:
        braa    proc_sbe_error_handler2
error3:
        braa    proc_sbe_error_handler3
error4:
        braa    proc_sbe_error_handler4

        .balign 64    // alignment to 64 bit boundary

        .global secure_boot_hash
secure_boot_hash:

//0000000: 40d487ff7380ed6a
//	   d54775d5795fea0d  @...s..j.Gu.y_..
//0000010: e2f541fea9db06b8
//	   466a42a320e65f75  ..A.....FjB. ._u
//0000020: b48665460017d907
//	   515dc2a5f9fc5095  ..eF....Q]....P.
//0000030: 4d6ee0c9b67d219d
//	   fb7085351d01d6d1  Mn...}!..p.5....

	.quad 0x40d487ff7380ed6a     // Placeholder for secure boot hash
        .quad 0xd54775d5795fea0d     // Placeholder for secure boot hash
        .quad 0xe2f541fea9db06b8     // Placeholder for secure boot hash
        .quad 0x466a42a320e65f75     // Placeholder for secure boot hash
        .quad 0xb48665460017d907     // Placeholder for secure boot hash
        .quad 0x515dc2a5f9fc5095     // Placeholder for secure boot hash
        .quad 0x4d6ee0c9b67d219d     // Placeholder for secure boot hash
        .quad 0xfb7085351d01d6d1     // Placeholder for secure boot hash

         // This variable is used by SLW code to save original MSR content
         // during ramming of SPRs as well as set a flag if there's an mtmsrd
         // in the .slw table.

         .global slw_saved_msr
slw_saved_msr:
        .quad 0x0  // Contains original MSR content
        .quad 0x0  // Contains a '1' if an mtmsrd in the .slw table was rammed

        // The Sleep/Winkle code runs the same EX-init procedures as the
        // original IPL, but is not allowed to update the SBEVITAL register.
        // Instead, when procedures run on the PORE-SLW they update this
        // virtual register as if it were the SBEVITAL register. This
        // includes the procedure numbers and substeps as well as the HALT
        // code.

        .global slw_vital
slw_vital:
        .quad   0

        // The PIBMEM based trigger winkle / deadman code needs a copy of
        // procedure control vector to avoid the long I2C access time.
        // The value is copied here by the SEEPROM calling producure prior
        // to invoking the PIBMEM subroutine.

        .global proc_sbe_trigger_winkle_pibmem_control
proc_sbe_trigger_winkle_pibmem_control:
        .quad   0


        // High Availability Address Write Pointer Save Area
        // Chiplet specific values are stored here upon a Deep Winkle Entry.
        // Upon Deep Winkle Exit, the chiplet specific value is restored from
        // these values.
        //
        // The HA Write Address Pointer is a 17 bit value per chiplet so a
        // .long (4B) is reserved for each.  Indexing uses the EX chiplet
        // number after masking out the "0x10" from it (eg indexes are 0 - F.
        // However, access to the PIBMEM are in quads (eg 8B each).  Thus, the
        // structure allocates 8 quads (64B) for up to 16 chiplets.
        //
        //  Structure
        //                            Even            Odd
        //      .quad  (8B) ->    4B (chiplet 0), 4B (chiplet 1)
        //      .quad  (8B) ->    4B (chiplet 2), 4B (chiplet 3)
        //      ....
        //      .quad  (8B) ->    4B (chiplet E), 4B (chiplet F)

        .global slw_ha_write_addr_ptr_sr_pibmem
slw_ha_write_addr_ptr_sr_pibmem:
        .rept   8
        .quad   0x0
        .endr

        // The following locations provide for counts of the various SLW Exit
        // events for the purpose of event tracking.  These are incremented by
        // SLW code.  Any clearing of these counts is done by external FAPI
        // proceduress

        .global slw_deep_sleep_count
slw_deep_sleep_count:
        .quad   0

        .global slw_deep_winkle_count
slw_deep_winkle_count:
        .quad   0

        .global slw_fast_sleep_count
slw_fast_sleep_count:
        .quad   0

        .global slw_fast_winkle_count
slw_fast_winkle_count:
        .quad   0

        .global slw_start_time
slw_start_time:
        .quad   0

        .global slw_stop_time
slw_stop_time:
        .quad   0


        // The following 3 locations are used for SBE state informations
        // that get lost during load_ring.
        // proc_sbe_chiplet_init.S will use these locations to store
        // information from CTR, A0 and D0, and restore this information
        // after load_ring from here.

        .global sbe_scan_state_memory0
sbe_scan_state_memory0:
        .quad   0

        .global sbe_scan_state_memory1
sbe_scan_state_memory1:
        .quad   0

        .global sbe_scan_state_memory2
sbe_scan_state_memory2:
        .quad   0


	// Per chiplet EDRAM disable mask

	.global edram_disable_mask
edram_disable_mask:
	.quad	0

	// LCO victim vector/hash disable

	.global lco_config
lco_config:
	.quad 0

	.global ex_scan_ratio_override
ex_scan_ratio_override:
	.quad	0

	.global proc_sbe_intr_service_delay_us
proc_sbe_intr_service_delay_us:
	.quad	0
