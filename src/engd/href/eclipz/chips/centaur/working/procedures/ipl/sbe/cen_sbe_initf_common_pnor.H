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



#ifndef __CEN_SBE_INITF_COMMON_PNOR_H
#define __CEN_SBE_INITF_COMMON_PNOR_H


        .set RING_TBL_OFFSET_DDx, 0x0
        .set RING_TBL_OFFSET_OVR, 0x8


	// Load base ring image + override ring image if pointer is available
        .macro load_ring, name:req, skipoverride=0, hasalternate=0, index=0

        // Try the alternate ring first
	.if (\hasalternate == 1)
        la      A0, \name\()_ring_alt
        ld	D0, (\index*8), A0
	cmpibrane D0, 9999f, 0
        // Alt ring is empty, so try default ring
        .endif

        // Locate base DD ring image
        la      A0, \name\()_ring
        ld	D0, (\index*8), A0
        
	// Zero indicates no ring data available to load 
	cmpibraeq D0, 99f, 0

9999:
        // Skip past the metadata and call the ring scan routine
	mr	A0, D0
	ld      D1, 0, A0
        add     D0, D0, D1
        bsrd    D0

99:
	.if (\skipoverride == 0)
                .if (\index != 0)
                .error "You must use the skipoverride=1 flag when using an index with load_ring"
                .endif

	        // Execute override ring image
	        la      A0, \name\()_ring
	        ld      D0, RING_TBL_OFFSET_OVR, A0

	        // Zero indicates no ring data available to load
	        cmpibraeq D0, 999f, 0

	        mr      A0, D0
	        ld      D1, 0, A0
	        add     D0, D0, D1
	        bsrd    D0
999:
	.endif

        .endm

#endif
