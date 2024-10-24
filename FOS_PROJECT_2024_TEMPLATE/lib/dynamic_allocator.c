/*
 * dynamic_allocator.c
 *
 *  Created on: Sep 21, 2023
 *      Author: HP
 */
#include <inc/assert.h>
#include <inc/string.h>
#include "../inc/dynamic_allocator.h"

//==================================================================================//
//============================== GIVEN FUNCTIONS ===================================//
//==================================================================================//

//=====================================================
// 1) GET BLOCK SIZE (including size of its meta data):
//=====================================================
__inline__ uint32 get_block_size(void *va)
{
	uint32 *curBlkMetaData = ((uint32 *)va - 1);
	return (*curBlkMetaData) & ~(0x1);
}

//===========================
// 2) GET BLOCK STATUS:
//===========================
__inline__ int8 is_free_block(void *va)
{
	uint32 *curBlkMetaData = ((uint32 *)va - 1);
	return (~(*curBlkMetaData) & 0x1);
}

//===========================
// 3) ALLOCATE BLOCK:
//===========================

void *alloc_block(uint32 size, int ALLOC_STRATEGY)
{
	void *va = NULL;
	switch (ALLOC_STRATEGY)
	{
	case DA_FF:
		va = alloc_block_FF(size);
		break;
	case DA_NF:
		va = alloc_block_NF(size);
		break;
	case DA_BF:
		va = alloc_block_BF(size);
		break;
	case DA_WF:
		va = alloc_block_WF(size);
		break;
	default:
		cprintf("Invalid allocation strategy\n");
		break;
	}
	return va;
}

//===========================
// 4) PRINT BLOCKS LIST:
//===========================

void print_blocks_list(struct MemBlock_LIST list)
{
	cprintf("=========================================\n");
	struct BlockElement *blk;
	cprintf("\nDynAlloc Blocks List:\n");
	LIST_FOREACH(blk, &list)
	{
		cprintf("(size: %d, isFree: %d)\n", get_block_size(blk), is_free_block(blk));
	}
	cprintf("=========================================\n");
}
//
////********************************************************************************//
////********************************************************************************//

//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//

bool is_initialized = 0;
//==================================
// [1] INITIALIZE DYNAMIC ALLOCATOR:
//==================================
void initialize_dynamic_allocator(uint32 daStart, uint32 initSizeOfAllocatedSpace)
{
	//==================================================================================
	// DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		if (initSizeOfAllocatedSpace % 2 != 0)
			initSizeOfAllocatedSpace++; // ensure it's multiple of 2
		if (initSizeOfAllocatedSpace == 0)
			return;
		is_initialized = 1;
	}
	//==================================================================================
	//==================================================================================

	// TODO: [PROJECT'24.MS1 - #04] [3] DYNAMIC ALLOCATOR - initialize_dynamic_allocator
	// COMMENT THE FOLLOWING LINE BEFORE START CODING
	// panic("initialize_dynamic_allocator is not implemented yet");
	// Your Code is Here...
	LIST_INIT(&freeBlocksList);

	uint32 *BEG_Block = (uint32 *)daStart;
	uint32 *END_Block = (uint32 *)(daStart + initSizeOfAllocatedSpace - sizeof(uint32));
	uint32 *Header = (uint32 *)(daStart + sizeof(uint32));
	uint32 *Footer = (uint32 *)(daStart + initSizeOfAllocatedSpace - 2 * sizeof(uint32));

	*Header = (initSizeOfAllocatedSpace - 2 * sizeof(uint32));
	*Footer = (initSizeOfAllocatedSpace - 2 * sizeof(uint32));
	struct BlockElement *firstFreeBlock = (struct BlockElement *)(daStart + 2 * sizeof(uint32));

	*BEG_Block = 0x0001;
	*END_Block = 0x0001;
	freeBlocksList.lh_first = firstFreeBlock;
	freeBlocksList.size = 1;
	LIST_HEAD(freeBlocksList, firstFreeBlock);

	// set Block Test

	//    void * va = (void*)0xF6543210;;
	//    set_block_data(va,9*sizeof(int), 1);
	//    uint32 res =  get_block_size(va);
	//    panic("BLOCK Size: %d\n\n",res);
	//    int8 res = is_free_block(va);
	//    panic("IS FREE BLOCK : %d\n\n",res);
}
//==================================
// [2] SET BLOCK HEADER & FOOTER:
//==================================
void set_block_data(void *va, uint32 totalSize, bool isAllocated)
{
	// TODO: [PROJECT'24.MS1 - #05] [3] DYNAMIC ALLOCATOR - set_block_data
	// COMMENT THE FOLLOWING LINE BEFORE START CODING
	//	panic("set_block_data is not implemented yet");
	//	Your Code is Here...

	uint32 header_footer_data;
	// lw allocated el flag = 1 lw la =0
	if (isAllocated)
	{
		header_footer_data = totalSize | 1;
	}
	else
	{
		header_footer_data = totalSize | 0;
	}
	// el header abl el address b 4 bytes
	*(uint32 *)(va - sizeof(uint32)) = header_footer_data;

	// el footer 3nd el address + el size - size of el footer wl header
	*(uint32 *)(va + totalSize - 2 * (sizeof(uint32))) = header_footer_data;
}

//=========================================
// [3] ALLOCATE BLOCK BY FIRST FIT:
//=========================================
void *alloc_block_FF(uint32 size)
// Size parameter without MetaData.
{
	//==================================================================================
	//DON'T CHANGE THESE LINES==========================================================
	//==================================================================================
	{
		if (size % 2 != 0) size++;	//ensure that the size is even (to use LSB as allocation flag)
		if (size < DYN_ALLOC_MIN_BLOCK_SIZE)
			size = DYN_ALLOC_MIN_BLOCK_SIZE ;
		if (!is_initialized)
		{
			uint32 required_size = size + 2*sizeof(int) /*header & footer*/ + 2*sizeof(int) /*da begin & end*/ ;
			uint32 da_start = (uint32)sbrk(ROUNDUP(required_size, PAGE_SIZE)/PAGE_SIZE);
			uint32 da_break = (uint32)sbrk(0);
			initialize_dynamic_allocator(da_start, da_break - da_start);
		}
	}
	//==================================================================================
	//==================================================================================

	//TODO: [PROJECT'24.MS1 - #06] [3] DYNAMIC ALLOCATOR - alloc_block_FF
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("alloc_block_FF is not implemented yet");
	//Your Code is Here...


	if(size == 0){
		return NULL;
	}

	uint32 size_with_metadata = size + 2*sizeof(uint32);

	struct BlockElement* blk;
	LIST_FOREACH(blk, &freeBlocksList){

		// Get size of each free block.

		uint32 current_blk_size_from_header = get_block_size((void *)blk);
//		cprintf("size_with_metadata: %d \n current_blk_size_from_header: %d \n", size_with_metadata, current_blk_size_from_header);
		if(size_with_metadata <= current_blk_size_from_header){
			uint32 free_blk_size = current_blk_size_from_header - size_with_metadata;

			if(free_blk_size < 2*DYN_ALLOC_MIN_BLOCK_SIZE){
				// There is an internal fragmentation.
				// Allocate size of header *current_blk_size_from_header.
//				cprintf("internal fragmentation. \n");
				set_block_data((void*) blk, current_blk_size_from_header, 1);
				LIST_REMOVE(&freeBlocksList, blk);
			}
			else {
//				cprintf("no internal fragmentation. Splitting occurs. \n");
				// There is no internal fragmentation. Splitting occurs.

//				cprintf("old free block: %p\n", blk);
				set_block_data((void*) blk, size_with_metadata, 1);

				struct BlockElement* remaining_blk = (struct BlockElement *)((char *)blk + size_with_metadata);
//				cprintf("new free block: %p\n", remaining_blk);
				set_block_data((void *) remaining_blk, free_blk_size, 0);

				LIST_INSERT_AFTER(&freeBlocksList, blk, remaining_blk);
				LIST_REMOVE(&freeBlocksList, blk);

			}
//			cprintf("block pointer: %p\n", (void *)blk);
			return (void *)blk;

		}
		else {
//			cprintf("size msh mkaffy \n");
			sbrk(5);
			return NULL;
		}
	}
	return NULL;
}

//=========================================
// [4] ALLOCATE BLOCK BY BEST FIT:
//=========================================
void *alloc_block_BF(uint32 size)
{
	// TODO: [PROJECT'24.MS1 - BONUS] [3] DYNAMIC ALLOCATOR - alloc_block_BF
	// COMMENT THE FOLLOWING LINE BEFORE START CODING
	panic("alloc_block_BF is not implemented yet");
	// Your Code is Here...
}

//===================================================
// [5] FREE BLOCK WITH COALESCING:
//===================================================

void free_block(void *va)
{
	cprintf("-------ITERATION---------\n\n");
	//TODO: [PROJECT'24.MS1 - #07] [3] DYNAMIC ALLOCATOR - free_block
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("free_block is not implemented yet");
	//Your Code is Here...

	if (va == NULL) {
	        cprintf("Please specify a valid address.\n");
	        return;
	}

	// Check if the block is already free.
	if (is_free_block(va)) {
		cprintf("The block at address %p is already free.\n", va);
		return;
	}

	// Free the block.
	uint32 size = get_block_size(va);
//	cprintf("Size of va: %d at address: %p\n", size, va);
	set_block_data(va, size, 0);

	// Add the freed block to the list.
	struct BlockElement* block = (struct BlockElement*) va;

	// Add it to the head of the list.
	if(LIST_SIZE(&freeBlocksList) == 0){
		cprintf("LIST IS EMPTY..\n");
		LIST_INSERT_HEAD(&freeBlocksList, block);
		return;
	}


//	cprintf("Size of first free block: %d\n", get_block_size(firstBlock));
//	cprintf("Size of last free block: %d\n", get_block_size(lastBlock));

	struct BlockElement* currentFreeBlock;


	// Getting previous and next block by their footer and header for merging.
	uint32 * previous_blk_footer = (uint32 *)((char *)block - 2 * sizeof(uint32));
	uint32 previous_blk_size = (*previous_blk_footer) & ~(0x1);

//	cprintf("Size of previous block without LSB: %d\n", previous_blk_size);

	// Track previous and next blocks in the free blocks list for merging.
	uint32 * previous_blk = (uint32 *)((char *)block - previous_blk_size);
	previous_blk =  previous_blk_size == 0 ? NULL : previous_blk;

	uint32 * next_blk = (uint32 *)((char *)block + get_block_size(block));
	next_blk = get_block_size(next_blk) == 0 ? NULL : next_blk;

//	cprintf("Size of previous block: %d Bytes at address: %p is free: %d\n", get_block_size(previous_blk), previous_blk, is_free_block(previous_blk));
//	cprintf("Size of next block: %d Bytes at address: %p is free: %d\n", get_block_size(next_blk), next_blk, is_free_block(next_blk));

	uint32 total_size_after_coalesce = get_block_size(block);

	// COALESCE WITH PREVIOUS BLOCK.
	if(previous_blk != NULL){
//	cprintf("Size of block PREV: %d\n", total_size_after_coalesce);
		if(is_free_block(previous_blk)){
			cprintf("COALESCE WITH PREVIOUS BLOCK.\n");
			total_size_after_coalesce += get_block_size(previous_blk);
			block = (struct BlockElement *)previous_blk;

			LIST_REMOVE(&freeBlocksList, (struct BlockElement *)previous_blk);
		}
	}

	// COALESCE WITH NEXT BLOCK.
	if(next_blk != NULL){
//		cprintf("Size of block NEXT: %d\n", total_size_after_coalesce);
		if(is_free_block(next_blk)){
			cprintf("COALESCE WITH NEXT BLOCK.\n");
			total_size_after_coalesce += get_block_size(next_blk);

			LIST_REMOVE(&freeBlocksList, (struct BlockElement *)next_blk);
		}
	}
	// Setting block with the total size according to the conditions above..
	set_block_data(block, total_size_after_coalesce, 0);

	struct BlockElement* firstFreeBlock = LIST_FIRST(&freeBlocksList);
	struct BlockElement* lastFreeBlock = LIST_LAST(&freeBlocksList);
	// Check if it's before the first free block in the list.
	if(block < firstFreeBlock){
//		cprintf("before the first free block\n");
//		cprintf("firstFreeBlockSize: %d\n", get_block_size(firstFreeBlock));
		LIST_INSERT_HEAD(&freeBlocksList, block);
		print_blocks_list(freeBlocksList);
		return;
	}
	// Check if it's after the last free block in the list.
	if(block > lastFreeBlock){
//		cprintf("after the last free block\n");
//		cprintf("lastFreeBlockSize: %d\n", get_block_size(lastFreeBlock));
		LIST_INSERT_TAIL(&freeBlocksList, block);
		print_blocks_list(freeBlocksList);
		return;
	}



	LIST_FOREACH(currentFreeBlock, &freeBlocksList){
		// Between 2 free blocks.
		if(LIST_NEXT(currentFreeBlock)){
			if(currentFreeBlock < block && LIST_NEXT(currentFreeBlock) > block){
//				cprintf("inside foreach\n");
				if(LIST_PREV(currentFreeBlock)){
					LIST_INSERT_AFTER(&freeBlocksList, LIST_PREV(currentFreeBlock), block);
				}
				else if(LIST_NEXT(currentFreeBlock)){
					LIST_INSERT_BEFORE(&freeBlocksList, LIST_NEXT(currentFreeBlock), block);
				}
				return;
			}
		}
	}
}

//=========================================
// [6] REALLOCATE BLOCK BY FIRST FIT:
//=========================================
void *realloc_block_FF(void *va, uint32 new_size)
{
	// TODO: [PROJECT'24.MS1 - #08] [3] DYNAMIC ALLOCATOR - realloc_block_FF
	// COMMENT THE FOLLOWING LINE BEFORE START CODING
	// panic("realloc_block_FF is not implemented yet");
	// Your Code is Here...

	//

	if (new_size < 16 || va == NULL)
		return NULL;
	if ((new_size ^ 1) != (new_size + 1))
		new_size++;
	uint32 remainingSizeAfterReallocation = get_block_size(va) - new_size - sizeof(uint32);
	if (remainingSizeAfterReallocation >= 16)
	{
		uint32 *currentBlockMetaData = ((uint32 *)va - 1);
		*currentBlockMetaData = new_size | 1;
		// hana3mel hena free block
		return va;
	}
	struct BlockElement *searchingBlock = freeBlocksList.lh_first;
	struct BlockElement *foundBlock = NULL;
	while (searchingBlock != NULL)
	{
		uint32 blockSize = get_block_size(searchingBlock);
		if (blockSize - sizeof(uint32) >= new_size + 16)
		{
			foundBlock = searchingBlock;
			break;
		}
		searchingBlock = searchingBlock->prev_next_info.le_next;
	}
	if (foundBlock != NULL)
	{
		memcpy(foundBlock, va, get_block_size(va));
		uint32 *new_Block_MetaData = ((uint32 *)foundBlock - 1);
		*new_Block_MetaData = new_size | 1;
		LIST_REMOVE(&freeBlocksList, foundBlock);
		if (remainingSizeAfterReallocation > sizeof(uint32))
		{
			// mafrood na3mel hena free Block
		}

		return foundBlock;
	}
	//	else sbrk();
	return NULL;
}

/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/
//=========================================
// [7] ALLOCATE BLOCK BY WORST FIT:
//=========================================
void *alloc_block_WF(uint32 size)
{
	panic("alloc_block_WF is not implemented yet");
	return NULL;
}

//=========================================
// [8] ALLOCATE BLOCK BY NEXT FIT:
//=========================================
void *alloc_block_NF(uint32 size)
{
	panic("alloc_block_NF is not implemented yet");
	return NULL;
}
