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

	.set	PIBMEM_LOADER_SUCCESS, 0
	.set	PIBMEM_LOADER_ALIGNMENT_ERROR, 1
	.set	PIBMEM_LOADER_OVERFLOW, 2
	.set	PIBMEM_LOADER_PIBMEM_ERROR, 3
	
	.set	COPY_SIZE_BYTES, (copy_end - copy)
	.set	COPY_SIZE_DW, (copy_end - copy) / 8

	// PIBMEM good status shows no errors, and the FSM state should be idle
	// (which is a 1 in bit 11).
	.set	PIBMEM_GOOD_STATUS, BIT(11)


//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

        // During execution:
        //
        // P0 : Holds the chiplet ID of the PIBMEM (constant)
        // A1 : Holds the base address of the PIBMEM image (constant)
        // A0 : Used to address the image to be copied
        // D1 : PIBMEM load address in doublewords (constant after error checks)
	// SPRG0 : The number of doublewords to copy (after error checks)

	.subroutine proc_sbe_pibmem_loader, ipl, "$Revision: 1.5 $"

        POREVE_INF("Loading %u bytes from image address 0x%08x "
                   "into PIBMEM address 0x%08x",
                   (uint32_t)io_pore.d0.read(), (uint32_t)io_pore.a0.read(),
                   (uint32_t)io_pore.d1.read());

	// Step 0.  Set up the invariant P0 register, then check the PIBMEM
	// status register for errors and correct state. This check and other
	// checks require that we use SPRG0 as scratch since the checks
	// destroy the paramater registers.

	lpcs	P0, PIBMEM0_0x00080000

	mr	SPRG0, D0
	ld	D0, PIBMEM_STATUS_0x00088005, P0
	cmpibrane D0, pre_error, PIBMEM_GOOD_STATUS
	mr	D0, SPRG0
	
	// Step 1. Set up the invariant A1 register and set up the PIBMEM for
	// indirect auto post-increment addressing. 

	mr	A1, A0
	sti	PIBMEM_CONTROL_0x00088000, P0, 0

	// Step 2. Consistency checks

	// Check the size of the image for alignment.  
	
	mr	SPRG0, D0
	andi	D0, D0, 0x7
	branz	D0, image_size_alignment
	mr	D0, SPRG0

	// Check the PIBMEM load address for alignment.  

	mr	SPRG0, D1
	andi	D1, D1, 0x7
	branz	D1, load_address_alignment
	mr	D1, SPRG0
	
	// Check to make sure the image will fit in the PIBMEM.
             
	mr	SPRG0, D0
	add	D0, D0, D1
	subs	D0, D0, PIBMEM_SIZE
	tfbugt	D0, overflow
	mr	D0, SPRG0

	// Change byte sizes to doubleword sizes. D1 (the PIBMEM load address
	// is invariant after this point. 

	srdi	D0, D0, 3
	srdi	D1, D1, 3

	// Step 3.  For small images, go directly to step 6a after setting up
	// the CTR with the actual number of doublewords to copy.  Note: SPRG0
	// holds the original number of doublewords to copy through steps 4
	// and 5.
	
	mr	SPRG0, D0
	subs	D0, D0, COPY_SIZE_DW
	tfbugt	D0, step4

	mr	CTR, SPRG0
	bra	step6a

	// Step 4.  The copy loop, running from the current context, copies
	// itself to PIBMEM.  The load address is initialized from the
	// parameter held in D1.
step4:	
	ls	CTR, COPY_SIZE_DW
	std	D1, PIBMEM_ADDRESS_0x00088001, P0
	la	A0, copy
	bsr	copy

	// Step 5.  The copy-loop, now running from PIBMEM, copies the bulk of
	// the image into PIBMEM.  The CTR is initialized with the bulk
	// doublewords to copy, and A0 is initialized with the bulk address. D0
	// computes the PIBMEM address of the bootloader. D1 must be computed
	// back to a byte address to compute the branch address.

	mr	D0, SPRG0
	subs	D0, D0, COPY_SIZE_DW
	mr	CTR, D0
	
	mr	A0, A1
	adds	A0, A0, COPY_SIZE_BYTES 

	lia	D0, PORE_SPACE_PIBMEM, 0
	sldi	D1, D1, 3
	or	D0, D0, D1
	srdi	D1, D1, 3
	bsrd	D0

	// Step 6.  The copy-loop, running from the current context again,
	// copies the intial bytes of the PIBMEM image into PIBMEM.  The
	// special entry point step6a is used for copying images smaller than
	// the size of the copy-loop.
	
	ls	CTR, COPY_SIZE_DW
step6a:
	mr	A0, A1
	std	D1, PIBMEM_ADDRESS_0x00088001, P0
	bsr	copy

	// Step 7.  Check the PIBMEM status register for errors and correct
	// state. 

	ld	D0, PIBMEM_STATUS_0x00088005, P0
	cmpibrane D0, post_error, PIBMEM_GOOD_STATUS
	
	// Done
	
	.end_subroutine proc_sbe_pibmem_loader


	// Error code.

pibmem_loader_errors:
	
pre_error:
	POREVE_ERR("proc_sbe_pibmem_loader: Unexpected status from " \
			"PIBMEM prior to execution of the procedure : " \
			"0x%016llx", io_pore.d0.read());
	reqhalt	RC_SBE_PIBMEM_PRE_ERROR

post_error:
	POREVE_ERR("proc_sbe_pibmem_loader: Unexpected status from " \
			"PIBMEM after execution of the procedure : " \
			"0x%016llx", io_pore.d0.read());
	reqhalt	RC_SBE_PIBMEM_POST_ERROR

image_size_alignment:
	POREVE_ERR("proc_sbe_pibmem_loader : The size of the image to load " \
			"is 0x%08x, which is not a multiple of 8", \
			 (uint32_t)(io_pore.sprg0.read()));
	reqhalt	RC_SBE_PIBMEM_IMAGE_SIZE_ALIGNMENT

load_address_alignment:
	POREVE_ERR("proc_sbe_pibmem_loader : The load address " \
			"is 0x%08x, which is not a multiple of 8", \
			 (uint32_t)(io_pore.sprg0.read()));
	reqhalt	RC_SBE_PIBMEM_LOAD_ADDRESS_ALIGNMENT

overflow:
	POREVE_ERR("proc_sbe_pibmem_loader : The load image would overflow " \
			"PIBMEM given the load address (0x%08x) and image " \
			"size (0x%08x)", \
			(uint32_t)(io_pore.d1.read()), \
			(uint32_t)(io_pore.sprg0.read()));
	reqhalt	RC_SBE_PIBMEM_OVERFLOW
	
	.epilogue pibmem_loader_errors

	
	// The copy loop.
	//
	// At Entry:
	//
	//   A0  : The address of the image to copy
	//   CTR : The number of doublewords to copy
	//   P0  : The chiplet Id of the PIBMEM
	//
	// At Exit:
	//
	//   A0, CTR, D0 : Destroyed

	.balign	8
copy:	
	bra	2f
1:
	ld	D0, 0, A0
	std	D0, PIBMEM_DATA_INC_0x00088003, P0
	adds	A0, A0, 8
2:	
	loop	1b
	ret
	.balign	8
copy_end:
	.epilogue copy


