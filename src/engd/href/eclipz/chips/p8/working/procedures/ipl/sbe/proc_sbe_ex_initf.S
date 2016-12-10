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
        .list


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
        .procedure proc_sbe_ex_initf, slw, "$Revision: 1.15 $"

	load_ring ex_lbst_eco conditional_override=1
	load_ring ex_abfa_eco conditional_override=1
	load_ring ex_cmsk_eco conditional_override=1
	load_ring ex_func_perv conditional_override=1
	load_ring ex_func_l3 conditional_override=1
	load_ring ex_func_l3refr conditional_override=1
        //Sim Speedup for L3 refresh cycles
        ##@ecmdDataBuffer data, partialgood;
        ##@ecmdChipTarget e_target;
        ##@std::string hierarchy;
        ##@fapi::ReturnCode rc;
        ##@uint32_t rc_ecmd;
        ##@uint8_t is_sim = 0;
        ##@rc = FAPI_ATTR_GET( ATTR_IS_SIMULATION, &i_target, is_sim);
        ##@if( !rc.ok() ) {
        ##@  return rc;
        ##@ }
        ##@if( is_sim ) {
        ##@  FAPI_DBG("Converting fapi-target to ecmd-target \n");
        ##@  fapiTargetToEcmdTarget( i_target, e_target);
        ##@  FAPI_DBG("Setting L3 refresh cycles to 0\n");
        ##@  if(io_pore.p0.read() & 0x40) {
        ##@    rc_ecmd = getScom( e_target, ALL_CORES_BITX_0x52000000|GENERIC_GP3_0x000F0012, partialgood);
        ##@    if(rc_ecmd){
        ##@      FAPI_ERR("Error (0x%x) getting partial good setup", rc_ecmd);
        ##@      rc.setEcmdError(rc_ecmd);
        ##@      return rc;
        ##@    }
        ##@  } else {
        ##@    partialgood.setBitLength(64) ;
        ##@    partialgood.setBit(io_pore.p0.read() & 0x3F) ;
        ##@  }
        ##@  e_target.chipUnitType = "ex";
        ##@  e_target.chipUnitTypeState = ECMD_TARGET_FIELD_VALID ;
        ##@  for(int i = 0x10; i < 0x20; i++ ) {
        ##@    e_target.chipUnitNumState = ECMD_TARGET_FIELD_VALID;
        ##@    if( partialgood.isBitSet(i)) {
        ##@      e_target.chipUnitNum = i-0x10;
        ##@      rc_ecmd = getScom( e_target, EX_CLK_STATUS_0x10030008+(0x01000000*e_target.chipUnitNum), data );
        ##@      if(rc_ecmd){
        ##@        FAPI_ERR("Error (0x%x) getting clock status in EX%02i", rc_ecmd, i-0x10);
        ##@        rc.setEcmdError(rc_ecmd);
        ##@        return rc;
        ##@      }
        ##@      if(data.isBitSet(24)) { //L3REFR SL status (1 = stopped, 0 = running)
        ##@        rc_ecmd = putSpyEnum( e_target,"EXP.L3.L3_ARB.L3CACTL.L3_PUMP_INIT_CFG","0_REFRESH_PERIODS");
        ##@        if(rc_ecmd){
        ##@          FAPI_ERR("Error (0x%x) setting L3_PUMP_INIT_CFG in EX%02i", rc_ecmd, i-0x10);
        ##@          rc.setEcmdError(rc_ecmd);
        ##@          return rc;
        ##@        }
        ##@        rc_ecmd = putSpyEnum( e_target,"EXP.L3.L3_ARB.L3CACTL.L3_DRAM_INIT_CFG","0_REFRESH_PERIODS");
        ##@        if(rc_ecmd){
        ##@          FAPI_ERR("Error (0x%x) setting L3_DRAM_INIT_CFG in EX%02i", rc_ecmd, i-0x10);
        ##@          rc.setEcmdError(rc_ecmd);
        ##@          return rc;
        ##@        }
        ##@      }
        ##@    }
        ##@  }
        ##@ }
        ##@return rc;
	load_ring ex_regf_l3 conditional_override=1
	load_ring ex_regf_l3refr conditional_override=1
        
        .end_procedure proc_sbe_ex_initf
