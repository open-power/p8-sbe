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




/// \file sbe_base_header.S
/// \brief SBE Base image SBE-XIP header assembler definition
///
/// The header is always linked at the base address of the image. The contents
/// of the header are documented in sbe_xip_image.h.

	.nolist
#include "p8_sbe.H"
#include "proc_sbe_fixed.H"
	.list

	.seeprom
	
	// *HACK* - make it look like a SEEPROM for now so branch from OTPROM
	// will work. Change to SBE_BASE_MAGIC eventualy.
	SbeXipHeader SBE_SEEPROM_MAGIC, SBE_BASE_ORIGIN, _sbe_seeprom_start, _sbe_base_size

	// These symbols defined in the header must be made global for the
	// benefit of proc_sbe_tp_ld_image which needs to locate the .pibmem0
	// section in the image.

	.global	__link_address, __pibmem0_section

	// Create the .fixed section

	.proc_sbe_fixed
