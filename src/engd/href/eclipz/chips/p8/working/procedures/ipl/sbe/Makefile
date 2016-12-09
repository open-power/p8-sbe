# $Id: Makefile,v 1.152 2015/07/27 15:34:30 jmcgill Exp $

# Makefile for OTPROM and SBE-IPL images for SEEPROM and PNOR.  This Make only
# works on X86 Linux hosts.

# Make targets:

# all          : (Default) Build OTPROM, SBE-PNOR and SBE-SEEPROM
#
# xml          : Process supporting XML files to generate header files required
#                for HALT codes and SBE-PNOR hook compilation
#
# otprom       : Build an OTPROM image.
#
# sbe_base     : Build the P8 SBE base image
#
# sbe_seeprom  : Build an SBE-SEEPROM image.  This is _only_ the SBE binary
#                image, not an entire SEEPROM image.
#
# sbe_pnor     : Build an SBE-PNOR image.  This is _only_ the SBE binary image,
#                not an entire PNOR image.
#
# pibmem0      : Build the PIBMEM0 image.  This is the first PIBMEM image,
#                initially loaded into the .pibmem0 section of the SEEPROM,
#                then copied to PIBMEM at run time.
#
# utilities    : Build utility programs and procedures
#
# clean        : Removes the bin/ directory and all symbolic links
#
# %.lst        : This is rule used to produce a detailed listing of a .S file
#                to stdout, e.g., 'make proc_sbe_tp_ld_image.lst'

# Command-line variables:

# DEFS     : Expected to be a set of -D options for preprocessing and
#            assembly, for example
#
#                make <target> DEFS="-DFOO=0 -DBAR=1"
#
# HOSTBOOT : 'make [target] HOSTBOOT=1' to skew the build for Host Boot.  This
#             causes the <image>.hook.cc files to only contain the global
#             symbols, and no other hook references.

# This build process creates most non-CVS-controlled files in a ./bin
# subdirectory. This includes dependencies, objects, listings, maps etc.  The
# most important final files required for testing and debugging an image are
# created in this directory.  The 'make clean' recreates ./bin as an empty
# directory and removes all local non-source files.

############################################################################

# Add all .S files required to build the OTPROM image below

OTPROM-SOURCES = sbe_otprom_header.S \
                 proc_sbe_enable_seeprom.S

# Add all .S files required to build the PIBMEM0 image below

PIBMEM0-SOURCES = \
	proc_sbe_pibmem_header.S \
	proc_sbe_error_handlers.S \
	proc_sbe_gear_switcher.S \
        proc_sbe_decompress_scan.S \
	proc_sbe_lco_loader_pibmem.S \
	proc_sbe_trigger_winkle_pibmem.S \
	proc_sbe_intr_service_pibmem.S

# Source files for the base/reference images are split into the code required
# for IPL and code required in the runtime images.  IPL code is compiled for
# .seeprom and goes into the .ipl_text and .ipl_data sections.  Runtime code
# is compiled for .oci and goes into the .text and .data sections.  Facilities
# are provided to build IPL and RT test images to gaurantee that the
# unsatisfied external references of the SBE code are well-understood.

# After the SBE-XIP header file, istep_seeprom, run_exinit, and common code, 
# IPL sources are listed in ISTEP order (from proc_sbe_istep_seeprom.S). 
# RT sources are unordered.

IPL-SOURCES = \
	sbe_base_header.S \
	proc_sbe_istep_seeprom.S \
	proc_sbe_run_exinit.S \
	proc_sbe_common.S \
	proc_sbe_security_setup.S \
	proc_sbe_standalone_setup.S \
	proc_sbe_tp_chiplet_init1.S \
	proc_sbe_tp_ld_image.S \
	proc_sbe_pibmem_loader.S \
        proc_sbe_nest_skewadjust.S \
	proc_sbe_npll_initf.S \
	proc_sbe_npll_setup.S \
	proc_sbe_tp_switch_gears.S \
	proc_sbe_tp_chiplet_init2.S \
	proc_sbe_tp_arrayinit.S \
	proc_sbe_tp_initf.S \
	proc_sbe_tp_chiplet_init3.S \
	proc_sbe_chiplet_init.S \
	proc_sbe_arrayinit.S \
	proc_sbe_setup_evid.S \
	proc_sbe_initf.S \
	proc_sbe_pb_startclocks.S \
	proc_sbe_scominit.S \
	proc_sbe_fabricinit.S \
	proc_sbe_check_master.S \
	proc_sbe_select_ex.S \
	proc_sbe_ex_chiplet_reset.S \
	proc_sbe_ex_chiplet_scan0.S \
	proc_sbe_ex_gptr_time_initf.S \
	proc_sbe_ex_core_gptr_time_initf.S \
	proc_sbe_ex_dpll_initf.S \
        proc_sbe_ex_dpll_setup.S \
	proc_sbe_ex_chiplet_init.S \
	proc_sbe_ex_repair_initf.S \
	proc_sbe_ex_core_repair_initf.S \
	proc_sbe_ex_arrayinit.S \
	proc_sbe_ex_initf.S \
	proc_sbe_ex_core_initf.S \
	proc_sbe_ex_do_manual_inits.S \
	proc_sbe_ex_startclocks.S \
	proc_sbe_ex_scominit.S \
	proc_sbe_ex_core_scominit.S \
	proc_sbe_ex_init_escape.S \
	proc_sbe_ex_sp_runtime_scom.S \
	proc_sbe_ex_occ_runtime_scom.S \
	proc_sbe_ex_host_runtime_scom.S \
	proc_sbe_enable_pnor.S \
	proc_sbe_lco_loader.S \
	proc_sbe_instruct_start.S \
	proc_sbe_trigger_winkle.S \
	proc_sbe_scan_service.S \
	proc_sbe_initfile_versions.S \
	proc_sbe_source_revision.S \

RT-SOURCES = \
	ima_slw_24x7.S \
	proc_slw_branch_table.S \
	proc_slw_pro_epi_log.S \
	proc_slw_base.S \
	proc_slw_error_handlers.S \
	proc_slw_poweronoff.S \
	proc_slw_sleep_thread_restore.S \
        proc_slw_ha_ptr_save_restore.S \
        proc_slw_ram.S \
	pts.S \
	pts_command.S \
	pts_error.S \
	pts_pba.S \
	pts_slw_config.S

SBE-BASE-SOURCES = $(IPL-SOURCES) $(RT-SOURCES)

IPL-TEST-SOURCES = $(IPL-SOURCES) proc_sbe_ipl_stubs.S

RT-TEST-SOURCES = $(RT-SOURCES) proc_sbe_rt_stubs.S

# Add all . and .C files needed to build utility procedures/programs below,
# along with the final list of utility programs

UTILITIES-SOURCES = sbe_xip_image.c sbe_xip_tool.c pore_inline_assembler.c pore_inline_disassembler.c

UTILITIES = sbe_xip_tool

# Add all halt code XML files to HALT-CODES below

XML = ../../xml/error_info
HALT-CODES = \
	$(XML)/sbe_common_halt_codes.xml \
        $(XML)/proc_sbe_scominit_errors.xml \
	$(XML)/proc_sbe_npll_setup_errors.xml \
	$(XML)/proc_sbe_fabricinit_errors.xml \
	$(XML)/proc_sbe_lco_loader_errors.xml \
	$(XML)/proc_sbe_check_master_errors.xml \
	$(XML)/proc_sbe_pb_startclocks.xml \
	$(XML)/proc_sbe_decompress_scan_halt_codes.xml \
	$(XML)/proc_sbe_pibmem_loader_halt_codes.xml \
	$(XML)/proc_slw_base_halt_codes.xml \
	$(XML)/sbe_load_ring_vec_ex_errors.xml \
        $(XML)/proc_sbe_setup_evid_errors.xml \
	$(XML)/proc_sbe_select_ex_errors.xml \
        $(XML)/proc_sbe_ex_dpll_setup_halt_codes.xml \
        $(XML)/proc_sbe_instruct_start_errors.xml \
	$(XML)/proc_sbe_scan_service_errors.xml \
	$(XML)/proc_sbe_trigger_winkle_errors.xml \
	$(XML)/proc_sbe_tp_switch_gears_errors.xml \
	$(XML)/proc_sbe_ex_startclocks_errors.xml \
	$(XML)/proc_sbe_ex_chiplet_scan0_errors.xml \
        $(XML)/proc_sbe_chiplet_init_errors.xml \
	${XML}/proc_pibmem_registers.xml \
	${XML}/proc_cfam_registers.xml \
	${XML}/proc_sbe_registers.xml \
	${XML}/p8_slw_registers.xml \
	${XML}/proc_clock_control_registers.xml \
        ${XML}/p8_pstate_registers.xml \
	${XML}/proc_sbe_nest_skewadjust_errors.xml

# VPATH
# Support file paths
PROC_PATH := ../../../procedures
VPATH     := ${PROC_PATH}:${PROC_PATH}/utils

############################################################################

OS = $(shell uname)
ifneq ($(OS),Linux)
$(error This build only works under Linux)
endif

ifeq ($(CTEPATH),)
$(warning CTEPATH not defined; defaulting to awd)
CTEPATH = /afs/awd/projects/cte
endif

ifdef HOSTBOOT
HOOK-INDEXER-GLOBAL-ONLY-FLAG = -g
else
HOOK-INDEXER-GLOBAL-ONLY-FLAG =
endif

# Are we setup for eCMD, if so let's get our eCMD Release from there
ifneq ($(strip $(ECMD_RELEASE)),)
  ECMD_RELEASE := $(shell ecmdVersion full)
  # Make sure we got a valid version back
  ifeq ($(findstring ver,$(ECMD_RELEASE)),)
    ECMD_RELEASE := rel
  endif
else
  # If not setup for eCMD, default to rel
  ECMD_RELEASE := rel
endif

# Ok, now set our eCMD Path, if not set already
ifeq ($(strip $(ECMD_PATH)),)
  ECMD_PATH   := ${CTEPATH}/tools/ecmd/${ECMD_RELEASE}/
endif

# Check the ECMD_ARCH env var to see if we should build 32 or 64 bit
ifeq ($(strip $(ECMD_ARCH)),)
  ifeq ($(strip $(OS)),AIX)
    TARGET_ARCH := aix
  else
    TARGET_ARCH := x86
  endif
else
  TARGET_ARCH := ${ECMD_ARCH}
endif

ifeq ($(strip $(ECMD_PLUGIN)),cro)
# Cronus plugin specific setup
  CRONUS_PATH := $(shell echo ${ECMD_EXE} | sed -n 's|\([a-zA-Z0-9]*\)\(_*\)\([a-zA-Z0-9]*\)_${TARGET_ARCH}\.exe|prcd_d|p')
  ifeq ($(strip $(CRONUS_PATH)),)
    $(error "Error determining CRONUS_PATH from env!")
  endif
endif

# determine LABPS from environment
ifeq ($(strip $(LABPS)),)
  $(warning LABPS not defined, defaulting to awd)
  LABPS := /afs/awd/projects/eclipz/lab/p8
endif
# set path to KnowledgeBase
ifeq ($(strip $(EKB)),)
  EKB = $(LABPS)/../../KnowledgeBase/eclipz
endif

# Firmware builds will use their own fapiHwpReturnCodes.H
ifndef HOSTBOOT
  FAPI_RC = fapiHwpReturnCodes.H
endif

# This is the path to POREVE tools and dependent source
POREVE-COMMON = $(EKB)/poreve/working

#  The common location of the HookManager header and tools to extract and index hooks
HOOK-TOOLS = $(POREVE-COMMON)/tools
HOOK-INDEXER = $(HOOK-TOOLS)/hook_indexer $(HOOK-INDEXER-GLOBAL-ONLY-FLAG)

# This is the standard GNU toolchain for PORE.  You can define
# PORE_TOOL_PREFIX to use another build.  Setting the special variable
# USE_GSIEXE_TOOLS=1 on the make command line allows use of alternate tools
#   from the gsiexe area of CTE.
# USE_CTE_TOOLS=1 on the make command line allows use of the CTE shadowed copies
#   This is the directory that sources the company-wide copies of CTE
#       /afs/watson/projects/vlsi/cte/tools/porebinutils
# By default we will use a versioned copy from the EKB (snapshotted from CTE)

# Uncomment only for special cases
#USE_GSIEXE_TOOLS = 1
#USE_CTE_TOOLS = 1

ifdef USE_GSIEXE_TOOLS
PORE_TOOL_PREFIX = $(CTEPATH)/tools/gsiexe/eclipz/pgas_asm/gnu/
endif
ifdef USE_CTE_TOOLS
PORE_TOOL_PREFIX = $(CTEPATH)/tools/porebinutils/prev/bin/pore-elf64-
endif
ifeq ($(PORE_TOOL_PREFIX),)
ifeq ($(TARGET_ARCH),ppc64)
PORE_TOOL_PREFIX = $(EKB)/porebinutils_ppc/linux/bin/pore-elf64-
else
PORE_TOOL_PREFIX = $(EKB)/porebinutils/pore-elf64-
endif
endif
PORE-AS      = $(PORE_TOOL_PREFIX)as
PORE-LD      = $(PORE_TOOL_PREFIX)ld
PORE-OBJCOPY = $(PORE_TOOL_PREFIX)objcopy
PORE-OBJDUMP = $(PORE_TOOL_PREFIX)objdump

# BOM generation program
SBE_BOM_TOOL = generateSBEImageBOM.pl

# We need common up-to-date headers for FAPI - currently using these.
FAPI = $(ECMD_PATH)ext/fapi

#  Locations of required headers.
INCLUDES = -I. -I../../ -I../../utils \
	-I${POREVE-COMMON}/poreve -I$(POREVE-COMMON)/model \
	-I$(CRONUS_PATH) \
	-I$(ECMD_PATH)/capi \
	-I$(FAPI)/capi

# Under Linux the scheme is to use a common compiler to create procedures.
# However, the common compiler can be VERY slow, so if the system compiler is
# also 4.1.2 we're using that one instead.  Also, the Linux FAPI libraries we
# link with are 32-bit only so we need to force 32-bit mode.
ifeq ($(TARGET_ARCH),x86_64)
  CC  = /opt/rh/devtoolset-2/root/usr/bin/gcc
  CXX = /opt/rh/devtoolset-2/root/usr/bin/g++
  CFLAGS   = -Os -g -Wall -Werror -pipe -fPIC -m64
  CXXFLAGS = $(CFLAGS)
  LDFLAGS  = -m elf_x86_64
  TARGET_EXT = _x86_64
else ifeq ($(TARGET_ARCH),ppc64)
  CC  = /usr/bin/gcc
  CXX = /usr/bin/g++
  CFLAGS   = -Os -g -Wall -Werror -pipe -fPIC -m64
  CXXFLAGS = $(CFLAGS)
  LDFLAGS  = -m elf64ppc
  TARGET_EXT = _ppc64
else 
  ifeq ($(wildcard /etc/ldap.conf), )
    ifeq ($(wildcard /usr/gsa/etc/gsa.conf), )
      GSACELL     = ausgsa
    else
      GSACELL  := $(shell cat /usr/gsa/etc/gsa.conf | grep cellname | cut -d" " -f2 | cut -d. -f1)
    endif
  else
    GSACELL     = $(shell cat /etc/ldap.conf | grep "host " | \
          cut -d" " -f2 | cut -d. -f1)
  endif

  GCC-VERSION = $(shell gcc -v 2>&1 | grep "version 4.1.2")

  ifeq ($(GCC-VERSION),)
  GCC-DIR = /gsa/$(GSACELL)/projects/e/ecmd/utils/gcc-4.1.2-glibc-2.3.2/i686-pc-linux-gnu/bin
  CC  = $(GCC-DIR)/i686-pc-linux-gnu-gcc
  CXX = $(GCC-DIR)/i686-pc-linux-gnu-g++
  else
  CC   = gcc
  CXX  = g++
  endif

  CFLAGS   = -Os -g -Wall -Werror -pipe -fPIC -m32
  CXXFLAGS = $(CFLAGS)
  LDFLAGS  = -m elf_i386
endif


# If the variable PTS-TEST is defined, the base image is built with all of the
# PORE thread scheduler (PTS) debugging options, and a special configuration
# of PTS threads is enabled for lab bringup.

ifdef PTS-TEST
DEFS += -DCONFIGURE_PTS_DEBUG=1 -DCONFIGURE_PTS_TEST=1 \
	-DCONFIGURE_PTS_TRACE=1 -DCONFIGURE_PTS_STATS=1
endif

# If the variable PTS-DEBUG-HALT is defined, the base image is built such that
# PTS itself and PTS threads will not attempt to handle _any_ errors, but
# simply halt. This is necessary because normal error handling must destroy Dx
# and Ax state. This does not modify the way deep idle code handles errors
# (they always halt).

ifdef PTS-DEBUG-HALT
DEFS += -DPTS_HALT_ON_ERRORS=1
endif


# Issue HW274735 documents that the PORE BSI and BCI instructions are broken
# for the GPE0/GPE1 engine pair. Ideally we would be able to use the
# workaround for this everywhere (i.e., redefining BSI and BCI as
# macros). Unfortunately this blows up the OTPROM image past its legal
# size. Therefore we specify that the images built by this Makefile should use
# the native instructions. This is safe as long as these images are _never_
# executed on GPE0/GPE1, which is the current plan of record.

DEFS += -DIGNORE_HW274735=1

############################################################################

#  OTPROM targets

OTPROM-OBJECTS      = $(patsubst %.S,bin/%.o,$(OTPROM-SOURCES))
OTPROM-DEPENDENCIES = $(patsubst %.S,bin/%.d,$(OTPROM-SOURCES))
OTPROM-HOOK-SOURCES = $(patsubst %.S,bin/%.hook.cc,$(OTPROM-SOURCES))
OTPROM-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(OTPROM-SOURCES))

#  IPL-TEST image targets
IPL-TEST-OBJECTS      = $(patsubst %.S,bin/%.o,$(IPL-TEST-SOURCES))
IPL-TEST-DEPENDENCIES = $(patsubst %.S,bin/%.d,$(IPL-TEST-SOURCES))
IPL-TEST-HOOK-SOURCES = $(patsubst %.S,bin/%.hook.cc,$(IPL-TEST-SOURCES))
IPL-TEST-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(IPL-TEST-SOURCES))

#  RT-TEST image targets
RT-TEST-OBJECTS      = $(patsubst %.S,bin/%.o,$(RT-TEST-SOURCES))
RT-TEST-DEPENDENCIES = $(patsubst %.S,bin/%.d,$(RT-TEST-SOURCES))
RT-TEST-HOOK-SOURCES = $(patsubst %.S,bin/%.hook.cc,$(RT-TEST-SOURCES))
RT-TEST-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(RT-TEST-SOURCES))

#  Base image targets
SBE-BASE-OBJECTS      = $(patsubst %.S,bin/%.o,$(SBE-BASE-SOURCES))
SBE-BASE-DEPENDENCIES = $(patsubst %.S,bin/%.d,$(SBE-BASE-SOURCES))
SBE-BASE-HOOK-SOURCES = $(patsubst %.S,bin/%.hook.cc,$(SBE-BASE-SOURCES))
SBE-BASE-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(SBE-BASE-SOURCES))

#  IPL (SEEPROM) image targets
SBE-IPL-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(IPL-SOURCES))

#  PIBMEM0 targets
PIBMEM0-OBJECTS      = $(patsubst %.S,bin/%.o,$(PIBMEM0-SOURCES))
PIBMEM0-DEPENDENCIES = $(patsubst %.S,bin/%.d,$(PIBMEM0-SOURCES))
PIBMEM0-HOOK-SOURCES = $(patsubst %.S,bin/%.hook.cc,$(PIBMEM0-SOURCES))
PIBMEM0-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(PIBMEM0-SOURCES))

#  Utility targets
UTILITIES-OBJc         = $(patsubst %.c,bin/%.o,$(UTILITIES-SOURCES))
UTILITIES-OBJECTS      += $(patsubst %.C,bin/%.o,$(UTILITIES-OBJc))
UTILITIES-DEPENDENCIES = $(patsubst %.o,%.d,$(UTILITIES-OBJECTS))
UTILITIES-EXECUTABLES  = $(patsubst %,bin/%,$(UTILITIES))


############################################################################

# This macro adds the finishing touches to SBE-XIP images by normalizing them
# and adding several fields of meta-data to the header.  The macro is expanded
# in-line with FINALIZE-IMAGE substituted for the image to modify.

FINALIZE := \
	./sbe_xip_tool FINALIZE-IMAGE normalize; \
	./sbe_xip_tool FINALIZE-IMAGE set \
		build_date `date +%Y%m%d` \
		build_time `date +%H%M` \
		build_host `hostname` \
		build_user `id -un`


$(info ............................................................................. $(MAKECMDGOALS) )

#  For now, the default target creates OTPROM, SBE-PNOR and SBE-SEEPROM
#  images, and indirectly the PIBMEM0 image and all of the utilities.

.PHONY : all
all: otprom pibmem0 sbe_base
#  sbe_pnor sbe_seeprom

#  To create an OTPROM, SBE-BASE or PIBMEM0 image:
#
# The build process is driven by the requirement to successfully build the
# %.hook.o files, which are only built if the assembly is also successful.
#
#   1) Pass the %.link through cpp to create the final bin/%.link.script
#   2) Link the binaries to create the final link object
#      (* SBE-BASE Only * - Link against pibmem0.out as well)
#   3) Validate the ELF section structure of the final link
#   4) Disassemble the final link object for reference
#   5) Use objcopy to create the flat binary from the final link object.  The
#      object file is padded to the final *_end symbol to guarantee that
#      fetches will succeed in the virtual engine.
#   6) * SBE-BASE Only * Finalize the SBE-XIP image
#   7) * SBE-BASE, PIBMEM0 only * Use objcopy to extract the (non-allocated)
#      .halt section
#   8) * SBE-BASE Only * Insert the .halt sections from step 7
#   9) * SBE-BASE Only * Insert the PIBMEM0 image into the .pibmem0 section

#
#  10) Use the hook_indexer to obtain hook addresses and global symbols from
#      the final link
#  11) Compile the hook index file and link with all of the hook object files


.PHONY : otprom
ifdef HOSTBOOT
otprom : otprom.bin
else
otprom : otprom.bin otprom.hooks$(TARGET_EXT).so
endif

otprom.bin : $(OTPROM-HOOK-OBJECTS) otprom.link
	cpp -P $(INCLUDES) $(DEFS) < otprom.link > bin/otprom.link.script
	$(PORE-LD) $(OTPROM-OBJECTS) \
	-Tbin/otprom.link.script -Map otprom.map -o otprom.out
	./sbe_xip_validate_object otprom.out otprom
	$(PORE-OBJDUMP) -d -S otprom.out > otprom.dis
	$(PORE-OBJCOPY) -O binary otprom.out otprom.bin \
	--pad-to 0x`/usr/bin/nm otprom.out | grep "A _otprom_end" | cut -d " " -f 1`
	ln -sf otprom.bin p8.otprom.bin

otprom.hooks$(TARGET_EXT).so : $(OTPROM-HOOK-OBJECTS) otprom.bin
	$(HOOK-INDEXER) \
	 -b otprom.out -c bin/otprom.hooks.cc -m otprom
	$(CXX) $(INCLUDES) $(CXXFLAGS) -shared -o otprom.hooks$(TARGET_EXT).so \
	bin/otprom.hooks.cc $(OTPROM-HOOK-OBJECTS)
	ln -sf otprom.hooks$(TARGET_EXT).so p8.otprom.hooks$(TARGET_EXT).so

.PHONY : pibmem0
pibmem0 : pibmem0.bin pibmem0.hooks$(TARGET_EXT).so

ifdef HOSTBOOT
pibmem0.bin : $(PIBMEM0-OBJECTS) pibmem.link
else
pibmem0.bin : $(PIBMEM0-HOOK-OBJECTS) pibmem.link
endif
	cpp -P $(INCLUDES) $(DEFS) < pibmem.link > bin/pibmem.link.script
	$(PORE-LD) $(PIBMEM0-OBJECTS) \
	-Tbin/pibmem.link.script -Map pibmem0.map -o pibmem0.out
	./sbe_xip_validate_object pibmem0.out pibmem
	$(PORE-OBJDUMP) -d -S pibmem0.out > pibmem0.dis
	$(PORE-OBJCOPY) -O binary pibmem0.out pibmem0.bin \
	--pad-to 0x`/usr/bin/nm pibmem0.out | grep "A _pibmem_end" | cut -d " " -f 1`
	$(PORE-OBJCOPY) -O binary pibmem0.out bin/pibmem0.halt \
	--only-section=.halt --set-section-flags .halt=alloc
	ln -sf pibmem0.bin p8.pibmem0.bin

pibmem0.hooks$(TARGET_EXT).so : $(PIBMEM0-HOOK-OBJECTS) pibmem0.bin
	$(HOOK-INDEXER) \
	 -b pibmem0.out -c bin/pibmem0.hooks.cc -m pibmem
	$(CXX) $(INCLUDES) $(CXXFLAGS) -shared -o pibmem0.hooks$(TARGET_EXT).so \
	bin/pibmem0.hooks.cc $(PIBMEM0-HOOK-OBJECTS)
	ln -sf pibmem0.hooks$(TARGET_EXT).so p8.pibmem0.hooks$(TARGET_EXT).so

# The SBE-BASE image requires the IPL and RT test images to be built.  This
# does not add much overhead since the majority of the work is cmopiling the .S
# and the .hook.cc files which needs to be done anyway.

# We need to build two *.hooks.so files here: One for the IPL-only
# code that goes into the SEEPROM, and the other for the full
# sleep/winkle/24x7/iospcn image. The IPL-only hooks are built from an object
# file created by stripping out all sections that do not appear in the IPL
# image. 


.PHONY : sbe_base
ifdef HOSTBOOT
sbe_base : p8.sbe_base.bin 

p8.sbe_base.bin : $(SBE-BASE-OBJECTS) \
	pibmem0.bin sbe_base.link utilities
else
sbe_base : p8.sbe_base.bin p8.sbe_base.hooks$(TARGET_EXT).so p8.sbe_ipl.hooks$(TARGET_EXT).so

p8.sbe_base.bin : $(SBE-BASE-HOOK-OBJECTS) \
	pibmem0.bin sbe_base.link utilities ipl_test rt_test
endif
	cpp -P $(INCLUDES) $(DEFS) < sbe_base.link > bin/sbe_base.link.script
	$(PORE-LD) $(SBE-BASE-OBJECTS) -R pibmem0.out \
	-Tbin/sbe_base.link.script -Map p8.sbe_base.map -o p8.sbe_base.out
	./sbe_xip_validate_object p8.sbe_base.out base
	$(PORE-OBJDUMP) -d -S p8.sbe_base.out > p8.sbe_base.dis
	$(PORE-OBJCOPY) -O binary p8.sbe_base.out p8.sbe_base.bin \
	--pad-to 0x`/usr/bin/nm p8.sbe_base.out | grep "A _sbe_base_end" | cut -d " " -f 1`
	$(FINALIZE:FINALIZE-IMAGE=p8.sbe_base.bin)
	$(PORE-OBJCOPY) -O binary p8.sbe_base.out bin/sbe_base.halt \
	--only-section=.halt --set-section-flags .halt=alloc
	./bin/sbe_xip_tool p8.sbe_base.bin append .halt bin/sbe_base.halt
	./bin/sbe_xip_tool p8.sbe_base.bin append .halt bin/pibmem0.halt
	./bin/sbe_xip_tool p8.sbe_base.bin append .pibmem0 pibmem0.bin
ifeq ($(BYPASS_BOM_TOOL),)
	$(SBE_BOM_TOOL) p8.sbe_base.bin
endif

p8.sbe_base.hooks$(TARGET_EXT).so : $(SBE-BASE-HOOK-OBJECTS) p8.sbe_base.bin
	$(HOOK-INDEXER) \
	 -b p8.sbe_base.out -c bin/sbe_base.hooks.cc -m seeprom
	$(CXX) $(INCLUDES) $(CXXFLAGS) -shared -o p8.sbe_base.hooks$(TARGET_EXT).so \
	bin/sbe_base.hooks.cc $(SBE-BASE-HOOK-OBJECTS)

p8.sbe_ipl.hooks$(TARGET_EXT).so : $(SBE-IPL-HOOK-OBJECTS) p8.sbe_base.bin
	$(PORE-OBJCOPY) -R .text -R .data -R .toc -R .strings -R .halt \
		p8.sbe_base.out bin/sbe_ipl.out
	$(HOOK-INDEXER) \
	 -b bin/sbe_ipl.out -c bin/sbe_ipl.hooks.cc -m seeprom
	$(CXX) $(INCLUDES) $(CXXFLAGS) -shared -o p8.sbe_ipl.hooks$(TARGET_EXT).so \
	bin/sbe_ipl.hooks.cc $(SBE-IPL-HOOK-OBJECTS)


# The IPL and RT test images are built to guarantee that the image structure
# is well understood for the eventual spilt into the SEEPROM.

.PHONY : ipl_test
ipl_test : p8.ipl_test.out

p8.ipl_test.out : $(IPL-TEST-HOOK-OBJECTS) pibmem0.bin sbe_base.link utilities
	cpp -P $(INCLUDES) $(DEFS) < sbe_base.link > bin/sbe_base.link.script
	$(PORE-LD) $(IPL-TEST-OBJECTS) -R pibmem0.out \
	-Tbin/sbe_base.link.script -Map p8.ipl_test.map -o p8.ipl_test.out
	./sbe_xip_validate_object p8.ipl_test.out ipl_test


.PHONY : rt_test
rt_test : p8.rt_test.out

p8.rt_test.out : $(RT-TEST-HOOK-OBJECTS) pibmem0.bin sbe_base.link utilities
	cpp -P $(INCLUDES) $(DEFS) < sbe_base.link > bin/sbe_base.link.script
	$(PORE-LD) $(RT-TEST-OBJECTS) -R pibmem0.out \
	-Tbin/sbe_base.link.script -Map p8.rt_test.map -o p8.rt_test.out
	./sbe_xip_validate_object p8.rt_test.out rt_test


# Currently the SBE-PNOR and SBE-SEEPROM images are linked to the SBE-BASE
# image, pending the implementation of the procedures that create the actual
# PNOR and SEEPROM images.

##.PHONY : sbe_pnor
##sbe_pnor: p8.sbe_base.bin p8.sbe_base.hooks.so
##	ln -sf p8.sbe_base.out p8.sbe_pnor.out
##	ln -sf p8.sbe_base.bin p8.sbe_pnor.bin
##	ln -sf p8.sbe_base.dis p8.sbe_pnor.dis
##	ln -sf p8.sbe_base.map p8.sbe_pnor.map
##	ln -sf p8.sbe_base.hooks.so p8.sbe_pnor.hooks.so


##.PHONY : sbe_seeprom
##sbe_seeprom: p8.sbe_base.bin p8.sbe_base.hooks.so
##	ln -sf p8.sbe_base.out p8.sbe_seeprom.out
##	ln -sf p8.sbe_base.bin p8.sbe_seeprom.bin
##	ln -sf p8.sbe_base.dis p8.sbe_seeprom.dis
##	ln -sf p8.sbe_base.map p8.sbe_seeprom.map
##	ln -sf p8.sbe_base.hooks.so p8.sbe_seeprom.hooks.so


#  Default rule to build .o and .hook.o files from .S files
#
#  1) Preprocess the .S file and pipe through the hook_extractor and into the
#     assembler. This creates a PORE object file, assembler listing (bin/%.lst)
#     and hook source code (bin/%.hook.cc) for every .S file.
#
#  2) If the assembly fails stop immediately - Don't compile the hooks.
#
#  3) Validate the ELF section structure of the object, again stopping
#     immediately in case of failure.
#
#  4) Compile the file created by the hook extractor to create the *.hook.o

# Note - The parallel build of the *.o and the *.hook.o is straighforward when
# everything works.  The process implemented below should gaurantee that make
# doesn't get 'stuck' or out of sync in the event of failures in either part.
# As a last resort, if things get stuck there's always
#
#     make clean; make

ifdef HOSTBOOT
bin/%.o: %.S
else
bin/%.hook.o: %.S
endif
	cpp $(INCLUDES) $(DEFS) $< | \
	$(HOOK-TOOLS)/hook_extractor $(patsubst %.S,bin/%.hook.cc,$<) | \
	$(PORE-AS) $(INCLUDES) -o $(patsubst bin/%.hook.o,bin/%.o,$@) \
	-g -ahln --listing-cont-lines='20' - > $(patsubst %.S,bin/%.lst,$<)
	if [ $$? -ne 0 ]; then exit 1; fi
	./sbe_xip_validate_object $(patsubst bin/%.hook.o,bin/%.o,$@)
	if [ $$? -ne 0 ]; then exit 1; fi
ifndef HOSTBOOT
	$(CXX) $(INCLUDES) $(CXXFLAGS) -c -o $@ $(patsubst %.o,%.cc,$@)
endif

#  This is a make rule to help find errors coming from headers and assembler
#  macros. The source file is preprocessed, all line markers are removed, then
#  the file is assembled with a detailed listing to stdout.  For example to
#  debug proc_sbe_tp_ld_image.S, try
#
#      make proc_sbe_tp_ld_image.lst

%.lst: %.S
	cpp $(INCLUDES) $(DEFS) $< | grep -h -v "^#" | \
	$(PORE-AS) $(INCLUDES) -o /dev/null \
	 -g -ahlnm --listing-cont-lines='20' -


# Build fapiHwpReturnCodes.H.  If the script fails then print the contents of
# the header and then delete whatever garbage the script left to force it to
# be built again.
#
# Adding the Makefile itself as a target precondition protects
# against misunderstandings when a new XML file is added to the Make but the
# user does not do a 'make clean' - this forces the header to be rebuilt
# (which forces all of the SBE code to be rebuilt as well).
#
# -*- HACK -*- Use local version of fapiParseErrorInfo.pl until FW team
# updates the standard version to work in assembly.  The source for this
# script is : $(FAPI)/capi/scripts/fapiParseErrorInfo.pl

.PHONY : xml

xml: $(FAPI_RC)

fapiHwpReturnCodes.H: $(FAPI)/capi/scripts/fapiParseErrorInfo.pl $(HALT-CODES) Makefile
	$(FAPI)/capi/scripts/fapiParseErrorInfo.pl . $(HALT-CODES)
	if [ $$? -ne 0 ]; then \
	echo "Build of fapiHwpReturnCodes.H failed; Current contents :"; \
	cat fapiHwpReturnCodes.H; \
	rm -f fapiHwpReturnCodes.H; \
	exit 1; fi

#  Make utility programs

.PHONY : utilities
utilities: $(UTILITIES-EXECUTABLES)

bin/%.o: %.c
	$(CXX) $(INCLUDES) $(CXXFLAGS) -DDEBUG_SBE_XIP_IMAGE=1 -c -o $@ $<

bin/sbe_xip_tool: bin/sbe_xip_tool.o bin/sbe_xip_image.o bin/pore_inline_assembler.o bin/pore_inline_disassembler.o bin/p8_ring_identification.o
	$(CXX) $(CXXFLAGS) ${INCLUDES} -o $@ $^
	ln -sf bin/sbe_xip_tool sbe_xip_tool

#  Clean up all object, dependency and other files.

.PHONY : clean
clean:
	rm -f *.o *.a *.so *.d *.d.* *.bin *.out *.dis *.lst *.map *.script \
		*.hook.* *.hooks.* sbe_xip_tool
	rm -rf bin
	rm -rf fapiHwpReturnCodes.H fapiHwpErrorInfo.H 
	mkdir -p bin


# From the GNU 'Make' manual - these scripts use the preprocessor to create
# dependency files (*.d), then mungs them slightly to make them work as Make
# targets. Note that the dependencies are for the bin/%.hook.o targets used to
# drive the build.
#
# -*- Hack -*- fapiHwpReturnCodes.H is explicitly specified to force the
# rebuild of a local copy rather than using the global copy which is not
# up-to-date.

bin/%.d: %.S $(FAPI_RC)
	@set -e; rm -f $@; \
	$(CXX) -MM $(INCLUDES) $(CXXFLAGS) $(DEFS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,bin/\1.hook.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

bin/%.d: %.c $(FAPI_RC)
	@set -e; rm -f $@; \
	$(CXX) -MM $(INCLUDES) $(CXXFLAGS) $(DEFS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,bin/\1.hook.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

bin/%.d: %.C $(FAPI_RC)
	@set -e; rm -f $@; \
	$(CXX) -MM $(INCLUDES) $(CXXFLAGS) $(DEFS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,bin/\1.hook.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$


# The Cronus team requested that dependency targets only be included when
# required, as they may maintain copies of this directory that do not include
# all source files.  This is difficult to do in general (given the conditional
# structures provided by 'make'), but the solution below should work for their
# application.  This assumes that 'make' is only given a single goal.

# Otherwise we go ahead and include all dependencies unless this is a 'make
# clean', which is the only way to reset the dependencies.

##ifeq ($(MAKECMDGOALS),sbe_pnor)
##include $(SBE-BASE-DEPENDENCIES)
##include $(PIBMEM0-DEPENDENCIES)
##endif

ifeq ($(MAKECMDGOALS),sbe_base)
include $(SBE-BASE-DEPENDENCIES)
include $(PIBMEM0-DEPENDENCIES)
include $(UTILITIES-DEPENDENCIES)
endif

ifeq ($(MAKECMDGOALS),otprom)
include $(OTPROM-DEPENDENCIES)
endif

ifeq ($(MAKECMDGOALS),pibmem0)
include $(PIBMEM0-DEPENDENCIES)
endif

ifneq ($(MAKECMDGOALS),clean)
#ifneq ($(MAKECMDGOALS),sbe_pnor)
#ifneq ($(MAKECMDGOALS),sbe_seeprom)
ifneq ($(MAKECMDGOALS),otprom)
ifneq ($(MAKECMDGOALS),pibmem0)
include $(OTPROM-DEPENDENCIES)
include $(SBE-BASE-DEPENDENCIES)
include $(PIBMEM0-DEPENDENCIES)
include $(UTILITIES-DEPENDENCIES)
endif
endif
#endif
#endif
endif
