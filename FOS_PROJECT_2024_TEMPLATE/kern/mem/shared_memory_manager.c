#include <inc/memlayout.h>
#include "shared_memory_manager.h"

#include <inc/mmu.h>
#include <inc/error.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/queue.h>
#include <inc/environment_definitions.h>

#include <kern/proc/user_environment.h>
#include <kern/trap/syscall.h>
#include "kheap.h"
#include "memory_manager.h"

//==================================================================================//
//============================== GIVEN FUNCTIONS ===================================//
//==================================================================================//
struct Share* get_share(int32 ownerID, char* name);

//===========================
// [1] INITIALIZE SHARES:
//===========================
//Initialize the list and the corresponding lock
void sharing_init()
{
#if USE_KHEAP
	LIST_INIT(&AllShares.shares_list) ;
	init_spinlock(&AllShares.shareslock, "shares lock");
#else
	panic("not handled when KERN HEAP is disabled");
#endif
}

//==============================
// [2] Get Size of Share Object:
//==============================
int getSizeOfSharedObject(int32 ownerID, char* shareName)
{
	//[PROJECT'24.MS2] DONE
	// This function should return the size of the given shared object
	// RETURN:
	//	a) If found, return size of shared object
	//	b) Else, return E_SHARED_MEM_NOT_EXISTS
	//
	struct Share* ptr_share = get_share(ownerID, shareName);
	if (ptr_share == NULL)
		return E_SHARED_MEM_NOT_EXISTS;
	else
		return ptr_share->size;

	return 0;
}

//===========================================================


//==================================================================================//
//============================ REQUIRED FUNCTIONS ==================================//
//==================================================================================//
//===========================
// [1] Create frames_storage:
//===========================
// Create the frames_storage and initialize it by 0
inline struct FrameInfo** create_frames_storage(int numOfFrames)
{
	//TODO: [PROJECT'24.MS2 - #16] [4] SHARED MEMORY - create_frames_storage()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("create_frames_storage is not implemented yet");
	//Your Code is Here...
	if(numOfFrames <= 0) return NULL;

	int sizeOfFrames = numOfFrames * sizeof(struct FrameInfo*);
	struct FrameInfo** frames_storage = (struct FrameInfo**)kmalloc(sizeOfFrames);
	if (frames_storage == NULL) return NULL;

	for (int i = 0; i < numOfFrames; i++) {
		frames_storage[i] = NULL;
	}

	return frames_storage;

}

//=====================================
// [2] Alloc & Initialize Share Object:
//=====================================
//Allocates a new shared object and initialize its member
//It dynamically creates the "framesStorage"
//Return: allocatedObject (pointer to struct Share) passed by reference
struct Share* create_share(int32 ownerID, char* shareName, uint32 size, uint8 isWritable)
{
	//TODO: [PROJECT'24.MS2 - #16] [4] SHARED MEMORY - create_share()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("create_share is not implemented yet");
	//Your Code is Here...

	/* Call kmalloc and give it size of the struct Share.
	* Initialize it's members:
	* 	References = 1.
	* 	ID = VA ele rage3 mn el kmalloc and mask MSB with it.
	* Call CreateFramesStorage give it the number of frames.
	*/
	struct Share* new_shared_obj = (struct Share *)kmalloc(sizeof(struct Share));
	if (new_shared_obj == NULL) return NULL;

	new_shared_obj->ownerID = ownerID;
	strncpy(new_shared_obj->name, shareName, sizeof(new_shared_obj->name) - 1);
	new_shared_obj->size = size;
	new_shared_obj->references = 1;
	new_shared_obj->isWritable = isWritable;
	new_shared_obj->ID = (uint32)new_shared_obj & 0x7FFFFFFF;

	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;
	new_shared_obj->framesStorage = create_frames_storage(numOfFrames);
	if (new_shared_obj->framesStorage == NULL) {
		// NULL if framesStorage creation failed.
		kfree(new_shared_obj);
		return NULL;
	}

	return new_shared_obj;
}

//=============================
// [3] Search for Share Object:
//=============================
//Search for the given shared object in the "shares_list"
//Return:
//	a) if found: ptr to Share object
//	b) else: NULL
struct Share* get_share(int32 ownerID, char* name)
{
	//TODO: [PROJECT'24.MS2 - #17] [4] SHARED MEMORY - get_share()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("get_share is not implemented yet");
	//Your Code is Here...
	if(&(AllShares.shares_list).size == 0) return NULL;

	struct Share* share_itr;

	LIST_FOREACH(share_itr, &(AllShares.shares_list)){
		if(share_itr->ownerID == ownerID && strcmp(share_itr->name, name) == 0)
			return share_itr;
	}

	return NULL;
}

//=========================
// [4] Create Share Object:
//=========================
int createSharedObject(int32 ownerID, char* shareName, uint32 size, uint8 isWritable, void* virtual_address)
{
	//TODO: [PROJECT'24.MS2 - #19] [4] SHARED MEMORY [KERNEL SIDE] - createSharedObject()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("createSharedObject is not implemented yet");
	//Your Code is Here...
	struct Env* myenv = get_cpu_proc(); //The calling environment
	cprintf("ownerID: %d\n", ownerID);
	struct Share* existingSharedObject = get_share(ownerID, shareName);
	cprintf("existingSharedObject: %d\n", existingSharedObject);
	if (existingSharedObject != NULL)
		return 0;

	struct Share* createdSharedObject = create_share(ownerID, shareName, size,
			isWritable);
	if (createdSharedObject == NULL)
		return 0;

	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;
//	cprintf("size %d\n",size);
//	cprintf("num of frames %d\n",numOfFrames) ;

//	createdSharedObject->framesStorage = (struct FrameInfo**) kmalloc(numOfFrames * sizeof(struct FrameInfo*));
	if (createdSharedObject->framesStorage == NULL)
		return 0;

	for (int i = 0; i < numOfFrames; i++) {
		struct FrameInfo* CreatingFrameForAllocation = NULL;

		// Allocate a frame
		int Checking = allocate_frame(&CreatingFrameForAllocation);
		if (Checking != 0)
			return 0;

		void* va = (void*) ((uint32*) virtual_address + i * PAGE_SIZE);
		int checkMapping = map_frame(myenv->env_page_directory,CreatingFrameForAllocation, (uint32) va, PERM_WRITEABLE);
		if (checkMapping != 0){
			free_frame(CreatingFrameForAllocation);
			return 0;
		}
		createdSharedObject->framesStorage[i] = CreatingFrameForAllocation;
	}

	LIST_INSERT_TAIL(&(AllShares.shares_list), createdSharedObject);
	cprintf("ID: %d\n", createdSharedObject->ID);

//	createdSharedObject->ID &= 0x7FFFFFFF;
	return createdSharedObject->ID;

//	create_share(ownerID, shareName, size,isWritable);
}


//======================
// [5] Get Share Object:
//======================
int getSharedObject(int32 ownerID, char* shareName, void* virtual_address)
{
	//TODO: [PROJECT'24.MS2 - #21] [4] SHARED MEMORY [KERNEL SIDE] - getSharedObject()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	panic("getSharedObject is not implemented yet");
	//Your Code is Here...

	struct Env* myenv = get_cpu_proc(); //The calling environment
}

//==================================================================================//
//============================== BONUS FUNCTIONS ===================================//
//==================================================================================//

//==========================
// [B1] Delete Share Object:
//==========================
//delete the given shared object from the "shares_list"
//it should free its framesStorage and the share object itself
void free_share(struct Share* ptrShare)
{
	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [KERNEL SIDE] - free_share()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	panic("free_share is not implemented yet");
	//Your Code is Here...

}
//========================
// [B2] Free Share Object:
//========================
int freeSharedObject(int32 sharedObjectID, void *startVA)
{
	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [KERNEL SIDE] - freeSharedObject()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	panic("freeSharedObject is not implemented yet");
	//Your Code is Here...

}
