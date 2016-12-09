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



#ifndef __CEN_ISTEP_NUM_H
#define __CEN__ISTEP_NUM_H

// $Id: cen_istep_num.H,v 1.4 2012/11/12 17:07:53 jeshua Exp $

/// Istep number encoding for all Centaur procedures.  Used to update the
/// SBEVITAL register to record procedure progress and to create unique hooki
/// bind points on procedure completion.

CONST_UINT64_T(cen_sbe_tp_chiplet_init1_istep_num,   ULL(0x0a01));
CONST_UINT64_T(cen_sbe_pll_initf_istep_num,          ULL(0x0a02));
CONST_UINT64_T(cen_sbe_pll_setup_istep_num,          ULL(0x0a03));
CONST_UINT64_T(cen_sbe_tp_chiplet_init2_istep_num,   ULL(0x0a04));
CONST_UINT64_T(cen_sbe_tp_arrayinit_istep_num,       ULL(0x0a05));
CONST_UINT64_T(cen_sbe_tp_chiplet_init3_istep_num,   ULL(0x0a06));
CONST_UINT64_T(cen_sbe_chiplet_init_istep_num,       ULL(0x0a07));
CONST_UINT64_T(cen_sbe_arrayinit_istep_num,          ULL(0x0a08));
CONST_UINT64_T(cen_sbe_dts_init_istep_num,           ULL(0x0a09));
CONST_UINT64_T(cen_sbe_initf_istep_num,              ULL(0x0a0a));
CONST_UINT64_T(cen_sbe_do_manual_inits_istep_num,    ULL(0x0a0b));
CONST_UINT64_T(cen_sbe_nest_startclocks_istep_num,   ULL(0x0a0c));
CONST_UINT64_T(cen_sbe_scominits_istep_num,          ULL(0x0a0d));

#endif  // __CEN_ISTEP_NUM_H
