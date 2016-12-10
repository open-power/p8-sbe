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



#ifndef __P8_SLW_H
#define __P8_SLW_H

#ifdef __ASSEMBLER__


    ##`#include "p8_slw.H"
    ##`#include "proc_slw_globals.H"
#include "proc_slw.H"
#include "proc_slw_globals.H"

#endif  // __ASSEMBLER__

//
// Use 2 bits in the ETR register (bits 48:49)
//            0x: IPL=0(default at power-on), Idle=1
//                This effectively reserves the code point of 01 as reserved.//
//            10: Winkle
//            11: Sleep


CONST_UINT64_T(ETR_IDLE_MASK,          ULL(0x000000000000C000));     // bits 48:49
CONST_UINT64_T(ETR_IDLE_CLEAR,         ULL(0xFFFFFFFFFFFF3FFF));     // bits 48:49
CONST_UINT64_T(ETR_IDLE_MASK_BIT,      ULL(0x0000000000008000));     // bit 48 only
CONST_UINT64_T(ETR_IDLE,               ULL(0x0000000000008000));     // bit 48 = 1
CONST_UINT64_T(ETR_IDLE_SLEEP_TST,     ULL(0x000000000000C000));     // bit 48:49 = 11
CONST_UINT64_T(ETR_IDLE_WINKLE_TST,    ULL(0x0000000000008000));     // bit 48:49 = 10
CONST_UINT64_T(ETR_IDLE_SLEEP_SET,     ULL(0x000000000000C000));     // bit 48:49 = 11
CONST_UINT64_T(ETR_IDLE_WINKLE_SET,    ULL(0x0000000000008000));     // bit 48:49 = 10



#ifdef __ASSEMBLER__

//
// Use 2 bits in the ETR register (bits 48:49)
//            0x: IPL=0(default at power-on), Idle=1
//                This effectively reserves the code point of 01 as reserved.//
//            10: Winkle
//            11: Sleep
//
//      .set ETR_IDLE_MASK,                 BITS(48,2)
//      .set ETR_IDLE_CLEAR,              ~(BITS(48,2))
//      .set ETR_IDLE_MASK_BIT,             BIT(48)
//      .set ETR_IDLE,                      BIT(48)
//      .set ETR_IDLE_SLEEP_TST,            BITS(48,2)      // bit 48:49 = 11
//      .set ETR_IDLE_WINKLE_TST,           BITS(48)        // bit 48:49 = 10
//      .set ETR_IDLE_SLEEP_SET,            BITS(48,2)      // bit 48:49 = 11
//      .set ETR_IDLE_WINKLE_SET,           BITS(48)        // bit 48:49 = 10

////////////////////////////////////////////////////////////////////////////////
/// \section SBE Procedure Use Macros
////////////////////////////////////////////////////////////////////////////////


/// ifsleep - Check if Sleep processing is enabled
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
/// \param[in] target Branch location
///

        .macro ifsleep, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_MASK
        cmpibraeq \dreg, \target, SLW_SPRG0_IDLE_SLEEP_TST
        .endm

/// ifnsleep - Check if Sleep processing is not enabled
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
/// \param[in] target Branch location
///
        .macro ifnsleep, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_MASK
        cmpibrane \dreg, \target, SLW_SPRG0_IDLE_SLEEP_TST
        .endm

/// ifwinkle - Check if Winkle processing is enabled
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
/// \param[in] target Branch location
///
        .macro ifwinkle, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_MASK
        cmpibraeq \dreg, \target, SLW_SPRG0_IDLE_WINKLE_TST
        .endm

/// ifnwinkle - Check if Winkle processing is not enabled
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
/// \param[in] target Branch location
///
        .macro ifnwinkle, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_MASK
        cmpibrane \dreg, \target, SLW_SPRG0_IDLE_WINKLE_TST

        .endm

/// ifidle - Check if either Sleep or Winkle processing is enabled
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
/// \param[in] target Branch location
///
        .macro ifidle, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_MASK_BIT
        cmpibraeq \dreg, \target, SLW_SPRG0_IDLE

        .endm

/// ifnidle - Check if neither Sleep or Winkle processing is enabled
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
/// \param[in] target Branch location
///
        .macro ifnidle, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_MASK_BIT
        cmpibrane \dreg, \target, SLW_SPRG0_IDLE

        .endm

/// ifdeepsleepexit - Determine if Deep Sleep Exit
///
/// \param[in] reg - Register to be used for comparison.
/// \param[in] target - offset to branch to if Sleep is active
///

        .macro ifdeepsleepexit, dreg:req, target:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_TV_DSX_MASK
        branz \dreg, \target

        .endm

/// ifdeepwinkleexit - Determine if Deep Winkle Exit
///
/// \param[in] reg - Register to be used for comparison.
/// \param[in] target - offset to branch to if Winkle is active
///

        .macro ifdeepwinkleexit, dreg:req, target:req
        // Reg checking
        ..data \dreg
        
        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_TV_DWX_MASK
        branz \dreg, \target

        .endm


/// .end_idle - Check if either Sleep or Winkle processing is enabled and,
///             if so, branch to the respective return label in the SLW code
///

        .macro .end_idle, proc:req

	    .ifndef	\proc
	    .error	"The symbol \proc referenced by .end_idle is not defined"
	    .error  "Check for typos in procedure names or a missing .procedure"
	    .endif

        ifnidle D0, end_idle_exit
        ifsleep D0, end_idle_sleep
end_idle_winkle:        
        bra  \proc\()_winkle_return
end_idle_sleep:
        bra  \proc\()_sleep_return      
end_idle_exit:
        .endm

// ifslwcntlbitclr - Check state of SLW control bits being clear
///
/// \param[in] Bit Mask to test
/// \param[in] target Branch location
///
        .macro ifslwcntlbitclr, bitmask:req, target:req
        la      A0, slw_control_vector
        ldandi  D0, 0, A0, \bitmask
        braz    D0, \target
        .endm

// ifslwcntlbitset - Check state of SLW control bits being set
///
/// \param[in] Bit Mask to test
/// \param[in] target Branch location
///
        .macro ifslwcntlbitset, bitmask:req, target:req
        la      A0, slw_control_vector
        ldandi  D0, 0, A0, \bitmask
        branz    D0, \target
        .endm


/// setp1_mcreadand - Multicast Read AND in P1 if P0 is MC enabled
///     If P0 is the multicast write type, set P1 to the AND-combining read group
///     with the same group ID as P0, otherwise simply set P1 = P0.
///     Polling would then use use P1 as the chiplet ID.
///
/// \param[in] dreg Scratch register used for P1 updating

        // (BIT(57) | ~BIT(58) | ~BIT(59) | ~BIT(60) | BIT(61) | BIT(62) | BIT(63))
        .set CLEAR_MC_TYPE_MASK,     0x47

        .macro setp1_mcreadand dreg:req

        mr \dreg, P0
        // P0 MC bit in right justified in 64 bit dreg is bit 57
        andi	(\dreg),(\dreg), BIT(57)
	    branz	(\dreg), 6273232631f
        // Not MC
        mr \dreg, P0
        mr P1, \dreg
        bra 6273232632f
6273232631:
        // MC
        mr \dreg, P0
        // Clear the MC type but retain the MC bit and group

        andi (\dreg), (\dreg), CLEAR_MC_TYPE_MASK

        // Read-AND MC type = 0b001
        ori (\dreg), (\dreg), BIT(60)
        mr P1,\dreg
6273232632:
        .endm


/// setp1_mcreador - Multicast Read OR in P1 if P0 is MC enabled
///     If P0 is the multicast write type, set P1 to the OR-combining read group
///     with the same group ID as P0, otherwise simply set P1 = P0.
///     Polling would then use use P1 as the chiplet ID.
///
/// \param[in] dreg Scratch register used for P1 updating c

        .macro setp1_mcreador dreg:req

        mr \dreg, P0
        // P0 MC bit in right justified in 64 bit dreg is bit 57
        andi	(\dreg), (\dreg), BIT(57)
	    branz	(\dreg), 6273232671f
        // Not MC
        mr \dreg, P0
        mr P1, \dreg
        bra 6273232672f
6273232671:
        // MC
        mr \dreg, P0
        // Clear the MC type but retain the MC bit and group
        andi (\dreg), (\dreg), CLEAR_MC_TYPE_MASK
        // Read-OR MC type = 0b000.  Already in place
        mr P1,\dreg
6273232672:
        .endm

/// error_exit - check for the mode of operation (IPL vs Idle) and invoke or
///              the appropriate handler
///
/// It is assumed that any relevant code is left in D1

        .macro error_exit code

        ifidle D0, 36343531f

        // IPL Error Handling
        hooki D0, 0xFFFE
        halt
36343531:
        // Idle Exit Handling
        hooki D0, 0xFFFF
        bra slw_proc_error

        .endm

////////////////////////////////////////////////////////////////////////////////
/// \section SLW Procedure Use Macros
////////////////////////////////////////////////////////////////////////////////

/// bra_proc_idle - Creates a bra and return labels used by .end_idle macro
///
/// \param[in] proc Name of procedure
/// \param[in] type Transition type

        .macro bra_proc_idle, proc:req, type:req

        bra \proc\()
        .global \proc\()_\type\()_return
\proc\()_\type\()_return:

        .endm



/// setsleep - Set Sleep Idle procedure control state
///     Does a RMW to SPRG0 reg
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
///
        .macro setsleep, dreg:req
        // Reg checking
        ..data \dreg
 
        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_CLEAR
        ori \dreg, \dreg,  SLW_SPRG0_IDLE_SLEEP_SET
        mr SPRG0, \dreg
        .endm

/// setwinkle - Set Winkle Idle procedure control state
///     Does a RMW to SPRG0 reg
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
///
        .macro setwinkle, dreg:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_CLEAR
        ori \dreg, \dreg,  SLW_SPRG0_IDLE_WINKLE_SET
        mr SPRG0, \dreg
        .endm

/// clearidle - Clear Idle procedure control state
///     Does a RMW to SPRG0 reg
///
/// \param[in] dreg Either D0 and D1 reg for scratch data
///
        .macro clearidle, dreg:req
        // Reg checking
        ..data \dreg

        // Macro body
        mr \dreg, SPRG0
        andi \dreg, \dreg, SLW_SPRG0_IDLE_CLEAR
        mr SPRG0, \dreg
        .endm




#endif  // __ASSEMBLER__

#endif  // __P8_SLW_H
