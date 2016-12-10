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



        .nolist
#include "p8_sbe.H"
#include "p8_slw.H"
#include "proc_sbe_initf_common_seeprom.H"
        .list

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
    .seeprom

    .set STEP_SBE_EVID_START,               0x1
    .set STEP_SBE_EVID_CONFIG,              0x2
    .set STEP_SBE_EVID_RIDI,                0x3
    .set STEP_SBE_EVID_WRITE_VOLTAGE,       0x4
    .set STEP_SBE_EVID_POLL_STATUS,         0x5
    .set STEP_SBE_EVID_TIMEOUT,             0x6
    .set STEP_SBE_EVID_BOOT_FREQ,           0x7
    .set STEP_SBE_EVID_COMPLETE,            0x8
    .set STEP_SBE_EVID_SPIVID_STATUS_ERR,   0x9
    .set STEP_SBE_EVID_SPIVID_CRC_ERR,      0xA

    .set MPIPL_BITNUM,                      0   
    .set CHIPPOS_ID,                        39 
    
    // PMC Mode Reset value from hardware
    //  3: ENABLE_PSTATE_VOLTAGE_CHANGES
    //  4: ENABLE_GLOBAL_ACTUAL_PSTATE_FORWARDING
    //  5: HALT_PSTATE_MASTER_FSM
    // 10: HONOR_OHA_IDLE_STATE_REQUESTS
    // 14: HALT_IDLE_STATE_MASTER_FSM 
    .set PMC_MODE_RESET_VALUE,              0x1C22000000000000    

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------
    
    // boot_voltage
    // Defaults:  VDD = 0.95V, EVID = x6A; VCS = 1.05V, EVID = 5A
    // Port enable (0:2) - default hardcoded to 100 (first port)
    .xip_quad sbe_boot_voltage_default, 0x806A5A0000000000


    // [ 0: 5] o2s_frame_size = 32; -> 0x20
    // [ 6:11] o2s_out_count1 = 32; -> 0x20
    // [12:17] o2s_in_delay1  =  0;     No concurrent input
    // [18:23] o2s_in_count1  =  0;     No input on first frame
    .xip_quad sbevid_o2s_ctrl_reg0a, ( BIT(0) | BIT(6) )

 
    // [ 0: 5] o2s_out_count2  = 0;     Check this in pmc_init - a parm 
    // [ 6:11] o2s_in_delay2   = 0;     No concurrent input
    // [12:17] o2s_in_count2   = 0;     No concurrent input
    .xip_quad sbevid_o2s_ctrl_reg0b, ( BIT(12))
    
    // [    0] o2s_bridge_enable
    // [    1] pmcocr1_reserved_1
    // [    2] o2s_cpol = 0;            Low idle clock
    // [    3] o2s_cpha = 0;            First edge
    // [ 4:13] o2s_clock_divider = 0xFA    Yield 1MHz with 2GHz nest   
    // [14:16] pmcocr1_reserved_2 
    // [   17] o2s_nr_of_frames = 1; Two frames
    // [18:20]o2s_port_enable (only port 0 (18) by default
    
    // Divider calculation (which can be overwritten)
    //  Nest Frequency:  2000MHz (0x7D0)
    //  SPIVID Frequency:    1MHz (0x1) (eg  1us per bit)
    //
    // Divider = Nest Frequency / (SPIVID Frequency * 8) - 1
    
    .xip_quad sbevid_o2s_ctrl_reg1, ( BIT(0) | BITS(4,4) | BIT(10) | BIT(17) | BIT(18))
        
    // [ 0:16] o2s_inter_frame_delay = filled in with ATTR data
    // Needs to be 10us or greater for SPIVID part operation
    // Set to ~16us for conservatism using a 100ns hang pulse
    // 16us = 16000ns -> 16000/100 = 160 = 0xA0;  aligned to 0:16 -> 0x005 
    .xip_quad sbevid_o2s_ctrl_reg2, ( BIT(9) | BIT(11) )
    
    // [ 0:16] spivid_inter_retry_delay = 20us = 200 x 100ns = 0xC8
    // [17:22] pmc_100ns_pls_range (100ns * (Nest_frequency_Hz/4))-1 = d50 = 0x32
    //           for a 2GHz nest
    // pmcocr4_reserved8_15 = 0x0;
    .xip_quad sbevid_o2s_ctrl_reg3, 0x0019640000000000
            
    // [    0] o2s_crc_gen_en = 1;
    // [    1] o2s_crc_check_en = 0;  // Not enabled due to long gen times
    // [    2] o2s_majority_vote_en = 1; 
    // [ 3: 7] o2s_max_retries = 0x3; // Retries 3 times.  This allow IPL anomolies to be ridden through
    // [ 8:15] o2s_crc_polynomial_enables = D5;
    // pmcocr4_reserved8_15 = 0x0;
    .xip_quad sbevid_o2s_ctrl_reg4, ( BIT(0) | BITS(6,2) | BIT(8) | BIT(9) | BIT(11) | BIT(13) | BIT(15) ) 

    .set SPIVID_WRITE, 0x0   
    .set MAX_POLL_LOOPS, 16             // Good a number as any
    .set SPIVID_POLL_DELAY, 35000       // 1ms @ (133MHz (ref clock) / 4)
                                        // 1ms / (75ns*4)
                                        // 1ms / 300ns -> 3333.333

     
    // Default boot_frequency in t3erms of a multiplier of the refclk frequency/4
    // This is value used if the mailbox value is zero
    //  Value implemented is 3.0GHz
    //  
    //  30000MHz / 33.125MHz = ~90;  0d90 => 0x5A 
    //.xip_quad sbe_boot_frequency_default, 0x005A000000000000
    
    // Note:  the above is aligned, as a value, to 0:15.  Bits 7:15 will get 
    // loaded into FREQCNTL(9:17) as the maximum DLL frequency.  In addition,
    // this same value will also be shifted and loaded into FREQCNTL(0:8) as
    // the minimum frequency in the event that CPMs get inadertently enabled
   
    .xip_quad sbe_boot_frequency_default, 0x005A000000000000                    
                      
//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------

    
    .procedure proc_sbe_setup_evid, ipl, "$Revision: 1.21 $"

    updatestep  STEP_SBE_EVID_START, D0, P1
    POREVE_INF("\nPMC EVID set start...");

    //Skip IOPCI workaround on MPIPL
    lpcs P1, MBOX_SCRATCH_REG1_0x00050039
    ifbitsetscom D0, D0, MBOX_SCRATCH_REG1_0x00050039, P1, MPIPL_BITNUM, end_iopci_workaround

    // Workaround for IOPCI over-current problem
    lpcs    P0, PCIE_CHIPLET_0x09000000
    ldandi  D0, GENERIC_GP3_0x000F0012, P0, BIT(0)
    braz    D0, end_iopci_workaround
    POREVE_INF("IOPCI over-current workaround... ");

    // Set PCIe scan ratio to 1:1 as PCIe is still at refclock
    sti     PCIE_OPCG_CNTL0_0x09030002, P0, 0x0
    load_ring pci_func_iopci

    // Set PCIe scan ratio back to 8:1
    // Inputs: A1 and P0, destroys D0 & D1
    lia     A1, PORE_SPACE_SEEPROM, proc_sbe_chiplet_init_control 
    bsr     set_scan_ratio
end_iopci_workaround:     

    
       
    //  ******************************************************************
    //  - set PMC_O2S_CTRL_REG0A 
    //  ******************************************************************
    
    la      A0, sbevid_o2s_ctrl_reg0a
    ld      D0, 0, A0
    
    lpcs    P1, PMC_O2S_CTRL_REG0A_0x00062050
    POREVE_DBG("Reading PMC O2S CTRL_REG_0B Configuration");
    ld      D1, PMC_O2S_CTRL_REG0A_0x00062050, P1
    
    POREVE_DBG("Read PMC O2S CTRL_REG_0B Configuration: 0x%16llX", io_pore.d1.read());
    
    std     D0, PMC_O2S_CTRL_REG0A_0x00062050, P1
    
    POREVE_DBG("PMC O2S CTRL_REG_0A Configuration: 0x%16llX", io_pore.d0.read());
    
    ///  ******************************************************************
    ///  set PMC_O2S_CTRL_REG0B
    ///  ******************************************************************

    la      A0, sbevid_o2s_ctrl_reg0b
    ld      D0, 0, A0
    
    lpcs    P1, PMC_O2S_CTRL_REG0B_0x00062051
    std     D0, PMC_O2S_CTRL_REG0B_0x00062051, P1
    
    POREVE_DBG("PMC O2S CTRL_REG_0B Configuration: 0x%16llX", io_pore.d0.read());
   
    ///  ******************************************************************
    ///  - set PMC_O2S_CTRL_REG1
    ///  ******************************************************************
    la      A0, sbevid_o2s_ctrl_reg1
    ld      D0, 0, A0   
        
    // Read the port enables from mailbox scratch reg 0x3D

    POREVE_INF("Reading port enables from Mailbox Scratch 3 ...")
    lpcs    P1, STBY_CHIPLET_0x00000000
    ldandi  D1, MBOX_SCRATCH_REG3_0x0005003B, P1, BITS(0,3)
    
    POREVE_DBG("Mailbox port enable - 0x%16llx ...", 
                        io_pore.d1.read())
    
    // If the Mailbox has no value, use the default (loaded in D0)
    braz    D1, evid_write_reg1
    
    // Clear the value from the default
    andi    D0, D0, ~(BITS(18,3))
    POREVE_DBG("Clear default port enables - 0x%16llx ...", 
                        io_pore.d0.read())
        
    // Align the field (0 to 18)
    srdi    D1, D1, 18
    POREVE_DBG("Align port enables - 0x%16llx ...", 
                        io_pore.d1.read())
    
    // OR in the mailbox value
    or      D0, D0, D1

evid_write_reg1:    
    lpcs    P1, PMC_O2S_CTRL_REG1_0x00062052
    std     D0, PMC_O2S_CTRL_REG1_0x00062052, P1

    POREVE_DBG("PMC O2S CTRL_REG_1 Configuration: 0x%16llX", io_pore.d0.read());
    
    ///  ******************************************************************
    ///  - set PMC_O2S_CTRL_REG2
    ///  ******************************************************************

    la      A0, sbevid_o2s_ctrl_reg2
    ld      D0, 0, A0
    
    lpcs    P1, PMC_O2S_CTRL_REG2_0x00062053
    std     D0, PMC_O2S_CTRL_REG2_0x00062053, P1

    POREVE_DBG("PMC O2S CTRL_REG_2 Configuration: 0x%16llX", io_pore.d0.read());

    ///  ******************************************************************    
    ///  - set PMC_O2S_CTRL_REG4
    ///  ******************************************************************
    la      A0, sbevid_o2s_ctrl_reg4
    ld      D0, 0, A0
    
    lpcs    P1, PMC_O2S_CTRL_REG4_0x00062055
    std     D0, PMC_O2S_CTRL_REG4_0x00062055, P1

    POREVE_INF("PMC O2S CTRL_REG_4 Configuration: 0x%16llX", io_pore.d0.read());
    
    //    updatestep  STEP_SBE_EVID_CONFIG, D1, P1

    ///  ******************************************************************    
    ///  - set PMC_SPIV_CTRL_REG3
    ///  ******************************************************************
    la      A0, sbevid_o2s_ctrl_reg3
    ld      D0, 0, A0
    
    lpcs    P1, PMC_SPIV_CTRL_REG3_0x00062044
    std     D0, PMC_SPIV_CTRL_REG3_0x00062044, P1

    POREVE_INF("PMC SPIVID CTRL_REG_3 Configuration: 0x%16llX", io_pore.d0.read());

    ///  ******************************************************************    
    ///  - set PMC_SPIV_CTRL_REG4
    ///  ******************************************************************
    la      A0, sbevid_o2s_ctrl_reg4
    ld      D0, 0, A0
    
    lpcs    P1, PMC_SPIV_CTRL_REG4_0x00062045
    std     D0, PMC_SPIV_CTRL_REG4_0x00062045, P1

    POREVE_INF("PMC SPIVID CTRL_REG_4 Configuration: 0x%16llX", io_pore.d0.read());
    
    updatestep  STEP_SBE_EVID_CONFIG, D1, P1

    ///  ******************************************************************
    ///  Enable the drivers and receivers
    ///  Read/modify/write to set FSI GP4 (28 - RI, 29 - DI1, 30 - DI2) 
    ///
    ///  Note:  while this action is not needed for enabling voltage
    ///  on the Slave chip of a DCM, the RI/DI lowering is assumed downstream
    ///  ******************************************************************
    
    lpcs    P1, MBOX_FSIGP4_0x00050013
    ld      D0, MBOX_FSIGP4_0x00050013, P1
    ori     D0, D0, (BITS(28,3))
    std     D0, MBOX_FSIGP4_0x00050013, P1
    
    POREVE_INF("PMC EVID Enable Drivers and Receivers: 0x%16llX", 
                        io_pore.d0.read());
    
    updatestep  STEP_SBE_EVID_RIDI, D1, P1
   
    ///-----------------------------------------------------------------------
    /// Restore hardware reset to PMC Mode reg to disable residual Pstate 
    /// enablement in the PMC for the case of MPIPL where Pstates had previously
    /// been enabled.  
    POREVE_INF("Reset PMC Mode register to disable residual Pstates (for MPIPL really)")
    li      D0, PMC_MODE_RESET_VALUE    
    lpcs    P1, PMC_MODE_REG_0x00062000
    std     D0, PMC_MODE_REG_0x00062000, P1
 
    ///-----------------------------------------------------------------------
    /// Perform the Write Voltage command on master chips only

    /// Read PCB chip id register to identify chip position
    lpcs    P1, PCBMS_DEVICE_ID_0x000F000F
    POREVE_INF("Reading chip id and position")
    ldandi  D0, PCBMS_DEVICE_ID_0x000F000F, P1, BIT(CHIPPOS_ID)
    branz   D0, spivid_finish        
    
    ///  ******************************************************************
    ///  write PMC_O2S_command_reg to clear any latent errors
    ///  ******************************************************************
    li      D0, 0x0
    lpcs    P1, PMC_O2S_COMMAND_REG_0x00062057
    std     D0, PMC_O2S_COMMAND_REG_0x00062057, P1
    
    ///  ******************************************************************
    ///  write PMC_O2S_Wdata_REG
    ///  The PO2SWR register is used for sending 3B of write data through the 
    ///  o2s bridge. Note that a write to this register starts the SPI 
    ///  transaction (read or write), if the switch enable_o2s_bridge is set.
    ///  ******************************************************************
    
    // Read the boot voltage and phase enables from mailbox scratch reg 0x3D
    POREVE_INF("Reading boot voltage from Mailbox Scratch 3 ...")
    lpcs    P1, STBY_CHIPLET_0x00000000
    ld      D0, MBOX_SCRATCH_REG3_0x0005003B, P1
    
    POREVE_DBG("Mailbox boot voltage - 0x%08llx ...", 
                        io_pore.d0.read())
    
    // If mailbox values are zero, use the default value from
    // sbe_boot_voltage_default.  

    // check VDD VID
    andi    D1, D0, BITS(8, 8)
    braz    D1, 99f
    
    // check VCS VID
    andi    D1, D0, BITS(16, 8)
    branz   D1, 1f
    nop
99:       
    POREVE_INF("One or both mailbox voltage values is 0."
               "Using default value from sbe_boot_voltage_default")
    la      A0, sbe_boot_voltage_default
    ld      D0, 0, A0
    
    POREVE_DBG("Default boot voltage - 0x%08llx ...", 
                       io_pore.d0.read())
    nop
1:

    POREVE_INF("Setting boot voltage to 0x%08llx",
                io_pore.d0.read())
    andi    D0, D0, ~BITS(24,8)             // The node ID was in these bits
    ori     D0, D0, 0x0000005A00000000      // Put in a checkbyte anyway.
                                            // CRC being enabled may replace
                                            // this value when sent.
                                            
    andi    D0, D0, ~(BITS(0,4))            // Clear the port enable value out
                                            // This also creates the "Write" command
      
    lpcs    P1, PMC_O2S_WDATA_REG_0x00062058
    std     D0, PMC_O2S_WDATA_REG_0x00062058, P1 // Sent the command
              
    updatestep  STEP_SBE_EVID_WRITE_VOLTAGE, D1, P1
    
    ///-----------------------------------------------------------------------
    /// Poll for operation being complete
    /// 
/*    
    ##@ // Force D0 to PMC_O2S_STATUS_REG_0x00062056 to act like hdw
    ##@ io_pore.d0.write(0x8000000000000000ull);
    ##@ printf ("--> Hook to force SPIVID completion\n");
    ##@ return hookOk;
*/    
    
    updatestep  STEP_SBE_EVID_POLL_STATUS, D1, P1
    
    pollbitclr D0, PMC_O2S_STATUS_REG_0x00062056, P1, 0 \
                MAX_POLL_LOOPS, SPIVID_POLL_DELAY, spivid_poll_timeout       
                
    ///-----------------------------------------------------------------------
    /// Check for valid status
    /// 
    
    // [ 1] o2s_crc_error0
    // [ 2] o2s_crc_error1
    // [ 3] o2s_crc_error2
    // [ 4] o2s_retry_timeout
    // [ 5] o2s_write_while_bridge_busy_err
    // [ 6] pmcosr_reserved_6
    // [ 7] o2s_fsm_err
    // [ 8] o2s_majority_detected_a_minority0
    // [ 9] o2s_majority_detected_a_minority1
    // [10] o2s_majority_detected_a_minority2
   
    // Skip check if instructed
        ##@ fapi::ReturnCode rc;
        ##@ uint8_t disable_i2c_access = 0;
        ##@ rc = FAPI_ATTR_GET(ATTR_DISABLE_I2C_ACCESS, NULL, disable_i2c_access);
        ##@ if (!rc.ok())
        ##@ {
        ##@     return rc;
        ##@ }
        ##@ if (disable_i2c_access)
        ##@ {
        ##@     io_pore.forceBranch("seeprom::spivid_finish");
        ##@ }
        ##@ return hookOk;
    andi    D1, D0, ( BITS(1,5) | BITS(7,4))
    branz   D1, spivid_o2s_status_error
    
    ///-----------------------------------------------------------------------
    /// Check a good response code from the SPIVID chip
    /// For Voltage Write command, this is AA repeated in the first 3 bytes
    /// 
       
    ldandi  D1, PMC_O2S_RDATA_REG_0x00062059, P1, BITS(0,24)
    xori    D0, D1, 0xAAAAAA0000000000
    branz   D0, spivid_o2s_write_status_error

	.global spivid_finish
spivid_finish:     

    ///-----------------------------------------------------------------------
    /// Read the boot frequency from the mailbox and write this to all    
    /// configured EX chiplets' PCBS-PM                                   
    ///                                                                   
    
    updatestep  STEP_SBE_EVID_BOOT_FREQ, D1, P1 
         
    // Read the boot frequency from mailbox scratch reg 0x38              
    //  Bytes 0:1 - 9 bit frequency multiplier of the refclk right justified
    //                                                                    
    POREVE_INF("Reading boot frequency from Mailbox Scratch 1 ...")
    lpcs    P1, STBY_CHIPLET_0x00000000                                   
    ld      D1, MBOX_SCRATCH_REG0_0x00050038, P1  
    
    POREVE_INF("Mailbox frequency value (bits 0:15): 0x%16llX", io_pore.d1.read())                         

    // If mailbox value for 7:15 (9 bits) are zero, use the default value 
    // from sbe_boot_frequency_default.  This allows the other bits to be used
    // if needed.                                                         

    andi    D1, D1, BITS(7, 9) 
    POREVE_DBG("After ANDI BITS(7, 9): 0x%16llX", io_pore.d1.read())                                   
    branz   D1, evid_freq_set
                                                             
    la      A0, sbe_boot_frequency_default 
    POREVE_DBG("A0 0x%16llX", io_pore.a0.read())                                        
    ld      D1, 0, A0  
    POREVE_INF("The mailbox boot frequency value is 0."
              "Using default value from image default value (0x%16llX)", 
              io_pore.d1.read()) 
    nop                                                      
evid_freq_set:
       
    POREVE_INF("Set DPLL_FMAX in FREQ_CTRL_REGister " )
    POREVE_DBG("Frequency 7:15         ->  0x%16llX", io_pore.d1.read())
    
    // Align the 7:15 to 9:17 (for the maximum)
    srdi    D1, D1, 2
    or      D0, D0, D1
    POREVE_DBG("Align to 9:17 for FMax ->  0x%16llX", io_pore.d0.read())  
    
    // Align the value to 0:8 (for the minimum)
    sldi    D1, D1, 9
    or      D0, D0, D1
    POREVE_DBG("Align to  0:8 for Fmin ->  0x%16llX", io_pore.d0.read())  
    
    // Setup P0 for all EX chiplets MC write group and write the built value
    lpcs    P0, ALL_EXS_WRITE_0x69000000
    
    // Setup P1 for all EX chiplets MC read group (should really do both and and or)
    setp1_mcreadand D1

    // Set bit 10 to: '1' => enable settings in FREQ_CTRL_REG             
    // Must be done before setting FREQ_CTL_REG or hardware will override
    //  the FMax value
    POREVE_INF("Set PMGP1_REG DPLL_FREQ_OVERRIDE_ENABLE" )
    sti     EX_PMGP1_REG_0_WORx100F0105, P0, BIT(10)                                                                               
                     
    POREVE_INF("Set FREQ_CTRL_REGister in all configured EX chiplets to 0x%16llX", io_pore.d1.read())          
    std     D0, EX_FREQCNTL_0x100F0151, P0  
   
    POREVE_INF("Clear PCBS_PM Mode reg to disable Pstates in all EX chiplets (for MPIPL case really)")          
    sti     EX_PCBSPM_MODE_REG_0x100F0156, P0, 0
           
    POREVE_INF("WORKAROUND:   Disable ping-pong synchronizer in DPLL_CPM_PARM_REG" )
    ld      D0, EX_DPLL_CPM_PARM_REG_0x100F0152, P1
    ori     D0, D0, BIT(32)
    std     D0, EX_DPLL_CPM_PARM_REG_0x100F0152, P0                  
                                                                          
    updatestep  STEP_SBE_EVID_COMPLETE, D1, P1
    POREVE_INF("PMC EVID set complete... \n");
    .end_procedure proc_sbe_setup_evid
    
spivid_poll_timeout:
    updatestep  STEP_SBE_EVID_TIMEOUT, D1, P1
    POREVE_ERR("PMC EVID set timeout... \n");
    reqhalt RC_SBE_SET_VID_TIMEOUT

spivid_o2s_status_error:    
    POREVE_ERR("Errors detected in O2S Status Reg setting Boot Voltage ... ");    
    reqhalt RC_SBE_SPIVID_STATUS_ERROR
        
spivid_o2s_write_status_error:    
    POREVE_ERR("SPIVID Device did not return good status the Boot Voltage Write operation... ");    
    reqhalt RC_SBE_SPIVID_WRITE_RETURN_STATUS_ERROR
