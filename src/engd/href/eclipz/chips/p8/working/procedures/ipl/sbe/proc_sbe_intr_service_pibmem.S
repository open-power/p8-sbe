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
#include "p8_scom_addresses.H"
#include "proc_sbe_intr_service.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .pibmem

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

     //
     // mailbox scan request constants
     //

     // request valid
        .set    REQ_VALID_MASK, BIT(0)
     // halt request
	.set	REQ_HALT_MASK, BIT(1)
     // decrementer loop count
	.set	DECREMENTER_LOOP_MASK, BITS(8,24)
	.set	DECREMENTER_LOOP_SHIFT, 32

     // decrementer sleep delay (achieve ~10us total loop time @ 2.4 GHz)
	.set	DECREMENTER_DELAY, 0x145A


//------------------------------------------------------------------------------
// Local Macros 
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure - pibmem
//------------------------------------------------------------------------------

	.global	proc_sbe_intr_service_pibmem
	.subroutine proc_sbe_intr_service_pibmem, pibmem, "$Revision: 1.3 $"
	
	POREVE_DBG("proc_sbe_intr_service: Marking SBE ready to service interrupt requests");
     // clear request mailbox (host->SBE)
        lpcs    P0, STBY_CHIPLET_0x00000000
        sti     MBOX_SCRATCH_REG2_0x0005003A, P0, 0
     // clear decrementer count
	ls	CTR, 0
     // clear progress counter (used for identifying critical section)
	ls	A0, 0
     // expose us delay
	ld	D0, proc_sbe_intr_service_delay_us, P0
	mr	A1, D0
     // write initial progress code
	sti     MBOX_SBEVITAL_0x0005001C, P0, ((PROC_SBE_INTR_SERVICE_ISTEP_NUM << 4) | PROC_SBE_INTR_SERVICE_SUBSTEP_SBE_READY) << 32
	bra	proc_sbe_intr_service_pibmem_wait

	.balign PORE_INSTRUCTION_BUFFER_SIZE
	.global proc_sbe_intr_service_pibmem_loop
proc_sbe_intr_service_pibmem_loop:
	nop
     // execute wait instruction which paces rate of decrementer & prevents SBE from consuming PIB with mailbox poll requests
proc_sbe_intr_service_pibmem_wait:
	waits	DECREMENTER_DELAY
     // tick progress counter before critical section
	adds	A0, 1
     // read & clear request mailbox
        POREVE_DBG("proc_sbe_intr_service: Polling for new interrupt request from host");
        ld      D1, MBOX_SCRATCH_REG2_0x0005003A, P0
	sti	MBOX_SCRATCH_REG2_0x0005003A, P0, 0
     // tick progress counter after critical section
	adds	A0, 1

     // check for a valid request
        POREVE_DBG("proc_sbe_intr_service: Read MBOX: %16llx", io_pore.d1.read());
        andi    D0, D1, REQ_VALID_MASK
     // if no new request, jump to decrementer update
	braz	D0, decrement
     // check for halt, stop SBE if requested
	andi	D0, D1, REQ_HALT_MASK
	branz	D0, proc_sbe_intr_service_pibmem_halt_requested

process_request:
     // load new decrementer parameters
	POREVE_DBG("proc_sbe_intr_service: Processing new interrupt request");
     // set decrementer (clamp to minmum value of 1 to ensure interrupt)
	andi	D0, D1, DECREMENTER_LOOP_MASK
	srdi	D0, D0, DECREMENTER_LOOP_SHIFT
	branz	D0, load_decrementer
	ls	D0, 1
load_decrementer:
	mr	CTR, D0
     // mark request done
	bra	proc_sbe_intr_service_pibmem_wait

decrement:
     // halt decrement at zero
	braz	CTR, proc_sbe_intr_service_pibmem_wait
     // tick decrementer
	subs	CTR, 1
     // if non-zero, go back to sleep
	branz	CTR, proc_sbe_intr_service_pibmem_wait
     // else, fire interrupt on 1->0 transition
//	sti	MBOX_SCRATCH_REG1_0x00050039, P0, 0xFEEDB0B000000000
	sti	OCC_ITP_MISC_OR_0x0006A022, P0, BIT(0) | BIT(14)
	bra	proc_sbe_intr_service_pibmem_wait

	.global proc_sbe_intr_service_pibmem_halt_requested
proc_sbe_intr_service_pibmem_halt_requested:
        sti     MBOX_SBEVITAL_0x0005001C, P0, ((PROC_SBE_INTR_SERVICE_ISTEP_NUM << 4) | PROC_SBE_INTR_SERVICE_SUBSTEP_HALT_SUCCESS) << 32
        reqhalt RC_SBE_SUCCESS, D0, P1

	.end_subroutine proc_sbe_intr_service_pibmem
