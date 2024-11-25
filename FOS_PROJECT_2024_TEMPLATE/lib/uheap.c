#include <inc/lib.h>

#define USER_HEAP_ARRAY_SIZE ((USER_HEAP_MAX - USER_HEAP_START) / PAGE_SIZE)
uint32 allocation_sizes[USER_HEAP_ARRAY_SIZE];

//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//

//=============================================
// [1] CHANGE THE BREAK LIMIT OF THE USER HEAP:
//=============================================
/*2023*/
void* sbrk(int increment) {
	return (void*) sys_sbrk(increment);
}

//=================================
// [2] ALLOCATE SPACE IN USER HEAP:
//=================================
void* malloc(uint32 size) {
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	if (size == 0)
		return NULL;
	//==============================================================
	//TODO: [PROJECT'24.MS2 - #12] [3] USER HEAP [USER SIDE] - malloc()
	// Write your code here, remove the panic and write your code
	//panic("malloc() is not implemented yet...!!");

	if (sys_isUHeapPlacementStrategyFIRSTFIT()) {
		if (size <= DYN_ALLOC_MAX_BLOCK_SIZE) {
			cprintf("size: %d \n", size);
			return (void*) alloc_block_FF(size);
		}

		uint32* virtual_address = AllocateInPageAllocator(size);

		return (void*) virtual_address;
	} else if (sys_isUHeapPlacementStrategyBESTFIT()) {

	}

	return NULL;
}

//=================================
// [3] FREE SPACE FROM USER HEAP:
//=================================
void free(void* virtual_address) {
//	cprintf("va: %x\n", virtual_address);
	if (virtual_address == NULL)
		return;

	if ((uint32) virtual_address >= myEnv->UhStart
			&& (uint32) virtual_address < myEnv->UhLimit) {
		free_block(virtual_address);
		return;
	}
	if ((uint32) virtual_address < USER_HEAP_START
			|| (uint32) virtual_address >= USER_HEAP_MAX)
		return;

	// Calculate index and retrieve size
	uint32 index = ((uint32) virtual_address - USER_HEAP_START) / PAGE_SIZE;

	// Validate the address is within the heap range
	if (index < 0) {
		panic("Invalid address: address out of heap range");
	}

	uint32 size = allocation_sizes[index];
//	cprintf("size: %d\n", size);

	// Check for zero-sized allocations
	if (size == 0) {
		panic("Invalid allocation size: zero-sized block");
	}

	// Free from page allocator
	sys_free_user_mem((uint32) virtual_address, size);
//	cprintf("size: %d\n", size);
	allocation_sizes[index] = 0;
}

//=================================
// [4] ALLOCATE SHARED VARIABLE:
//=================================
void* smalloc(char *sharedVarName, uint32 size, uint8 isWritable) {
	//==============================================================
	//DON'T CHANGE THIS CODE========================================
	if (size == 0)
		return NULL;
	//==============================================================
	//TODO: [PROJECT'24.MS2 - #18] [4] SHARED MEMORY [USER SIDE] - smalloc()
	// Write your code here, remove the panic and write your code
	//	panic("smalloc() is not implemented yet...!!");

	uint32* virtual_address = AllocateInPageAllocator(size);

	int SharedObjectId = sys_createSharedObject(sharedVarName, size, isWritable,
			(void*) virtual_address);
	if (SharedObjectId == 0)
		return NULL;
	return (void*) virtual_address;
}

//========================================
// [5] SHARE ON ALLOCATED SHARED VARIABLE:
//========================================
void* sget(int32 ownerEnvID, char *sharedVarName) {
	//TODO: [PROJECT'24.MS2 - #20] [4] SHARED MEMORY [USER SIDE] - sget()
	// Write your code here, remove the panic and write your code
	panic("sget() is not implemented yet...!!");
	return NULL;
}

//==================================================================================//
//============================== BONUS FUNCTIONS ===================================//
//==================================================================================//

//=================================
// FREE SHARED VARIABLE:
//=================================
//	This function frees the shared variable at the given virtual_address
//	To do this, we need to switch to the kernel, free the pages AND "EMPTY" PAGE TABLES
//	from main memory then switch back to the user again.
//
//	use sys_freeSharedObject(...); which switches to the kernel mode,
//	calls freeSharedObject(...) in "shared_memory_manager.c", then switch back to the user mode here
//	the freeSharedObject() function is empty, make sure to implement it.

void sfree(void* virtual_address) {
	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [USER SIDE] - sfree()
	// Write your code here, remove the panic and write your code
	panic("sfree() is not implemented yet...!!");
}

//=================================
// REALLOC USER SPACE:
//=================================
//	Attempts to resize the allocated space at "virtual_address" to "new_size" bytes,
//	possibly moving it in the heap.
//	If successful, returns the new virtual_address, in which case the old virtual_address must no longer be accessed.
//	On failure, returns a null pointer, and the old virtual_address remains valid.

//	A call with virtual_address = null is equivalent to malloc().
//	A call with new_size = zero is equivalent to free().

//  Hint: you may need to use the sys_move_user_mem(...)
//		which switches to the kernel mode, calls move_user_mem(...)
//		in "kern/mem/chunk_operations.c", then switch back to the user mode here
//	the move_user_mem() function is empty, make sure to implement it.
void *realloc(void *virtual_address, uint32 new_size) {
	//[PROJECT]
	// Write your code here, remove the panic and write your code
	panic("realloc() is not implemented yet...!!");
	return NULL;

}
/*
 * helper function for Page Allocating
 * */

void* AllocateInPageAllocator(uint32 size) {
	uint32 virtual_address = myEnv->UhLimit + PAGE_SIZE;
	uint32 numOfPages = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE, countPages = 0;

	cprintf("--------numOfPages: %d\t,\tSize: %d------------\n", numOfPages, size);
	uint32 current = virtual_address, startAdd = virtual_address;

	while (countPages < numOfPages) {
		if ((uint32) current > USER_HEAP_MAX) {
			return NULL;
		}

		if (sys_is_marked_page((uint32) current)) {
			countPages = 0;
			current += PAGE_SIZE;
			virtual_address = current;
			continue;
		}
		++countPages;
		current += PAGE_SIZE;
	}
	sys_allocate_user_mem((uint32) virtual_address, size);

	uint32 index = ((uint32) virtual_address - USER_HEAP_START) / PAGE_SIZE;
	uint32 totalSize = ROUNDUP(size, PAGE_SIZE);
	allocation_sizes[index] = totalSize;
	if ((virtual_address + totalSize) > USER_HEAP_MAX) {
		return NULL;
	}
	return (void*) virtual_address;
}

//==================================================================================//
//========================== MODIFICATION FUNCTIONS ================================//
//==================================================================================//

void expand(uint32 newSize) {
	panic("Not Implemented");

}
void shrink(uint32 newSize) {
	panic("Not Implemented");

}
void freeHeap(void* virtual_address) {
	panic("Not Implemented");

}
