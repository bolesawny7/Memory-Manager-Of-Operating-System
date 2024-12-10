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

struct FrameInfo* frames_info_collection[PAGE_SIZE/4];

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

void printShare(struct Share *share, int numOfFrames) {
    if (share == NULL) {
        cprintf("Share object is NULL.\n");
        return;
    }

    cprintf("===============================================\n");
    cprintf("Share Object Details:\n");
    cprintf("===============================================\n");
    cprintf("ID:\t\t\t%d\n", share->ID);
    cprintf("Owner ID:\t\t%d\n", share->ownerID);
    cprintf("Name:\t\t\t%s\n", share->name);
    cprintf("Size:\t\t\t%d\n", share->size);
    cprintf("References:\t\t%d\n", share->references);
    cprintf("Writable:\t\t%s\n", share->isWritable ? "Yes" : "No");
    cprintf("Frames Storage Address:\t%p\n", share->framesStorage);

//    cprintf("Linked List Info:\n");
//    cprintf("\tPrevious:\t%p\n", share->prev_next_info.prev);
//    cprintf("\tNext:\t\t%p\n", share->prev_next_info.next);

    cprintf("===============================================\n");
    cprintf("Frames Storage Details:\n");
    cprintf("===============================================\n");
    cprintf("Frame Address\t\tFrame References\n");
    cprintf("-----------------------------------------------\n");

    if (share->framesStorage == NULL || numOfFrames <= 0) {
        cprintf("No frames to display.\n");
    } else {
    	cprintf("numOfFrames: %d\n", numOfFrames);
        for (int i = 0; i < numOfFrames; i++) {
            struct FrameInfo *frame = share->framesStorage[i];
            if (frame != NULL) {
                cprintf("%p\t\t%d\n", frame, frame->references);
            } else {
                cprintf("NULL\t\t\t-\n");
            }
        }
    }

    cprintf("===============================================\n\n");
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
	acquire_spinlock(&(AllShares.shareslock));
	struct FrameInfo** frames_storage = (struct FrameInfo**)kmalloc(sizeOfFrames);
	release_spinlock(&(AllShares.shareslock));
	if (frames_storage == NULL) return NULL;

//	for (int i = 0; i < numOfFrames; i++) {
//		frames_storage[i] = NULL;
//	}
	memset(frames_storage, 0, sizeOfFrames);


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
	acquire_spinlock(&(AllShares.shareslock));
	struct Share* new_shared_obj = (struct Share *)kmalloc(sizeof(struct Share));
	release_spinlock(&(AllShares.shareslock));
	if (new_shared_obj == NULL) return NULL;

	new_shared_obj->ownerID = ownerID;
	strncpy(new_shared_obj->name, shareName, sizeof(new_shared_obj->name) - 1);
	new_shared_obj->name[sizeof(new_shared_obj->name) - 1] = '\0'; // Ensures null-terminated.
	new_shared_obj->size = size;
	new_shared_obj->references = 1;
	new_shared_obj->isWritable = isWritable;
//	new_shared_obj->ID = (uint32)new_shared_obj & 0x7FFFFFFF;

	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;
	new_shared_obj->framesStorage = create_frames_storage(numOfFrames);
	if (new_shared_obj->framesStorage == NULL) {
		// NULL if framesStorage creation failed.
		acquire_spinlock(&(AllShares.shareslock));
		kfree(new_shared_obj);
		release_spinlock(&(AllShares.shareslock));
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
	//aquire
	acquire_spinlock(&(AllShares.shareslock));
	LIST_FOREACH(share_itr, &(AllShares.shares_list)){
		if(share_itr->ownerID == ownerID && strcmp(share_itr->name, name) == 0){
			// release
			release_spinlock(&(AllShares.shareslock));
			return share_itr;
		}
	}
	//release
	release_spinlock(&(AllShares.shareslock));

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

	struct Share* existingSharedObject = get_share(ownerID, shareName);
	if (existingSharedObject != NULL) return 0;

	struct Share* createdSharedObject = create_share(ownerID, shareName, size, isWritable);
	if (createdSharedObject == NULL) return 0;
	createdSharedObject->ID = (int32)virtual_address & 0x7FFFFFFF;

	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;

	if (createdSharedObject->framesStorage == NULL) return 0;

	struct FrameInfo* CreatingFrameForAllocation = NULL;
	for (int i = 0; i < numOfFrames; i++) {

		int Checking = allocate_frame(&CreatingFrameForAllocation);
		if (Checking != 0) return 0;

		createdSharedObject->framesStorage[i] = CreatingFrameForAllocation;
		uint32* va = (uint32*)((uint32) virtual_address + i * PAGE_SIZE);

		int checkMapping = map_frame(myenv->env_page_directory, CreatingFrameForAllocation, (uint32) va, PERM_WRITEABLE | PERM_USER | PERM_PRESENT);

		if (checkMapping != 0){
			cprintf("FREEING FRAME: %p\n", CreatingFrameForAllocation);
			free_frame(CreatingFrameForAllocation);
			return 0;
		}
//		cprintf("Creating frame @: %p Virtual Address @: %p, DEREFERENCE FRAME: %d, DEREFERENCE VA: %d\n", CreatingFrameForAllocation, va, *CreatingFrameForAllocation, *va);
	}

	acquire_spinlock(&(AllShares.shareslock));
		LIST_INSERT_TAIL(&(AllShares.shares_list), createdSharedObject);
	release_spinlock(&(AllShares.shareslock));

//	cprintf("Share created: ID = %d, Name = %s, OwnerID = %d, numOfFrames: %d, isWritable: %d\n", createdSharedObject->ID, createdSharedObject->name, createdSharedObject->ownerID, numOfFrames, createdSharedObject->isWritable);
//	printShare(createdSharedObject, numOfFrames);
	return createdSharedObject->ID;
}

//======================
// [5] Get Share Object:
//======================
int getSharedObject(int32 ownerID, char* shareName, void* virtual_address)
{
    struct Env* myenv = get_cpu_proc(); //The calling environment
    //TODO: [PROJECT'24.MS2 - #21] [4] SHARED MEMORY [KERNEL SIDE] - getSharedObject()
    //COMMENT THE FOLLOWING LINE BEFORE START CODING
    //panic("getSharedObject is not implemented yet");
    //Your Code is Here...
    struct Share* current_share = get_share(ownerID,shareName);
    if(current_share == NULL) return E_SHARED_MEM_NOT_EXISTS;

    uint32 size = getSizeOfSharedObject(ownerID, shareName);

    int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;

    struct FrameInfo** framesStorage = current_share->framesStorage;
    uint32 va = (uint32)virtual_address;
	for(int i = 0; i < numOfFrames; i++)
	{
		struct FrameInfo* frame = framesStorage[i];

		if (current_share->isWritable == 1) {
			map_frame(myenv->env_page_directory, frame, (uint32)va, PERM_WRITEABLE | PERM_USER | PERM_PRESENT);
		}
		else {
			map_frame(myenv->env_page_directory, frame, (uint32)va,  PERM_USER | PERM_PRESENT);
		}
		va += PAGE_SIZE;
//            cprintf("Fetching frame @: %p Virtual Address @: %p, DEREFERENCE FRAME: %d, DEREFERENCE VA: %d\n", frame, va, *frame, *va);
	}
	acquire_spinlock(&(AllShares.shareslock));
    current_share->references++;
    release_spinlock(&(AllShares.shareslock));

//    cprintf("Share used: ID = %d, Name = %s, OwnerID = %d, numOfFrames: %d, isWritable: %d\n", current_share->ID, current_share->name, current_share->ownerID, numOfFrames, current_share->isWritable);
//    printShare(current_share, numOfFrames);
    return (int)((uint32) virtual_address & 0x7FFFFFFF);

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
//	cprintf("Freeing Share..\n");
	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [KERNEL SIDE] - free_share()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("free_share is not implemented yet");
	//Your Code is Here...
	if(ptrShare == NULL) return;
	acquire_spinlock(&(AllShares.shareslock));
	kfree(ptrShare->framesStorage);
	kfree(ptrShare);
	LIST_REMOVE(&(AllShares.shares_list), ptrShare);
	release_spinlock(&(AllShares.shareslock));
	tlbflush();
}
//========================
// [B2] Free Share Object:
//========================
int freeSharedObject(int32 sharedObjectID, void *startVA)
{
	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [KERNEL SIDE] - freeSharedObject()
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("freeSharedObject is not implemented yet");
	//Your Code is Here...
	struct Env* myenv = get_cpu_proc();

	struct Share* current_share;
	// Searches for the share object.
	acquire_spinlock(&(AllShares.shareslock));
	LIST_FOREACH(current_share, &(AllShares.shares_list)){
		if(current_share->ID == sharedObjectID){
			break;
		}
	}
	release_spinlock(&(AllShares.shareslock));

	// If Share is null return.
	if (current_share == NULL) {
		cprintf("Current Share Not Found..\n");
		return -1;
	}

	int numOfFrames = ROUNDUP(current_share->size, PAGE_SIZE) / PAGE_SIZE;
//	printShare(current_share, numOfFrames);

//	acquire_spinlock(&(AllShares.shareslock));
//	cprintf("BEFORE\n");
//	printShare(current_share, numOfFrames);
//	cprintf("AFTER\n");
//	current_share->references--;
//	release_spinlock(&(AllShares.shareslock));

	struct FrameInfo** framesStorage = current_share->framesStorage;
	// If references of share still bigger than 0 then just return.
	uint32 va = (uint32)startVA;
	if(current_share->references > 0){
		acquire_spinlock(&(AllShares.shareslock));
//		cprintf("Share references decreased..\n");
		for (int i = 0; i < numOfFrames; i++) {
			if (framesStorage[i] != NULL) {
				cprintf("UNMAPPING FRAME..\n");
				unmap_frame(myenv->env_page_directory, (uint32)va);
			}

			// Check if page table size is 0 then free the table first.
			uint32* page_table;
			if (get_page_table(myenv->env_page_directory, va, &page_table) == TABLE_IN_MEMORY) {
				// Check if the page table has any present entries.
				if (is_page_table_empty(page_table)) {
					// Free the page table if it is empty.
					kfree(page_table);
				}
			}
			va += PAGE_SIZE;

		}
		release_spinlock(&(AllShares.shareslock));
		return 0;
	}


	// Looping on the numOfFrames to free the frames and unmap them.
//	cprintf("Before freeing frames: Free frames = %d\n", calculate_available_frames());

	va = (uint32)startVA;
	for (int i = 0; i < numOfFrames; i++) {
		if (framesStorage[i] != NULL) {
			unmap_frame(myenv->env_page_directory, (uint32)va);
			if(framesStorage[i]->references == 0){
				free_frame(framesStorage[i]);
				framesStorage[i] = NULL;
			}
		}

		// Check if page table size is 0 then free the table first.
		uint32* page_table;
		if (get_page_table(myenv->env_page_directory, va, &page_table) == TABLE_IN_MEMORY) {
		    // Check if the page table has any present entries.
		    if (is_page_table_empty(page_table)) {
		        // Free the page table if it is empty.
		        kfree(page_table);
		    }
		}
		va += PAGE_SIZE;

	}
//	cprintf("After freeing frames: Free frames = %d\n", calculate_available_frames());
//	printShare(current_share, numOfFrames);


	free_share(current_share);

	return 0;
}



bool is_page_table_empty(uint32* page_table) {
    for (int i = 0; i < 1024; i++) {
        if (page_table[i] & PERM_PRESENT) {
            return 0;
        }
    }
    return 1;
}
