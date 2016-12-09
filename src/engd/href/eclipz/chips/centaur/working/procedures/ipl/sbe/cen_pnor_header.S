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




/// \file cen_pnor_header.S
/// \brief SBE-XIP header for Centaur
///
/// The header is always linked at the base address of the SBE-XIP image. The
/// contents of the header are documented in sbe_xip_image.h.

	.nolist
#include "sbe_common.H"
#include "sbe_xip_image.h"
#include "sbe_xip_header.H"
#include "cen_sbe_fixed.H"
	.list

	.pnor
	
	SbeXipHeader SBE_CENTAUR_MAGIC, SBE_BASE_ORIGIN, _sbe_pnor_start, _sbe_base_size

	// Create the .fixed data section

	.cen_sbe_fixed
