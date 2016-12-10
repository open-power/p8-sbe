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



// $Id: p8_centaur_build.C,v 1.6 2014/10/10 22:38:48 cmolsen Exp $
/*------------------------------------------------------------------------------*/
/* *! TITLE : p8_centaur_build.C                                                */
/* *! DESCRIPTION : Copies and decompresses RS4 rings from unsigned ref image   */
//                  and creates wiggle-flip programs in PNOR.
//
/* *! EXTENDED DESCRIPTION :                                                    */
//
/* *! USAGE : To build -                                                        */
//              buildecmdprcd -C "p8_image_help.C,p8_image_help_base.C,p8_scan_compression.C" -c "sbe_xip_image.c,pore_inline_assembler.c" p8_centaur_build.C
//
/* *! ASSUMPTIONS :                                                             */
//    - For p8_centaur_build, sysPhase=2 is assumed.                       
//
/* *! COMMENTS :                                                                */
//    - No sections are removed from the image.                           
//    - Full TOC info.
//
/*------------------------------------------------------------------------------*/

#define SLW_COMMAND_LINE
#include <p8_delta_scan_rw.h>
#include <p8_pore_table_gen_api.H>

#define THIS_HELP  ("\nUSAGE:\n\tp8_centaur_build  -help [anything]\n\t  or\n"\
															"\tp8_centaur_build \n"\
															"\t\t<Input unsigned reference image file>\n"\
															"\t\t<DD level [hex value]>\n"\
															"\t\t<Output Centaur image file>\n")

//  main() input parms:
//  arg1:   Input unsigned reference image file name
//  arg2:   DD level [hex value]
//  arg3:   Output Centaur image file name
int main( int argc, char *argv[])
{
	int				rc=0;
  uint32_t	i;
  char			*i_fnImageIn, *i_fnImageOut;
  uint32_t	i_ddLevel=0;
  uint32_t	fdImageIn=0;
	FILE			*fpImageOut;
	struct stat stbuf;
	uint32_t 	sizeImageIn=0, sizeImageOut=0;
	void *imageIn, *imageOut=NULL;

	SBE_XIP_ERROR_STRINGS(g_errorStrings);

	// ==========================================================================
	// Convert input parms from char to <type>
	// ==========================================================================
	MY_INF("\n--> Processing Input Parameters...\n");

	if (argc<4 || strcmp(argv[1], "-h")==0 || strcmp(argv[1], "--h")==0)  {
		MY_ERR("%s",THIS_HELP);
		return 1;
	}
	
 	// Convert input parms from char to <type>
 	//
	i_fnImageIn		=				 argv[1];
	i_ddLevel			=	strtol(argv[2], NULL, 16);
	i_fnImageOut	= 			 argv[3];

	MY_INF("\tInput Ref image fn      = %s\n",i_fnImageIn);
	MY_INF("\tDD level                = 0x%02x\n",i_ddLevel);
	MY_INF("\tOutput Centaur image fn = %s\n",i_fnImageOut);

	// ==========================================================================
	// Memory map input image.
	// ==========================================================================
	MY_INF("--> Memory map Reference input image... \n");
	fdImageIn=open( i_fnImageIn, O_RDONLY);
	if (fstat(fdImageIn, &stbuf)!=0)  {
		MY_ERR("Could not fstat the input image file.\n");
		return 1;
	}
	sizeImageIn = stbuf.st_size;
	imageIn = mmap(0, sizeImageIn, PROT_READ, MAP_SHARED, fdImageIn, 0);
	if (imageIn==MAP_FAILED)  {
		MY_ERR("m\tmmap() of input image failed...\n");
		return 1;
	}
	// ...validate image.
  rc = sbe_xip_validate(imageIn, sizeImageIn);
  if (rc)   {
      MY_ERR("\tsbe_xip_validate() of input image failed: %s\n", SBE_XIP_ERROR_STRING(g_errorStrings, rc));
      return 1;
  }

	// Allocate sufficient memory for output image and make initial copy of Ref image.
	//
	if (sizeImageIn>SIZE_IMAGE_BUF_MAX)  {
		MY_ERR("Input image size exceeds max allowed buffer size.\n");
		return 1;
	}
	imageOut = (uint8_t*)malloc(SIZE_IMAGE_BUF_MAX);
	if (!imageOut)  {
		MY_ERR("\tmalloc() for Centaur output image memory failed.\n");
		if (imageOut)  free(imageOut);
		return 1;
	}
	memcpy( imageOut, imageIn, sizeImageIn);

	// Create the Centaur image.
	//
	MY_INF("-> Calling p8_centaur_build().\n");
	rc = p8_centaur_build(	imageIn,
													i_ddLevel,
													imageOut,
													SIZE_IMAGE_CENTAUR_MAX);
	if (rc==DSLWB_SLWB_SUCCESS)
		MY_INF("Centaur build was SUCCESSFUL.\n");
	else
	if (rc==DSLWB_SLWB_NO_RING_MATCH)
		MY_INF("Centaur build was SUCCESSFUL but no WF rings appended (rc=%i).\n",rc);
	else  {			
		MY_ERR("Centaur build was UNSUCCESSFUL (rc=%i).\n",rc);
		MY_ERR("No image file will be created.\n");
		if (imageOut)  free(imageOut);
		return 1;
	}
	close(fdImageIn);

	// Save the Centaur image in the output file.
	//
	sbe_xip_image_size(imageOut, &sizeImageOut);
	MY_INF("\tOutput Centaur image size = %i\n",sizeImageOut);
	fpImageOut = fopen(i_fnImageOut, "w");
	for (i=0; i<sizeImageOut; i++)
		fprintf(fpImageOut,"%c",((char*)imageOut)[i]);
	fclose(fpImageOut);
	
	// Clean up.
	//
	if (imageOut)
		free(imageOut);
	return rc;
}



//  Parameter list:
//  void 			*i_imageIn:   	Pointer to memory mapped input Reference image
//  uint32_t	i_ddLevel:			DD level
//  void			*i_imageOut:  	Pointer to where the initial IPL output image is
//  uint32_t  i_sizeImageOutMax: Max size of output image.
//
int p8_centaur_build(	void 			*i_imageIn,
											uint32_t	i_ddLevel,
											void 			*i_imageOut,
											uint32_t	i_sizeImageOutMax)
{
	int      rcLoc=0, rcLoc1=0, rcLoc2=0, rcSearch=0;
	uint32_t i=0, countRings=0;
	uint8_t  sysPhase=0;
	uint8_t  *deltaRingDxed=NULL;
  uint32_t sizeImage=0, sizeImageOut=0, sizeImageTmp, sizeImageOld;
  uint32_t ringBitLen=0;
  uint32_t *bufWf=NULL;
	void     *buf2=NULL;
	uint32_t sizeBufWf=0, sizeBuf2=0, wfInlineLenInWords=0;
	uint32_t scanMaxRotate=SCAN_ROTATE_DEFAULT;
  CompressedScanData *deltaRingRS4;
	DeltaRingLayout rs4RingLayout;
	void *nextRing=NULL;

	// Define fixed size ring buffers, as this is used now in
	// create_wiggle_flip_prg() and write_wiggle_flip_to_image().
	sizeBufWf = FIXED_RING_BUF_SIZE;
	bufWf = (uint32_t*)malloc(sizeBufWf);
	if (!bufWf)  {
	  printf("\tmalloc() for ring buffer 1 failed.\n");
	  return IMGBUILD_ERR_MEMORY;
	}
	sizeBuf2 = FIXED_RING_BUF_SIZE;
	buf2 = malloc(sizeBuf2);
	if (!buf2)  {
	  printf("\tmalloc() for ring buffer 1 failed.\n");
	  free(bufWf);
	  return IMGBUILD_ERR_MEMORY;
	}

	// ==========================================================================
	// First, remove NO sections AT ALL for centaur_build().
	// ==========================================================================
	//
	rcLoc1 = sbe_xip_delete_section( i_imageOut, SBE_XIP_SECTION_RINGS);
  rcLoc2 = sbe_xip_image_size(i_imageOut, &sizeImage);
  rcLoc =  sbe_xip_validate(i_imageOut, sizeImage);
	if (rcLoc1 || rcLoc2 || rcLoc)  {
		MY_ERR("_delete_section(.rings) (rcLoc1=%i), _image_size() (rcLoc2=%i) and/or _validate() (rcLoc=%i) failed.\n",rcLoc1,rcLoc2,rcLoc);
    if (bufWf)  free(bufWf);
		if (buf2) free(buf2);
		return IMGBUILD_ERR_SECTION_DELETE;
	}
	MY_INF("Image size (after .rings delete): %i\n",sizeImage);


	/***************************************************************************
	 *														SEARCH LOOP - Begin												 	 *
	 ***************************************************************************/
 	do  {
 	
	MY_INF("nextRing (at top)=0x%016llx\n",(uint64_t)nextRing);
	
	// ==========================================================================
	// Get ring layout from image
	// ==========================================================================
	MY_INF("--> Retrieving RS4 ring from Reference image.\n");
	rcLoc = get_ring_layout_from_image(	i_imageIn,
																			i_ddLevel,
																			sysPhase,
																			&rs4RingLayout,
																			&nextRing);
	rcSearch = rcLoc;
	if (rcSearch!=DSLWB_RING_SEARCH_MATCH && 
			rcSearch!=DSLWB_RING_SEARCH_EXHAUST_MATCH && 
			rcSearch!=DSLWB_RING_SEARCH_NO_MATCH)  {
		MY_ERR("\tERROR : Error during retrieval of delta rings from the image (rcSearch=%i).\n",rcSearch);
		MY_ERR("\tNo further WF rings will be appended to the Centaur image.\n");
		MY_ERR("\tThe Centaur image is incomplete.\n");
    if (bufWf)  free(bufWf);
		if (buf2) free(buf2);
		return IMGBUILD_ERR_INCOMPLETE_IMG_BUILD;
	}
	if (rcSearch==DSLWB_RING_SEARCH_MATCH || 
			rcSearch==DSLWB_RING_SEARCH_EXHAUST_MATCH)
		MY_INF("\tRetrieving RS4 ring was successful.\n");

	// Check if we're done at this point.
	//			
	if (rcSearch==DSLWB_RING_SEARCH_NO_MATCH)  {
		MY_INF("Centaur image build done.\n");
		MY_INF("Number of WF rings appended: %i\n", countRings);
		if (countRings==0)
			MY_INF("ZERO WF rings appended to .rings section.\n");
		sbe_xip_image_size( i_imageOut, &sizeImageOut);
		MY_INF("Final Centaur image size: %i\n", sizeImageOut);
    if (bufWf)  free(bufWf);
		if (buf2) free(buf2);
		return IMGBUILD_SUCCESS;
	}

  deltaRingRS4 = (CompressedScanData*)rs4RingLayout.rs4Delta;

  MY_DBG("Dumping ring layout:\n");
  MY_DBG("\tentryOffset      = %i\n",(uint32_t)myRev64(rs4RingLayout.entryOffset));
  MY_DBG("\tbackItemPtr     = 0x%016llx\n",myRev64(rs4RingLayout.backItemPtr));
  MY_DBG("\tsizeOfThis      = %i\n",myRev32(rs4RingLayout.sizeOfThis));
  MY_DBG("\tsizeOfMeta      = %i\n",myRev32(rs4RingLayout.sizeOfMeta));
  MY_DBG("\tddLevel         = %i\n",myRev32(rs4RingLayout.ddLevel));
  MY_DBG("\tsysPhase        = %i\n",rs4RingLayout.sysPhase);
  MY_DBG("\toverride        = %i\n",rs4RingLayout.override);
  MY_DBG("\treserved1+2     = %i\n",rs4RingLayout.reserved1|rs4RingLayout.reserved2);
  MY_DBG("\tRS4 magic #     = 0x%08x\n",myRev32(deltaRingRS4->iv_magic));
  MY_DBG("\tRS4 total size  = %i\n",myRev32(deltaRingRS4->iv_size));
  MY_DBG("\tUnXed data size = %i\n",myRev32(deltaRingRS4->iv_length));
  MY_DBG("\tScan select     = 0x%08x\n",myRev32(deltaRingRS4->iv_scanSelect));
  MY_DBG("\tHeader version  = 0x%02x\n",deltaRingRS4->iv_headerVersion);
  MY_DBG("\tFlush optimize  = 0x%02x (reverse of override)\n",deltaRingRS4->iv_flushOptimization);
  MY_DBG("\tRing ID         = 0x%02x\n",deltaRingRS4->iv_ringId);
  MY_DBG("\tChiplet ID      = 0x%02x\n",deltaRingRS4->iv_chipletId);
  MY_DBG("Dumping meta data:\n");
  MY_DBG("\tsizeOfData = %i\n",myRev32(rs4RingLayout.sizeOfMeta));
  MY_DBG("\tMeta data  = ");
  for (i=0; i<myRev32(rs4RingLayout.sizeOfMeta); i++)  { // String may not be null terminated.
    MY_DBG("%c",rs4RingLayout.metaData[i]);
  }
	MY_DBG("\n");

  // ==========================================================================
	// Decompress RS4 delta state.
	// ==========================================================================
	MY_INF("--> Decompressing RS4 delta ring.\n");
  // Note:  deltaRingDxed is left-aligned. If converting to uint32_t, do BE->LE flip.
  deltaRingDxed = NULL;
  rcLoc = rs4_decompress( &deltaRingDxed,
                          &ringBitLen,
                          deltaRingRS4);
  if (rcLoc)  {
    MY_ERR("\tERROR : rs4_decompress() failed: rc=%i\n",rcLoc);
    if (deltaRingDxed)  free(deltaRingDxed);
    if (bufWf)  free(bufWf);
		if (buf2) free(buf2);
    return IMGBUILD_ERR_RS4_DECOMPRESS;
  }
  MY_INF("\tDecompression successful.\n");


  // ==========================================================================
  // Create Wiggle-Flip Programs
  // ==========================================================================
  MY_INF("--> Creating Wiggle-Flip Program.\n");
	wfInlineLenInWords = sizeBufWf/4;
  scanMaxRotate = SCAN_ROTATE_DEFAULT;
	rcLoc = create_wiggle_flip_prg( (uint32_t*)deltaRingDxed,
                                  ringBitLen,
                                  myRev32(deltaRingRS4->iv_scanSelect),
                                  (uint32_t)deltaRingRS4->iv_chipletId,
                                  &bufWf,
                                  &wfInlineLenInWords,
                                  deltaRingRS4->iv_flushOptimization,
																	scanMaxRotate,
                                  0,  // No need to use waits for Centaur.
                                  0); // Centaur doesn't support scan polling.
  if (rcLoc)  {
    MY_ERR("ERROR : create_wiggle_flip_prg() failed w/rcLoc=%i\n",rcLoc);
    if (deltaRingDxed)  free(deltaRingDxed);
    if (bufWf)  free(bufWf);
		if (buf2) free(buf2);
    return IMGBUILD_ERR_PORE_INLINE;
  }
  MY_INF("\tWiggle-flip programming successful.\n");


  // ==========================================================================
  // Append Wiggle-Flip programs to .rings section.
  // ==========================================================================
  MY_INF("--> Appending wiggle-flip and layout header to .rings section.\n");
  sizeImageTmp = i_sizeImageOutMax;
  rcLoc = write_wiggle_flip_to_image( i_imageOut,
                                      &sizeImageTmp,
                                      &rs4RingLayout,
                                      bufWf,
                                      wfInlineLenInWords);
  if (rcLoc)  {
    MY_ERR("ERROR : write_wiggle_flip_to_image() failed w/rcLoc=%i\n",rcLoc);
		MY_ERR("\tImage size (old) = %i\n", sizeImageOld);
		MY_ERR("\tImage size (est) = %i\n", sizeImageTmp);
		MY_ERR("\tImage size (max) = %i\n", i_sizeImageOutMax);
    if (deltaRingDxed)  free(deltaRingDxed);
    if (bufWf)  free(bufWf);
		if (buf2) free(buf2);
    return rcLoc;
  }
  MY_INF("\tUpdating image w/wiggle-flip program + header was successful.\n");

	// Update some variables for debugging and error reporting.
	sizeImageOld = sizeImageTmp;
	countRings++;

	
	// ==========================================================================
	// Are we done?
	// ==========================================================================
	if (rcSearch==DSLWB_RING_SEARCH_EXHAUST_MATCH)  {
		MY_INF("Centaur image build done.\n");
		MY_INF("Number of WF rings appended: %i\n", countRings);
		if (countRings==0)
			MY_INF("ZERO WF rings appended to .rings section.\n");
		sbe_xip_image_size( i_imageOut, &sizeImageOut);
		if (bufWf) free(bufWf);
		if (buf2) free(buf2);
		return IMGBUILD_SUCCESS;
	}

	MY_INF("nextRing (at bottom)=0x%016llx\n",(uint64_t)nextRing);


	}  while (nextRing!=NULL);
	/***************************************************************************
	 *														SEARCH LOOP - End													 	 *
	 ***************************************************************************/

	MY_ERR("\n\t**** Something's wrong. Shouldn't be in this code section. Check code. ****\n");
	return IMGBUILD_ERR_CHECK_CODE;

}


