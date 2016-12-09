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
#include "proc_sbe_initf_common_seeprom.H"
#include "p8_slw.H"
        .list

//------------------------------------------------------------------------------
// constant declaration
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// preprocessor directives
//------------------------------------------------------------------------------

// #define SIM_PLL_SLOW

//------------------------------------------------------------------------------
// Directives
//------------------------------------------------------------------------------
        .seeprom

//------------------------------------------------------------------------------
// Global Data
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Local Macros
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Procedure
//------------------------------------------------------------------------------
        .procedure proc_sbe_ex_dpll_initf, slw, "$Revision: 1.24 $"


        // TODO - All of the register access commands in this file should go into some other procedure.
        //        This procedure should contain only those commands which set the DPLL scan ring.


        // ----- Setting OPCG Reg0 to 0x0080000000000000 -----
        // TODO - understand why this is needed to get the DPLL to lock,
        // See if we can get rid of this step.
//      POREVE_INF("<proc_sbe_ex_dpll_initf>: EX Chiplet -> Start DPLL init" )                                         //AK-WAFER : Makes no sense !
//      POREVE_INF("EX Chiplet -> Setting OPCG Reg0 to 0x0080000000000000")	// Jeshua working on scan fix ?        //AK-WAFER : Makes no sense !
//      andi    D1, D1, 0x0000000000000000                                                                             //AK-WAFER : Makes no sense !
//      ori     D1, D1, 0x0080000000000000                                                                             //AK-WAFER : Makes no sense !
//      std     D1, GENERIC_OPCG_CNTL0_0x00030002, P0                                                                  //AK-WAFER : Makes no sense !


        // ----- Drop DPLL test mode -----
        // TODO: is this action necessary?
        // Clear bit 3 of EX GP3 Register
        POREVE_INF("EX Chiplet -> Drop DPLL test mode" )
        sti     EX_GP3_AND_0x100F0013, P0, ~(BIT(3))


        // ----- Put DPLL into Reset -----
        // Set bit 10 of EX PM GP0 Register
//        POREVE_INF("<proc_sbe_ex_dpll_initf> : Assert DPLL reset" )
//       sti     EX_PMGP0_OR_0x100F0102, P0, BIT(10)
        // ----- Drop DPLL Reset -----
        // REDUNDANT WITH BYPASS!!!!
        // Clear bit 4 of EX GP3 Register
        // Clear bit 10 of EX PM GP0 Register
//        POREVE_INF("EX Chiplet -> Drop DPLL reset" )
//        sti     EX_GP3_AND_0x100F0013, P0, ~(BIT(4))
        sti     EX_PMGP0_AND_0x100F0101, P0, ~(BIT(10))


        // ----- Put the DPLL into bypass -----
        // Set bit 5 of EX GP3 Register
        POREVE_INF("<proc_sbe_ex_dpll_initf> : Put DPLL into bypass" )
        sti     EX_GP3_OR_0x100F0014, P0, BIT(5)


        // ----- Make sure that ff_bypass is set to "1" -----
        // TODO: is this necessary?  (It is supposed to scan to that state.)
        // Set bit 11 of DPLL Mode register  0x150F0152
        POREVE_INF("<proc_sbe_ex_dpll_initf> : Make sure ff_bypass is asserted" )
        setp1_mcreadand D0
        ld      D0, EX_DPLL_CPM_PARM_REG_0x100F0152, P1
        ori     D0, D0, BIT(11)
        std     D0, EX_DPLL_CPM_PARM_REG_0x100F0152, P0


        // ----- Set dpllclk_muxsel (syncclk_muxsel) to "1" -----
        POREVE_INF("<proc_sbe_ex_dpll_initf> : Set syncclk_muxsel prior to the DPLL scan")
        sti     GENERIC_GP0_OR_0x00000005, P0, BIT(1)
        sti     EX_PMGP0_OR_0x100F0102, P0, BIT(11)

        // Set EX scan ratio to 1:1 as EX is still at refclock                                 //AK-LAB
        POREVE_INF("<proc_sbe_ex_dpll_initf> : Set EX scan ratio to 1:1 ...\n")                //AK-LAB
        sti     EX_OPCG_CNTL0_0x10030002, P0, 0x0                                              //AK-LAB

        // ----- Scan the DPLL control bits into the ex_func_dpll chain -----
        POREVE_INF("<proc_sbe_ex_dpll_initf> : *** Loading DPLL ring for EX ***")
        load_ring ex_func_dpll conditional_override=1

        // Set EX scan ratio back to 8:1                                                       //AK-LAB
        POREVE_INF("<proc_sbe_ex_dpll_initf> : Set EX scan ratio to 8:1 ...\n")                //AK-LAB
        //Inputs: A1 and P0 and D0, destroys D0 & D1
        .pibmem_port (PORE_SPACE_PIBMEM & 0xf) 
        lpcs    P1, PIBMEM0_0x00080000
        ld      D0, ex_scan_ratio_override, P1
        bsr     set_scan_ratio_d0

        //Initialize the DPLL var osc to behave correctly
        ##@char facname[1024];
        ##@ecmdDataBuffer data, partialgood;
        ##@ecmdChipTarget e_target;
        ##@std::string hierarchy;
        ##@fapi::ReturnCode rc;
        ##@fapi::ATTR_NAME_Type chip_type;
        ##@bool is_naples=false; 
        ##@rc= FAPI_ATTR_GET_PRIVILEGED(ATTR_NAME, &i_target, chip_type);
        ##@if(rc)
        ##@{
        ##@FAPI_ERR("Error getting attr_name to check for Naples");
        ##@return rc; 
        ##@}
        ##@if(chip_type == fapi::ENUM_ATTR_NAME_NAPLES)
        ##@{
        ##@FAPI_INF("NAPLES chip found.");
        ##@is_naples=true; 
        ##@}
        ##@else
        ##@{
        ##@FAPI_INF("MURANO or VENICE found.");
        ##@} 
        ##@uint32_t rc_ecmd;
        ##@FAPI_DBG("Converting fapi-target to ecmd-target \n");
        ##@fapiTargetToEcmdTarget( i_target, e_target);
        ##@rc_ecmd = simGetHierarchy( e_target, hierarchy );
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) getting target hierarchy", rc_ecmd);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@rc_ecmd = getScom( e_target, ALL_CORES_BITX_0x52000000|GENERIC_GP3_0x000F0012, partialgood);
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) getting partial good setup", rc_ecmd);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@for(int i = 0x10; i < 0x20; i++ ) {
        ##@if( partialgood.isBitSet(i)) {
        ##@if(is_naples)
        ##@{
        ##@data.setBitLength( 1 );
        ##@data.setBit(0);
        ##@sprintf( facname, "%sEX%.2i.TP.ECO_DOM.TC_CCFLUSH_DC_INT", hierarchy.data(), i-0x10 );
        ##@rc_ecmd = simSTKFAC( facname, 1, data, 0, 0);
        ##@if(rc_ecmd){ 
        ##@FAPI_ERR("Error (0x%x) sticking %s", rc_ecmd, facname);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}    
        ##@}
        ##@else
        ##@{
        ##@data.setBitLength( 1 );
        ##@data.clearBit( 0 );
        ##@sprintf( facname, "%sEX%.2i.TP.ECO_DOM.DPLL.C_DPLL_BS.OSC.RTX_CNTL", hierarchy.data(), i-0x10 );
        ##@rc_ecmd = simSTKFAC( facname, 1, data, 0, 0);
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) sticking %s", rc_ecmd, facname);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@data.setBitLength( 16 );
        ##@data.setHalfWord( 0, (uint16_t)0x0480 );
        ##@sprintf( facname, "%sEX%.2i.TP.ECO_DOM.DPLL.C_DPLL_BS.REF_RATE", hierarchy.data(), i-0x10 );
        ##@rc_ecmd = simSTKFAC( facname, 16, data, 0, 0);
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) sticking %s", rc_ecmd, facname);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@data.setBitLength( 1 );
        ##@data.setBit( 0 );
        ##@sprintf( facname, "%sEX%.2i.TP.ECO_DOM.DPLL.C_DPLL_BS.OSC.START_LT", hierarchy.data(), i-0x10 );
        ##@rc_ecmd = simSTKFAC( facname, 1, data, 0, 0);
        ##@if(rc_ecmd){
        ##@FAPI_ERR("Error (0x%x) sticking %s", rc_ecmd, facname);
        ##@rc.setEcmdError(rc_ecmd);
        ##@return rc;
        ##@}
        ##@}
        ##@}
        ##@}
        ##@return rc;

        POREVE_INF("<proc_sbe_ex_dpll_initf> : *** End of procedure ***")

        .end_procedure proc_sbe_ex_dpll_initf
