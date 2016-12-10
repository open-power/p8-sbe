# $Id: Makefile,v 1.49 2015/07/27 15:05:16 jmcgill Exp $
#
# Makefile for SBE-IPL images for PNOR.  This Make only works on
# X86 Linux hosts. 
#
# Make targets:
#
# all       : (Default) Build SBE-PNOR images and utilities
#
# xml       : Process supporting XML files to generate header files required
#             for HALT codes and SBE-PNOR hook compilation
#
# sbe_pnor  : Build an SBE-PNOR image.  This is _only_ the SBE binary image,
#             not an entire PNOR image.
#
# utilities : Build utility programs and procedures
#
# clean     : Removes the bin/ directory and all symbolic links

# Command-line variables:

# DEFS     : Expected to be a set of -D options for preprocessing and
#            assembly, for example
#
#                make <target> DEFS="-DFOO=0 -DBAR=1"
#
# HOSTBOOT : 'make [target] HOSTBOOT=1' to skew the build for Host Boot.  This
#             causes the <image>.hook.cc files to only contain the global
#             symbols, and no other hook references.

# This build process creates all non-CVS-controlled files in a ./bin
# subdirectory. This includes dependencies, objects, listings, maps,
# disassembly and the final link and binary images.  When images are built a
# few symbolic links are created back to this directory for all objects
# normally required for testing and debugging an image. The 'make clean'
# recreates ./bin as an empty directory and removes all symbolic links.

############################################################################
# set SBE_ROOT to the root directory where both p8 and centaur directory trees exist
# This assumes we are in one or the other of the sbe sub-directories
# like p8/working/procedures/ipl/sbe or centaur/working/procedures/ipl/sbe
SBE_ROOT := $(shell cd ../../../../..;pwd)
PROC_SBE := $(SBE_ROOT)/p8/working/procedures/ipl/sbe
CEN_SBE  := $(SBE_ROOT)/centaur/working/procedures/ipl/sbe

############################################################################

# Add all .S files required to build an SBE-IPL image for PNOR below

SBE-PNOR-SOURCES = \
  cen_pnor_header.S \
  cen_sbe_istep_pnor.S cen_sbe_tp_chiplet_init1.S \
  cen_sbe_tp_chiplet_init2.S cen_sbe_tp_arrayinit.S \
  cen_sbe_tp_chiplet_init3.S cen_sbe_chiplet_init.S \
  cen_sbe_arrayinit.S cen_sbe_pll_initf.S cen_sbe_pll_setup.S \
  cen_sbe_dts_init.S cen_sbe_initf.S \
  cen_sbe_do_manual_inits.S cen_sbe_nest_startclocks.S \
  cen_sbe_scominits.S \
  cen_sbe_initfile_versions.S \
  cen_sbe_source_revision.S \
  proc_sbe_common.S

# Add all .XML files required to build hook error handling code to
# SBE-PNOR-XML-SOURCES 

P8-XML = $(SBE_ROOT)/p8/working/procedures/xml/error_info
SBE-PNOR-XML-SOURCES = \
	$(P8-XML)/sbe_common_halt_codes.xml \
	$(SBE_ROOT)/centaur/working/procedures/xml/error_info/memory_errors.xml \
        $(SBE_ROOT)/centaur/working/procedures/xml/error_info/cen_sbe_repair_loader_errors.xml

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

$(info ............................................................................. $(MAKECMDGOALS) )

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
SBE_BOM_TOOL = ${PROC_SBE}/generateSBEImageBOM.pl

FAPI = $(ECMD_PATH)ext/fapi

#  Locations of required headers.
INCLUDES = -I. -I../../ \
	-I$(POREVE-COMMON)/poreve -I$(POREVE-COMMON)/model \
	-I$(ECMD_PATH)/capi \
	-I$(FAPI)/capi -I../../../../../common/working/procedures

INCLUDES += -I $(SBE_ROOT)/p8/working/procedures/ipl/sbe
INCLUDES += -I $(SBE_ROOT)/p8/working/procedures

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

  CFLAGS   = -Os -g -Wall -Werror -pipe -fPIC -m32 -DCENTAUR
  CXXFLAGS = $(CFLAGS)
  LDFLAGS  = -m elf_i386
endif

# Centaur code only runs on PORE-SBE.  This setting eliminates some
# conditional code from sbe_common.H specific to the Sleep/Winkle
# application. 

DEFS += -D__SBE_ONLY__=1

############################################################################

#  SBE-PNOR targets
SBE-PNOR-OBJECTS      = $(patsubst %.S,bin/%.o,$(SBE-PNOR-SOURCES))      
SBE-PNOR-DEPENDENCIES = $(patsubst %.S,bin/%.d,$(SBE-PNOR-SOURCES))      
SBE-PNOR-HOOK-SOURCES = $(patsubst %.S,bin/%.hook.cc,$(SBE-PNOR-SOURCES))
SBE-PNOR-HOOK-OBJECTS = $(patsubst %.S,bin/%.hook.o,$(SBE-PNOR-SOURCES)) 

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
	$(PROC_SBE)/sbe_xip_tool FINALIZE-IMAGE normalize; \
	$(PROC_SBE)/sbe_xip_tool FINALIZE-IMAGE set \
		build_date `date +%Y%m%d` \
		build_time `date +%H%M` \
		build_host `hostname` \
		build_user `id -un`


#  For now, the default target creates an SBE-PNOR
#  image, and all the utilities

.PHONY : all
all: utilities sbe_pnor

#  To create an SBE-PNOR image:
#
# The build process is driven by the requirement to successfully build the
# %.hook.o files, which are only built if the assembly is also successful.
#
#   1) Pass the %.link through cpp to create the final bin/%.link.script
#   2) Link the binaries to create the final link object
#   3) Validate the ELF section structure of the final link
#   4) Use objcopy to create the flat binary from the final link object.  The
#      object file is padded to the final *_end symbol to guarantee that
#      fetches will succeed in the virtual engine.
#   5) Use objcopy to extract the (non-allocated) .halt section
#   6) Finalize the SBE-XIP image ( The executable is over in the p8
#      ipl/sbe/bin directory ) 
#   7) Insert the .halt section from step 6 into the binary
#   8) Disassemble the final link object for reference
#  
#   9) Use the hook_indexer to obtain hook addresses and global symbols from
#      the final link
#  10) Compile the hook index file and link with all of the hook object files
#  11) Symbolically link the hook shared object back up here


.PHONY : sbe_pnor
ifdef HOSTBOOT 
sbe_pnor : centaur.sbe_pnor.bin 

centaur.sbe_pnor.bin : $(SBE-PNOR-OBJECTS) $(PROC_SBE)/sbe_base.link
else
sbe_pnor : centaur.sbe_pnor.bin centaur.sbe_pnor.hooks$(TARGET_EXT).so centaur.sbe_base.hooks$(TARGET_EXT).so

centaur.sbe_pnor.bin : $(SBE-PNOR-HOOK-OBJECTS) $(PROC_SBE)/sbe_base.link
endif
	cpp -P $(INCLUDES) -DCENTAUR $(DEFS) < $(PROC_SBE)/sbe_base.link > bin/sbe_pnor.link.script
	$(PORE-LD) -L $(PROC_SBE) $(SBE-PNOR-OBJECTS) \
	-Tbin/sbe_pnor.link.script -Map centaur.sbe_pnor.map -o centaur.sbe_pnor.out
	$(PROC_SBE)/sbe_xip_validate_object centaur.sbe_pnor.out centaur
	$(PORE-OBJCOPY) -O binary centaur.sbe_pnor.out centaur.sbe_pnor.bin \
	--pad-to 0x`/usr/bin/nm centaur.sbe_pnor.out | grep "A _sbe_base_end" | cut -d " " -f 1`
	$(PORE-OBJCOPY) -O binary centaur.sbe_pnor.out bin/sbe_pnor.halt \
	--only-section=.halt --set-section-flags .halt=alloc
	$(FINALIZE:FINALIZE-IMAGE=centaur.sbe_pnor.bin)
	$(PROC_SBE)/bin/sbe_xip_tool centaur.sbe_pnor.bin append .halt bin/sbe_pnor.halt
	$(PORE-OBJDUMP) -d -S centaur.sbe_pnor.out > centaur.sbe_pnor.dis
	$(SBE_BOM_TOOL) -c centaur.sbe_pnor.bin

centaur.sbe_pnor.hooks$(TARGET_EXT).so : $(SBE-PNOR-HOOK-OBJECTS) centaur.sbe_pnor.bin
	$(HOOK-INDEXER) -b centaur.sbe_pnor.out -c bin/sbe_pnor.hooks.cc -m pnor
	$(CXX) $(INCLUDES) $(CFLAGS) -shared -o centaur.sbe_pnor.hooks$(TARGET_EXT).so \
	bin/sbe_pnor.hooks.cc $(SBE-PNOR-HOOK-OBJECTS)

centaur.sbe_base.hooks$(TARGET_EXT).so : $(SBE-PNOR-HOOK-OBJECTS) centaur.sbe_pnor.hooks$(TARGET_EXT).so
	ln -s centaur.sbe_pnor.hooks$(TARGET_EXT).so centaur.sbe_base.hooks$(TARGET_EXT).so

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
	cpp $(INCLUDES) -DCENTAUR $(DEFS) $< | \
	$(HOOK-TOOLS)/hook_extractor $(patsubst %.S,bin/%.hook.cc,$<) | \
	$(PORE-AS) $(INCLUDES) -o $(patsubst bin/%.hook.o,bin/%.o,$@) \
	-g -ahln --listing-cont-lines='20' - > $(patsubst %.S,bin/%.lst,$<)
	if [ $$? -ne 0 ]; then exit 1; fi
	$(PROC_SBE)/sbe_xip_validate_object $(patsubst bin/%.hook.o,bin/%.o,$@)
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
	cpp $(INCLUDES) $(DEFS) $< 


# Write header files from dependent XML files. If the script fails then print
# the contents of the header and then delete whatever garbage the script left
# to force it to be built again.
#
# -*- HACK -*- Use fapiParseErrorInfo.pl from PROC_SBE until FW team updates
# the standard version for HALT codes.

.PHONY : xml

xml: $(FAPI_RC)

fapiHwpReturnCodes.H: $(FAPI)/capi/scripts/fapiParseErrorInfo.pl $(SBE-PNOR-XML-SOURCES) Makefile
	$(FAPI)/capi/scripts/fapiParseErrorInfo.pl . $(SBE-PNOR-XML-SOURCES)
	if [ $$? -ne 0 ]; then \
		echo "Build of fapiHwpReturnCodes.H failed; Current contents :"; \
		cat fapiHwpReturnCodes.H; \
		rm -f fapiHwpReturnCodes.H; \
        exit 1; fi

#  Make utility programs

.PHONY : utilities
utilities:
	$(MAKE) -C $(PROC_SBE) utilities

# Bring over a copy of proc_sbe_common.S whenever it changes.  This file is
# listed in the .cvsignore as it is not really part of this repository.  Given
# that only this single source file is shared this seems easier than building
# a shared archive.

proc_sbe_common.S: $(PROC_SBE)/proc_sbe_common.S
	cp -a $(PROC_SBE)/proc_sbe_common.S .

#  Clean up all object, dependency and other files
.PHONY : clean
clean:
	rm -f *.o *.a *.so *.d *.d.* *.bin *.out *.dis *.lst *.map *.script \
		*.hook.* *.hooks.*
	rm -rf bin
	mkdir -p bin
	rm -rf trying_gnu pgas.h # Temporary hack for trying GNU binutils
	rm -rf fapiHwpErrorInfo.H fapiHwpReturnCodes.H


# From the GNU 'Make' manual - these scripts uses the preprocessor to create
# dependency files (*.d), then mungs them slightly to make them work as Make
# targets. Note that the dependencies are for the bin/%.hook.o targets used to
# drive the build.
#
# -*- Hack -*- fapiHwpReturnCodes.H is explicitly specified to force the
# rebuild of a local copy rather than using the global copy which is not
# up-to-date. 

bin/%.d: %.S fapiHwpReturnCodes.H
	@set -e; rm -f $@; \
	$(CXX) -MM $(INCLUDES) $(CFLAGS) $(DEFS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,bin/\1.hook.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

bin/%.d: %.c fapiHwpReturnCodes.H
	@set -e; rm -f $@; \
	$(CXX) -MM $(INCLUDES) $(CFLAGS) $(DEFS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,bin/\1.hook.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

bin/%.d: %.C fapiHwpReturnCodes.H
	@set -e; rm -f $@; \
	$(CXX) -MM $(INCLUDES) $(CFLAGS) $(DEFS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,bin/\1.hook.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$


# The Cronus team requested that dependency targets only be included when
# required, as they may maintain copies of this directory that do not include
# all source files.  This is difficult to do in general (given the conditional
# structures provided by 'make'), but the solution below should work for their
# application.  This assumes that 'make' is only given a single goal, which
# for CRONUS will be 'sbe_pnor'.

# Otherwise we go ahead and include all dependencies unless this is a 'make
# clean', which is the only way to reset the dependencies.

ifeq ($(MAKECMDGOALS),sbe_pnor)
include $(SBE-PNOR-DEPENDENCIES)
endif

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(MAKECMDGOALS),sbe_pnor)
include $(SBE-PNOR-DEPENDENCIES)
endif
endif
