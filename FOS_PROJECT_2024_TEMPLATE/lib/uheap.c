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
//			cprintf("size: %d \n", size);
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

	if (virtual_address == NULL)
		return;

	if ((uint32) virtual_address >= myEnv->UhStart && (uint32) virtual_address < myEnv->UhLimit) {
		free_block(virtual_address);
		return;
	}
	if ((uint32) virtual_address < USER_HEAP_START || (uint32) virtual_address >= USER_HEAP_MAX)
		return;

	// Calculate index and retrieve size
	uint32 index = ((uint32) virtual_address - USER_HEAP_START) / PAGE_SIZE;

	// Validate the address is within the heap range
	if (index < 0) {
		panic("Invalid address: address out of heap range");
	}

	uint32 size = allocation_sizes[index];

	// Check for zero-sized allocations
	if (size == 0) {
		panic("Invalid allocation size: zero-sized block");
	}

	// Free from page allocator
	sys_free_user_mem((uint32) virtual_address, size);

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
	uint32* virtual_address = (uint32*)AllocateInPageAllocator(size);
	if(!virtual_address) return NULL;
//	cprintf("Found virtual address @: %p\n", virtual_address);
	int SharedObjectId = sys_createSharedObject(sharedVarName, size, isWritable,
			(void*) virtual_address);
	if (SharedObjectId == 0)
		return NULL;
//	cprintf("Found shared object with ID: %p\n", SharedObjectId);
	return (void*) virtual_address;
}

//========================================
// [5] SHARE ON ALLOCATED SHARED VARIABLE:
//========================================
void* sget(int32 ownerEnvID, char *sharedVarName) {
	//TODO: [PROJECT'24.MS2 - #20] [4] SHARED MEMORY [USER SIDE] - sget()
	// Write your code here, remove the panic and write your code
	//1- get size of shared variable
	void* start_va;
	uint32 size = sys_getSizeOfSharedObject(ownerEnvID, sharedVarName);
	if(size == 0) return NULL;

	start_va = AllocateInPageAllocator(size);
	if(!start_va) return NULL;

//	cprintf("Found virtual address @: %p\n", start_va);

//	*((uint32 *)start_va) = 20;
	uint32 id = sys_getSharedObject(ownerEnvID, sharedVarName, (uint32 *)start_va);

	if(id == E_SHARED_MEM_NOT_EXISTS) return NULL;

//	sys_bypassPageFault(0);
	return start_va;
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
//	panic("sfree() is not implemented yet...!!");
	if (virtual_address == NULL) {
		panic("NULL address\n");
	}

	// Call kernel function to free the shared memory
	cprintf("Masked Bit: %d\n", (int32)virtual_address & 0x7FFFFFFF);
	int xd = sys_freeSharedObject((int32)virtual_address & 0x7FFFFFFF, virtual_address);

	if (xd != 0) {
		panic("Failed in freeing shared object\n");
	}
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
	uint32 virtual_address = (uint32)GetConsecutivePages(size);
	if(!virtual_address) return NULL;

	sys_allocate_user_mem((uint32) virtual_address, size);

	return (void*) virtual_address;
}


uint32* GetConsecutivePages(uint32 size) {
	uint32 virtual_address = myEnv->UhLimit + PAGE_SIZE;
	uint32 numOfPages = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE, countPages = 0;

	uint32 current = virtual_address;
	while (countPages < numOfPages) {
		if ((uint32) current > USER_HEAP_MAX) {
			return NULL;
		}
		// Check if marked or present.
		if (sys_is_marked_page((uint32) current)) {
			countPages = 0;
			current += PAGE_SIZE;
			virtual_address = current;
			continue;
		}
		++countPages;
		current += PAGE_SIZE;
	}

	uint32 index = ((uint32) virtual_address - USER_HEAP_START) / PAGE_SIZE;
	uint32 totalSize = size;
	allocation_sizes[index] = totalSize;
	if ((virtual_address + ROUNDUP(size, PAGE_SIZE)) > USER_HEAP_MAX) {
		return NULL;
	}
	return (uint32 *)virtual_address;
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
