# IBM_PROLOG_BEGIN_TAG                                                   
# This is an automatically generated prolog.                             
#                                                                        
# OpenPOWER Project                                             
#                                                                        
# Contributors Listed Below - COPYRIGHT 2012,2016                        
# [+] International Business Machines Corp.                              
#                                                                        
#                                                                        
# Licensed under the Apache License, Version 2.0 (the "License");        
# you may not use this file except in compliance with the License.       
# You may obtain a copy of the License at                                
#                                                                        
#     http://www.apache.org/licenses/LICENSE-2.0                         
#                                                                        
# Unless required by applicable law or agreed to in writing, software    
# distributed under the License is distributed on an "AS IS" BASIS,      
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or        
# implied. See the License for the specific language governing           
# permissions and limitations under the License.                         
#                                                                        
# IBM_PROLOG_END_TAG                                                     




#
# Periods delimit name components    e.g. s1.10.RUNTIME.ringname.meta
#
NAME_PARTS	= ${@:s/./ /g}
CHIPTYPE	= ${NAME_PARTS:xs/ .*//f}
EC		= ${NAME_PARTS:xs/^\S+ //e:xs/ .*//f}
IPLMODE		= ${NAME_PARTS:xs/^\S+ \S+ //e:xs/ .*//f}
RING		= ${NAME_PARTS:xs/^\S+ \S+ \S+ //e:xs/ .*//f}
#
# Slightly different naming for seeprom binaries
#
CHIPTYPE_PREF	= ${@:s/_/ /g:xs/ .*//f}
SEEPROM_EC	= ${@:S/.sbe_seeprom.bin$//f:S/^${CHIPTYPE_PREF}_//f}
SEEPROM_HDR_BIN = ${@:S/_seeprom.bin/_seeprom.hdr.bin/f}
#
INITFILE	= ${CHIPTYPE}.initfile
EC_PREFIXS	= ${EC:@PREFIX@${CHIPTYPE}.${PREFIX}@}
#
# Centaur file name related dynamic variables
#
CEN_EC_PREFIXS		=	${CEN_EC:@PREFIX@centaur.${PREFIX}@}
CEN_EC_IPLMODE_PREFIXS	=	${CEN_EC_PREFIXS:@PREFIX@${CEN_IPLMODE:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
CEN_QUALIFIED_RINGS	=	${CEN_EC_IPLMODE_PREFIXS:@PREFIX@${CEN_SCAN_RINGS:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
CEN_ADD_RINGS		=	${CEN_QUALIFIED_RINGS:@PREFIX@${PREFIX}.ADD-RING @:Q-}
CEN_EC_SEEPROM_BINS	=	${CEN_EC:@PREFIX@centaur_${PREFIX}.sbe_seeprom.bin@}

#
# Murano file name related dynamic variables
#
S1_EC_PREFIXS		=	${S1_EC:@PREFIX@s1.${PREFIX}@}
S1_EC_IPLMODE_PREFIXS	=	${S1_EC_PREFIXS:@PREFIX@${S1_IPLMODE:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
S1_QUALIFIED_RINGS	=	${S1_EC_IPLMODE_PREFIXS:@PREFIX@${S1_SCAN_RINGS:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
S1_ADD_RINGS		=	${S1_QUALIFIED_RINGS:@PREFIX@${PREFIX}.ADD-RING @:Q-}
S1_EC_SEEPROM_BINS	=	${S1_EC:@PREFIX@s1_${PREFIX}.sbe_seeprom.bin@}
S1_ADD_OVR_RINGS	=	${S1_OVR_EC:@PREFIX@s1.${PREFIX}.OVR.ex_func_core.ADD-OVR-RING @:Q-}
#
# Venice file name related dynamic variables
#
P8_EC_PREFIXS		=	${P8_EC:@PREFIX@p8.${PREFIX}@}
P8_EC_IPLMODE_PREFIXS	=	${P8_EC_PREFIXS:@PREFIX@${P8_IPLMODE:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
P8_QUALIFIED_RINGS	=	${P8_EC_IPLMODE_PREFIXS:@PREFIX@${P8_SCAN_RINGS:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
P8_ADD_RINGS		=	${P8_QUALIFIED_RINGS:@PREFIX@${PREFIX}.ADD-RING @:Q-}
P8_EC_SEEPROM_BINS	=	${P8_EC:@PREFIX@p8_${PREFIX}.sbe_seeprom.bin@}
P8_ADD_OVR_RINGS	=	${P8_OVR_EC:@PREFIX@p8.${PREFIX}.OVR.ex_func_core.ADD-OVR-RING @}
#
# Naples file name related dynamic variables
#
N1_EC_PREFIXS		=	${N1_EC:@PREFIX@n1.${PREFIX}@}
N1_EC_IPLMODE_PREFIXS	=	${N1_EC_PREFIXS:@PREFIX@${N1_IPLMODE:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
N1_QUALIFIED_RINGS	=	${N1_EC_IPLMODE_PREFIXS:@PREFIX@${N1_SCAN_RINGS:@SUFFIX@${PREFIX}.${SUFFIX} @}@}
N1_ADD_RINGS		=	${N1_QUALIFIED_RINGS:@PREFIX@${PREFIX}.ADD-RING @:Q-}
N1_EC_SEEPROM_BINS	=	${N1_EC:@PREFIX@n1_${PREFIX}.sbe_seeprom.bin@}

# Set ODE and env. variables
ADD_RING_CMD		= ${:! ls -s ${${ENV_DIR}/${.PREFIX}.bin.srd:P}!:xs/^0.+/${ADD_RING_EMPTY}/e:xs/^[1-9].+/${ADD_RING_NORMAL}/e}

#
# Directory / path variables
#
# Stradale base make directory is one node above current
BASE_MK_DIR		=  ${CURDIR}
OBJ			=  ${CURDIR}
EKB_DIR			= eclipz
CTE_DIR			= cte
EKB_PATHHEAD		:= ${BASE_MK_DIR}/${EKB_DIR}
OVR_RING_DIR		= ${${CHIPTYPE}.1x.OVR.ex_func_core.bin.srd:P:H}
ENV_DIR			= ${ENV:S/W/hdw/f:S/U/vbu/f}
#ENV_DIR			= ${@:xs/^vbu\/.+/vbu/e:xs/$@/hdw/e}
FIPS_EXPORT		%=  ${bb}/export/ppc/fips/include
# Note: CTEPATH is used by sbe makefiles.
CTEPATH			=  ${BASE_MK_DIR}/${CTE_DIR}
P8EKB			=  ${EKB_PATHHEAD}/chips/p8
CENEKB			=  ${EKB_PATHHEAD}/chips/centaur
P8INIT_PATH		=  ${P8EKB}/working/ec_ind/scan
CENINIT_PATH		=  ${CENEKB}/working/ec_ind/scan
UTILS_SUBDIR		=  ${P8EKB}/working/procedures/utils
SBE_SUBDIR		=  ${P8EKB}/working/procedures/ipl/sbe
IPLTOOLS_SUBDIR		=  ${P8EKB}/working/procedures/ipl/tools
CEN_SBE_SUBDIR		=  ${CENEKB}/working/procedures/ipl/sbe
IPL_BUILD_SUBDIR	=  ${IPLTOOLS_SUBDIR}/p8_ipl_build
CEN_BUILD_SUBDIR	=  ${IPLTOOLS_SUBDIR}/p8_centaur_build
DELTASCAN_W_SUBDIR	=  ${IPLTOOLS_SUBDIR}/p8_delta_scan_w
DELTASCAN_R_SUBDIR	=  ${IPLTOOLS_SUBDIR}/p8_delta_scan_r
MOD2SCAN_SUBDIR		=  ${IPLTOOLS_SUBDIR}/modifier2scanselect
SAMPLE_SUBDIR		=  ${P8EKB}/working/procedures/sample/
ECMDPERLBIN		=  /usr/bin/perl
VPATH =hdw:vbu:../scandef:../figspy:../initfiles:../initfiles/ifscrub:bin:${SBE_SUBDIR}:${SBE_SUBDIR}/bin:${UTILS_SUBDIR}:${CEN_SBE_SUBDIR}:${IPLTOOLS_SUBDIR}/release:${FAPI}:${FIPS_EXPORT}:${OVR_RING_DIR}
FAPI			=  ${CTEPATH}/tools/ecmd/rel/ext/fapi/capi
PATH			%= ${PATH}:${IPLTOOLS_SUBDIR}/release:${IPLTOOLS_SUBDIR}/p8_centaur_build:${IPLTOOLS_SUBDIR}/p8_ipl_build:${SBE_SUBDIR}:${SBE_SUBDIR}/bin:${FAPI}:${FIPS_EXPORT}

#
# Path qualified files
#
REF_IMAGE_TAR		=	${refImage.tar.gz:P}
BIN_UTILS_TAR		=	${binUtils.tar.gz:P}
CTE_TOOLS_TAR		=	${ctetools.tar.gz:P}
INIT_MERGER		=	${initMerger.pl:P}
IF_SCRUBBER		=	${ifScrubber:P} 
SBE_HWP_ID		=	${sbe_hwp_id.pl:P}
SBE_XIP_TOOL		= 	${sbe_xip_tool:P} 
BUILD_PREFIX_HEADER	=	${buildPrefixHeader.pl:P}
SCRUBBER_CONFIG_FILE	=	${ifScrubber.config:P}
SPYDEF_FILE		=	${${CHIPTYPE}_${EC}.spydef:P:S/s1_12/s1_10/f}
SCANDEF_FILE		=	${${CHIPTYPE}_${EC}.scandef:P:S/s1_12/s1_10/f}

#############################################################################################
# DO NOT DELETE THESE
# The following variables are used in the EKB makefiles and need to be defined in order to build the SBE images
# CRONUS_PATH and ECMD_PLUGIN defs are another hack that goes with the rule below.  These compensate for a
# EKB makefile that assumes they are set without checking
#
# _NFP needs to be defined to get some of the p8.utilities programs built successfully
CFLAGS				%= -D_NFP -I${FAPI} -I${FIPS_EXPORT}
CTEPATH				%= ${CTEPATH}
CRONUS_PATH			%= ${sb}/../export/ppc/fips/include -I${FIPS_EXPORT}
ECMD_EXE			=  ${ECMD_PLUGIN}/ecmd_x86.exe
ECMD_PLUGIN			%= ${CURDIR}/hack
EKB				%= ${EKB_PATHHEAD}
LABPS				%= ${EKB_PATHHEAD}/lab/p8
LD_LIBRARY_PATH			%= ${LD_LIBRARY_PATH}:${FAPI}:${FIPS_EXPORT}:${CURDIR}

#
# Initfile variables
#

# NOTE: Only the initfiles identified in centaur.base.scaninits.def and p8.base.scaninits.def are to be included in the sbe & slw rings
#
CENTAUR_SCAN_INITS		= ${:! grep "CENTAUR_SCAN_INITS " ${CENINIT_PATH}/../centaur.base.scaninits.def | sed "s|^CENTAUR_SCAN_INITS :=||g" | sed "s| | -i ${CENINIT_PATH}/|g"!}

P8_HBI_AND_RUNTIME_SCAN_INITS 	= ${:! grep "P8_HBI_AND_RUNTIME_SCAN_INITS " ${P8INIT_PATH}/../p8.base.scaninits.def | sed "s|^P8_HBI_AND_RUNTIME_SCAN_INITS :=||g" | sed "s| | -i ${P8INIT_PATH}/|g"!}

P8_HBI_ONLY_SCAN_INITS 		= ${:! grep "P8_HBI_ONLY_SCAN_INITS " ${P8INIT_PATH}/../p8.base.scaninits.def | sed "s|^P8_HBI_ONLY_SCAN_INITS        :=||g" | sed "s| | -i ${P8INIT_PATH}/|g"!}

INIT_VERSIONS			= ${:! grep "^Versions =  " ${${CHIPTYPE}.HBI.initfile:P} | sed "s/^Versions =  //g" | sed "s/ //g" | sed "s/:/ : /g" | tr ',' ' ' !}

#
# Other variables
#

# Builder ID
BUILDER		=${:!id -un!}

# Date/time for logging
DATE_TIME	= ${DUMMY:!date!}

# Date / time value to stick in binaries for production build
PRODUCTION_BUILD_LOCATION = ${bb:T}
PRODUCTION_BUILD_TAR_DATE = ${:!stat --format=%z ${REF_IMAGE_TAR}!:xs/\s.+//e:xs/-//g}
PRODUCTION_BUILD_TAR_TIME = ${:!stat --format=%z ${REF_IMAGE_TAR}!:xs/\..+//e:xs/.+ //e:xs/://e:xs/:.+//e}

# Set up command to replace default build info for production builds
.if ${BUILDER} == "fspbld"
BUILD_DATE_TIME_UPDATE = echo ${DATE_TIME} "Overriding build date in sbe image for production builds with EKB tar date/time"; \
	${SBE_XIP_TOOL} $@ set \
		build_date '${PRODUCTION_BUILD_TAR_DATE}' \
		build_time '${PRODUCTION_BUILD_TAR_TIME}' \
		build_host '${PRODUCTION_BUILD_LOCATION}'
.else
PRODUCTION_BUILD_LOCATION +=_dirty
PRODUCTION_BUILD_DIRTY_LOCATION = ${PRODUCTION_BUILD_LOCATION:s/ //g}

BUILD_DATE_TIME_UPDATE = echo ${DATE_TIME} "Non-production build no changes needed to build date/time."; \
${SBE_XIP_TOOL} $@ set \
		build_host '${PRODUCTION_BUILD_DIRTY_LOCATION}'
.endif

# IPLMODE flag for delta scan tool
IPLMODE_FLAG	= ${IPLMODE:S/HBI/0/f:S/RUNTIME/1/f}

# Gen SBE version html
GEN_SBE_VERS_HTML	= ${SBE_HWP_ID} -f -D ${MAKETOP}../.. -l  >| sbe_hwp_id.html


# Untar rule name (not used for stradale)
#UNTAR			=	
UNTAR			= p8.href_untar

# Concurrent core init test option (not supported for stradale)
CCI_TEST_OPTION		= cci_test

# Makefile modification rule
BUILD_ENV_MODS		= makefile_ode_mods

# Create metadata command
META_DATA_CONTENT	= ${:! id -un!},EC=${EC},${IPLMODE},${RING}

# Required scan rings
REQUIRED_RINGS		= ${:! cat ${CHIPTYPE}_affected_rings | sort | uniq!:S/^/${ENV_DIR}\//g}

.include "makefile.common"


# The rules for the makefile must be at the end
.include <${RULES_MK}>
