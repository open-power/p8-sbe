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




#ifndef __PROC_SBE_L3_PGOOD_H
#define __PROC_SBE_L3_PGOOD_H

#include "proc_sbe_initf_common_seeprom.H"

     .set L3_SETUP_ACTION_DISABLE, 1
     .set L3_SETUP_ACTION_ENABLE, 0
     .set L3_SETUP_UNIT_L2, 1
     .set L3_SETUP_UNIT_L3, 0
     .set L3_SETUP_UNIT_L3_EDRAM, 2
     .set L3_SETUP_UNIT_L3_LCO, 3

    //----------------------------------------------------------------------
    // l2_disable_l3
    //----------------------------------------------------------------------
    // Set L2 switches to operate under disabled L3 cache
    // Assumes P1 is set to chiplet to initialize
    // D0 is destroyed, all other registers are preserved
    //----------------------------------------------------------------------

    .macro l2_disable_l3

	 bsi	D0, EX_L2_MODE_REG0_0x1001280A, P1, BIT(11)

    .endm

    //----------------------------------------------------------------------
    // l3_disable_l3
    //----------------------------------------------------------------------
    // Set L3 switches to disable L3 cache
    // Assumes P1 is set to chiplet to initialize
    // D0 is destroyed, all other registers are preserved
    //----------------------------------------------------------------------

    .macro l3_disable_l3

	bsi    D0, EX_L3_MODE_REG0_0x1001082B, P1, BIT(0)

    .endm

    //----------------------------------------------------------------------
    // l3_enable_edram
    //----------------------------------------------------------------------
    // Set L3 dials to enable & unfence EDRAM
    // Assumes base sets chiplet(s) to initialize
    // All registers are preserved
    //----------------------------------------------------------------------

    .macro l3_enable_edram base:req

        // Enable EDRAM GP3(28)
        sti     GENERIC_GP3_OR_0x000F0014, \base, BIT(28)
        // Enable EDRAM PM-GP0.40
        sti     GENERIC_PMGP0_OR_0x000F0102, \base, BIT(40)
        // Clear L3 EDRAM fence
        sti     GENERIC_GP0_AND_0x00000004,\base, ~BIT(19)

    .endm

    //----------------------------------------------------------------------
    // l3_lco_setup
    //----------------------------------------------------------------------
    // L3 LCO configuration macro
    // Assumes P1 is set to chiplet(s) to initialize
    // D0 is destroyed, all other registers are preserved
    //----------------------------------------------------------------------

    .macro l3_lco_setup

	// perform L3 LCO configuration for this chiplet
	POREVE_DBG("<l3_lco_setup>: Setting L3 LCO configuration for chiplet ID 0x%02llX", io_pore.p1.read());

        // save D1 from outer loop (preserve action mask)
	mr	D0, D1
	// save P0 (EX init pervasive base)
	mr	A0, P0
	// save CTR/A0/D0 to pibmem
	bsr     store_ctr_a0_d0_module
	// save P1 (preserve target chiplet ID)
	mr      A1, P1

	// LCO targeting scheme only includes target IDs for *implemented*
	// chiplets, shift chiplet ID to this encoding
	mr      D0, P1
	// remove offset of 16 (chiplet ID offset for EX)
	andi    D0, D0, ~BIT(59)
	mr      D1, D0
	// subtract one regardless of EX chiplet ID
	subs    D0, D0, 1
	andi    D1, D1, BIT(60)
	braz    D1, l3_lco_setup_normalized
 
l3_lco_setup_normalize_8_15:
	// EX chiplet ID is greater than 8, subtract two more
	subs    D0, D0, 2
 
l3_lco_setup_normalized:
	// align with target ID field
	POREVE_DBG("<l3_lco_setup>: LCO target ID = 0x%llX ...\n", io_pore.d0.read());
	sldi    D0, D0, 58
	// read LCO victim vector from pibmem
	lpcs    P1, STBY_CHIPLET_0x00000000
	ld      D1, lco_config, P1
	andi    D1, D1, BITS(0, 12)
	POREVE_DBG("<l3_lco_setup>: LCO victim vector = %016llX ...\n", io_pore.d1.read())
	// align with target victims field
	srdi    D1, D1, 6
	// form SCOM data field
	or      D1, D0, D1
	// set valid bit
	ori	D1, D1, BIT(0)
        // restore P1
        mr      P1, A1
        // store LCO configuration
	POREVE_DBG("<l3_lco_setup>: Mode Reg1 = %016llX\n", io_pore.d1.read())
        std     D1, EX_L3_MODE_REG1_0x1001080A, P1

	// read LCO hash disable indicator from pibmem
	// and align with hash disable bit
        lpcs    P1, STBY_CHIPLET_0x00000000
        ld      D1, lco_config, P1
	andi	D1, D1, 0x1
	sldi	D1, D1, 54
 	// restore P1
	mr	P1, A1
	// read-modify-write existing register content
	ld	D0, EX_L3_MODE_REG0_0x1001082B, P1
	andi	D0, D0, ~BIT(9)
	or	D0, D0, D1
	// store LCO configuration
        POREVE_DBG("<l3_lco_setup>: Mode Reg0 = %016llX\n", io_pore.d0.read())
	std     D0, EX_L3_MODE_REG0_0x1001082B, P1
	
	// restore CTR/A0/D0 from pibmem
	bsr	restore_ctr_a0_d0_module
	// restore P0 for EX init procedures
	mr	P0, A0
	// restore D1 for outer loop
	mr	D1, D0

    .endm

    //----------------------------------------------------------------------
    // l3_setup
    //----------------------------------------------------------------------
    // L3 partial good configuration macro
    // Configures L2/L3 appropriately based on state of L3 EDRAM (enabled/
    // disabled)
    // Assumes P0 is set to chiplet(s) to initialize
    // P1, D0, D1 are destroyed, all other registers are preserved
    //----------------------------------------------------------------------

    .macro l3_setup, action: req, unit: req

	.pibmem_port (PORE_SPACE_PIBMEM & 0xf)

	// use edram_disable_mask vector in pibmem to determine if L3
	// cache configuration needs to be altered
	POREVE_DBG("<l3_setup>:	Reading L3 EDRAM disable mask");
	lpcs    P1, STBY_CHIPLET_0x00000000
	ld      D1, edram_disable_mask, P1

	POREVE_INF("EDRAM disable mask = %016llx ...\n", io_pore.d1.read())

	// if edram_disable_mask is all clear, exit early & optionally
	// execute action code
	.if (\action == L3_SETUP_ACTION_DISABLE)
		// no change to POR flush state required, exit directly
		POREVE_DBG("Executing disable path\n")
		braz	D1, l3_setup_done
        .else
                // perform action & exit
                POREVE_DBG("Executing enable path\n")
                branz	D1, l3_setup_process
                .if (\unit == L3_SETUP_UNIT_L3_EDRAM)
                        l3_enable_edram P0
			bra	l3_setup_done
                .elseif (\unit == L3_SETUP_UNIT_L3_LCO)
			bra	l3_setup_process
		.else
                        .error "Unsupported action!"
                .endif
	.endif

	// determine which EX chiplet(s) are being initialized
	// (specified by P0) and use chiplet specific bit(s) of
	// edram_disable_mask to take appropriate action
l3_setup_process:
	mr	D1, P0
	ifbitset D0, D1, 57, l3_setup_multicast

l3_setup_unicast:
	// unicast, walk a single bit into its proper position in the
	// bitmask, based on pervasive base value in D0
	POREVE_DBG("<l3_setup>: Performing unicast L3 setup");
	// normalize chiplet ID (16-31) to loop count (15-0), store in CNT
	// left shift is most efficient
	ls	D0, 0x1f
	sub	D1, D0, D1
	mr	CTR, D1
	li	D1, BIT(31)
	bra	l3_setup_unicast_loop_end

l3_setup_unicast_loop_begin:
	sldi	D1, D1, 1

l3_setup_unicast_loop_end:
	loop	l3_setup_unicast_loop_begin
	bra	l3_setup_form_mask

l3_setup_multicast:
	// multicast, read partial good bitmask via mutlicast
	POREVE_DBG("<l3_setup>: Performing multicast L3 setup");
	ls      D0, SWITCH_WRITE_OP_TO_BITX_OP_MASK
	xor     D0, D0, D1
	mr      P1, D0
	// do multicast read to obtain set of enabled chiplets
	ld      D1, GENERIC_GP3_0x000F0012, P1
	// restore pervasive base in preparation for reload
	// of edram_disable_mask
	lpcs	P1, STBY_CHIPLET_0x00000000

l3_setup_form_mask:
	// from either unicast/multicast path above, D1 will contain
	// per-chiplet bit mask of chiplets to consider
	ld      D0, edram_disable_mask, P1
	// optionally invert mask based on action being performed
	.if (\action == L3_SETUP_ACTION_ENABLE)
		xori	D0, D0, BITS(0,64)
	.endif
	and	D1, D0, D1
	// shift off non-EX chiplets (IDs 0-15)
	sldi	D1, D1, 0x10

	// D1 now contains per-chiplet action mask
	// use P1 to issue SCOMs to currently selected chiplet
	// via unicast
	POREVE_DBG("<l3_setup>: Mask of chiplets to act on %016llX", io_pore.d1.read());
	ls   	P1, 0x10

l3_setup_loop:
	// examine msb of per-chiplet mask associated with
	// current chiplet ID
	andi	D0, D1, BIT(0)
	braz	D0, l3_setup_next

l3_setup_action:
	// perform L3 configuration action for this chiplet
	POREVE_DBG("<l3_setup>: Setting L3 configuration for chiplet ID %02llX", io_pore.p1.read());
	.if (\action == L3_SETUP_ACTION_DISABLE)
		.if (\unit == L3_SETUP_UNIT_L2)
			l2_disable_l3
		.else
			l3_disable_l3
		.endif
	.else
		.if (\unit == L3_SETUP_UNIT_L3_EDRAM)
			l3_enable_edram P1
		.elseif (\unit == L3_SETUP_UNIT_L3_LCO)
			l3_lco_setup
		.else
			.error "Unsupported action!"
		.endif
	.endif

l3_setup_next:
	// prep per-chiplet mask for next iteration
	sldi	D1, D1, 1
	// if mask has become zero we can exit early (there are no
	// more L3 chiplets which need to be processed)
	braz	D1, l3_setup_done

	// prep pervasive base for next iteration
	mr	D0, P1
	adds	D0, D0, 1
	mr	P1, D0

	// check if we've reached the last chiplet ID
	// we need to process
	cmpibrane D0, l3_setup_loop, 0x20

l3_setup_done:
	.endm


#endif
