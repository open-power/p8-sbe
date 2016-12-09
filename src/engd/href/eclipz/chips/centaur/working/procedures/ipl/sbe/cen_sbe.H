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



#ifndef __CEN_SBE_H
#define __CEN_SBE_H

// $Id: cen_sbe.H,v 1.7 2012/04/12 13:06:51 bcbrock Exp $

/// \file cen_sbe.H
/// \brief A header to be included into all Centaur SBE assembler files and C++
/// hardware procedures that interact with Centaur SBE images.
///
/// This header #include-s all generally useful headers required for SBE code
/// development as well as defining other needed facilities.  Note that any
/// sub-includes must be done in an assembler-safe way.

#include "sbe_common.H"
#include "cen_scom_addresses.H"
#include "cen_istep_num.H"

// The #include of fapiHwpReturnCodes.H must be made here (instead of in
// sbe_common.H) to guarantee that the Centaur-local copy is used.
#include "fapiHwpReturnCodes.H"

#ifdef __ASSEMBLER__

        // cen_sbe.H 'recursively' inserts itself into any hook code extracted
        // from an assembly context that includes cen_sbe.H.

	##`#include "cen_sbe.H"

#endif  // __ASSEMBLER__


#endif  // __CEN_SBE_H
