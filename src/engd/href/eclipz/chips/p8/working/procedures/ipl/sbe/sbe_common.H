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



#ifndef __SBE_COMMON_H
#define __SBE_COMMON_H

// $Id: sbe_common.H,v 1.27 2013/07/22 21:08:56 jeshua Exp $

/// \file sbe_common.H

/// \brief This header contains #include-s and macro definitions common to P8
/// and Centaur SBE code development.  It is #include-ed into p8_sbe.H and
/// cen_sbe.H which have other setup specific to each environment.

#include "pgas.h"
#include "sbe_link.H"
#include "sbe_xip_image.h"
#include "sbe_xip_header.H"
#include "pore_bitmanip.H"
#include "poreve_hooks.H"
#include "proc_control_bits.H"

/// The size of the PORE engine instruction buffer
///
/// This constant is used as an alignment target to enable safe development of
/// self-modifying code.  Currently only the OCI-attached engines include an
/// instruction buffer, however ideally they eventually all will.
#define PORE_INSTRUCTION_BUFFER_SIZE 8


#ifdef __ASSEMBLER__

/// \defgroup proc_sbe_halt_codes SBE Procedure Halt Codes
///
/// Standard halt codes inserted into SBEVITAL[12:15] when the SBE engine
/// halts successfully or due to an error.
///
/// If the SBE halts due to an error, then the SBEVITAL register fields
/// SBE_PROC_AREA and SBE_PROC_ID identify the procedure in execution at the
/// time of the error. The procedure may also have updated the SBE_PROC_STEP
/// field from its initial 0 value to indicate where in the procedure the
/// error occurred, or which particular error is being signalled. See each
/// individual procedure for details.
///
/// Normally all error halts are signalled with the reqhalt macro which leaves
/// the SBE vital halt code at it's default 0 (fatal error) value.  The caller
/// then uses the contents of the .halt section to determine the exact error
/// being signalled.
///
/// Note: SBEVITAL halt codes are only set by the SBE engine, never by the
/// PORE-SLW running Sleep/Winkle wakeup procedures.
///
/// @{

	// The default value; A generic fatal error
	.set	PROC_SBE_HC_FATAL,          0x0

	.set	PROC_SBE_HC_UNASSIGNED_0x1, 0x1
	.set	PROC_SBE_HC_UNASSIGNED_0x2, 0x2
	.set	PROC_SBE_HC_UNASSIGNED_0x3, 0x3
	.set	PROC_SBE_HC_UNASSIGNED_0x4, 0x4
	.set	PROC_SBE_HC_UNASSIGNED_0x5, 0x5

	// -*- Deprecated -*- Checkstop/recoverable/special attention
	.set	PROC_SBE_HC_XRS,            0x6

	// -*- Deprecated -*-  SCAN0 OPCG polling timout
	.set	PROC_SBE_HC_SCAN0_TIMEOUT,  0x7

	// -*- Deprecated -*- A fatal error; The SBEVITAL.sbe_step_code
	// contains the proc.-specific code
	.set	PROC_SBE_HC_STEP,           0x8

	// -*- Deprecated -*- CHIPLET error: CLOCKS couldn´t be started
	.set	PROC_SBE_HC_CLOCK_ERROR,    0x9

	.set	PROC_SBE_HC_UNASSIGNED_0xa, 0xa
	.set	PROC_SBE_HC_UNASSIGNED_0xb, 0xb
	.set	PROC_SBE_HC_UNASSIGNED_0xc, 0xc
	.set	PROC_SBE_HC_UNASSIGNED_0xd, 0xd
	.set	PROC_SBE_HC_UNASSIGNED_0xe, 0xe

	// Success
	.set	PROC_SBE_HC_SUCCESS,        0xf

/// }@

#endif // __ASSEMBLER__

#ifdef __ASSEMBLER__


	// These eCmd headers are commonly required for VBU hook code.

        ##`#include "fapiSharedUtils.H"
        ##`#include "ecmdUtils.H"


/// Generate a HALT instruction indexed in the .halt section
///
/// The halt code is required to be a defined assembler symbol.
/// RC_SBE_SUCCESS, RC_SBE_PROC_PRE_HALT and RC_SBE_PROC_POST_HALT require
/// updating SBEVITAL.halt_code to PROC_SBE_HC_SUCCESS, which is done in a
/// helper macro. For good halts the user must provide a Dx/Px pair to scratch
/// to update SBEVITAL.  The Dx/Px pair are not required for bad halts as the
/// machine will simply stop without corrupting any state. Good halts never
/// dump; a bad halt will cause a dump if dump is set to 1 on the halt.
///
/// For bad halts and the RC_SBE_SUCCESS halt the 32-bit halt code itself is
/// assembled into memory following the HALT instruction.  The PC will be
/// pointing to the code when the machine stops. Since this is likely an
/// illegal instruction is will not be possible to simply continue after a bad
/// halt or completion halt.  The halt code is not written into memory for the
/// procedure control halts, so it is possible to continue after them.
///
/// All halts are indexed in the .halt section, which maps the address the PC
/// will contain at the time of the halt to the string form of the return
/// code.  All structures in the .halt section are 4-byte aligned.
///
/// Note: A decision was made to treat a procedure-control HALT as a
/// successful halt in the SBE vital register.  The entity looking at the
/// final SBE vital may need to do more analysis to determine if the HALT
/// indicates a true completion of the IPL, or simply the completion of a
/// procedure.

	.macro	reqhalt, code:req, dx=-1, px=-1, dump=0

	// The halt code is required to be a defined symbol
	
	.ifndef	\code
	.error	"reqhalt: Return code is not a defined symbol; Check for typos or missing XML files in the Makefile"
	.endif

	// Handle good halts

	.if	((\code == RC_SBE_SUCCESS) || \
                 (\code == RC_SBE_SUCCESS_SLAVE_CHIP) || \
                 (\code == RC_SBE_PAUSE_WITH_SUCCESS) || \
		 (\code == RC_SBE_PROC_ENTRY_HALT) || \
		 (\code == RC_SBE_PROC_EXIT_HALT))

		.if	(((\dx) < 0) || ((\px) < 0))
                        .error	"reqhalt: Non-error halts must provide Dx and Px parameters"
		.endif
	
		updatehalt PROC_SBE_HC_SUCCESS, (\dx), (\px)

	.else

		.if	(((\dx) >= 0) || ((\px) >= 0))
                        .error	"reqhalt: Dx and Px parameters are not required for error halts"
		.endif
	
		.if	(\dump != 0)
			POREVE_DUMP()
		.endif
	.endif


	// Generate the halt and insert the halt code in the word following
	// the halt. The halt code is not inserted for the entry/exit halts
	// since execution must continue from those points.  Also create a
	// text entry in the .halt section indexed by the PC that will be
	// observed when the machine stops.

	// Also don't insert the halt code for slave chip success, so that
        // IPL controller can "continue" the IPL with no ill effects on the
        // slave chips.

        // Rather than using a real halt instruction, we'll use an invalid
        // instruction (ascii "halt") that will cause the SBE to halt with
        // and invalid instruction error. The bad instruction will be
        // trapped in the IBUF regs, so debug code can detect this and
        // will know to look at the next 4 bytes for the error RC
	.if	((\code != RC_SBE_SUCCESS)    && \
		 (\code != RC_SBE_PROC_ENTRY_HALT)    && \
		 (\code != RC_SBE_PROC_EXIT_HALT)     && \
		 (\code != RC_SBE_SUCCESS_SLAVE_CHIP) && \
		 (\code != RC_SBE_PAUSE_WITH_SUCCESS) )
	.byte 'h'
	.byte 'a'
	.byte 'l'
	.byte 't'
7374258:
	.long	\code
        .else
        halt
7374258:
	.endif	

	.pushsection .halt
	.balign	4
	.quada	7374258b
	.asciz	"\code"
	.balign 4
	.popsection

	.endm
	

/// Update SBEVITAL[12:15] (SBE_HALT_CODE) with a 4-bit halt code from the set
/// PROC_SBE_HC_*
///
/// The caller must name a Dx and a Px register to scratch.  If regparm=1 is
/// specified, then the code parameter is a data register that contains the
/// halt code, but this register can not be Dx.
///
/// Note: True SBEVITAL halt codes are only set by the SBE engine.  SLW code
/// sets its virtual slw_vital register in PIBMEM.

        .macro  updatehalt, code:req, dx:req, px:req, regparm=0
        
        ..data  (\dx), "updatehalt: Expecting a data register"
        ..pervasive_chiplet_id (\px), \
               "updatehalt: Expecting a pervasive chiplet id register"
        
        .if (\regparm)
            ..dxdy  (\code), (\dx), \
                "updatehalt: Expecting D0, D1 in either order"
        .else
            ..checku (\code), 4, \
                "updatehalt: Halt code must be 0x0 <= code <= 0xf"
        .endif
        
#ifndef __SBE_ONLY__

        tebsbe (\dx), 873283f

        // Virtual slw_vital update for PORE-SLW

        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)

        lpcs    (\px), PIBMEM0_0x00080000
        ld      (\dx), slw_vital, (\px)
        
        .if (\regparm)
            insrdi  (\dx), (\code), 4, 12
        .else
            insertbits (\dx), 12, 4, (\code)
        .endif
        
        .if     ((\dx) == D0)
                POREVE_DBG("updatehalt: SLW Vital virtual register update : " \
                           "%016llX", \
                            io_pore.d0.read())
        .else
                POREVE_DBG("updatehalt: SLW Vital virtual register update : " \
                           "%016llX", \
                            io_pore.d1.read())
        .endif                

        std     (\dx), slw_vital, (\px)
        bra     873284f    
        
#endif
        
873283: 
        // SBEVITAL update for PORE-SBE

        lpcs    (\px), MBOX_SBEVITAL_0x0005001C
        ld      (\dx), MBOX_SBEVITAL_0x0005001C, (\px)
        
        .if (\regparm)
            insrdi  (\dx), (\code), 4, 12
        .else
            insertbits (\dx), 12, 4, (\code)
        .endif
        
        .if     ((\dx) == D0)
                POREVE_DBG("updatehalt: SBE Vital register update : %016llX",
                    io_pore.d0.read())
        .else
                POREVE_DBG("updatehalt: SBE Vital register update : %016llX",
                    io_pore.d1.read())
        .endif                

        std     (\dx), MBOX_SBEVITAL_0x0005001C, (\px)

873284: 
        .endm


/// Update SBEVITAL[28:31] (SBE_PROC_STEP) with a procedure-specific 4-bit
/// step code
///
/// The caller must name a Dx and a Px register to scratch.  If regparm=1 is
/// specified, then the step parameter is a data register that contains the
/// step code, but this register can not be Dx.
///
/// Note: True SBEVITAL halt codes are only set by the SBE engine.  SLW code
/// sets its virtual slw_vital register in PIBMEM.
/// 
/// THE PIBMEM MUST BE FUNCTIONAL WHEN THIS IS CALLED!
/// Note: if CENTAUR is defined, updatestep becomes updatestep_inline

        .macro	updatestep, step:req, dx:req, px:req, regparm=0
#ifndef CENTAUR
	..data	(\dx), "updatestep: Expecting a data register"
	..pervasive_chiplet_id (\px), \
      	"updatestep: Expecting a pervasive chiplet id register"

	.if	(\regparm)
		..dxdy	(\step), (\dx), \
      		"updatestep: Expecting D0, D1 in either order"
	.else
		..checku (\step), 4,                                    \
      		"updatestep: Step code must be 0x0 <= code <= 0xf"
	.endif

        // Setup PRV_BASE_ADDR0; points to PIB
        lpcs    (\px), STBY_CHIPLET_0x00000000

        .pibmem_port (PORE_SPACE_PIBMEM & 0xf)

        //save off P1 if it's not OK to destory it
        .if (\px != P1)
        mr      (\dx), P1
        std     (\dx), sbe_scan_state_memory0, (\px)
        lpcs    P1, STBY_CHIPLET_0x00000000
        .endif

        //save off D0 if it's not OK to destory it
        .if (\dx != D0)
        std     D0, sbe_scan_state_memory1, P1
        .endif

        //save off D1 if it's not OK to destroy it
        .if (\dx != D1)
        std     D1, sbe_scan_state_memory2, P1
        .endif

        //Set D1 to the step
        .if (\regparm)
          .if (\dx == D1)
             //This means step was in D0, so move it into D1
             mr D1, D0
          .else
          //step was in D1 already, so do nothing
          .endif
        .else
          //Not regparm, so put step into D1
          ls      D1, (\step)
        .endif

        //Now it's safe to destroy D0, P1, and set step D1
        bsr     updatestep_D0_P1_step_D1

        //Restore P1 if needed
        .if (\px != P1)
        ld      (\dx), sbe_scan_state_memory0, (\px)
        mr      P1, (\dx)
        .endif
        
        //Restore D0 if needed
        .if (\dx != D0)
        ld      D0, sbe_scan_state_memory1, (\px)
        .endif

        //Restore D1 if needed
        .if (\dx != D1)
        ld      D1, sbe_scan_state_memory2, (\px)
        .endif
	.endm



         //This is the space-wasting inline version of the macro
         //Needed for when PIBMEM isn't available yet
	.macro	updatestep_inline, step:req, dx:req, px:req, regparm=0
#endif
	..data	(\dx), "updatestep_inline: Expecting a data register"
	..pervasive_chiplet_id (\px), \
      	"updatestep_inline: Expecting a pervasive chiplet id register"

	.if	(\regparm)
		..dxdy	(\step), (\dx), \
      		"updatestep_inline: Expecting D0, D1 in either order"
	.else
		..checku (\step), 4,                                    \
      		"updatestep_inline: Step code must be 0x0 <= code <= 0xf"
	.endif
	
	lpcs    (\px), MBOX_SBEVITAL_0x0005001C

	.if	(\regparm)
        	ld	(\dx), MBOX_SBEVITAL_0x0005001C, (\px)
		insrdi	(\dx), (\step), 4, 28
	.else
		insertbitsscom (\dx), MBOX_SBEVITAL_0x0005001C, (\px), 28, 4, (\step)
	.endif

        .if     ((\dx) == D0)
        	POREVE_DBG("updatestep_inline:	SBE Vital register update : %016llX",
                	io_pore.d0.read())
        .else
        	POREVE_DBG("updatestep_inline:	SBE Vital register update : %016llX",
                	io_pore.d1.read())
        .endif

	std	(\dx), MBOX_SBEVITAL_0x0005001C, (\px)

	.endm

	
/// A section for data required to be at a fixed location, and always available
/// for easy search/update even in stripped images.
	
	.section .fixed, "a", @progbits

/// A section containing a reduced TOC entry for the .fixed section	

	.section .fixed_toc, "a", @progbits

/// A section for 8-byte aligned PORE data required during the IPL

        .section .ipl_data, "a", @progbits

        .macro  .ipl_data
	.section .ipl_data
        .balign 8
        .endm

/// A section for 4-byte aligned PORE text required during the IPL

        .section .ipl_text, "ax", @progbits

	.macro  .ipl_text
        .section .ipl_text
        .balign 4
        .endm

/// A section for 8-byte aligned PORE data required at runtime
///
/// Aliased to standard .data section		

        .macro  .rt_data
	.data
        .balign 8
        .endm

/// A section for 4-byte aligned PORE text required at runtime
///
/// Aliased to standard .text section
	
	.macro  .rt_text
        .text
        .balign 4
        .endm

/// A section for global SBE-PNOR Table of Contents (TOC) records
///
/// Each TOC record contains either the data (for scalar types) or a pointer
/// to the data (for string and vector types) along with a pointer to a string
/// identifying the data and the data type.

        .section .toc, "a", @progbits

/// A section for global SBE-PNOR data strings
///
/// This section is for use by the TOC and for external tools.  The TOC Id
/// keys are stored here. Several types of meta-data are also string entries,
/// e.g., procedure revision levels. These strings are all linked in the
/// .strings section. To save space these strings are packed rather than being
/// 8-byte aligned as would be required if they were to be used by PORE code.

        .section .strings, "aS", @progbits

/// A section for records associating HALT addresses with fapi::ReturnCode
/// strings
///
/// Records in the .halt section are created by the reqhalt macro.  The data
/// layout and usage is described in the header sbe_xip_image.h; see the
/// structure SbeXipHalt.
///
/// For consistency between the way that PIBMEM and other images are
/// processed, the .halt section is treated as pure meta-data that is not
/// "allocated" in the binary.  The .halt sections are extracted from the
/// object files and then inserted into the SBE-XIP binaries after they have
/// been built.

        .section .halt, "", @progbits

/// A dummy illegal section
///
/// This must be the last new section type declared.  As a loadable section,
/// this becomes the default section of any subsequent code or data.  This
/// section is not named in the linker scripts so that it will cause link
/// errors unless each code file implicitly or explicitly names the assembly
/// section.

        .section .illegal, "ax", @progbits


/// Declare a subroutine, procedure or array 'epilogue'
///
/// The .epilogue pseudo-op defines a type and size of a symbol, which could
/// be a subroutine, procedure, or even a data array.  This allows you to find
/// out how much code or data is associated with a particular procedure,
/// subroutine or array.  By default the macro records size information for
/// functions.  To record size information for generic data you can specify
/// the optional second argument as @object.  The .epilogue macro is placed
/// immediately after the code or data to be measured and records the size as
/// the current location counter minus a symbol (which is presumed to name the
/// first byte of the code or data to be measured.)
///
/// Size information is available using the -S option of nm. For example try
/// somthing like the below, which provides a report of the addresses and
/// sizes of all text symbols with size information.
///
/// \code
///     nm -S bin/sbe_seeprom.out | egrep "^([[:xdigit:]]){16} ([[:xdigit:]]){16} [Tt]"
/// \endcode
///	

	.macro	.epilogue, symbol:req, type=@function

        .type   \symbol, \type
        .size   \symbol, (. - \symbol)
		
	.endm


/// Declare a procedure
///
/// \param[in] proc The procedure name (symbol name)
///
/// \param[in] type The procedure type.  The procedure type is a symbol chosen
/// from the following:
///
/// - otprom This is an OTPROM procedure
///
/// - ipl This is a procedure that is only required during P8 IPL
///
/// - cen This is a procedure that is only required to IPL Centaur
///
/// - slw This is a procedure that is required to support Sleep/Winkle
/// operations.
///
/// \param[in] revision The CVS revision string.  This argument should always
/// be coded as "$Revision: 1.27 $" (including double quotes) in the initial coding
/// of a procedure.
///
/// A \e procedure is \e not a subroutine.  In order to preserve precious
/// stack entries, a procedure is more like a separately-compiled macro.
/// Procedures are only called from a single unique location.  The .callproc
/// macro calls the procedure by branching to it; the .end_procedure macro
/// branches back to the unique calling location.
///
/// The behavior of the .procedure macro varies depending on whether the
/// procedure targets OTPROM or an SBE-XIP image.
///
/// This macro does the following for OTPROM procedures
///
/// - Switches to .ipl_text
///
/// - Declares the procedure entry point as a global symbol
///
/// This macro does the following for procedures going into SBE-XIP images:
///
/// - Declares a global TOC entry that contains the entry point of the
/// procedure.  The TOC entry is indexed with the procedure name <proc>.
///
/// - Declares a global TOC entry that contains a string form of the revision
/// ID of the procedure, <proc>_revision.
///
/// - Switches to the proper text section, which is either .ipl_text or
/// .rt_text depending on the parameter.
///
/// - Declares the procedure entry point as a global symbol

        .macro  .procedure, proc:req, type:req, revision:req

        .if     (_PGAS_DEFAULT_SPACE == PORE_SPACE_OTPROM)

        // OTPROM procedure

        .ifnc   \type, otprom
        .error  "All OTPROM-space procedures must be type 'otprom'"
        .endif

        .ipl_text

        .global \proc
\proc\():

        .elseif ((_PGAS_DEFAULT_SPACE == PORE_SPACE_PNOR) || \
		 (_PGAS_DEFAULT_SPACE == PORE_SPACE_SEEPROM))

        // PNOR/SEEPROM procedure - All of the PNOR/SEEPROM procedure control
        // variables are allocated in the .fixed section.

	//.xip_cvs_revision \proc\()_revision, "\revision"
	.xip_address \proc

        .ifc    \type, ipl
        .ipl_text
        .else
        .ifc    \type, slw
        .ipl_text
        .else
	.ifc	\type, cen
	.ipl_text
	.else		
        .error  "All SEEPROM- and PNOR-space procedures must be type 'ipl', 'slw' or 'cen'"
        .endif
        .endif
	.endif

        .global \proc
\proc\():

        .elseif (_PGAS_DEFAULT_SPACE == PORE_SPACE_OCI)

        // OCI procedure

        .xip_quad \proc\()_control, 0
	//.xip_cvs_revision \proc\()_revision, "\revision"
	.xip_address \proc

        .ifc    \type, slw
        .rt_text
        .else
        .ifc    \type, rt
        .rt_text
        .else
        .error  "All OCI-space procedures must be type 'slw' or 'rt'"
        .endif
	.endif

        .global \proc
\proc\():

        .else
        .error  "Procedures must be declared in OTPROM, SEEPROM, PNOR or OCI space"
        .endif

        .endm


/// End a procedure
///
/// \param[in] proc The procedure name (symbol name)
///
/// This macro does the following:
///
/// - Generates a branch back to the unique .callproc macro that invokes
/// the procedure.
///
/// - Generates some debugging information about the procedure

        .macro  .end_procedure, proc:req

	.ifndef	\proc
	.error	"The symbol \proc referenced by .end_procedure is not defined"
	.error  "Check for typos in procedure names or a missing .procedure"
	.endif

        bra    return_from_\proc

	.epilogue \proc

        .endm


/// Call a procedure
///
/// This macro is introduced to provide control over procedure
/// calling, error checking and layout. All procedure invocations \e must use
/// this macro. The behavior of the macro depends on the memory space (OTPROM
/// or PNOR) of the procedure, assumed to be the current memory space.
///
/// For OTPROM procedures:
///
/// - Implements a branch to the procedure, followed by the label for the
/// unique return address.
///
/// For PNOR and OCI procedures
///
/// - Processes procedure control to implement SKIP, TRAP or HALT at entry
///
/// - Implements a branch to the procedure, followed by the global label for
/// the unique return address.
///
/// - Implements post-procedure modeable error checking, and post-procedure
/// TRAP or HALT.


        .macro  .callproc, proc:req, skipentrychecks=0, skiperrorchecks=0

        // Currently a stub, needs to be filled out

        .if     (_PGAS_DEFAULT_SPACE == PORE_SPACE_OTPROM)

        // OTPROM procedure

        bra    \proc
        .global return_from_\proc
return_from_\proc\():

        .else

        // Check various control bits to determine if we should halt, trap
	// and/or skip the respective procedure.  D0 is set to 1/0 on entry to
	// indicate whether to do SBEVITAL updates, which are not supported for
	// OCI-based SLW procedures. If D0 comes back non-0 the
	// procedure is skipped.
	
        .if (\skipentrychecks == 0)
	la	A0, \proc\()_control
	.if	(_PGAS_DEFAULT_SPACE == PORE_SPACE_OCI)
	ls	D0, 0
	.else
	ls	D0, \proc\()_istep_num
	.endif
	bsr	callproc_prologue
	branz	D0, 1f
        bra    \proc
1:	
        .else
	bra	\proc
	.endif

        .global return_from_\proc
return_from_\proc\():

	la	A0, \proc\()_control
	ls	D0, \skiperrorchecks
	bsr	callproc_epilogue

	// Hook provided as a anchor point for other sim/debug environments to
	// inject code in place of or after a given procedure.  OCI-based SLW
	// procedures do not support this.
	
	.if	(_PGAS_DEFAULT_SPACE != PORE_SPACE_OCI)
	hooki   0, \proc\()_istep_num
	.endif
	
	.endif

        .endm


/// Declare a subroutine
///
/// \param[in] subr The subroutine name (symbol name)
///
/// \param[in] type The subroutine type determines which test section the
/// subroutine goes into
///
/// - otprom : .ipl_text
/// - ipl    : .ipl_text
/// - cen    : .ipl_text
/// - slw    : .ipl_text or .rt_text
/// - pibmem : .ipl_text	
///
/// \param[in] revision The CVS revision string.  This argument should always
/// be coded as "$Revision" (including double quotes)
///
/// The behavior of the .subroutine macro varies depending on whether the
/// subroutine is in OTPROM, PNOR, SEEPROM, OCI or PIBMEM space.
///
/// This macro does the following for OTPROM and PIBMEM subroutines
///
/// - Switches to .ipl_text
///
/// - Declares the subroutine entry point as a global symbol
///
/// This macro does the following for subroutines that go into SBE-XIP format
/// binary images:
///
/// - Declares a global TOC entry that contains the entry point of the
/// subroutine.  The TOC entry is indexed with the subroutine name <subr>.
///
/// - Declares a global TOC entry that contains a string form of the revision
/// ID of the subroutine, <subr>_revision.
///
/// - Switches to the proper text section, which is either .ipl_text or
/// .rt_text depending on the parameter.
///
/// - Declares the subroutine entry point as a global symbol

        .macro  .subroutine, subr:req, type:req, revision:req

        .if     (_PGAS_DEFAULT_SPACE == PORE_SPACE_OTPROM)

        // OTPROM subroutine

        .ifnc   \type, otprom
        .error  "All OTPROM-space subroutines must be type 'otprom'"
        .endif

        .ipl_text

        .global \subr
\subr\():

        .elseif ((_PGAS_DEFAULT_SPACE == PORE_SPACE_PNOR) || \
	         (_PGAS_DEFAULT_SPACE == PORE_SPACE_SEEPROM))

        // SBE-XIP subroutine

	//.xip_cvs_revision \subr\()_revision, "\revision"
	.xip_address \subr

        .ifc    \type, ipl
        .ipl_text
        .else
        .ifc    \type, slw
        .ipl_text
        .else
	.ifc	\type, cen
	.ipl_text
	.else		
        .error  "All SEEPROM- and PNOR-space subroutines must be type 'ipl', 'slw' or 'cen'"
        .endif
        .endif
	.endif

        .global \subr
\subr\():

        .elseif (_PGAS_DEFAULT_SPACE == PORE_SPACE_OCI)

        // OCI subroutine

	//.xip_cvs_revision \subr\()_revision, "\revision"
	.xip_address \subr

        .ifc    \type, slw
        .rt_text
	.else
        .ifc    \type, rt
        .rt_text
        .else
        .error  "All OCI-space subroutines must be type 'slw' or 'rt'"
	.endif
	.endif
	
        .global \subr
\subr\():

        .elseif (_PGAS_DEFAULT_SPACE == PORE_SPACE_PIBMEM)

        // PIB subroutine

        .ifc    \type, pibmem
        .ipl_text
        .else
        .error  "All PIBMEM-space subroutines must be type 'pibmem'"
	.endif

        .global \subr
\subr\():

        .else
        .error  "Subroutines must be declared in OTPROM, SEEPROM, PNOR, OCI or PIBMEM space"
        .endif

        .endm


/// End a subroutine
///
/// \param[in] subr The subroutine name (symbol name)
///
/// This macro does the following:
///
/// - Generates a RET statement
///
/// - Generates some debugging information about the subroutine

        .macro  .end_subroutine, subr:req

	.ifndef	\subr
	.error	"The symbol \subr referenced by .end_subroutine is not defined"
	.error  "Check for typos in subroutine names or a missing .subroutine"
	.endif

        ret

	.epilogue \subr

        .endm

#endif  // __ASSEMBLER__


/// Macros for generating the .fixed section
///
/// The CPP macros PROC_SBE_FIXED_UINT64[_VECTOR] generate equivalent code
/// depending on whether they are being called from assembler (where they
/// actually create the .fixed section data) or from C (where they specifiy a
/// C-structure form of the contents of the .fixed section.
///
/// In assembler each invocation also creates space in the .fixed_toc section
/// for a fixed TOC entry.  Unlike the normal TOC no data is generated for
/// .fixed_toc by the data declaration.  Instead, the fixed TOC table is
/// filled in during image normalization by normalizeToc (sbe_xip_image.c)
/// which requires that there be one and only one fixed TOC entery allocated
/// per TOC entry referencing the .fixed section. This means that in the
/// current implementation it is not possible to create .fixed_toc entries
/// for addresses or for data stored in sections other than .fixed.

#ifdef __ASSEMBLER__

	.macro	proc_sbe_fixed_uint64, symbol:req, elements=1
	.global \symbol
\symbol\():
	.rept	(\elements)
	.quad 0
	.endr
	
	.xip_toc \symbol, SBE_XIP_UINT64, \symbol, (\elements)

	.pushsection .fixed_toc
        .space	 8
	.popsection

	.endm

        .macro	proc_sbe_fixed_quadia, symbol:req, space:req, address:req
	.global \symbol
\symbol\():
	.quadia (\space), (\address)
	
	.xip_toc \symbol, SBE_XIP_UINT64, \symbol

	.pushsection .fixed_toc
        .space	 8
	.popsection

	.endm

	.macro remove_from_mc_group dx: req, addr:req, px:req
        // Current multicast group is in bits 3:5
        ldandi  \dx, \addr, \px, BITS(3,3)
        // Need to write 0xFC and previous group (bits 19:21) to current group
        rotrdi  \dx, \dx, 16
        ori     \dx, \dx, BITS(0,6)
        std     \dx, \addr, \px
        .endm


#define PROC_SBE_FIXED_UINT64(symbol) proc_sbe_fixed_uint64 symbol

#define PROC_SBE_FIXED_UINT64_VECTOR(symbol, elements) \
             proc_sbe_fixed_uint64 symbol, elements

#define PROC_SBE_FIXED_QUADIA(symbol, space, address) \
             proc_sbe_fixed_quadia symbol, (space), (address)
             

#else  // __ASSEMBLER__

#define PROC_SBE_FIXED_UINT64(symbol) uint64_t symbol

#define PROC_SBE_FIXED_UINT64_VECTOR(symbol, elements) \
		uint64_t symbol[elements]

#define PROC_SBE_FIXED_QUADIA(symbol, space, address) uint64_t symbol

#endif // __ASSEMBLER__

#endif  // __SBE_COMMON_H
