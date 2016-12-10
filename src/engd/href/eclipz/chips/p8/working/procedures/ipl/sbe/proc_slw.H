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



#ifndef __PROC_SLW_H
#define __PROC_SLW_H



/// \defgroup SLW Procedure control bits
///
/// Define in global location "slw_control_vector"
///
/// @{

/// If set, this allows for TEST MODE functionality to be enabled
CONST_UINT64_T(PROC_SLW_TEST_MODE, BIT(0));

/// If set, enable the REDUCED FUNCTION SLEEP
CONST_UINT64_T(PROC_SLW_REDUCED_FUNCTION_SLEEP, BIT(1));

/// If set, enable the REDUCED FUNCTION WINKLE
CONST_UINT64_T(PROC_SLW_REDUCED_FUNCTION_WINKLE, BIT(2));

/// If set, skip flushing of rings; modified externally for sim
CONST_UINT64_T(PROC_SLW_SKIP_FLUSH, BIT(3));

/// If set, acts like the runtime code set the address
CONST_UINT64_T(PROC_SLW_SET_HOST_SCOM_ADDRESS, BIT(4));

/// If set, enables simulation only effects
CONST_UINT64_T(PROC_SLW_SIM_MODE, BIT(5));

/// If set, enables simulation only effects
CONST_UINT64_T(PROC_SLW_DEEP_WINKLE_EXIT_PAUSE, BIT(6));

/// If set, inject the indicated error.  If multiples are set,
/// priority is as indicated                                          Priority

CONST_UINT64_T(PROC_SLW_ERRINJ_INVALID_INSTR,               BIT(8));    // 2
CONST_UINT64_T(PROC_SLW_ERRINJ_INVALID_OCI_ADDRESS,         BIT(9));    // 3
CONST_UINT64_T(PROC_SLW_ERRINJ_INVALID_PIB_ADDRESS,         BIT(10));   // 4
CONST_UINT64_T(PROC_SLW_ERRINJ_PC_UNDERFLOW,                BIT(11));   // 5
CONST_UINT64_T(PROC_SLW_ERRINJ_PC_OVERFLOW,                 BIT(12));   // 6
CONST_UINT64_T(PROC_SLW_ERRINJ_TIMEOUT,                     BIT(13));   // 7
CONST_UINT64_T(PROC_SLW_ERRINJ_SIMPLE_HALT,                 BIT(14));   // 1
CONST_UINT64_T(PROC_SLW_ERRINJ_NEVER_REACH_HALT,            BIT(15));   // 8

/// @}

/// This mask reserves bit 8:15 as error inject bit.  This must be consistent
/// with the ERRINJ bit definitions above
CONST_UINT64_T(PROC_SLW_ERRINJ_MASK,                        BITS(8,8));

/// Define the Master Error Injection Enable Address and bit
CONST_UINT64_T(PROC_SLW_ERRINJ_MASTER_ADDR,                 SPIPSS_P2S_CTRL_REG1_0x00070041);
CONST_UINT64_T(PROC_SLW_ERRINJ_MASTER_BIT,                  BIT(15));

#ifdef __ASSEMBLER__


        .set MAX_CORES, 16
        .set CHIPLET0, 0x10


// Regions

        .set CORE,  C0E
        .set ECO,   EC0


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup SLW Error Codes
///
/// 6 bits defined
///
/// @{
///     .set SLW_RC_GOOD,                      0x00
///
///     // PORE Hardware detected errors
///     .set SLW_RC_PIB_ERROR,                 0x01
///     .set SLW_RC_OCI_ERROR,                 0x02
///     .set SLW_RC_INST_ERROR,                0x03
///     .set SLW_RC_INTERNAL_DATA_ERROR,       0x04
///     .set SLW_RC_ERROR_ON_ERROR,            0x05
///
///
///     // PORE SLW image Return Codes
///     .set SLW_RC_PFET_TIMEOUT_ERROR,        0x11
///     .set SLW_RC_PFET_DECODE_ERROR,         0x12
///     .set SLW_RC_PMC_TIMEOUT,               0x13
///     .set SLW_RC_IPL_ERROR,                 0x14
///     .set SLW_RC_RAM_TIMEOUT,               0x15
///     .set SLW_RC_UNDEFINED_PROGRAM,         0x16
///     .set SLW_RC_UNDEFINED_SV,              0x17
///     .set SLW_RC_PROC_ERROR,                0x18
///     .set SLW_RC_RAM_QUIESCE_ERROR,         0x19
///     .set SLW_RC_GOTO_SYNC_ERROR,           0x1A
///
/// @}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup SLW Error Mask
///
///
///     Event 0: PIB Instruction or Read Data Error
///     Event 1: OCI Instruction or Read Data Error
///     Event 2: Instruction fetch/decode Error
///     Event 3: Internal Error
///     Event 4: Error on Error
///
///      0: enable error handler event 0
///      1: enable error handler event 1
///      2: enable error handler event 2
///      3: enable error handler event 3
///      4: enable error handler event 4
///      5: enable ibuf_error line event 0
///      6: enable ibuf_error line event 1
///      7: enable ibuf_error line event 2
///      8: enable ibuf_error line event 3          <- Internal
///      9: enable ibuf_error line event 4
///     10: enable ibuf_fatal_error line event 0    <- PIB
///     11: enable ibuf_fatal_error line event 1    <- OCI
///     12: enable ibuf_fatal_error line event 2    <- Instruction
///     13: enable ibuf_fatal_error line event 3    <- Internal
///     14: enable ibuf_fatal_error line event 4    <- Err on Err
///     15: enable ibuf_stop_on_error line event 0  <- PIB
///     16: enable ibuf_stop_on_error line event 1  <- OCI
///     17: enable ibuf_stop_on_error line event 2  <- Instruction
///     18: enable ibuf_stop_on_error line event 3  <- Internal
///     19: enable ibuf_stop_on_error line event 4  <- Err on Err
///     20: enable gate_chiplet_offline event 0     <-
///                                          
///
///
/// @{
        .set SLW_ERROR_MASK,   (    BIT(8) | \
                                    BITS(10,2) | BITS(13,2) | \
                                    BITS(15,5))
/// @}



//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Atomic Lock Values

        .set SET_ATOMIC_LOCK_DATA,              0x8800000000000000
        .set CLEAR_ATOMIC_LOCK_DATA,            0x0800000000000000


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// \defgroup Force PCBS state machine regs and values
/// @{

        .set PCBS_GOTO_IDLE,                    BIT(1)      // 01
        .set PCBS_GOTO_SLEEP_CONT,              BIT(0)      // 10
        .set PCBS_GOTO_WINKLE_CONT,             BITS(0,2)   // 11
        
        .set PCBS_GOTO_IVRM_BS_SLEEP_ENTRY,     BIT(2)
        .set PCBS_GOTO_IVRM_BS_WINKLE_ENTRY,    BIT(3)
        .set PCBS_GOTO_IVRM_BS_TRIGGER_WAKEUP,  BIT(4)
         
        .set SLW_IVRM_BS_SYNC_POLLS,            0x10000
        .set SLW_IVRM_BS_SYNC_POLL_DELAY,       1024
        .set SLW_IVRM_CAL_POLLS,                100
        .set SLW_IVRM_CAL_POLL_DELAY,           5000 // 5000 x 2ns = 10us
        .set SLW_IVRM_CAL_VREF_DELAY,           5000 // 5000 x 2ns = 10us

/// @}


//------------------------------------------------------------------------------
// \defgroup Special Wake-up delays for OHA
/// @{         
        .set SLW_OHA_SPWKUP_POLLS,              32
        .set SLW_OHA_SPWKUP_POLL_DELAY,         1024
/// @}
        
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup PCBS "PORE GOTO" States
///
///
/// @{
        .set WAIT_FOR_PORE_DONE,                0b0101110 << (63 - 29)  // x2E
        .set WINKLE_EXIT_WAIT_PORE_GOTO_CMD,    0b1010001 << (63 - 29)  // x51
        .set WINKLE_EXIT_WAIT_FOR_PORE_DONE,    0b1010111 << (63 - 29)  // x57
        .set SLEEP_EXIT_WAIT_PORE_GOTO_CMD,     0b1010000 << (63 - 29)  // x50

        .set PCBS_MONITOR_IFSM_MASK,            (BITS(23,7))
        .set PCBS_GOTO_POLLS,                   0xfff
        .set PCBS_GOTO_POLL_DELAY,              0xf //\todo this need tuning

/// @}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup PMGP1 Power Up/Down Enable Field Masks
/// @{
// PMGP1 bit masks
        .set PMGP1_SLEEP_POWER_DOWN_EN,         BIT(0)
        .set PMGP1_SLEEP_POWER_UP_EN,           BIT(1)
        .set PMGP1_SLEEP_POWER_OFF_SEL,         BIT(2)
        .set PMGP1_WINKLE_POWER_DOWN_EN,        BIT(3)
        .set PMGP1_WINKLE_POWER_UP_EN,          BIT(4)
        .set PMGP1_WINKLE_POWER_OFF_SEL,        BIT(5)

/// @}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup EXE Trigger (ETR) Field Masks
/// @{
///
///     0:7     - reserved
///     8:11    - start vector (encoded)
///     12:19   - status
///     20:31   - reserved
///     32:47   - 16 bit chiplet vector
///     48:49   - Idle transition indicator for SBE procs (see p8_slw.H)
///     50:63   - reserved

        .set SLW_ETR_SV_MASK,                   BITS(8,4)
        .set SLW_ETR_SV_RALIGN64,               52                 # shift amt
        .set SLW_ETR_STATUS_MASK,               BITS(12,8)
        .set SLW_ETR_STATUS_CLEAR,             ~BITS(12,8)
        .set SLW_ETR_CHIPLET_MASK,              BITS(32,16)
        .set SLW_ETR_CHIPLET_CLEAR,            ~BITS(32,16)
        .set SLW_ETR_CM_RALIGN64,               16                 # shift amt

/// @}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup Start Vector Encodes
/// @{

        .set SLW_SV_FSE,                        0x0
        .set SLW_SV_DSE,                        0x1
        .set SLW_SV_FSX,                        0x2
        .set SLW_SV_DSX,                        0x3
        .set SLW_SV_FWE,                        0x4
        .set SLW_SV_DWE,                        0x5
        .set SLW_SV_FWX,                        0x6
        .set SLW_SV_DWX,                        0x7
/// @}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// \defgroup SLW SPRG0 Definition
///
/// Note:SPRG0 is a 32 bit register that must have logical operations done via a
///     data register (64bit).  Upon 'mr', the lower order words of the data reg
///     are operatated on.
///
/// Sleep Winkle Base SPRG0 Use
/// @{
///     0:7     (64b: 32:39)    Transition vector decoded from ETR Start Vector

        .set SLW_SPRG0_TV_FSE_MASK,             BIT(32)
        .set SLW_SPRG0_TV_DSE_MASK,             BIT(33)
        .set SLW_SPRG0_TV_FSX_MASK,             BIT(34)
        .set SLW_SPRG0_TV_DSX_MASK,             BIT(35)
        .set SLW_SPRG0_TV_FWE_MASK,             BIT(36)
        .set SLW_SPRG0_TV_DWE_MASK,             BIT(37)
        .set SLW_SPRG0_TV_FWX_MASK,             BIT(38)
        .set SLW_SPRG0_TV_DWX_MASK,             BIT(39)

        .set SLW_SPRG0_TV_MASK,                 BITS(32,8)
        .set SLW_SPRG0_TV_CLEAR,              ~(BITS(32,8))

        .set SLW_SPRG0_TV_ANYSLEEP_MASK,        BITS(32,4)
        .set SLW_SPRG0_TV_ANYWINKLE_MASK,       BITS(36,4)
        .set SLW_SPRG0_TV_ANYENTRY_MASK,       (BIT(32)|BIT(33)|BIT(36)|BIT(37))
        .set SLW_SPRG0_TV_ANYEXIT_MASK,        (BIT(34)|BIT(35)|BIT(38)|BIT(39))

        // Any Sleep Exit; Any Winkle Exit
        .set SLW_SPRG0_TV_ANYSX_MASK,          (BIT(34)|BIT(35))
        .set SLW_SPRG0_TV_ANYWX_MASK,          (BIT(38)|BIT(39))
        
        // Any Fast; Any Deep
        .set SLW_SPRG0_TV_ANYFAST_MASK,        (BIT(32)|BIT(34)|BIT(36)|BIT(38))
        .set SLW_SPRG0_TV_ANYDEEP_MASK,        (BIT(33)|BIT(35)|BIT(37)|BIT(39))

///     8       (64b: 40)     Rail:  VDD=0; VCS=1  
        .set SLW_SPRG0_RAIL_FLAG,              (BIT(40))      
        .set SLW_SPRG0_RAIL_FLAG_CLEAR,       ~(BIT(40))      

///     9:      (64b: 41)       Release core Pause
        .set SLW_SPRG0_RCP_MASK,               (BIT(41))      
        .set SLW_SPRG0_RCP_CLEAR,             ~(BIT(41))      

///     10:11   (64b: 42:43)    IPL/Idle    
///           0x: IPL=0(default at power-on), Idle=1
///               This effectively reserves the code point of 01 as reserved.
///           10: Winkle
///           11: Sleep

        .set SLW_SPRG0_IDLE_MASK,               BITS(42,2)
        .set SLW_SPRG0_IDLE_CLEAR,            ~(BITS(42,2))
        .set SLW_SPRG0_IDLE_MASK_BIT,           BIT(42)
        .set SLW_SPRG0_IDLE,                    BIT(42)
        .set SLW_SPRG0_IDLE_SLEEP_TST,          BITS(42,2)      // bit 42:43 = 11
        .set SLW_SPRG0_IDLE_WINKLE_TST,         BIT(42)         // bit 42:43 = 10
        .set SLW_SPRG0_IDLE_SLEEP_SET,          BITS(42,2)      // bit 42:43 = 11
        .set SLW_SPRG0_IDLE_WINKLE_SET,         BIT(42)         // bit 42:43 = 10
        
///     12:15   (64b: 44:47)    Power Enable Bits

        .set SPRG0_SLEEP_POWER_DOWN_EN_MASK,    BIT(44)         // 12
        .set SPRG0_SLEEP_POWER_UP_EN_MASK,      BIT(45)         // 13
        .set SPRG0_WINKLE_POWER_DOWN_EN_MASK,   BIT(46)         // 14
        .set SPRG0_WINKLE_POWER_UP_EN_MASK,     BIT(47)         // 15
        .set SPRG0_SLEEP_POWER_DOWN_EN_BIT,     BIT(44)         // 12
        .set SPRG0_SLEEP_POWER_UP_EN_BIT,       BIT(45)         // 13
        .set SPRG0_WINKLE_POWER_DOWN_EN_BIT,    BIT(46)         // 14
        .set SPRG0_WINKLE_POWER_UP_EN_BIT,      BIT(47)         // 15
        .set SPRG0_SLEEP_PWR_EN_MASK,           BITS(44,2)
        .set SPRG0_SLEEP_PWR_EN_SET_MASK,     ~(BITS(44,2))     // OR mask
        .set SPRG0_SLEEP_PWR_EN_CLEAR,        ~(BITS(44,2))     // AND mask
        .set SPRG0_WINKLE_PWR_EN_MASK,          BITS(46,2)
        .set SPRG0_WINKLE_PWR_EN_SET_MASK,    ~(BITS(46,2))     // OR mask
        .set SPRG0_WINKLE_PWR_EN_CLEAR,       ~(BITS(46,2))     // AND mask
        .set SPRG0_PWR_EN_MASK,                 BITS(44,4)
        .set SPRG0_PWR_EN_CLEAR,              ~(BITS(44,4))
        .set PMGP1_SPRG0_SLEEP_PWR_ALIGN,       44              // PMGP1 bit is 0
        

        
///     16:31   (64b: 48:63)    Save area for rotated chiplet mask

        .set SLW_SPRG0_CHIPLET_MASK,            BITS(48,16)
        .set SLW_SPRG0_CHIPLET_CLEAR,         ~(BITS(48,16))
        .set SLW_SPRG0_CHIPLET_TEST,            BIT(48)
/// @}

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// Sleep Winkle SPRG0 Use Macros


/// Set Release Core Pause
        .macro slw_set_release_core_pause, reg:req

        mr      \reg, SPRG0
        ori     \reg, \reg, SLW_SPRG0_RCP_MASK
        mr      SPRG0, \reg
        .endm


/// Clear Release Core Pause
        .macro slw_clear_release_core_pause, reg:req

        mr      \reg, SPRG0
        andi    \reg, \reg, SLW_SPRG0_RCP_CLEAR
        mr      SPRG0, \reg
        .endm


/// Test for Release Core Pause
        .macro if_release_core_pause, reg:req, dst:req

        mr      \reg, SPRG0
        andi    \reg, \reg, SLW_SPRG0_RCP_MASK
        branz   \dst
        .endm
        
/// Test for Release Core Pause
        .macro ifn_release_core_pause, reg:req, dst:req

        mr      \reg, SPRG0
        andi    \reg, \reg, SLW_SPRG0_RCP_MASK
        braz    \dst
        .endm        

/// Get Chiplet Mask into a data reg
        .macro slw_sprg_get_chiplet, dst:req

        mr \dst, SPRG0
        andi \dst, \dst, SLW_SPRG0_CHIPLET_MASK

        .endm
        
/// Save Chiplet Mask from a data reg (right justified)
        .macro slw_sprg_put_chiplet, src:req, scratch:req

        mr \scratch, SPRG0
        andi \src, \src, SLW_SPRG0_CHIPLET_MASK
        or \scratch, \scratch, \src
        mr SPRG0, \scratch

        .endm

// TODO:  is this needed?
// PMGP1 multicast read AND register to determine assist for deep exits
        .set PMGP1_MULICAST_READ_AND,                   0x4D0F0103


#endif  // __ASSEMBLER__

// SRAM Minimum and Maximum Addresses
CONST_UINT64_T( OCC_SRAM_ADDRESS_MIN                  , ULL(0xFFF80000) );
CONST_UINT64_T( OCC_SRAM_ADDRESS_MAX                  , ULL(0xFFFFFFFF) );


// Registers for addition to p8_com_addresses.H
CONST_UINT64_T( CORE_SCRATCH_REG0_0x10012683          , ULL(0x10012683) );
CONST_UINT64_T( CORE_SCRATCH_REG1_0x10012684          , ULL(0x10012684) );
CONST_UINT64_T( CORE_SCRATCH_REG2_0x10012685          , ULL(0x10012685) );
CONST_UINT64_T( CORE_SCRATCH_REG3_0x10012686          , ULL(0x10012686) );
CONST_UINT64_T( CORE_SCRATCH_REG4_0x10012687          , ULL(0x10012687) );
CONST_UINT64_T( CORE_SCRATCH_REG5_0x10012688          , ULL(0x10012688) );
CONST_UINT64_T( CORE_SCRATCH_REG6_0x10012689          , ULL(0x10012689) );
CONST_UINT64_T( CORE_SCRATCH_REG7_0x1001268A          , ULL(0x1001268A) );

// atomic lock regs and data value
CONST_UINT64_T( PCBS_ATOMIC_LOCK_MULTICAST_0x6D0F0F01 , ULL(0x6D0F0F01) );
CONST_UINT64_T( PCBS_ATOMIC_LOCK_0x100F03FF           , ULL(0x100F03FF) );

#endif  // __PROC_SLW_H
