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





OS           := $(shell uname)
TARGET_SOURCE  := modifier2scanselect.C

# *****************************************************************************
# The Linux Setup stuff
# *****************************************************************************
ifeq (${OS},Linux)
  TARGET       := modifier2scanselect.x86
  SUBDIR       := obj_x86/
	CC           := /gsa/ausgsa/projects/e/ecmd/utils/gcc-4.1.2-glibc-2.3.2/i686-pc-linux-gnu/bin/i686-pc-linux-gnu-g++
#  LDFLAGS      := -ldl 
#  CFLAGS       := ${CFLAGS} -ftemplate-depth-30 -Wall
endif

# *****************************************************************************
# The Aix Setup stuff
# *****************************************************************************
ifeq (${OS},AIX)
  TARGET       := modifier2scanselect.aix
  SUBDIR       := obj_aix/
	CC           := /gsa/ausgsa/projects/e/ecmd/utils/vacpp.7002/usr/vacpp/bin/xlC
  LDFLAGS      := 
  CFLAGS       := ${CFLAGS} -+ -qstaticinline -qnoinline 
endif

TARGET_SOURCE_OBJS  = $(basename $(TARGET_SOURCE))
TARGET_SOURCE_OBJS := $(addsuffix .o, $(TARGET_SOURCE_OBJS))

CFLAGS      := ${CFLAGS} -g -I.

#  $(info .... CC=${CC} TARGET_SOURCE_OBJS=${TARGET_SOURCE_OBJS} CFLAGS=${CFLAGS})

all: dir ${TARGET}
	@ls | grep "\."o$ | xargs -i mv {} ${SUBDIR}/

dir:
	@mkdir -p ${SUBDIR}


${TARGET}: ${TARGET_SOURCE_OBJS}
	${CC} ${LDFLAGS} $^ -o $@ 

clean:
	@echo "Removing files for modifier2scanselect ..."
	-rm ${TARGET}
	-rm ${SUBDIR}/${TARGET_SOURCE_OBJS}

${TARGET_SOURCE_OBJS}: %.o : %.C 
	${CC} -c ${CFLAGS} $< -o $@

promote:
	@echo Copying executables to release directory
	cp -p modifier2scanselect.aix ../release
	cp -p modifier2scanselect.x86 ../release
