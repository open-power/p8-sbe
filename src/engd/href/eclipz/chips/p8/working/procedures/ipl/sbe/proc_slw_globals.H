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



#ifndef __SLW_GLOBALS_H
#define __SLW_GLOBALS_H


#ifdef __ASSEMBLER__


        // The .struct directive begins assembly in the absolute
        // section. The .pushsection here simply allows us to pop back to the
        // previous section once the symbols are defined.

        .pushsection .illegal

        // Begin symbol definition 1KB from the end of SRAM
        
        .struct 0xfffffc00
                    

         // This variable is used by SLW code to save original MSR content
         // during ramming of SPRs as well as set a flag if there's an mtmsrd
         // in the .slw table.

slw_saved_msr:
        .org    . + 8 // Contains original MSR content
        .org    . + 8 // Contains a '1' if an mtmsrd in the .slw table was rammed


        // The PIBMEM based trigger winkle / deadman code needs a copy of
        // procedure control vector to avoid the long I2C access time.
        // The value is copied here by the SEEPROM calling producure prior        
        // to invoking the PIBMEM subroutine.
        // High Availability Address Write Pointer Save Area
        // Chiplet specific values are stored here upon a Deep Winkle Entry.
        // Upon Deep Winkle Exit, the chiplet specific value is restored from
        // these values.
        //
        // The HA Write Address Pointer is a 17 bit value per chiplet so a
        // .long (4B) is reserved for each.  Indexing uses the EX chiplet
        // number after masking out the "0x10" from it (eg indexes are 0 - F.
        // However, access to the SRAM are in quads (eg 8B each).  Thus, the
        // structure allocates 8 quads (64B) for up to 16 chiplets.
        //
        //  Structure
        //                            Even            Odd
        //      .quad  (8B) ->    4B (chiplet 0), 4B (chiplet 1)
        //      .quad  (8B) ->    4B (chiplet 2), 4B (chiplet 3)
        //      ....
        //      .quad  (8B) ->    4B (chiplet E), 4B (chiplet F)

slw_ha_write_addr_ptr_sr_sram:
        .rept   8
        .org   . + 8
        .endr

        // The following locations provide register save/restore 
slw_a0_sr:
        .org    . + 8       // A0 save/restore
slw_a1_sr:
        .org    . + 8       // A1 save/restore
slw_d0_sr:
        .org    . + 8       // D0 save/restore
slw_d1_sr:
        .org    . + 8       // D1 save/restore
slw_ctr_sr:
        .org    . + 8       // CTR save/restore
        
        // General scratch registers
slw_x00_sr:
        .org    . + 8       // Generic scratch reg 00
slw_x01_sr:
        .org    . + 8       // Generic scratch reg 01
slw_x02_sr:
        .org    . + 8       // Generic scratch reg 02
slw_x03_sr:
        .org    . + 8       // Generic scratch reg 03
slw_x04_sr:
        .org    . + 8       // Generic scratch reg 04
slw_x05_sr:
        .org    . + 8       // Generic scratch reg 05
slw_x06_sr:
        .org    . + 8       // Generic scratch reg 06
slw_x07_sr:
        .org    . + 8       // Generic scratch reg 07
slw_x08_sr:
        .org    . + 8       // Generic scratch reg 08
slw_x09_sr:
        .org    . + 8       // Generic scratch reg 09
slw_x10_sr:
        .org    . + 8       // Generic scratch reg 10

        // The following contains content of OHA status reg just before
        // the prestart routine is launched.
slw_oha_status_sleep:
        .org    . + 8       // OHA status reg when exiting deep sleep
slw_oha_status_winkle:
        .org    . + 8       // OHA status reg when exiting deep winkle

        // The following locations provide for counts of the various SLW Exit
        // events for the purpose of event tracking.  These are incremented by
        // SLW code.  Any clearing of these counts is done by external FAPI
        // proceduress

slw_deep_sleep_count:
        .org    . + 8

slw_deep_winkle_count:
        .org    . + 8

slw_fast_sleep_count:
        .org    . + 8

slw_fast_winkle_count:
        .org    . + 8

slw_start_time:
        .org    . + 8

slw_stop_time:
        .org    . + 8
       
        // The following location is used for counting how many times we
        // exhaust the poll counter in slw_check_goto.
slw_check_goto_exhaust_count:
        .org    . +8      // SLW enter (pore done)
        .org    . +8      // Sleep exit (goto cmd)
        .org    . +8      // Winkle exit (goto cmd)
        .org    . +8      // Winkle exit (pore done)

        // The following location is used for saving previous idle state.
        // Bits(0:15) contain whether prev idle state was (1) or was not (0) deep winkle.
slw_prev_idle_state:
        .org    . +8

        // The following locations are used for iVRM calibration debug.
ivrm_parm:
        .org    . +8
        .org    . +8
				
				// The following locations hold generic count and last time stamps for all 8 idle transition routines.
idle_transition_count:
        .org    . +8  // Generic counter (in case TOD isn't running).
        .org    . +8  // Generic check [read] counter (checking we can read from prev).

idle_transition_ts:
				.org		. +8	// slw_transition entry (any state)           - 0*8
				.org		. +8	// slw_transition exit (any state)            - 1*8
				.org		. +8	// slw_transition exit -overhead (and state)  - 2*8
				.org		. +8	// slw_transition exit -dwxroutine            - 3*8
				.org		. +8	// fse entry                                  - 4*8
				.org		. +8	// fse exit                                   - 5*8
				.org		. +8	// fsx entry                                  - 6*8
				.org		. +8	// fsx exit                                   - 7*8
				.org		. +8	// fwe entry                                  - 8*8
				.org		. +8	// fwe exit                                   - 9*8
				.org		. +8	// fwx entry                                  - 10*8
				.org		. +8	// fwx exit                                   - 11*8
				.org		. +8	// dse entry                                  - 12*8
				.org		. +8	// dse exit                                   - 13*8
				.org		. +8	// dsx entry                                  - 14*8
				.org		. +8	// dsx exit                                   - 15*8
				.org		. +8	// dwe entry                                  - 16*8
				.org		. +8	// dwe exit                                   - 17*8
				.org		. +8	// dwx entry                                  - 18*8
				.org		. +8	// dwx exit                                   - 19*8

				
				// The following locations hold CHTM mode reg during idles.
chtm_mode_reg:
        .org    . +8  // Holds chiplet 0x10.
        .org    . +8  // Holds chiplet 0x11.
        .org    . +8  // Holds chiplet 0x12.
        .org    . +8  // Holds chiplet 0x13.
        .org    . +8  // Holds chiplet 0x14.
        .org    . +8  // Holds chiplet 0x15.
        .org    . +8  // Holds chiplet 0x16.
        .org    . +8  // Holds chiplet 0x17.
        .org    . +8  // Holds chiplet 0x18.
        .org    . +8  // Holds chiplet 0x19.
        .org    . +8  // Holds chiplet 0x1a.
        .org    . +8  // Holds chiplet 0x1b.
        .org    . +8  // Holds chiplet 0x1c.
        .org    . +8  // Holds chiplet 0x1d.
        .org    . +8  // Holds chiplet 0x1e.
        .org    . +8  // Holds chiplet 0x1f.

        // The following location holds the Ram complete poll count max used value
ram_complete_max_polls:
        .org    . +8

        .popsection

#endif // __ASSEMBLER__

#endif // __SLW_GLOBALS_H
