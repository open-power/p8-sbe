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



// $Id: p8_delta_scan_w.C,v 1.26 2014/08/19 20:25:11 cmolsen Exp $
//
/*------------------------------------------------------------------------------*/
/* *! TITLE         p8_delta_scan_w.C                                                   */
/* *! DESCRIPTION : Generates and compresses delta ring state.  Then appends    */
//                  the state to the .initf section in the image.
/* *! OWNER NAME :  Michael Olsen                                               */
//
/* *! EXTENDED DESCRIPTION :                                                    */
//
/* *! USAGE : To build -                                                        */
//              buildecmdprcd -C "p8_scan_compression.C,p8_image_help.C,p8_image_help_base.C" -c "sbe_xip_image.c,pore_inline_assembler.c,p8_ring_identification.c" p8_delta_scan_w.C
//
/* *! ASSUMPTIONS :                                                             */
//    - A ring may only be stored with sysPhase=0, 1 or 2. (But requesting
//      a ring with sysPhase=2 is not allowed in the reader nor slw_build!)
/* *! COMMENTS :                                                                */
//
/*------------------------------------------------------------------------------*/

#include <list>
#include <string>
#include <ecmdDataBuffer.H>
#ifndef SLW_COMMAND_LINE
#define SLW_COMMAND_LINE
#endif
#include <errno.h>
#include <p8_delta_scan_rw.h>
#include <p8_ring_identification.H>

SBE_XIP_ERROR_STRINGS(g_errorStrings);

#define DS_HELP_W  ("\nUSAGE:\n\tp8_delta_scan_w  -help [anything]\n\t  or\n"\
															"\tp8_delta_scan_w \n"\
															"\t\t<SBE-XIP image>\n"\
															"\t\t<Init ring file>\teCMD data file\n"\
															"\t\t<Alter ring file>\teCMD data file\n"\
															"\t\t<Ring name>\t\tTOC key word in SBE-XIP image\n"\
															"\t\t<DD level>\t\tMust be a hex value\n"\
															"\t\t<System phase>\t\t0: IPL  1: Runtime  2: Non-specific\n"\
															"\t\t<Override>\t\t0: Init==Flush  1: Init!=Flush\n"\
															"\t\t<Meta data file>\n"\
															"\t\t<Chiplet ID>\t\tMust be an integer\n"\
															"\t\t<Scan select value>\t64-bit hex value\n"\
															"\t\t[<verbose level>]\tOptional - default=0 max=3\n\n")

//  Input parms:
//  arg1:  I/O SBE-XIP image file [SBE-XIP binary]
//  arg2:  Init ring file [eCMD data buffer]
//  arg3:  Alter ring file [eCMD data buffer]
//  arg4:  Ring/var name
//  arg5:  DD level - Must be a hex value either in 0x10 or 0x910500 format.
//  arg6:  System phase - 0: IPL,  1: Runtime,  2: Non-specific
//  arg7:  Override - 0: Init==Flush (Alter!=_ovr)  1: Init!=Flush (Alter==_ovr)
//  arg8:  Meta data file
//  arg9:  Chiplet ID - Must be an integer
//  arg10: Scan select - Must be a hex value
//  Optional:
//  arg11: Verbose level: =0: none (default)  =1: minimal  =2: sufficient  =3: too much
int main( int argc, char *argv[])
{
  char			*i_fnImage;
  char			*i_fnInitRing;
  char			*i_fnAlterRing;
	char 			*i_ringName;
	uint32_t	i_ddLevel;
	uint8_t		i_sysPhase=2;
	uint8_t 	i_override=0;
	uint8_t   ringType=0;
	char			*i_fnMetaData;
	uint8_t		i_chipletId=-1;
	uint64_t	i_scanSelect=0; //0x04000800*2^32;
  uint32_t 	dbgl=0;

  uint32_t rc=0, i=0;
	uint32_t rs4Size=0;

	FILE *fpCheck, *fpInit, *fpAlter, *fpDelta;
  const char *fnInit="initState.txt";
  const char *fnAlter="alterState.txt";
  const char *fnDelta="deltaState.txt";

	std::string stateString;
	ecmdDataBuffer ringDataBuf;
	uint32_t ringBitLen=0, ringWordLen=0, ringTrailBits=0;
	uint32_t *initRing=NULL, *alterRing=NULL, *deltaRing=NULL;
  CompressedScanData *deltaRingRS4=NULL;
	uint32_t *deltaRingRS4_4B;

	void      *bufTmp=NULL;
	uint32_t  sizeBufTmp;

	// ==========================================================================
	// Convert input parms from char to <type>
	// ==========================================================================
	printf("\n--> Processing Input Parameters...\n");

	if (argc<11 || strcmp(argv[1],"-h")==0 || strcmp(argv[1],"--h")==0)  {
		printf("%s",DS_HELP_W);
		return IMGBUILD_ERR_GENERIC;
	}
	
  i_fnImage =		 		 	  argv[ 1];
  i_fnInitRing =			  argv[ 2];
  i_fnAlterRing =			  argv[ 3];
	i_ringName = 				  argv[ 4];
	i_ddLevel =   strtoul(argv[ 5], NULL, 16);
	i_sysPhase =		 atoi(argv[ 6]);
	i_override = 		 atoi(argv[ 7]);
	i_fnMetaData =			  argv[ 8];
	i_chipletId =    atoi(argv[ 9]);
	i_scanSelect=strtoull(argv[10], NULL, 16);
  if (argc>=12)
  	dbgl = 			 	 atoi(argv[11]);

	// Check if input files exist.
  fpCheck = fopen(i_fnImage, "r");
	if (fpCheck) fclose(fpCheck);
	else  {
		printf("Could not open input image file.\n");
		return IMGBUILD_ERR_FILE_ACCESS;
  }
	fpCheck = fopen(i_fnInitRing, "r");
	if (fpCheck) fclose(fpCheck); 
	else  {
		printf("Could not open input InitRing file.\n");
		return IMGBUILD_ERR_FILE_ACCESS;
  }
  fpCheck = fopen(i_fnAlterRing, "r");
	if (fpCheck) fclose(fpCheck);
	else  {
		printf("Could not open input AlterRing file.\n");
		return IMGBUILD_ERR_FILE_ACCESS;
  }
  fpCheck = fopen(i_fnMetaData, "r");
	if (fpCheck) fclose(fpCheck);
	else  {
		printf("Could not open input MetaData file.\n");
		return IMGBUILD_ERR_FILE_ACCESS;
  }
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
	if (i_sysPhase>2)  {
		printf("ERROR:  System phase (=%i) out of range (=[0,1,2])\n",i_sysPhase);
		printf("%s",DS_HELP_W);
		return IMGBUILD_ERR_GENERIC;
	}
	if (i_override>1)  {
		printf("ERROR:  Override value (=%i) out of range (=[0,1])\n",i_override);
		printf("%s",DS_HELP_W);
		return IMGBUILD_ERR_GENERIC;
	}

	// Determine if ring type is a #G VPD ring and check if the supplied chiplet ID agrees
	//   with the VPD ring list range unless it's multicast 0xFF.
  uint8_t iVpdType;
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
  if (ringType==0)
    printf("Ring type: Non-VPD\n");
  else  {
    if (iVpdType==0)
      printf("Ring type: VPD #G\n");
    else  {
      printf("Ring type: VPD #R\n");
      printf("Insertion of VPD #R rings not supported!\n");
      return IMGBUILD_RINGTYPE_NOT_ALLOWED;
    }
		if (i_chipletId!=0xFF && 
		    i_chipletId<(ring_id_list+iRing)->chipIdMin &&
				i_chipletId>(ring_id_list+iRing)->chipIdMax)  {
			printf("The VPD ring's (=%s) chipletId (=0x%02X) is not equal to 0xFF nor does it fall within the range in the VPD ring list.\n",i_ringName,i_chipletId);
			return IMGBUILD_ERR_CHIPLET_ID_MESS;
		}
	}
  if (ringType==1)  {
    if (i_override==1)  {
      printf("Overrides are not allowed for MVPD rings.\n");
      return IMGBUILD_BAD_ARGS;
    }
  }

	if (dbgl>=2)
	  printf ("ChipletID=%i, Scan select=0x%08x%08x\n", i_chipletId, (uint32_t)(i_scanSelect>>32),(uint32_t)(i_scanSelect&0x00000000ffffffff));

	// ==========================================================================
	// Extract the data from the eCMD buffers.
	// ==========================================================================
	printf("--> Reading eCMD Input Scan Files...\n");
	
	// First, read init ring
	ringDataBuf.readFile( i_fnInitRing, ECMD_SAVE_FORMAT_ASCII);
	ringBitLen = ringDataBuf.getBitLength();
	ringWordLen = (ringBitLen-1)/32+1;
	ringTrailBits = ringBitLen-(ringWordLen-1)*32;
  initRing = (uint32_t*)calloc(ringWordLen, sizeof(uint32_t));
  if (!initRing)  {
    fprintf(stderr, "calloc() failed for initRing.  Stopping.");
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
		exit(1);
  }
	for (i=0; i<ringWordLen-1; i++)  {
		stateString = ringDataBuf.genHexLeftStr(32*i, 32);
		sscanf(stateString.c_str(),"%x",&initRing[i]);
	}
	if (ringTrailBits>0)  {
		stateString = ringDataBuf.genBinStr(32*(ringWordLen-1), ringTrailBits);
		initRing[ringWordLen-1] = strtol(stateString.c_str(), NULL, 2);
		initRing[ringWordLen-1] = initRing[ringWordLen-1]<<(32-ringTrailBits);
		if (dbgl>=1)  {
			printf("\tRemaining Init  bits (bin): %s\n",stateString.c_str());
			printf("\tLast Init  word (0-padded): 0x%08x\n",initRing[ringWordLen-1]);
		}
	}
	// Second, read alter ring
	ringDataBuf.readFile( i_fnAlterRing, ECMD_SAVE_FORMAT_ASCII);
	if (ringDataBuf.getBitLength()!=ringBitLen)  {
		printf("ERROR:  Length of Init and Alter rings do not match.\n");
		exit(1);
	}
  alterRing = (uint32_t*)calloc(ringWordLen, sizeof(uint32_t));
  if (!alterRing)  {
    fprintf(stderr, "calloc() failed for alterRing.  Stopping.");
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
		exit(1);
  }
	for (i=0; i<ringWordLen-1; i++)  {
		stateString = ringDataBuf.genHexLeftStr(32*i, 32);
		sscanf(stateString.c_str(),"%x",&alterRing[i]);
	}
	if (ringTrailBits>0)  {
		stateString = ringDataBuf.genBinStr(32*(ringWordLen-1), ringTrailBits);
		alterRing[ringWordLen-1] = strtol(stateString.c_str(), NULL, 2);
		alterRing[ringWordLen-1] = alterRing[ringWordLen-1]<<(32-ringTrailBits);
		if (dbgl>=1)  {
			printf("\tRemaining Alter bits (bin): %s\n",stateString.c_str());
			printf("\tLast Alter word (0-padded): 0x%08x\n",alterRing[ringWordLen-1]);
		}
	}

  if (dbgl>=2)  {
		fpInit=fopen(fnInit,"w");
		fpAlter=fopen(fnAlter,"w");
		for (i=0; i<ringWordLen; i++)  {
			fprintf(fpInit, "%08x\n", initRing[i]);
			fprintf(fpAlter, "%08x\n", alterRing[i]);
		}
		fclose(fpInit);
		fclose(fpAlter);
	}

	if (dbgl>=1)
  	printf ("\tringBitLen=%i\n \tringTrailBits=%i\n", ringBitLen, ringTrailBits);

	
	// ===========================================================================
	// Calculate Delta between Init and Flush Ring States
	// ===========================================================================
	printf("--> Calculating Delta State...\n");
	deltaRing = (uint32_t *)calloc(ringWordLen, sizeof(uint32_t));
  if (!deltaRing)  {
    printf("calloc() failed for deltaRing.  Stopping.");
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
		exit(1);
  }
  rc = gen_ring_delta_state( 	ringBitLen, 
   														initRing, 
   														alterRing, 
   														deltaRing, 
   														dbgl);
  if (rc)  {
    printf("gen_ring_delta_state() returned error code: rc=%i  Stopping.\n", rc);
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
    exit(1);
  }
	else
		printf("\tDelta Calculation Successful.\n");
  
  if (dbgl>=2)  {
	  printf("\tSize of delta ring state = %i\n", ringBitLen);
		printf("\tDelta state dumped to %s\n", fnDelta);
		fpDelta=fopen(fnDelta,"w");
		for (i=0; i<ringWordLen; i++)
			fprintf(fpDelta,"%08x\n",deltaRing[i]);
		fclose(fpDelta);
	}


	// ===========================================================================
	// RS4 Compression of Delta Scan Ring State
	// ===========================================================================
	printf("--> Doing RS4 Compression of Delta State...\n");

	if (ringType==1)  {
    printf("[i] initRing alterRing deltaRing\n");
	  for (i=0; i<ringWordLen; i++)  {
	  	printf("%3i:  %08x  ", i, initRing[i]);
	  	printf("%08x  ", alterRing[i]);
		  printf("%08x\n", deltaRing[i]);
    }
  }
	// Left-align delta ring state before compression, i.e. convert it to BE.
	for (i=0; i<ringWordLen; i++)
		deltaRing[i] = myRev32(deltaRing[i]);

	rc = rs4_compress(	&deltaRingRS4, 
											&rs4Size,
											(uint8_t*)deltaRing, 
											ringBitLen,
											i_scanSelect, 
											(uint8_t)0,
											i_chipletId,
											(1-i_override));
	if (rc)  {
		printf("rs4_compress() failed: rc = %i   Stopping.\n",rc);
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
		exit(1);
	}
	else
	if (rs4Size!=myRev32(deltaRingRS4->iv_size))  {
		printf("rs4_compress() problem: rc=%i but RS4 size info differ.  Stopping.\n",rc);
		printf("\tReturned size = %i\n", rs4Size);
		printf("\tSize from container = %i\n", myRev32(deltaRingRS4->iv_size));
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
		exit(1);
	}
	else
		printf("\tCompression Successful.\n");


	// --------------------------------------------------------------------------
	// Debug section:  Compare RS4 containers in BE and LE formats.
	// --------------------------------------------------------------------------
	if (dbgl>=2)  {  // Dump the whole RS4 buffer (incl container)
		deltaRingRS4_4B = (uint32_t*)deltaRingRS4;
		printf("\nRS4 ScanData info: (Big-endian format)\n");
		for (i=0; i<myRev32(deltaRingRS4->iv_size)/sizeof(uint32_t); i++)  {
			printf("deltaRingRS4_4B[%i]=0x%08x",i,deltaRingRS4_4B[i]);
			if (i<myRev32(deltaRingRS4->iv_size)/sizeof(uint32_t)-1)  {
				switch(i) {
				case 0:
					printf(" (RS4 magic#)\n");
					break;
				case 1:
					printf(" (Size of compressed scan chain + %i)\n",sizeof(CompressedScanData));
					break;
				case 2:
					printf(" (Algorithm)\n");
					break;
				case 3:
					printf(" (Length of uncompressed scan chain)\n");
					break;
				case 4:
					printf(" (Scan select register)\n");
					break;
				case 5:
					printf(" (ChipletID; Rsvd; Flush optimize; RS4 hdr version)\n");
					break;
				case 6:
					printf(" (Begin - compressed data)\n");
					break;
				default:
					printf("\n");
					break;
				}
			}
			else  {
				printf(" (End - compressed data, incl 0x0 padding)\n");
			}
		}
	}

	if (dbgl>=1)  {  // Dump only the RS4 container (Little-endian format)
		uint32_t *deltaRingRS4_le_4B;
		CompressedScanData deltaRingRS4_le;

		// BE->LE translation.
		compressed_scan_data_translate( &deltaRingRS4_le, 
																		deltaRingRS4);

		deltaRingRS4_le_4B = (uint32_t*)(&deltaRingRS4_le);
		printf("\nRS4 ScanData container info: (Little-endian format)\n");
		for (i=0; i<sizeof(CompressedScanData)/sizeof(uint32_t); i++)  {
			printf("deltaRingRS4_le_4B[%i]=0x%08x",i,deltaRingRS4_le_4B[i]);
			if (i<deltaRingRS4_le.iv_size/sizeof(uint32_t)-1)  {
				switch(i) {
				case 0:
					printf(" (RS4 magic#)\n");
					break;
				case 1:
					printf(" (Size of compressed scan chain + %i)\n",sizeof(CompressedScanData));
					break;
				case 2:
					printf(" (Algorithm)\n");
					break;
				case 3:
					printf(" (Length of uncompressed scan chain)\n");
					break;
				case 4:
					printf(" (Scan select register)\n");
					break;
				case 5:
					printf(" (ChipletID; Rsvd; Flush optimize; RS4 hdr version)\n");
					break;
				case 6:
					printf(" (Begin - compressed data)\n");
					break;
				default:
					printf("\n");
					break;
				}
			}
			else  {
				printf(" (End - compressed data, incl 0x0 padding)\n");
			}
		}
	}


	// ==========================================================================
	// Store RS4 ScanData Delta State as Assembled Binary in External File
	// ==========================================================================
	sizeBufTmp = FIXED_RING_BUF_SIZE;
	bufTmp = malloc(sizeBufTmp);
  if (!bufTmp)  {
	  printf("\tmalloc() for fixed ring buffer failed.\n");
	  exit(1);
	}
	printf("--> Updating SBE-XIP Image with RS4 Compressed Delta State... \n");
	rc = write_rs4_ring_to_ref_image(	i_fnImage,
																		deltaRingRS4,
																		i_ddLevel,
																		i_sysPhase,
																		i_override,
																		ringType,
																		i_ringName,
																		i_fnMetaData,
																		bufTmp,
																		sizeBufTmp,
																		dbgl);
	free(bufTmp);
	if (rc)  {
		printf("\twrite_rs4_ring_to_ref_image() failed: rc=%i   Stopping.\n",rc);
		cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
		exit(1);
	}
	else
		printf("\tImage Update Successful.\n");


	// --------------------------------------------------------------------------
	// Debug section:  Compare delta state before and after compression+decrompression.
	// --------------------------------------------------------------------------
	if (dbgl>=2)  {
		printf("--> Debug section - Comparing delta states before and after compression...\n");
		
		uint8_t *deltaRing_tmp=NULL;
		uint32_t *deltaRing_dxed;
		uint32_t count=0;
		uint32_t ringBitLenTmp=0;
		
		rc = rs4_decompress( 	&deltaRing_tmp,
													&ringBitLenTmp,
													deltaRingRS4);
		if (rc)
			printf("\trs4_decompress() failed: rc=%i  Continuing. \n",rc);
		if (ringBitLenTmp!=myRev32(deltaRingRS4->iv_length))  {
			printf("rs4_decompress() problem: rc=%i but ring length info differ.\n",rc);
			printf("\tReturned ring length = %i\n", ringBitLenTmp);
			printf("\tRing length from container = %i\n", myRev32(deltaRingRS4->iv_length));
			printf("\tStopping.\n");
			cleanup(initRing, alterRing, deltaRing, deltaRingRS4);
			exit(1);
		}

		deltaRing_dxed = (uint32_t *)deltaRing_tmp;
		count=0;
		for (i=0; i<(ringBitLenTmp-1)/32+1; i++)
			if (deltaRing[i]!=deltaRing_dxed[i])  {
				if (count<10)
					printf("\tStates differ!  deltaRing[%i]=0x%08x vs deltaRing_dxed[%i]=0x%08x\n",i,deltaRing[i],i,deltaRing_dxed[i]);
				count++;
			}
		if (count)
			printf("\tDumping of differences stopped after 10 dumps.\n");
		if (!count && !rc)
			printf("\tDelta states agree.\n");
		if (deltaRing_tmp)  free(deltaRing_tmp);
	}	


	// ==========================================================================
	// Clean up
	// ==========================================================================
	cleanup(initRing, alterRing, deltaRing, deltaRingRS4);

	return rc;
}

/*                        END of main() program                              */
/* ========================================================================= */
/*                                                                           */
/* ========================================================================= */
/*                        BEGINNING of functions                             */

// gen_ring_delta_state() parms:
// bitLen - length of ring
// i_init - scan flush state
// i_alter - scan init state
// o_delta - scan delta state
// dbgl - debug level (0->3)
int gen_ring_delta_state(	uint32_t bitLen, 
													uint32_t *i_init, 
													uint32_t *i_alter, 
													uint32_t *o_delta, 
													uint32_t dbgl)
{
  uint32_t rc=0, i=0;
  uint32_t count=0;
  uint32_t bit=0, remainder=0, remainingBits=0;
  uint32_t flush=0;
  uint32_t init=0;
  uint32_t mask=0;
  uint32_t xorVal=0;

  // Do some checkin of input parms
  if ((bitLen==0) || (i_alter==NULL) || (i_init==NULL))  {
  	printf("Bad input arguments.\n");
    rc=IMGBUILD_BAD_ARGS;
    return rc;
  }

  // Compare and scan the ring if there is a difference
  // ------------------------------------------------------

  // Check how many 32-bit shift ops are needed and if we need final shift of remaining bit.
  count = bitLen/32;
  remainder = bitLen%32;
	if (remainder >0)
	    count = count + 1;
	
	// From P7+: skip first 32 bits associated with FSI engine
	//TODO: check with perv design team if FSI 32 bit assumption is still valid in p8
	//remainingBits=bitLen-32;
	// CMO: I changed this as follows:
	remainingBits = bitLen;
	
	if (dbgl>=2)
		printf("count=%i  rem=%i  remBits=%i\n",count,remainder,remainingBits);

	// Compare 32 bit data at a time then shift ring (p7+ reqmt)
	// TODO: check if p8 still requires skipping the 1st 32 bit 
	//printf (">>>   DEBUG<<< count = %d \n", count);

  // Read and compare init and flush values 32 bits at a time.  Store delta in o_delta buffer.
	for (i=0; i<count; i++)  {

		if (remainingBits<=0)  {
			printf("remaingBits<=0. Not good.  Stopping.\n");
			return IMGBUILD_ERR_GENERIC;
		}

    flush=i_init[i];
    init=i_alter[i];

    if (dbgl>=3)
    	printf("i=%d, flush_i=0x%08x, init_i=0x%08x\n",i,flush,init);

    if (remainingBits>=32)
      remainingBits=remainingBits-32;
	  else  {  //If remaining bits are less than 32 bits, mask unused bits
	    mask=0;
	    for (bit=0; bit<(32-remainingBits); bit++)  {
	      mask=mask << 1;
	      mask=mask+1;
	    }
	    if (dbgl>=1)
		    printf("Remaining bits < 32. Padding with zeros. True bit length unaltered. (remainingBits=%i word count=%i)\n",remainingBits,count);
	    mask=~mask;
	    flush=flush & mask;
	    init=init & mask;
	    remainingBits=0;
	  }

		xorVal=flush ^ init;
		
		o_delta[i] = xorVal;

	}

  return rc;
}



// write_rs4_ring_to_ref_image()
// 1 - mmap input image,
// 2 - Compose delta binary buffer containing RS4 launcher + RS4 delta data,
// 3 - Append delta buffer to .rings section.
// 4 - Save new image to output image file.
// NB!  - Rings are added in the random order they come in. The only thing that 
//      uniquely identifies the rings is their backward pointer which will point
//      to the base address of the TOC item for a base ring or it will point to
//      the override address of the TOC item for an override ring (i.e., which is
//      +8 bytes from the base address of the TOC item.)
//      - Wrt to the forward pointers at the TOC items base and override addresses,
//      there's is some minor confusion in case of adding an override ring cause what
//      will happen is that the variable name's TOC item will contain a pointer to
//      the override ring rather than to the base ring while the TOC item + 8 byte
//      will remain pointing to zero.
//      - The TOC base and override items won't really be used until after you run
//      slw_build, ipl_build or centaur_build on the ref image.
int write_rs4_ring_to_ref_image(char			*i_fnImage,
																CompressedScanData *i_RS4,
																uint32_t	i_ddLevel,
																uint8_t		i_sysPhase,
																uint8_t 	i_override,
																uint8_t   i_ringType,
																char 			*i_ringName,
																char			*i_fnMetaData,
																void      *i_bufTmp,
																uint32_t  i_sizeBufTmp,
																uint32_t	dbgl)
{
	uint32_t rc=0, rcLoc1=0, rcLoc2=0, bufLC;
  int      rc_int=0;
	int      deltaLC=0, i;
	int      fdImage, fdMetaData;
	struct stat stbuf;
	void     *imageIn=NULL, *imageOut=NULL;
	uint32_t sizeImageIn, sizeImageOut, sizeImageOutMax, newDataBlockSize;
	uint32_t sizeRS4Launch, sizeRS4Delta;
	uint32_t asmBuffer[ASM_RS4_LAUNCH_BUF_SIZE/4];
	uint64_t scanChipletAddress=0;
	PoreInlineContext ctx;
	uint32_t sizeMetaData;
	uint32_t asmInitLC=0;
	void *ringsBuffer=NULL, *metaDataBuffer=NULL;
	DeltaRingLayout rs4RingLayout, rs4RingLayoutBE;
	SbeXipHeader hostHeader;
	uint32_t initfRS4SectionOffset=0;
	uint64_t addrOfFwdPtr=0; // initfRS4PoreAddress=0
	SbeXipItem tocItem;
	
	printf("\ti_ringName=%s  i_ddLevel=%i  i_sysPhase=%i  i_override=%i  i_ringtype=%i  i_fnMetaData=%s ",
		i_ringName, i_ddLevel, i_sysPhase, i_override, i_ringType, i_fnMetaData);
	printf("i_fnImage=%s  dbgl=%i\n", i_fnImage, dbgl);	

	// Lock and determine size of input image and memory map it.
	//
  fdImage = open(i_fnImage, O_RDWR);
  errno = 0;
  rc_int = lockf( fdImage, F_TLOCK, 0); // Test and lock the entire image.
  if (rc_int)  {
    printf("lockf(fdImage,F_TLOCK,0) failed locking the image file w/rc_int=%i and w/errno=%i\n",rc_int,errno);
    if (errno==EBADF)  {
      printf("errno=EBADF\n");
    }
    else if (errno==EACCES)  {
      printf("errno=EACCES\n");
    }
    else if (errno==EAGAIN)  {
      printf("errno=EAGAIN\n");
    }
    else if (errno==EDEADLK)  {
      printf("errno=EDEADLK\n");
    }
    else if (errno==EINTR)  {
      printf("errno=EINTR\n");
    }
    else if (errno==EINVAL)  {
      printf("errno=EINVAL\n");
    }
    else if (errno==EOVERFLOW)  {
      printf("errno=EOVERFLOW\n");
    }
    else if (errno==ENOLCK)  {
      printf("errno=ENOLCK\n");
    }
    else if (errno==EOPNOTSUPP)  {
      printf("errno=EOPNOTSUPP\n");
    }
    else  {
      printf("errno NO MATCH\n");
    }
    return IMGBUILD_ERR_FILE_ACCESS;
  }
	if (fstat(fdImage, &stbuf)!=0)  {
		printf("\tCould not fstat the input image file.\n");
		return IMGBUILD_ERR_GENERIC;
	}
	sizeImageIn = (uint32_t)stbuf.st_size;
	imageIn = mmap(0, (size_t)sizeImageIn, PROT_READ, MAP_SHARED, fdImage, 0);
	if (imageIn==MAP_FAILED)  {
		printf("m\tmmap() of input image file failed...\n");
		return IMGBUILD_ERR_GENERIC;
	}

	// Do image header check.
	//
	// ...verify image header version.
  sbe_xip_translate_header(&hostHeader, (SbeXipHeader*)imageIn);
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
  rc = sbe_xip_validate(imageIn, sizeImageIn);
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
      return IMGBUILD_ERR_GENERIC;
  }
	if (rcLoc1 || rcLoc2)  {
		printf("\tImage validation successful, but header check or image size check failed.\n");
		printf("\tExiting.\n");
		return IMGBUILD_ERR_GENERIC;
	}

  // Allocate temporary memory to append ring layout content to .rings/.dcrings section.
  //
  sizeImageOutMax = MAX_REF_IMAGE_SIZE;
  imageOut = malloc((size_t)sizeImageOutMax);
  if (imageOut == NULL)  {
    printf("\tmalloc() of output image buffer failed...\n");
    return IMGBUILD_ERR_GENERIC;
  }
	// ...copy input SBE-XIP image to temp mem.
	memcpy( imageOut, imageIn, (size_t)sizeImageIn);
	// ...test if a successful copy.
  rc = sbe_xip_validate(imageOut, sizeImageIn);
  if (rc)   {
      printf("\tsbe_xip_validate() of input image copy failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
      return IMGBUILD_ERR_GENERIC;
  }

  
  // Read the meta data file into a string.
	//
  fdMetaData = open(i_fnMetaData, O_RDWR);
	if (fstat(fdMetaData, &stbuf)!=0)  {
		printf("\tCould not fstat the meta data file.\n");
		if (i_ringType==0)
			return IMGBUILD_ERR_GENERIC;
		else
		  printf("\tSince this is a VPD ring, probably OK. Continuing...\n");
	}
	if (i_ringType==0)  {
		sizeMetaData = stbuf.st_size;
		if (sizeMetaData)  {
			metaDataBuffer = mmap(0, sizeMetaData, PROT_READ, MAP_SHARED, fdMetaData, 0);
			if (metaDataBuffer==MAP_FAILED)  {
				printf("m\tmmap() of meta data file failed.\n");
				return IMGBUILD_ERR_GENERIC;
			}
		}
		else
			metaDataBuffer = NULL;
	}
	else  {
		printf("\tMeta data for VPD rings not supported. Meta data stripped off.\n");
		sizeMetaData = 0;
		metaDataBuffer = NULL;
	}
		
	
	// --------------------------------------------------------------------------
	// Add rings to reference image according to ring type:
	// ringType = 0:  Non-VPD ring. May have meta data attached to it. Inserted
  //                into .rings section. .dcrings section must be removed first
  //                and reinserted afterwards.
	// ringType = 1:  VPD ring. Meta data is not applicable. iv_chipletId is used.
  //                Inserted into .dcrings section (i.e., the last section of
  //                the image).
	// --------------------------------------------------------------------------

  if (i_ringType==0)  {

		// Create RS4 launcher and store in asmBuffer.
		// Note! We need not worry about endianness upon producing the PORE binary code since
		//       the assembler always produces code in BE format. What about disassembly?
		//
		// First, let's make sure we can get hold of the scan_chiplet_address needed for the launcher.
		//
    if (hostHeader.iv_magic!=SBE_CENTAUR_MAGIC)  {
  		rc = sbe_xip_get_scalar( imageOut, "proc_sbe_decompress_scan_chiplet_address", &scanChipletAddress);
  	  if (rc)   {
        printf("\tWARNING: sbe_xip_get_scalar() failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
        if (rc==SBE_XIP_ITEM_NOT_FOUND)  {
  				printf("\tProbable cause:\n");
  				printf("\t\tThe key word (=proc_sbe_decompress_scan_chiplet_address) does not exist in the image. (No TOC record.)\n");
  				return IMGBUILD_ERR_GENERIC; // DS_KEY_WORD_NOT_FOUND
  			} 
  			else
        if (rc==SBE_XIP_BUG)  {
  				printf("\tProbable cause:\n");
  				printf("\t\tIllegal keyword, maybe?\n");
  				return 2; // DS_KEY_WORD_ILLEGAL
  			} 
  			else  {
  				printf("\tUnknown cause.\n");
    	    return 3; // DS_GET_SCALAR_UNKNOWN_BUG
    	  }
  	  }
  	  if (scanChipletAddress==0)  {
  	  	printf("\tValue of key word (proc_sbe_decompress_scan_chiplet_address=0) is not permitted. Exiting.\n");
  	  	return IMGBUILD_ERR_GENERIC;
  	  }
    }  // End of   if (hostHeader.iv_magic==SBE_CENTAUR_MAGIC)

    // Now, create the inline assembler code.
		rc = pore_inline_context_create( &ctx, asmBuffer, ASM_RS4_LAUNCH_BUF_SIZE*4, asmInitLC, 0);
		if (rc)  {
			printf("\tpore_inline_context_create() failed w/rc=%i =%s\n", rc, pore_inline_error_strings[rc]);
			return 5; // DS_PORE_CTX_BUG
		}
		pore_MR(&ctx, A0, PC);
		pore_ADDS(&ctx, A0, A0, ASM_RS4_LAUNCH_BUF_SIZE);
    if (hostHeader.iv_magic==SBE_CENTAUR_MAGIC)  {
		  pore_LI(&ctx, D0, 0x0);
    }
    else  {
		  pore_LI(&ctx, D0, scanChipletAddress);
    }
		pore_BRAD(&ctx, D0);
		if (ctx.error)  {
			printf("\tpore_MR/ADDS/LI/BRAD() failed w/rc=%i =%s\n", rc, pore_inline_error_strings[rc]);
			return 6; // DS_PORE_ASM_BUG
		}
	
		// Check sizeRS4Launch and that sizeRS4Launch and sizeRS4Delta both are 8-byte aligned.
		sizeRS4Launch = ctx.lc - asmInitLC;
		sizeRS4Delta = myRev32(i_RS4->iv_size);
		if (sizeRS4Launch!=ASM_RS4_LAUNCH_BUF_SIZE)  {
			printf("\tSize of RS4 launch code differs from assumed size.\n\tsizeRS4Launch=%i\n\tASM_RS4_LAUNCH_BUF_SIZE=%i\n",
			  sizeRS4Launch,ASM_RS4_LAUNCH_BUF_SIZE);
				return IMGBUILD_ERR_CHECK_CODE;
		}
		if (sizeRS4Launch%8 || sizeRS4Delta%8)  {
			printf("\tRS4 launch code or data not 8-byte aligned.\n\tsizeRS4Launch=%i\n\tASM_RS4_LAUNCH_BUF_SIZE=%i\n\tsizeRS4Delta=%i\n",
			  sizeRS4Launch,ASM_RS4_LAUNCH_BUF_SIZE,sizeRS4Delta);
				return IMGBUILD_ERR_CHECK_CODE;
		}
	
		// Obtain the back pointer to the .data item, i.e. the location of the ptr associated 
    //   with the ring/var name in the TOC.
		//
		rc = sbe_xip_find( imageOut, i_ringName, &tocItem);
	  if (rc)  {
	    printf("\tsbe_xip_find() failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    if (rc==SBE_XIP_ITEM_NOT_FOUND)  {
				printf("\tProbable cause:\n");
				printf("\t\tThe variable name supplied (=%s) is not a valid key word in the image. (No TOC record.)\n",	i_ringName);
				return IMGBUILD_ERR_GENERIC; // DS_KEY_WORD_NOT_FOUND
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
		
		// Populate the local ring layout structure
		//
		rs4RingLayout.entryOffset = (uint64_t)(
		                            sizeof(rs4RingLayout.entryOffset) +
																sizeof(rs4RingLayout.backItemPtr) +
																sizeof(rs4RingLayout.sizeOfThis) +
																sizeof(rs4RingLayout.sizeOfMeta) +
																sizeof(rs4RingLayout.ddLevel) +
																sizeof(rs4RingLayout.sysPhase) +
																sizeof(rs4RingLayout.override) +
																sizeof(rs4RingLayout.reserved1) +
																sizeof(rs4RingLayout.reserved2) +
																myByteAlign(8, sizeMetaData) ); // 8-byte align RS4 launch.
		rs4RingLayout.backItemPtr	= addrOfFwdPtr;
		rs4RingLayout.sizeOfThis 	=	rs4RingLayout.entryOffset +     // Must be 8-byte aligned.
		                            sizeRS4Launch +                 // Must be 8-byte aligned.
																sizeRS4Delta;                   // Must be 8-byte aligned.
		rs4RingLayout.sizeOfMeta	=	sizeMetaData; // This can be any byte size.
		rs4RingLayout.ddLevel			= i_ddLevel;
		rs4RingLayout.sysPhase		= i_sysPhase;
		rs4RingLayout.override		= i_override;
		rs4RingLayout.reserved1		= 0;
		rs4RingLayout.reserved2		= 0;
		rs4RingLayout.metaData		= (char*)metaDataBuffer;
		rs4RingLayout.rs4Launch		= &asmBuffer[0];
		rs4RingLayout.rs4Delta		= (uint32_t*)i_RS4;
		
		if (rs4RingLayout.entryOffset%8)  {
			printf("\tRS4 launch code entry not 8-byte aligned.\n\trs4RingLayout.entryOffset=%i",
			  (uint32_t)rs4RingLayout.entryOffset);
			return IMGBUILD_ERR_CHECK_CODE;
		}
		if (rs4RingLayout.sizeOfThis%8)  {
			printf("\tRS4 ring layout not 8-byte aligned.\n\trs4RingLayout.sizeOfThis=%i\n",
			  rs4RingLayout.sizeOfThis);
			return IMGBUILD_ERR_CHECK_CODE;
		}
				
		// Calc the size of the data section we're adding and the resulting output image's
		// max size (needed for sbe_xip_append() )..
		//
		newDataBlockSize = rs4RingLayout.sizeOfThis;
	
		if (dbgl>=1)  {
			printf("\tInput image size (.dcrings possibly removed)\t= %6i\n\tNew initf data block size\t= %6i\n\tOutput image size (est max)\t\t= %6i\n",
				sizeImageIn, 
				newDataBlockSize, 
				sizeImageIn + newDataBlockSize + SBE_XIP_MAX_SECTION_ALIGNMENT);
			printf("\tentryOffset = %i\n\tsizeOfThis = %i\n\tMeta data size = %i\n",
				(uint32_t)rs4RingLayout.entryOffset, rs4RingLayout.sizeOfThis, rs4RingLayout.sizeOfMeta);
			printf("\tRS4 launch size = %i\n\tRS4 delta size = %i\n",
				sizeRS4Launch, sizeRS4Delta);
			printf("\tBack item ptr = 0x%08x%08x\n",
				(uint32_t)(rs4RingLayout.backItemPtr>>32), (uint32_t)(rs4RingLayout.backItemPtr&0x00000000ffffffff));
			printf("\tDD level = %i\n\tSys phase = %i\n\tOverride = %i\n",
				rs4RingLayout.ddLevel, rs4RingLayout.sysPhase, rs4RingLayout.override);
		}
	
		// Combine rs4RingLayout members into a unified buffer (ringsBuffer).
		//
		ringsBuffer = malloc((size_t)newDataBlockSize);
	  if (ringsBuffer == NULL)  {
	    printf("\tmalloc() of initf buffer failed...\n");
	    return IMGBUILD_ERR_GENERIC;
	  }
	  // ... and copy the rs4 ring layout data into ringsBuffer in BIG-ENDIAN format.
	  bufLC = 0;
	  rs4RingLayoutBE.entryOffset = myRev64(rs4RingLayout.entryOffset);
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayoutBE.entryOffset, sizeof(rs4RingLayoutBE.entryOffset));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.entryOffset);
		rs4RingLayoutBE.backItemPtr = myRev64(rs4RingLayout.backItemPtr);
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayoutBE.backItemPtr,  sizeof(rs4RingLayoutBE.backItemPtr));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.backItemPtr);
		rs4RingLayoutBE.sizeOfThis = myRev32(rs4RingLayout.sizeOfThis);
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayoutBE.sizeOfThis,  sizeof(rs4RingLayoutBE.sizeOfThis));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.sizeOfThis);
		rs4RingLayoutBE.sizeOfMeta = myRev32(rs4RingLayout.sizeOfMeta);
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayoutBE.sizeOfMeta,  sizeof(rs4RingLayoutBE.sizeOfMeta));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.sizeOfMeta);
		rs4RingLayoutBE.ddLevel = myRev32(rs4RingLayout.ddLevel);
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayoutBE.ddLevel,  sizeof(rs4RingLayoutBE.ddLevel));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.ddLevel);
		rs4RingLayoutBE.sysPhase = rs4RingLayout.sysPhase;
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayout.sysPhase,  sizeof(rs4RingLayoutBE.sysPhase));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.sysPhase);
		rs4RingLayoutBE.override = rs4RingLayout.override;
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayout.override,  sizeof(rs4RingLayoutBE.override));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.override);
		rs4RingLayoutBE.reserved1 = rs4RingLayout.reserved1;
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayout.reserved1,  sizeof(rs4RingLayoutBE.reserved1));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.reserved1);
		rs4RingLayoutBE.reserved2 = rs4RingLayout.reserved2;
		memcpy( (uint8_t*)ringsBuffer+bufLC, &rs4RingLayout.reserved2,  sizeof(rs4RingLayoutBE.reserved2));
		
		bufLC = bufLC + sizeof(rs4RingLayoutBE.reserved2);
		// BE conversion not needed for char-type metaData.
		if (sizeMetaData)
			memcpy( (uint8_t*)ringsBuffer+bufLC, rs4RingLayout.metaData, sizeMetaData);
		// (if needed) Pad with 0s up to 8-byte alignment.
		deltaLC = rs4RingLayout.entryOffset-sizeMetaData-bufLC;
		if (deltaLC<0 || deltaLC>=8)  {
		  printf("\tBad RS4 ring layout code.\n\tdeltaLC=%i\n",deltaLC);
			return IMGBUILD_ERR_CHECK_CODE;
		}
		if (deltaLC>0)  {
		  for (i=0; i<deltaLC; i++)
			  *(uint8_t*)((uint8_t*)ringsBuffer+bufLC+sizeMetaData+i) = 0;
		}
	
		bufLC = (uint32_t)rs4RingLayout.entryOffset; // This is [already] 8-byte aligned.
		// RS4 launch buffer alread BE formatted.
		memcpy( (uint8_t*)ringsBuffer+bufLC, asmBuffer, (size_t)sizeRS4Launch);
	
		bufLC = bufLC + sizeRS4Launch;               // This is [already] 8-byte aligned.
		if (bufLC%8)  {
			printf("\tRS4 ring layout (during buffer copy) is not 8-byte aligned.\n\tbufLC=%i\n",
			  bufLC);
			return IMGBUILD_ERR_CHECK_CODE;
		}
	
		// RS4 delta ring already BE formatted.
		memcpy( (uint8_t*)ringsBuffer+bufLC, i_RS4, (size_t)sizeRS4Delta);
	
	  // Safe to close meta file now.
		close(fdMetaData);

    // Copy .dcrings section first, then remove it. Reappend after .rings has been
    //   updated.
    //
    SbeXipSection xipSectionDcrings;
    void          *hostSectionDcrings=NULL, *bufDcrings=NULL;
    
    rc = sbe_xip_get_section( imageOut, SBE_XIP_SECTION_DCRINGS, &xipSectionDcrings);
    if (rc)  {
      printf("_get_section(.dcrings...) failed with rc=%i\n",rc);
      return IMGBUILD_ERR_GET_SECTION;
    }

    if (!(xipSectionDcrings.iv_size==0 && xipSectionDcrings.iv_offset==0))  {
      hostSectionDcrings = (void*)((uint64_t)imageOut + (uint64_t)xipSectionDcrings.iv_offset);
      bufDcrings = malloc((size_t)xipSectionDcrings.iv_size);
      if (!bufDcrings)  {
        printf("malloc() of xipSectionDcrings.iv_size failed.\n");
        return IMGBUILD_ERR_MEMORY;
      }
      memcpy( bufDcrings, hostSectionDcrings, (size_t)xipSectionDcrings.iv_size);
      rc = sbe_xip_delete_section(imageOut, SBE_XIP_SECTION_DCRINGS);
      if (rc)  {
        printf("\t_delete_section(.dcrings...) failed w/rc=%i\n",rc);
        return IMGBUILD_ERR_SECTION_DELETE;
      }
    }
	
		// Append rs4DeltaLayout to .rings section of in-memory input image.
		//   Note! All rs4DeltaLayout members should already be 8-byte aligned.
		//
		initfRS4SectionOffset = 0;
		rc = sbe_xip_append( 	imageOut, 
													SBE_XIP_SECTION_RINGS, 
													(void*)ringsBuffer,
													newDataBlockSize,
													sizeImageOutMax,
													&initfRS4SectionOffset);
	  printf("\tinitfRS4SectionOffset=0x%08x\n",initfRS4SectionOffset);
	  if (rc)   {
	    printf("\t_append(.rings...) failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    return IMGBUILD_ERR_APPEND;
	  }
    // Re-append .dcrings section.
    //
    if (!(xipSectionDcrings.iv_size==0 && xipSectionDcrings.iv_offset==0))  {
      rc = sbe_xip_append(  imageOut,
                            SBE_XIP_SECTION_DCRINGS,
                            bufDcrings,
                            xipSectionDcrings.iv_size,
                            sizeImageOutMax,
                            NULL);
      free(bufDcrings);
      if (rc)  {
	      printf("\t_append(.dcrings...) failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
        return IMGBUILD_ERR_APPEND;
      }
    }

		// Get new image size and test if successful update.
		sbe_xip_image_size(imageOut, &sizeImageOut);
	  rc = sbe_xip_validate(imageOut, sizeImageOut);
	  if (rc)   {
	    printf("\tsbe_xip_validate() of output image copy failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    return IMGBUILD_ERR_XIP_MISC;
	  }
	  printf("\tSuccessful append of RS4 ring to .rings.\n");
/*
		// ...convert rings section offset to a PORE address
		rc = sbe_xip_section2pore( imageOut, SBE_XIP_SECTION_RINGS, initfRS4SectionOffset, &initfRS4PoreAddress);
	  printf("\tinitfRS4PoreAddress=0x%08x\n",(uint32_t)initfRS4PoreAddress);
	  if (rc)   {
	    printf("\tsbe_xip_section2pore() failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    return IMGBUILD_ERR_GENERIC;
	  }
		// ...and lastly, associate PORE addr with the variable name, i_ringName.
		rc = sbe_xip_set_scalar( imageOut, i_ringName, initfRS4PoreAddress); 
	  if (rc)   {
	    printf("\tsbe_xip_set_scalar() failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    if (rc==SBE_XIP_BUG)  {
				printf("\tProbable cause:\n");
				printf("\t\tThe variable name supplied (=%s) is a valid key word but it cannot be updated with a scalar value.\n",
					i_ringName);
					return IMGBUILD_ERR_GENERIC;
			}
	    if (rc==SBE_XIP_ITEM_NOT_FOUND)  {
				printf("\tProbable cause:\n");
				printf("\t\tThe variable name supplied (=%s) is not a valid key word in the image. (No TOC record.)\n", i_ringName);
					return IMGBUILD_ERR_GENERIC;
			}
	    return IMGBUILD_ERR_GENERIC;
	  }
// ...test if successful update.
	  rc = sbe_xip_validate(imageOut, sizeImageOut);
	  if (rc)   {
	    printf("\tsbe_xip_validate() of output image copy failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    if (rc==SBE_XIP_IMAGE_ERROR)  {
				printf("\tProbable cause:\n");
				printf("\t\tThe variable name supplied (=%s) is a valid key word but it is illegal to update its value in this context.\n",
					i_ringName);
					return IMGBUILD_ERR_GENERIC;
			}
	    return IMGBUILD_ERR_GENERIC;
	  }
*/

  }
  else  if (i_ringType==1)  {

    sizeImageOut = sizeImageOutMax;
    rc = write_vpd_ring_to_ipl_image(
										         imageOut,
														 sizeImageOut,
														 i_RS4,
														 i_ddLevel,
														 i_sysPhase,
														 i_ringName,
														 i_bufTmp,
														 i_sizeBufTmp,
                             SBE_XIP_SECTION_DCRINGS);
		if (rc)  {
			printf("\tUnsuccesful update of image with VPD ring.\n");
			printf("\twrite_vpd_ring_to_ipl_image() failed w/rc=%i\n",rc);
		  free(ringsBuffer);
			free(imageOut);
			return IMGBUILD_ERR_GENERIC;
		}
		// Get new image size and test if successful update.
		sbe_xip_image_size(imageOut, &sizeImageOut);
	  rc = sbe_xip_validate(imageOut, sizeImageOut);
	  if (rc)   {
	    printf("\tsbe_xip_validate() of output image copy failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
	    return IMGBUILD_ERR_GENERIC;
	  }
	  printf("\tSuccessful append of #G RS4 ring to .dcrings.\n");
	}
	else  {
		printf("\tUnsupported ringType (=%i).\n",i_ringType);
		printf("\tCheck code. We shouldn't be here since ringType was checked in main().\n");
		free(ringsBuffer);
		free(imageOut);
		return IMGBUILD_ERR_CHECK_CODE;
	}

	printf("\tSuccessful [in-memory] image update.\n");
	
	// Save the updated image to the supplied output file.
//  fpImageOut = fopen(i_fnImage,"w");

//  imageByteOut = (uint8_t*)imageOut;
//  for (iImg=0; iImg<sizeImageOut; iImg++)  {
////  	fprintf(fpImageOut, "%c", *imageByteOut++);
//write(fdImage, imageByteOut, 1);
//  }

write(fdImage, (uint8_t*)imageOut, sizeImageOut);
//  fclose(fpImageOut);
  
  // Unlock and close the input image.
  errno = 0;
  rc_int = lockf( fdImage, F_ULOCK, 0); // Unlock the entire image.
  if (rc_int)  {
    printf("lockf(fdImage,F_ULOCK,0) failed unlocking the image file w/rc_int=%i and errno=%i\n",rc_int,errno);
    if (errno==EBADF)  {
      printf("errno=EBADF\n");
    }
    else if (errno==EACCES)  {
      printf("errno=EACCES\n");
    }
    else if (errno==EAGAIN)  {
      printf("errno=EAGAIN\n");
    }
    else if (errno==EDEADLK)  {
      printf("errno=EDEADLK\n");
    }
    else if (errno==EINTR)  {
      printf("errno=EINTR\n");
    }
    else if (errno==EINVAL)  {
      printf("errno=EINVAL\n");
    }
    else if (errno==EOVERFLOW)  {
      printf("errno=EOVERFLOW\n");
    }
    else if (errno==ENOLCK)  {
      printf("errno=ENOLCK\n");
    }
    else if (errno==EOPNOTSUPP)  {
      printf("errno=EOPNOTSUPP\n");
    }
    else  {
      printf("errno NO MATCH\n");
    }
    return IMGBUILD_ERR_FILE_ACCESS;
  }
	close(fdImage);
	
	free(ringsBuffer);
	free(imageOut);
		
	return rc;
}


