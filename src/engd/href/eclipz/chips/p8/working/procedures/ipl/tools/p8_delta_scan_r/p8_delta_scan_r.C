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



// $Id: p8_delta_scan_r.C,v 1.12 2014/08/19 20:31:44 cmolsen Exp $
/*------------------------------------------------------------------------------*/
/* *! TITLE         p8_delta_scan_r.C                                           */
/* *! DESCRIPTION : Extracts and decompresses delta ring state from xip image   */
//                  based on variable name.  Returns ring state and meta data
//                  in eCMD data files.
//
/* *! EXTENDED DESCRIPTION :                                                    */
//
/* *! USAGE : To build -                                                        */
//              buildecmdprcd -C "p8_scan_compression.C" -c "sbe_xip_image.c,pore_inline_assembler.c,p8_ring_identification.c" p8_delta_scan_r.C
//
/* *! ASSUMPTIONS :                                                             */
//    - A ring may only be requested with the sysPhase=0 or 1. sysPhase=2
//      is not allowed.
//
/* *! COMMENTS :                                                                */
//
/*------------------------------------------------------------------------------*/

#include <ecmdDataBuffer.H>
#define SLW_COMMAND_LINE
#include <p8_delta_scan_rw.h>
#include <p8_ring_identification.H>

int get_delta_ring_from_image(
              char       *i_fnImage,
              char       *i_ringName,
              uint32_t   i_ddLevel,
              uint8_t    i_sysPhase,
              uint8_t    i_override,
              uint8_t    i_ringType,
              MetaData  **o_metaData,
              CompressedScanData  **o_deltaRingRS4,
              uint32_t   verbose);

SBE_XIP_ERROR_STRINGS(g_errorStrings);

#define DS_HELP_R  ("\nUSAGE:\n\tp8_delta_scan_r  -help [anything]\n\t  or\n"\
															"\tp8_delta_scan_r \n"\
															"\t\t<SBE-XIP image>\n"\
															"\t\t<Ring name>\t\tTOC key word in SBE-XIP image\n"\
															"\t\t<DD level>\t\tMust be a hex value\n"\
															"\t\t<System phase>\t\t0: IPL  1: Runtime\n"\
															"\t\t<Override>\t\t0: Init==Flush  1: Init!=Flush\n"\
															"\t\t<Ring file>\t\teCMD data file\n"\
															"\t\t<Meta data file>\n"\
															"\t\t[<verbose level>]\tOptional - default=0 max=3\n\n")

//  main() input parms:
//  arg1:  Input SBE-XIP image file [SBE-XIP binary]
//  arg2:  Ring/var name
//  arg3:  DD level - Must be a hex value
//  arg4:  System phase - 0: IPL,  1: Runtime
//  arg5:  Override - 0: Init==Flush (Alter!=_ovr)  1: Init!=Flush (Alter==_ovr)
//  arg6:  Output ring file [eCMD data buffer]
//  arg7:  Output meta data file
//  Optional:
//  arg8:  Verbose level: =0: none (default)  =1: minimal  =2: nice amount  =3: plenty
int main( int argc, char *argv[])
{
  char		 	*i_fnImage;
	char 			*i_ringName;
	uint32_t	i_ddLevel;
	uint8_t		i_sysPhase=2;	 
	uint8_t		i_override;
  char			*i_fnDeltaRing;
	char			*i_fnMetaData;
  uint32_t 	dbgl=0;

  uint32_t 	rc=0,i,j;

	// Memory buffers
  uint32_t *deltaRing=NULL;
	uint8_t *deltaRingDxed=NULL;
  CompressedScanData *deltaRingRS4=NULL;
	MetaData *metaData=NULL;

	FILE *fpMetaData, *fpDeltaX, *fpCheck;
  const char *fnDeltaX="deltaStateX.txt";

	ecmdDataBuffer ringDataBuf;
	uint32_t ringBitLen=0, ringByteLen=0, ringTrailBits=0;
	uint8_t mask, byteVal;
	uint32_t bitPos, bitVal;

	// ==========================================================================
	// Convert input parms from char to <type>
	// ==========================================================================
	printf("\n--> Processing Input Parameters...\n");

	if (argc<8 || strcmp(argv[1], "-h")==0 || strcmp(argv[1], "--h")==0)  {
		printf("%s",DS_HELP_R);
		return IMGBUILD_ERR_GENERIC;
	}
	
	if (dbgl>=2)  {
		printf("\tvar name = %s\n",argv[1]);
		printf("\tvar offset name = %s\n",argv[2]);
		printf("\tmeta data file name = %s\n",argv[3]);
		printf("\teprom file name = %s\n",argv[4]);
		printf("\tring file name = %s\n",argv[5]);
	}

  i_fnImage =				 argv[1];
	i_ringName =			 argv[2];
	i_ddLevel	=strtoul(argv[3], NULL, 16);
	i_sysPhase =	atoi(argv[4]);
	i_override =	atoi(argv[5]);
  i_fnDeltaRing	=		 argv[6];
	i_fnMetaData =	 	 argv[7];
  if (argc>=7)
	  dbgl =			atoi(argv[8]);

  // Check if input file exists.
  fpCheck = fopen(i_fnImage, "r");
  if (fpCheck) fclose(fpCheck);
  else  {
    printf("Could not open input image file.\n");
    return IMGBUILD_ERR_FILE_ACCESS;
  }

	// Convert ddLevel (temporary until full support in image).
  if (i_ddLevel>=0x100)  {
	  if (i_ddLevel<0x1000000)  {
	    printf("Input ddLevel=0x%X ",i_ddLevel);
	    i_ddLevel = (i_ddLevel&0x0ff000)>>12;
	    printf("converted to ddLevel =0x%2X (or %i decimal).\n",i_ddLevel,i_ddLevel);
	  }
		else  {
	    printf("Input ddLevel=0x%X exceeds 6 nipples and is invalid.\n",i_ddLevel);
		  return IMGBUILD_ERR_GENERIC;
		}
  }

	// Determine if ring type is a #G VPD ring.
  uint8_t iVpdType, ringType;
  uint32_t iRing;
	RingIdList *ring_id_list=NULL;
	uint32_t ring_id_list_size;
	ringType = 0;
	for (iVpdType=0; iVpdType<MAX_VPD_TYPES; iVpdType++)  {
    if (iVpdType==0)  {
		  ring_id_list = (RingIdList*)RING_ID_LIST_PG;
		  ring_id_list_size = (uint32_t)RING_ID_LIST_PG_SIZE;
		}
		else  {
		  ring_id_list = (RingIdList*)RING_ID_LIST_PR;
		  ring_id_list_size = (uint32_t)RING_ID_LIST_PR_SIZE;
		}
		for (iRing=0; iRing<ring_id_list_size; iRing++)  {
		  if (strcmp((ring_id_list+iRing)->ringNameImg,i_ringName)==0)  {
		    ringType = 1;
		    break;
		  }
	  }
	  if (ringType==1)
	    break;
	}
	
	// ==========================================================================
	// Read RS4 ScanData Delta State from Image
	// ==========================================================================
	printf("--> Reading RS4 delta ring info from SBE-XIP Image... \n");
	rc = get_delta_ring_from_image(	i_fnImage,
																	i_ringName,
																	i_ddLevel,
																	i_sysPhase,
																	i_override,
																	ringType,
																	&metaData,
																	&deltaRingRS4, // This is returned in host format. Convert before decompress.
																	dbgl);
	if (rc)  {
	  if (rc==4 || rc==11)  {
			printf("\tINFO: Getting delta ring from image was unsuccessful because\n");
			printf("\t  either the .rings section was empty or there was no ring\n");
			printf("\t  which matched the requested ring characteristics.\n");
			printf("\tRing file and meta data will not be updated.\n");
			cleanup(deltaRing, deltaRingRS4, deltaRingDxed, metaData);
			return 1;  // IMGBUILD_INFO_DSR_RING_NOT_FOUND
		}
		else  {
			printf("\tERROR: Getting delta ring from image was unsuccessful. Something went very wrong.\n");
		  cleanup(deltaRing, deltaRingRS4, deltaRingDxed, metaData);
		  return 2;  // IMGBUILD_ERR_DSR
		}
	}
	else
		if (dbgl>=1)
			printf("\tReading delta state was successful.\n");

	if (dbgl>=1)  {  // Dump the RS4 container and the meta data.
		printf("Dumping RS4 container:\n");
		printf("\tRS4 magic #     = 0x%08x\n",myRev32(deltaRingRS4->iv_magic));		
		printf("\tRS4 total size  = %i\n",myRev32(deltaRingRS4->iv_size));
		printf("\tUnXed data size = %i\n",myRev32(deltaRingRS4->iv_length));
		printf("\tScan select     = 0x%08x\n",myRev32(deltaRingRS4->iv_scanSelect));
		printf("\tHeader version  = 0x%02x\n",deltaRingRS4->iv_headerVersion);
		printf("\tFlush optimize  = 0x%02x\n",deltaRingRS4->iv_flushOptimization);
		printf("\tRing ID         = 0x%02x\n",deltaRingRS4->iv_ringId);
		printf("\tChiplet ID      = 0x%02x\n",deltaRingRS4->iv_chipletId);
		printf("Dumping meta data:\n");
		printf("\tsizeOfData = %i\n",metaData->sizeOfData);
		printf("\tData = ");
		for (i=0; i<metaData->sizeOfData; i++) // String may not be null terminated.
			printf("%c",metaData->data[i]);
		printf("\n");
	}

	// Copy meta data into file.
	fpMetaData = fopen(i_fnMetaData, "w");
	for (i=0; i<metaData->sizeOfData; i++)
		fprintf(fpMetaData,"%c",metaData->data[i]);
	fclose(fpMetaData);


	// ==========================================================================
	// Decompress RS4 delta state.
	// ==========================================================================
	printf("--> Decompressing RS4 delta ring...\n");
	// Note:  deltaRingDxed is left-aligned. If converting to uint32_t, do BE->LE flip.
	rc = rs4_decompress( 	&deltaRingDxed,
												&ringBitLen,
												deltaRingRS4);
	if (rc)  {
		printf("\trs4_decompress() failed: rc=%i   Stopping.\n",rc);
		cleanup(deltaRing, deltaRingRS4, deltaRingDxed, metaData);
		exit(1);
	}
	if (ringBitLen!=myRev32(deltaRingRS4->iv_length))  {
		printf("rs4_decompress() problem: rc=%i but ring length info differ.\n",rc);
		printf("\tReturned ring length = %i\n", ringBitLen);
		printf("\tRing length from container = %i\n", myRev32(deltaRingRS4->iv_length));
		printf("\tStopping.\n");
		cleanup(deltaRing, deltaRingRS4, deltaRingDxed, metaData);
		exit(1);
	}
	printf("\tDecompression Successful.\n");

	ringByteLen = (ringBitLen-1)/8+1;
	ringTrailBits = ringBitLen - 8*(ringByteLen-1);


	// --------------------------------------------------------------------------
	// Debug section:  Copy delta ring to file. Bits "rounded up" to nearest byte for convenience.
	// --------------------------------------------------------------------------
	if (dbgl>=2)  {
		printf("\tExtracted delta ring saved in file: %s\n", fnDeltaX);
		fpDeltaX = fopen(fnDeltaX, "w");
		j=0;
		for (i=0; i<ringByteLen; i++)  {
			fprintf(fpDeltaX,"%02x",*(deltaRingDxed+i));
			j++;
			if (j==4)  {
				fprintf(fpDeltaX,"\n");
				j=0;
			}
		}
		fclose(fpDeltaX);
	}
	
	
	// ==========================================================================
	// Saving delta ring to eCMD data buffer.
	// ==========================================================================
	printf("--> Saving ring data to eCMD file...\n");
	
	ringDataBuf.setBitLength( ringBitLen);
	ringDataBuf.memCopyIn( deltaRingDxed, ringByteLen-1); // Copy all, except last [partial] byte.
	mask = 0x80;
	byteVal = *(deltaRingDxed+ringByteLen-1);
	bitPos = 8*(ringByteLen-1);
	for (i=1; i<=ringTrailBits; i++) {
		bitVal = (byteVal & mask)>>(8-i);
		ringDataBuf.writeBit( bitPos, bitVal);
		mask = mask>>1;
		bitPos++;
	}
	ringDataBuf.writeFile( i_fnDeltaRing, ECMD_SAVE_FORMAT_ASCII);


	// ==========================================================================
	// Clean up
	// ==========================================================================
	cleanup(deltaRing, deltaRingRS4, deltaRingDxed, metaData);	
	
	
	if (rc)
		return rc;
	else
	  return 0;
}

/*                        END of main() program                              */
/* ========================================================================= */
/*                                                                           */
/* ========================================================================= */
/*                        BEGINNING of functions                             */

// get_delta_ring_from_image()
// 1 - mmap input image,
// 2 - Copy RS4 portion into o_metaData buffer.
// 3 - Copy meta data portion into o_deltaRingRS4 buffer.
int get_delta_ring_from_image(	char			*i_fnImage,
																char 			*i_ringName,
																uint32_t	i_ddLevel,
																uint8_t		i_sysPhase,
																uint8_t		i_override,
																uint8_t   i_ringType,
																MetaData						**o_metaData,
																CompressedScanData	**o_deltaRingRS4,
																uint32_t	dbgl)
{
	uint32_t rc=0, rcLoc1=0, rcLoc2=0, i;
	uint32_t fdImage;
	struct stat stbuf;
	DeltaRingLayout rs4RingLayout, rs4RingLayoutBE, *nextRingLayout;
	uint32_t sizeImageIn, sizeSection, sizeDeltaRingRs4;
	void *imageBuffer=NULL;
	SbeXipHeader hostHeader;
	SbeXipItem tocItem;
	SbeXipSection xipSection;
	void		 *hostRingBlockRs4, *hostSection;
	uint64_t addrOfFwdPtr=0;
	uint8_t bRingFound=0, bRingNotFound=0;
	
	if (dbgl>=2)
		printf("\ti_ringName=%s  i_fnImage=%s  dbgl=%i\n", i_ringName, i_fnImage, dbgl);	

	// Memory map input image.
	//
  fdImage =	open(i_fnImage, O_RDONLY);
	if (fstat(fdImage, &stbuf)!=0)  {
		printf("\tCould not fstat the input image file.\n");
		return 1;
	}
	sizeImageIn = stbuf.st_size;
	imageBuffer = mmap(0, sizeImageIn, PROT_READ, MAP_SHARED, fdImage, 0);
	if (imageBuffer==MAP_FAILED)  {
		printf("m\tmmap() of input image file failed...\n");
		return 1;
	}

	// Do image header check.
	//
	// ...verify image header version.
  sbe_xip_translate_header(&hostHeader, (SbeXipHeader*)imageBuffer);
  if (hostHeader.iv_headerVersion!=SBE_XIP_HEADER_VERSION)  {
		printf("\tProbable header version mismatch:\n");
		printf("\t\tImage's header version = %i\n",hostHeader.iv_headerVersion);
		printf("\t\tCode's header version  = %i\n",SBE_XIP_HEADER_VERSION);
		printf("\n\t\t!!!  Outdated delta_scan code  OR  outdated image.\n");
		printf("\t\t!!!  Bring either code and/or image up to date.\n");
		printf("\t\t!!!  Action (code)  ==>  Do a p8_proc_update then recompile delta_scan.\n");
		printf("\t\t!!!  Action (image) ==>  Do a p8_proc_update and then a make in ./utils/sbe, then use image(s) in ./utils/sbe/bin as the basis of your new image(s).\n\n");
		rcLoc1 = 1;
	}
	// ...verify image size
	if (sizeImageIn!=hostHeader.iv_imageSize)  {
  	printf("\tsizeImageIn(=%i) != hostHeader.iv_imageSize(=%i).\n",sizeImageIn,hostHeader.iv_imageSize);
		rcLoc2 = 1;
  }
	// ...validate image.
  rc = sbe_xip_validate(imageBuffer, sizeImageIn);
  if (rc)   {
      printf("\tsbe_xip_validate() of input image failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
			if (rcLoc1==0)  {
				printf("\t\tInput image's header version = %i\n",hostHeader.iv_headerVersion);
				printf("\t\tdelta_scan's header version  = %i\n",SBE_XIP_HEADER_VERSION);
			}
			else
				printf("\t\tFailure probably due to header mismatch.\n");
			printf("\t\tInput image's magic number   = 0x%08x%08x\n",(uint32_t)(hostHeader.iv_magic>>32),(uint32_t)(hostHeader.iv_magic));
			if (hostHeader.iv_magic==SBE_BASE_MAGIC)
				printf("\t\tImage's magic number matches PNOR.\n");
			else
			if (hostHeader.iv_magic==SBE_SEEPROM_MAGIC)
				printf("\t\tImage's magic number matches SEEPROM.\n");
			else
			if (hostHeader.iv_magic==SBE_CENTAUR_MAGIC) 
				printf("\t\tImage's magic number matches CENTAUR.\n");
			else
				printf("\t\tImage's magic number doesn't match PNOR, SEEPROM nor CENTAUR.\n");
			printf("\tExiting.\n");
      return 1;
  }
	if (rcLoc1 || rcLoc2)  {
		printf("\tImage validation successful, but header check or image size check failed.\n");
		printf("\tExiting.\n");
		return 1;
	}
	rcLoc1 = 0;
	rcLoc2 = 0;

	// Before starting the search, obtain the back pointer address, i.e. the address of the
	//   forward pointer [in the .data section] associated with the ring/var name in the TOC.
	//
	rc = sbe_xip_find( imageBuffer, i_ringName, &tocItem);
  if (rc)   {
      printf("\tWARNING: sbe_xip_find() failed w/rc=%i\n", rc);
      if (rc==SBE_XIP_ITEM_NOT_FOUND)  {
				printf("\tProbable cause:\n");
				printf("\t\tThe keyword supplied (=%s) does not have a TOC record.)\n",	i_ringName);
				return 1; // DS_KEY_WORD_NOT_FOUND
			} 
			else  {
				printf("\tUnknown cause.\n");
  	    return 4; // DS_FIND_UNKNOWN_BUG
  	  }
  }
  addrOfFwdPtr = tocItem.iv_address + 8*i_override;
	if (dbgl>=2)  {
		printf("\tAddr of forward ptr = 0x%08x%08x\n", (uint32_t)(addrOfFwdPtr>>32),
																									(uint32_t)(addrOfFwdPtr&0x00000000ffffffff));
	}

	// Further, before searching, get .rings or .dcrings stats from the TOC (i.e., section offset and size).
	//
	uint8_t  xipSectionId=0;
	if (i_ringType==0)  {
		xipSectionId = SBE_XIP_SECTION_RINGS;
	}
	else  {
		xipSectionId = SBE_XIP_SECTION_DCRINGS;
	}
  rc = sbe_xip_get_section( imageBuffer, xipSectionId, &xipSection);
  if (rc)   {
      printf("\tsbe_xip_get_section() failed w/rc=%i\n", rc);
			printf("\tProbable cause:\n");
			printf("\t\tThe section ID (=%i) was not found.\n",xipSectionId);
			return IMGBUILD_ERR_XIP_MISC;
  }
  if (xipSection.iv_offset==0 || xipSection.iv_size==0)  {
  	printf("\tINFO: Section ID =%i (SBE_XIP_SECTION_RINGS) is empty. This is not an error.\n",SBE_XIP_SECTION_RINGS);
		return 4; // DS_NO_DATA
  }
	hostSection = (void*)((uint8_t*)imageBuffer + xipSection.iv_offset);
	sizeSection = xipSection.iv_size;

	nextRingLayout = (DeltaRingLayout*)hostSection;
	bRingFound = 0;
	bRingNotFound = 0;
	
	// SEARCH loop:  Parse ring blocks successively until we find a ring that matches:
	//     backItemPtr == addrOfFwdPtr
	//     ddLevel == i_ddLevel
	//     sysPhase == i_sysPhase
	//     override == i_override
	//
	while (!bRingFound && !bRingNotFound)  {

		if (dbgl>=2)  {
			printf("\tNext backItemPtr = 0x%08x%08x\n",(uint32_t)(myRev64(nextRingLayout->backItemPtr)>>32),
																								 (uint32_t)(myRev64(nextRingLayout->backItemPtr)&0x00000000ffffffff));
			printf("\tNext ddLevel = %i\n",myRev32(nextRingLayout->ddLevel));
			printf("\tNext sysPhase = %i\n",nextRingLayout->sysPhase);
			printf("\tNext override = %i\n",nextRingLayout->override);
			printf("\tNext reserved1 = %i\n",nextRingLayout->reserved1);
			printf("\tNext reserved2 = %i\n",nextRingLayout->reserved2);
		}
		if (myRev64(nextRingLayout->backItemPtr)==addrOfFwdPtr)  {
			if (myRev32(nextRingLayout->ddLevel)==i_ddLevel)  { // Is there a non-specific DD level, like for sys phase?
				if ((nextRingLayout->sysPhase==0 && i_sysPhase==0) || 
						(nextRingLayout->sysPhase==1 && i_sysPhase==1) ||
						(nextRingLayout->sysPhase==2 && (i_sysPhase==0 || i_sysPhase==1)))  {
					if (nextRingLayout->override==i_override)  {
						bRingFound = 1;
					}
				}
			}
		}

		if (bRingFound)  {
			printf("\tRing match found!\n");
			break;
		}
		else
			nextRingLayout = (DeltaRingLayout*)((uint8_t*)nextRingLayout + myRev32(nextRingLayout->sizeOfThis));

		if (nextRingLayout>=(DeltaRingLayout*)((uint8_t*)hostSection+sizeSection))
			bRingNotFound = 1;
		
	}  // End of SEARCH.

	if (bRingNotFound)  {
		printf("\tINFO: No ring data was found for\n");
		printf("\t  Ring name = %s\n",i_ringName);
		printf("\t  DD level  = %i\n",i_ddLevel);
		printf("\t  Sys phase = %i\n",i_sysPhase);
		printf("\t  Override  = %i\n",i_override);
		return 11; // DS_NO_RING_MATCH
	}

	hostRingBlockRs4 = (uint64_t*)nextRingLayout;
		
	// Populate the local RS4 ring layout structure in host LE format where needed.
	// Note! Entire memory content is in BE format. So we do LE conversions where needed.
	//
	rs4RingLayoutBE.entryOffset	=	*(uint64_t*)hostRingBlockRs4;
	rs4RingLayout.entryOffset 	= myRev64(rs4RingLayoutBE.entryOffset);
	
	rs4RingLayoutBE.backItemPtr	=	*(uint64_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset));
	rs4RingLayout.backItemPtr 	= myRev64(rs4RingLayoutBE.backItemPtr);

	rs4RingLayoutBE.sizeOfThis 	=	*(uint32_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr));
	rs4RingLayout.sizeOfThis		= myRev32(rs4RingLayoutBE.sizeOfThis);
	
	rs4RingLayoutBE.sizeOfMeta	=	*(uint32_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis));
	rs4RingLayout.sizeOfMeta		= myRev32(rs4RingLayoutBE.sizeOfMeta);
	
	rs4RingLayoutBE.ddLevel			=	*(uint32_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta));
	rs4RingLayout.ddLevel				= myRev32(rs4RingLayoutBE.ddLevel);
	
	rs4RingLayoutBE.sysPhase		=	*(uint8_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta) +
																sizeof(rs4RingLayout.ddLevel));
	
	rs4RingLayoutBE.override		=	*(uint8_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta) +
																sizeof(rs4RingLayout.ddLevel) +
																sizeof(rs4RingLayout.sysPhase));
	
	rs4RingLayoutBE.reserved1		=	*(uint8_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta) +
																sizeof(rs4RingLayout.ddLevel) +
																sizeof(rs4RingLayout.sysPhase) +
																sizeof(rs4RingLayout.override));
	
	rs4RingLayoutBE.reserved2		=	*(uint8_t*)((uint8_t*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta) +
																sizeof(rs4RingLayout.ddLevel) +
																sizeof(rs4RingLayout.sysPhase) +
																sizeof(rs4RingLayout.override) +
																sizeof(rs4RingLayout.reserved1));
	
	rs4RingLayoutBE.metaData		=	(char*)hostRingBlockRs4 + 
																sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta) +
																sizeof(rs4RingLayout.ddLevel) +
																sizeof(rs4RingLayout.sysPhase) +
																sizeof(rs4RingLayout.override) +
																sizeof(rs4RingLayout.reserved1) +
																sizeof(rs4RingLayout.reserved2);
	
	// Need to make sure we point to the nearest [higher] word boundary.
	rs4RingLayoutBE.rs4Launch		= (uint32_t*)((((uint32_t)(uint8_t*)hostRingBlockRs4 +
																rs4RingLayout.entryOffset-1)/4+1)*4);
	
	// Need to make sure we point to the nearest [higher] double-word boundary.
	rs4RingLayoutBE.rs4Delta		= (uint32_t*)((((uint32_t)(uint8_t*)(rs4RingLayoutBE.rs4Launch) +
																ASM_RS4_LAUNCH_BUF_SIZE-1)/8+1)*8);
	
	// ...size of delta ring block.
	sizeDeltaRingRs4 = (uint8_t*)hostRingBlockRs4 + rs4RingLayout.sizeOfThis - (uint8_t*)(rs4RingLayoutBE.rs4Delta);

	if (dbgl>=1)  {
		printf("\tentryOffset = %i\n",(uint32_t)(rs4RingLayout.entryOffset));
		printf("\tbackItemPtr = 0x%08x%08x\n",(uint32_t)(rs4RingLayout.backItemPtr>>32),(uint32_t)(rs4RingLayout.backItemPtr&0x00000000ffffffff));
		printf("\tsizeOfThis = %i\n",rs4RingLayout.sizeOfThis);
		printf("\tsizeOfMeta = %i\n",rs4RingLayout.sizeOfMeta);
		printf("\tddLevel = %i\n",rs4RingLayout.ddLevel);
		printf("\tsysPhase = %i\n",rs4RingLayoutBE.sysPhase);
		printf("\toverride = %i\n",rs4RingLayoutBE.override);
		printf("\treserved1 = %i\n",rs4RingLayoutBE.reserved1);
		printf("\treserved2 = %i\n",rs4RingLayoutBE.reserved2);
		printf("\tmetaData = ");
		for (i=0; i<rs4RingLayout.sizeOfMeta; i++) // String may not be null terminated.
			printf("%c",rs4RingLayoutBE.metaData[i]);
		printf("\n");
		printf("\trs4Launch = 0x%08x\n",(uint32_t)(rs4RingLayoutBE.rs4Launch));
		printf("\trs4Delta = 0x%08x\n",(uint32_t)(rs4RingLayoutBE.rs4Delta));
		printf("\tSize of delta ring block= %i\n", sizeDeltaRingRs4);
	}
	
	// Check that the ring layout structure in the memory is double-word aligned. This must be so, because
	//    The entryOffset address must be on an 8-byte boundary because the start of the .initf ELF section must
	//    be 8-byte aligned AND because the rs4Delta member is the last member and which must itself be 8-byte aligned.
	//    These two things together means that both the beginning and end of the delta ring layout must be 8-byte
	//    aligned, and thus the whole block,i.e. sizeOfThis, must be 8-byte aligned.
	// Also check that the RS4 delta ring is double-word aligned.
	// Also check that the RS4 launcher is word aligned.
	//
	if ((uint32_t)hostRingBlockRs4%8 || 
			rs4RingLayout.sizeOfThis%8 || 
			(uint32_t)rs4RingLayoutBE.rs4Delta%8 || 
			(uint32_t)rs4RingLayoutBE.rs4Launch%4)  {
		printf("\tRing layout is not double-word-aligned or RS4 launcher is not word aligned. Stopping\n");
		exit(1);
	}

  // Allocate buffers for scan ring and meta data and make copies. (Buffers are freed in main program.)
  //
  // RS4 delta buffer.
  *o_deltaRingRS4 = (CompressedScanData*)malloc(sizeDeltaRingRs4);
  if (*o_deltaRingRS4 == NULL)  {
    printf("\tmalloc() of RS4 delta ring buffer failed...\n");
    exit(1);
  }
	// Copy content from SBE-XIP image... and retain the BE format of the rs4Delta member.
	memcpy( (uint32_t*)(*o_deltaRingRS4), rs4RingLayoutBE.rs4Delta, sizeDeltaRingRs4);
	if (*(rs4RingLayoutBE.rs4Delta)!=(*o_deltaRingRS4)->iv_magic)  {
		printf("\tmemcpy() of delta ring failed... Stopping.\n");
		free(*o_deltaRingRS4);
		exit(1);
	}
	if ((*o_deltaRingRS4)->iv_magic!=RS4_MAGIC && myRev32((*o_deltaRingRS4)->iv_magic)!=RS4_MAGIC)  {
		printf("\tThe retrived delta ring isn't valid:\n");
		printf("\t\tRetrieved magic # = 0x%08x\n",(*o_deltaRingRS4)->iv_magic);
		printf("\t\tTrue RS4_MAGIC #  = 0x%08x\n",RS4_MAGIC);
		free(*o_deltaRingRS4);
		exit(1);
	}

	// Meta data buffer.
	*o_metaData = (MetaData*)malloc(sizeof((*o_metaData)->sizeOfData)+rs4RingLayout.sizeOfMeta);
	if (*o_metaData==NULL)  {
		printf("\tmalloc() of meta data buffer failed...\n");
		free(*o_deltaRingRS4);
		exit(1);
	}
	(*o_metaData)->sizeOfData = rs4RingLayout.sizeOfMeta;
	// Copy content from SBE-XIP image.
	memcpy( (*o_metaData)->data, rs4RingLayoutBE.metaData, (*o_metaData)->sizeOfData);
	
	
	// Local clean up.
	//
	close(fdImage);
		
	return rc;
}


// cleanup()
// Free all the memory we've allocated along the way.
void cleanup(	void *buf1, 
							void *buf2, 
							void *buf3,
							void *buf4,
							void *buf5)
{
	if (buf1) free(buf1);
	if (buf2) free(buf2);
	if (buf3) free(buf3);
	if (buf4) free(buf4);
	if (buf5) free(buf5);
}
