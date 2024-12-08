#include "kheap.h"

#include <inc/memlayout.h>
#include <inc/dynamic_allocator.h>
#include "memory_manager.h"

#define Mega  (1024*1024)
#define kilo (1024)

#define DYNAMIC_ALLOCATOR_DS 0 //ROUNDUP(NUM_OF_KHEAP_PAGES * sizeof(struct MemBlock), PAGE_SIZE)
#define INITIAL_KHEAP_ALLOCATIONS (DYNAMIC_ALLOCATOR_DS) //( + KERNEL_SHARES_ARR_INIT_SIZE + KERNEL_SEMAPHORES_ARR_INIT_SIZE) //
#define INITIAL_BLOCK_ALLOCATIONS ((2*sizeof(int) + MAX(num_of_ready_queues * sizeof(uint8), DYN_ALLOC_MIN_BLOCK_SIZE)) + (2*sizeof(int) + MAX(num_of_ready_queues * sizeof(struct Env_Queue), DYN_ALLOC_MIN_BLOCK_SIZE)))
#define ACTUAL_START ((KERNEL_HEAP_START + DYN_ALLOC_MAX_SIZE + PAGE_SIZE) + INITIAL_KHEAP_ALLOCATIONS)

#define KERNEL_HEAP_ARRAY_SIZE ((KERNEL_HEAP_MAX - KERNEL_HEAP_START) / PAGE_SIZE)
uint32 allocation_sizes[KERNEL_HEAP_ARRAY_SIZE];
uint32 FramesToPagesK[KERNEL_HEAP_ARRAY_SIZE];

// index calculation => (va-KERNEL_HEAP_START)/PAGE_SIZE

//Initialize the dynamic allocator of kernel heap with the given start address, size & limit
//All pages in the given range should be allocated
//Remember: call the initialize_dynamic_allocator(..) to complete the initialization
//Return:
//	On success: 0
//	Otherwise (if no memory OR initial size exceed the given limit): PANIC
//initialize_kheap_dynamic_allocator(KERNEL_HEAP_START, PAGE_SIZE, KERNEL_HEAP_START + DYN_ALLOC_MAX_SIZE);
int initialize_kheap_dynamic_allocator(uint32 daStart, uint32 initSizeToAllocate, uint32 daLimit)
{
	//TODO: [PROJECT'24.MS2 - #01] [1] KERNEL HEAP - initialize_kheap_dynamic_allocator
	// Write your code here, remove the panic and write your code
	//panic("initialize_kheap_dynamic_allocator() is not implemented yet...!!");

	// initialize values
	khStart = (uint32 *)daStart;
	sBreak = (uint32 *)ROUNDUP((daStart + initSizeToAllocate), PAGE_SIZE);
	khLimit = (uint32 *)daLimit;

	if ((uint32)sBreak > daLimit) {
		panic("Size exceeded limit.");
	}
	// pointer for current address
	uint32 *ptr_current = khStart;

	while(ptr_current < sBreak){
		struct FrameInfo *frame = NULL;
		if (allocate_frame(&frame) != 0) {
			panic("NO memory!!!");
		}
		int r = map_frame(ptr_page_directory, frame, (uint32)ptr_current, PERM_WRITEABLE);
		if (r == E_NO_MEM)
		{
			panic(" Failed to map !! ");
		}
		uint32 index = to_frame_number(frame);
		FramesToPagesK[index] = (uint32)ptr_current;

		ptr_current = (uint32 *)((char *)ptr_current + PAGE_SIZE);

	}
//	/* THIS IS NEW */
//	int index = ((uint32)sBreak - KERNEL_HEAP_START)/PAGE_SIZE;
//	uint32 totalSize = *sBreak;
//	allocation_sizes[index] = totalSize;
//	/* THIS IS NEW */
//	cprintf("ptr_current: %p\n", ptr_current);
//	cprintf("initialSize: %d\n", initSizeToAllocate);
    initialize_dynamic_allocator(daStart, initSizeToAllocate);

	return 0;
}


void* sbrk(int numOfPages) {
	/* numOfPages > 0: move the segment break of the kernel to increase the size of its heap by the given numOfPages,
	 * 				you should allocate pages and map them into the kernel virtual address space,
	 * 				and returns the address of the previous break (i.e. the beginning of newly mapped memory).
	 * numOfPages = 0: just return the current position of the segment break
	 *
	 * NOTES:
	 * 	1) Allocating additional pages for a kernel dynamic allocator will fail if the free frames are exhausted
	 * 		or the break exceed the limit of the dynamic allocator. If sbrk fails, return -1
	 */
	//MS2: COMMENT THIS LINE BEFORE START CODING==========
	//	//return (void*) -1;
	//	//====================================================
	//	//TODO: [PROJECT'24.MS2 - #02] [1] KERNEL HEAP - sbrk
	//	// Write your code here, remove the panic and write your code
	//	//	panic("sbrk() is not implemented yet...!!");

    uint32 oldSBreak = (uint32)sBreak;

    if (numOfPages > 0) {
        uint32 incrementSize = numOfPages * PAGE_SIZE;

        if ((uint32)sBreak + incrementSize < (uint32)sBreak ||
            (uint32)sBreak + incrementSize > (uint32)khLimit) {
        /* bt2aked en el new sbreak msh m3addeya el khlimit
        * w enaha msh as8ar mn ele ablaha
        */
            return (void*)-1;
        }

        uint32 newBreak = oldSBreak + incrementSize;
        // hnallocate w nmap pages
        cprintf("\n\n\n\nSabaho\n\n\n\n\n");
        for (uint32 va = oldSBreak; va < newBreak; va += PAGE_SIZE) {
            struct FrameInfo* currentFrame = NULL;

            if (allocate_frame(&currentFrame) == E_NO_MEM) {
                return (void*)-1;
            }

            if (map_frame(ptr_page_directory, currentFrame, va, PERM_WRITEABLE) == E_NO_MEM) {
                return (void*)-1;
            }
            uint32 frameNumber = to_frame_number(currentFrame);
			FramesToPagesK[frameNumber] = (uint32)va;
        }
		// 3addel el end block el gdida 5aliha 0x1
		uint32* blockFooter = (uint32*)((uint32)newBreak - sizeof(uint32));
		*blockFooter = 0x1;

//		/* THIS IS NEW */
//		int index = ((uint32)oldSBreak - KERNEL_HEAP_START)/PAGE_SIZE;
//		uint32 totalSize = numOfPages * PAGE_SIZE;
//		allocation_sizes[index] = totalSize;
//		/* THIS IS NEW */

		// 7arak el segmant
		sBreak = (uint32*)newBreak;

	   return (void*)oldSBreak;
    }

    // Ragga3 makan el old sbreak
    else if (numOfPages == 0) {
        return (void*)oldSBreak;
    }

    // Input 8alat (numOfPages as8ar mn 0)
    else {
        return (void*)-1;
    }
}

uint32 * findConsecutivePages(int numOfPages){
	uint32 *virtual_address = (uint32 *)ACTUAL_START;
    int countOfPages = 0;
    uint32 *current_va = virtual_address;
    uint32 *ptr_page_table = NULL;

    while (countOfPages < numOfPages) {
        if (get_frame_info(ptr_page_directory, (uint32)current_va, &ptr_page_table) == 0 &&
        		(uint32)current_va < KERNEL_HEAP_MAX) {
            // va is in the range.
            countOfPages++;
        } else {
            // reset counter and start again.
            countOfPages = 0;
            virtual_address = (uint32*)((uint32)current_va + PAGE_SIZE);
        }
        if ((uint32)current_va >= KERNEL_HEAP_MAX)
            return NULL; // insufficient memory.
        current_va = (uint32 *)((uint32)current_va + PAGE_SIZE);
    }
    return virtual_address;
}

//TODO: [PROJECT'24.MS2 - BONUS#2] [1] KERNEL HEAP - Fast Page Allocator

void* kmalloc(unsigned int size) {
    if (size == 0 || size > (KERNEL_HEAP_MAX - ACTUAL_START))
        return NULL;

    if (size <= DYN_ALLOC_MAX_BLOCK_SIZE) {
        // Block Allocator.
    	// Call ALLOC FF from MS1.
//        cprintf("Allocate in dynamic allocator.\n");
        return (void *)alloc_block_FF(size);
    } else {
        // Page Allocator.
        int numOfPages = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;

        uint32 *virtual_address = findConsecutivePages(numOfPages);

        if (virtual_address == NULL) return NULL;
        uint32 *virtual_address_to_be_returned = virtual_address;

        int r, k;
        struct FrameInfo *ptr_frame_info = NULL;

        // Allocate w map consecutive pages
        for (int i = 0; i < numOfPages; i++) {
            r = allocate_frame(&ptr_frame_info);
            if (r == 0) {
                k = map_frame(ptr_page_directory, ptr_frame_info, (uint32)virtual_address,
                		PERM_WRITEABLE);
				uint32 index = to_frame_number(ptr_frame_info);
				FramesToPagesK[index] = (uint32)virtual_address;
            }

            if (k == E_NO_MEM) {
				// free frame w return null.
				free_frame(ptr_frame_info);
				return NULL;
			}
            // Move ll next page and repeat.
            virtual_address = (uint32 *)((uint32)virtual_address + PAGE_SIZE);
        }

        //record allocation size in the array
        uint32 index = ((uint32)virtual_address_to_be_returned - KERNEL_HEAP_START)/PAGE_SIZE;
//        uint32 totalSize = ROUNDUP(size, PAGE_SIZE);
        uint32 totalSize = size;
        allocation_sizes[index] = totalSize;

        return (void *)virtual_address_to_be_returned;
    }
}


void kfree(void* virtual_address)
{
	//TODO: [PROJECT'24.MS2 - #04] [1] KERNEL HEAP - kfree
	// Write your code here, remove the panic and write your code
//	panic("kfree() is not implemented yet...!!");

	//you need to get the size of the given allocation using its address
	//refer to the project presentation and documentation for details

	if (virtual_address == NULL)
	        return;
	uint32 va = (uint32)virtual_address;

	if ((uint32 *)virtual_address >= khStart && (uint32 *)virtual_address < khLimit) {
		free_block(virtual_address);
		return;
	}

	if (va < KERNEL_HEAP_START || va >= KERNEL_HEAP_MAX)
		return;

	uint32 index = (va - KERNEL_HEAP_START) / PAGE_SIZE;

	uint32 size = allocation_sizes[index];
	if (size == 0)
		return;
	int numOfPages = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;

	for (uint32 i = 0; i < numOfPages; i++) {
        uint32 *ptr_page_table = NULL;
        struct FrameInfo* frame = get_frame_info(ptr_page_directory,va,&ptr_page_table);
		unmap_frame(ptr_page_directory, va);
//		if(frame->references == 0)
//			free_frame(frame);
		FramesToPagesK[to_frame_number(frame)] = 0;
		va += PAGE_SIZE;
	}

	allocation_sizes[index] = 0;
}

unsigned int kheap_physical_address(unsigned int virtual_address)
{
	//TODO: [PROJECT'24.MS2 - #05] [1] KERNEL HEAP - kheap_physical_address
	// Write your code here, remove the panic and write your code
//	panic("kheap_physical_address() is not implemented yet...!!");

	//return the physical address corresponding to given virtual_address
	//refer to the project presentation and documentation for details
	//EFFICIENT IMPLEMENTATION ~O(1) IS REQUIRED ==================

	 uint32* ptr_page_table = NULL;
	 struct FrameInfo* frame = get_frame_info(ptr_page_directory,virtual_address,&ptr_page_table);
	 if(ptr_page_table == NULL)
		 return 0;

	 if (frame == NULL) return 0;
	 uint32 offset = virtual_address & 0xFFF;
	 uint32 pa = (uint32)to_physical_address(frame) + offset;
	 return pa;

}

unsigned int kheap_virtual_address(unsigned int physical_address)
{
	//TODO: [PROJECT'24.MS2 - #06] [1] KERNEL HEAP - kheap_virtual_address
	// Write your code here, remove the panic and write your code
//	panic("kheap_virtual_address() is not implemented yet...!!");

	//return the virtual address corresponding to given physical_address
	//refer to the project presentation and documentation for details

	//EFFICIENT IMPLEMENTATION ~O(1) IS REQUIRED ==================
	struct FrameInfo* frame = to_frame_info(physical_address);
	uint32 offset = physical_address & 0xFFF;

	uint32 va = (uint32)FramesToPagesK[to_frame_number(frame)];
	if (va == 0) return 0;

	return va | offset;
}

void freeConsecutivePages(uint32* start_virtual_address, int numOfFreedPages){
	uint32 current_va = (uint32)start_virtual_address;
	uint32 *ptr_page_table = NULL;
	uint32 pageNumber = ((uint32)start_virtual_address - KERNEL_HEAP_START) / PAGE_SIZE;
	for(int i = 0; i < numOfFreedPages; i++){
		// Get the frame.
		struct FrameInfo* frame = get_frame_info(ptr_page_directory, current_va, &ptr_page_table);
		// Unmap it.
		unmap_frame(ptr_page_directory, current_va);

		// Remove the pages virtual addresses from FramesToPages array.
		FramesToPagesK[to_frame_number(frame)] = 0;
		current_va += PAGE_SIZE;
	}
	allocation_sizes[pageNumber] = 0;
}

uint32 * findMoreConsecutivePages(uint32* va, int oldNumOfPages, int diffNumOfPages){
	uint32 *virtual_address = (uint32 *)va;
    int countOfPages = 0;
    uint32 *current_va = (uint32*)((uint32)virtual_address + (oldNumOfPages * PAGE_SIZE));
    uint32 *ptr_page_table = NULL;

    while (countOfPages < diffNumOfPages) {
        if (get_frame_info(ptr_page_directory, (uint32)current_va, &ptr_page_table) == 0 &&
        		(uint32)current_va < KERNEL_HEAP_MAX) {
            // va is in the range.
            countOfPages++;
        } else {
        	/* Couldn't find more pages in the same start address */
            return NULL;
        }
        if ((uint32)current_va >= KERNEL_HEAP_MAX)
            return NULL; // insufficient memory.
        current_va = (uint32 *)((uint32)current_va + PAGE_SIZE);
    }
    return virtual_address;
}

//=================================================================================//
//============================== BONUS FUNCTION ===================================//
//=================================================================================//
// krealloc():

//	Attempts to resize the allocated space at "virtual_address" to "new_size" bytes,
//	possibly moving it in the heap.
//	If successful, returns the new virtual_address, if moved to another loc: the old virtual_address must no longer be accessed.
//	On failure, returns a null pointer, and the old virtual_address remains valid.

//	A call with virtual_address = null is equivalent to kmalloc().
//	A call with new_size = zero is equivalent to kfree().

void *krealloc(void *virtual_address, uint32 new_size)
{
	//TODO: [PROJECT'24.MS2 - BONUS#1] [1] KERNEL HEAP - krealloc
	// Write your code here, remove the panic and write your code
//	return NULL;
//	panic("krealloc() is not implemented yet...!!");

	if(virtual_address == NULL){
//		cprintf("Virtual Address is NULL, Allocating in a new location..\n");
		return kmalloc(new_size);
	}
	if(new_size == 0) {
//		cprintf("Size is equal 0.\n");
		kfree(virtual_address);
		return NULL;
	}
	uint32 pageNumber = ((uint32)virtual_address - KERNEL_HEAP_START) / PAGE_SIZE;

	uint32 old_size = allocation_sizes[pageNumber];

//	cprintf("old size: %d, new size: %d\n", old_size, new_size);

	if (old_size <= DYN_ALLOC_MAX_BLOCK_SIZE) {
	// Old block was found in dynamic allocator.
		if(new_size <= DYN_ALLOC_MAX_BLOCK_SIZE){
			// New block was found in dynamic allocator.
//			cprintf("Old and New blocks in dynamic allocator.\n");
			return realloc_block_FF(virtual_address, new_size);
		}
		// New block was found in page allocator.
		void* new_allocate = kmalloc(new_size);
		if(new_allocate){
//			cprintf("New allocation found in heap.\n");
//			cprintf("Old block in dynamic allocator, New block in page allocator.\n");
			free_block(virtual_address);
			return new_allocate;
		}
		return NULL;
	}
	// Old block was found in page allocator.
	if(old_size > DYN_ALLOC_MAX_BLOCK_SIZE){
//		cprintf("Old block in page alloctor.\n");
		// New block was found in dynamic allocator.
		if(new_size <= DYN_ALLOC_MAX_BLOCK_SIZE){
//			cprintf("New block in dynamic alloctor.\n");
			void* new_allocate = alloc_block_FF(new_size);
			if(new_allocate){
//				cprintf("New allocation found in heap.\n");
//				cprintf("Old block in page allocator, New block in dynamic allocator.\n");
				kfree(virtual_address);
				return new_allocate;
			}
			return NULL;
		}
	}

	// Old & new blocks was found in page allocator.

	int diff_size = new_size - old_size;
//	cprintf("difference in size: %d\n", diff_size);
	int oldNumOfPages = ROUNDUP(old_size, PAGE_SIZE) / PAGE_SIZE;
	int diffNumOfPages = ROUNDUP(diff_size, PAGE_SIZE) / PAGE_SIZE;

	if(diff_size == 0){
		// No Change in size.
//		cprintf("Size is the same.\n");
		return virtual_address;
	}
	else if(diff_size < 0){
		// New size is smaller. Free the rest of the pages.
//		cprintf("New size is smaller than the old size.\n");
		uint32* strt_address_to_free = (uint32*)((uint32)virtual_address + new_size);
		freeConsecutivePages(strt_address_to_free, diffNumOfPages);
		return virtual_address;
	}

	// Now check if we can add more consecutive pages without reallocating the whole block.
//	cprintf("Try adding more consecutive pages in the same address.\n");

	uint32 *extended_virtual_address = findMoreConsecutivePages(virtual_address, oldNumOfPages, diffNumOfPages);
	if(extended_virtual_address == NULL){
//		cprintf("Could't add more consecutive pages in the same address.\n");
		// If not, then free the old blocks and allocate from the beginning. (using first fit)
		void* new_allocate = kmalloc(new_size);
		if(new_allocate){ // If we can allocate the new size in a new location, then free all old pages and return new location.
//			cprintf("New allocation found in heap.\n");
			freeConsecutivePages(virtual_address, oldNumOfPages);
			return new_allocate;
		}
//		cprintf("Couldn't find space for the new size.\n");
		return NULL;
	}


	// Return the same start address if we can add more consecutive pages without reallocating the whole block.
//	cprintf("Added more consecutive pages in the same address successfully.\n");
	return virtual_address;
}
