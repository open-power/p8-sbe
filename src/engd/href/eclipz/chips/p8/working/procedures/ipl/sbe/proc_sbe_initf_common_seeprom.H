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




#ifndef __PROC_SBE_INITF_COMMON_SEEPROM_H
#define __PROC_SBE_INITF_COMMON_SEEPROM_H


        //Inverting 58:60 switches from MC write op(101) to bitx read op(010)
        .set SWITCH_WRITE_OP_TO_BITX_OP_MASK, BITS(58,3)


        //----------------------------------------------------------------------
        // load_ring
        //----------------------------------------------------------------------
	// Assumes P0 contains the chiplet(s) to scan
        // A0, A1, D0, D1, P1, SPRG0, CTR and the ALU flags are destroyed
        //
	// Load base ring image + override ring image if pointer is available
        //
        // Note: rings in the fixed section don't have overrides, so must
        //  be called with skipoverride=1
           .macro load_ring, name:req, skipoverride=0, hasalternate=0, index=0, conditional_override=0

        // Try the alternate ring first, because we can't scan both base and alternate
	.if (\hasalternate == 1)
        la      A0, \name\()_ring_alt
        ld	D0, (\index*8), A0
	branz   D0, 9999f
        // Alt ring is empty, so try default ring
        .endif

        // Locate base DD ring image
        la      A0, \name\()_ring
        .if (\index == 0)
9999:
                bsr     scan_a0
        .else
        ld	D0, (\index*8), A0
9999:
        bsr     scan_d0
        .endif

	.if (\skipoverride == 0)
                .if (\index != 0)
                .error "You must use the skipoverride=1 flag when using an index with load_ring"
                .endif

                .if (\conditional_override == 1)
                   la      A0, skip_ex_override_ring_scans
                   ld      D0, 0x0, A0
                   branz   D0, 99999f
                .endif
                   
	        // Execute override ring image
	        la      A0, \name\()_ring

                bsr     scan_a0_override
99999:
	.endif

        .endm


        //----------------------------------------------------------------------
        // load_ring_vec_ex_unicast
        //----------------------------------------------------------------------
	// Assumes D0 contains P0
        // A0, A1, D0, D1, P1, SPRG0, CTR and the ALU flags are destroyed
	.macro load_ring_vec_ex_unicast name: req, id:req, next_id:req, done_target: req 

load_ring_vec_ex_unicast_\name\()_\id:
	// if id doesn't match D0, then try the next one
	cmpibrane D0, load_ring_vec_ex_unicast_\name\()_\next_id, (0x10+\id)
        
	// match, so do the scan and branch to done
	load_ring \name index=\id skipoverride=1
        bra     \done_target
        .endm

        //----------------------------------------------------------------------
        // load_ring_vec_ex_multicast
        //----------------------------------------------------------------------
        // Assumes: D0 contains the partial good vector
        //          CTR, A0, and D0 are already saved in PIBMEM
        // At Exit:
        //     A1, D1, P0, P1, SPRG0, and the ALU flags are destroyed
        //     A0, D0, and CTR are restored from PIBMEM
	.macro load_ring_vec_ex_multicast name: req, id:req, next_id:req

load_ring_vec_ex_multicast_\name\()_\id:
	// if bit for this chiplet isn't set, then try the next one
        ifbitclr D1, D0, (0x10+\id), load_ring_vec_ex_multicast_\name\()_\next_id

        // match, so do the scan and restore state before continuing
        ls      P0, (0x10+\id)
        POREVE_INF("Scanning EX%llu Core rings ...\n", (io_pore.p0.read() & 0x0F) )
        load_ring \name index=\id skipoverride=1
        bsr       restore_ctr_a0_d0_module
        .endm


        //----------------------------------------------------------------------
        // load_ring_vec_ex
        //----------------------------------------------------------------------
        // Assumes: P0 contains the chiplet(s) to be scanned
        // 
        // At Exit:
        //     A0, A1, D0, D1, P1, SPRG0, CTR, and the ALU flags are destroyed
	.macro load_ring_vec_ex name: req

        //Check for multicast
        mr      D0, P0
        ifbitset D1, D0, 57, multicast

unicast:
        //D0 contains a copy of P0
        //Note: only the chiplet number in D0 will be scanned, the others will be skipped
        //Unicast scan code     (name,        id, next,   done)
        load_ring_vec_ex_unicast \name, 1,  2,     scan_done
        load_ring_vec_ex_unicast \name, 2,  3,     scan_done
        load_ring_vec_ex_unicast \name, 3,  4,     scan_done
        load_ring_vec_ex_unicast \name, 4,  5,     scan_done
        load_ring_vec_ex_unicast \name, 5,  6,     scan_done
        load_ring_vec_ex_unicast \name, 6,  9,     scan_done
        load_ring_vec_ex_unicast \name, 9,  10,    scan_done
        load_ring_vec_ex_unicast \name, 10, 11,    scan_done
        load_ring_vec_ex_unicast \name, 11, 12,    scan_done
        load_ring_vec_ex_unicast \name, 12, 13,    scan_done
        load_ring_vec_ex_unicast \name, 13, 14,    scan_done
        load_ring_vec_ex_unicast \name, 14, error, scan_done
load_ring_vec_ex_unicast_\name\()_error:        
        POREVE_ERR("Failed to find a chiplet to scan") ;
        reqhalt    RC_SBE_LOAD_RING_VEC_EX_\name\()_ERROR

multicast:
	// Get the list of good EX chiplets into D0
        //D0 contains a copy of P0
        //xori    D0, D0, SWITCH_WRITE_OP_TO_BITX_OP_MASK --JDS ls + xor is shorter than xori
        ls      D1, SWITCH_WRITE_OP_TO_BITX_OP_MASK
        xor     D0, D0, D1
        mr      P1, D0
        ld      D0, GENERIC_GP3_0x000F0012, P1
        // Save P0 in CTR
        mr      CTR, P0
        // Don't care about A0 for core
        // Save off CTR, A0, D0
        bsr     store_ctr_a0_d0_module
        //P0 has been destroyed by the subroutine call, but is saved in CTR

        //Note: only the chiplets in D0 will be scanned, the others will be skipped
        //Multicast scan code     (name,        id, next)
        load_ring_vec_ex_multicast \name, 1,  2
        load_ring_vec_ex_multicast \name, 2,  3
        load_ring_vec_ex_multicast \name, 3,  4
        load_ring_vec_ex_multicast \name, 4,  5
        load_ring_vec_ex_multicast \name, 5,  6
        load_ring_vec_ex_multicast \name, 6,  9
        load_ring_vec_ex_multicast \name, 9,  10
        load_ring_vec_ex_multicast \name, 10, 11
        load_ring_vec_ex_multicast \name, 11, 12
        load_ring_vec_ex_multicast \name, 12, 13
        load_ring_vec_ex_multicast \name, 13, 14
        load_ring_vec_ex_multicast \name, 14, cleanup
load_ring_vec_ex_multicast_\name\()_cleanup:
        //Set P0 back to the multicast group
        mr      P0, CTR

scan_done:
        .endm



#endif
