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




#ifndef __PROC_SBE_L2_PGOOD_H
#define __PROC_SBE_L2_PGOOD_H

#include "proc_sbe_initf_common_seeprom.H"


	//----------------------------------------------------------------------
	// l2_single_member
	//----------------------------------------------------------------------
	// L2 partial good configuration macro
	// Assumes P0 is set to chiplet(s) to initialize
	// P1, A0, D0, D1 are destroyed, all other registers are preserved
	//----------------------------------------------------------------------

	.macro l2_single_member

	// use l2_single_member_enable_mask vector to determine if L2
	// cache configuration needs to be altered
	POREVE_DBG("<l2_setup>:	Reading L2 single member enable mask");
        lia     A0, PORE_SPACE_SEEPROM, l2_single_member_enable_mask
	ld      D1, 0x00, A0

	POREVE_INF("L2 single member enable mask = %016llx ...\n", io_pore.d1.read())

	// if mask is all clear, exit early
	braz	D1, l2_setup_done

	// determine which EX chiplet(s) are being initialized
	// (specified by P0) and use chiplet specific bit(s) of
	// l2_single_member_enable_mask to take appropriate action
l2_setup_process:
	mr	D1, P0
	ifbitset D0, D1, 57, l2_setup_multicast

l2_setup_unicast:
	// unicast, walk a single bit into its proper position in the
	// bitmask, based on pervasive base value in D0
	POREVE_DBG("<l2_setup>: Performing unicast L2 setup");
	// normalize chiplet ID (16-31) to loop count (15-0), store in CNT
	// left shift is most efficient
	ls	D0, 0x1f
	sub	D1, D0, D1
	mr	CTR, D1
	li	D1, BIT(31)
	bra	l2_setup_unicast_loop_end

l2_setup_unicast_loop_begin:
	sldi	D1, D1, 1

l2_setup_unicast_loop_end:
	loop	l2_setup_unicast_loop_begin
	bra	l2_setup_form_mask

l2_setup_multicast:
	// multicast, read partial good bitmask via mutlicast
	POREVE_DBG("<l2_setup>: Performing multicast L2 setup");
	ls      D0, SWITCH_WRITE_OP_TO_BITX_OP_MASK
	xor     D0, D0, D1
	mr      P1, D0
	// do multicast read to obtain set of enabled chiplets
	ld      D1, GENERIC_GP3_0x000F0012, P1

l2_setup_form_mask:
	// from either unicast/multicast path above, D1 will contain
	// per-chiplet bit mask of chiplets to consider
	// reload single member enable mask
	lia	A0, PORE_SPACE_SEEPROM, l2_single_member_enable_mask
	ld	D0, 0x00, A0
	and	D1, D0, D1
	// shift off non-EX chiplets (IDs 0-15)
	sldi	D1, D1, 0x10

	// D1 now contains per-chiplet action mask
	// use P1 to issue SCOMs to currently selected chiplet
	// via unicast
	POREVE_DBG("<l2_setup>: Mask of chiplets to act on %016llX", io_pore.d1.read());
	ls   	P1, 0x10

l2_setup_loop:
	// examine msb of per-chiplet mask associated with
	// current chiplet ID
	andi	D0, D1, BIT(0)
	braz	D0, l2_setup_next

l2_setup_action:
	// perform L2 configuration action for this chiplet
	POREVE_DBG("<l2_setup>: Setting L2 configuration for chiplet %02llX", io_pore.p1.read());
	bsi     D0, EX_L2_MODE_REG0_0x1001280A, P1, BITS(2,2)

l2_setup_next:
	// prep per-chiplet mask for next iteration
	sldi	D1, D1, 1
	// if mask has become zero we can exit early (there are no
	// more chiplets which need to be processed)
	braz	D1, l2_setup_done

	// prep pervasive base for next iteration
	mr	D0, P1
	adds	D0, D0, 1
	mr	P1, D0

	// check if we've reached the last chiplet ID
	// we need to process
	cmpibrane D0, l2_setup_loop, 0x20

l2_setup_done:
	.endm


#endif
