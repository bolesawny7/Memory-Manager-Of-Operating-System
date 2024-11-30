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
	struct FrameInfo** frames_storage = (struct FrameInfo**)kmalloc(sizeOfFrames);
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
	struct Share* new_shared_obj = (struct Share *)kmalloc(sizeof(struct Share));
	if (new_shared_obj == NULL) return NULL;

	new_shared_obj->ownerID = ownerID;
	strncpy(new_shared_obj->name, shareName, sizeof(new_shared_obj->name) - 1);
	new_shared_obj->name[sizeof(new_shared_obj->name) - 1] = '\0'; // Ensures null-terminated.
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
//
////=========================
//// [4] Create Share Object:
////=========================
//int createSharedObject(int32 ownerID, char* shareName, uint32 size, uint8 isWritable, void* virtual_address)
//{
//	//TODO: [PROJECT'24.MS2 - #19] [4] SHARED MEMORY [KERNEL SIDE] - createSharedObject()
//	//COMMENT THE FOLLOWING LINE BEFORE START CODING
////	panic("createSharedObject is not implemented yet");
//	//Your Code is Here...
//	struct Env* myenv = get_cpu_proc(); //The calling environment
////	cprintf("ownerID: %d\n", ownerID);
//
//	struct Share* existingSharedObject = get_share(ownerID, shareName);
////	cprintf("existingSharedObject: %d\n", existingSharedObject);
//	if (existingSharedObject != NULL)
//		return 0;
////	cprintf("VA: %p \t IsWritable: \%d \n",virtual_address, isWritable);
//	struct Share* createdSharedObject = create_share(ownerID, shareName, size,
//			isWritable);
//
//
//	if (createdSharedObject == NULL) return 0;
//
//	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;
//
////	createdSharedObject->framesStorage = (struct FrameInfo**) kmalloc(numOfFrames * sizeof(struct FrameInfo*));
//	if (createdSharedObject->framesStorage == NULL)
//		return 0;
//
//	struct FrameInfo* CreatingFrameForAllocation = NULL;
//	for (int i = 0; i < numOfFrames; i++) {
//
//		// Allocate a frame
//		int Checking = allocate_frame(&CreatingFrameForAllocation);
//		if (Checking != 0) return 0;
//
//		createdSharedObject->framesStorage[i] = CreatingFrameForAllocation;
//
//		void* va = (void*) ((uint32*) virtual_address + i * PAGE_SIZE);
//		int checkMapping = map_frame(myenv->env_page_directory, CreatingFrameForAllocation, (uint32) va, PERM_WRITEABLE);
//		int perm = createdSharedObject->isWritable ? PERM_WRITEABLE : 0;
////		pt_set_page_permissions(myenv->env_page_directory, (uint32) virtual_address, PERM_MARKED | perm, PERM_PRESENT);
//		pt_set_page_permissions(myenv->env_page_directory, (uint32) va, PERM_MARKED | perm, PERM_PRESENT);
//
//		if (checkMapping != 0){
//			cprintf("FREEING FRAME: %p\n", CreatingFrameForAllocation);
//			free_frame(CreatingFrameForAllocation);
//			return 0;
//		}
//
////		cprintf("%d# created Frame number: %d, deref: %d\n", i, to_frame_number(createdSharedObject->framesStorage[i]), *(uint32 *)va);
//	}
//
//	LIST_INSERT_TAIL(&(AllShares.shares_list), createdSharedObject);
////	cprintf("ID: %d\n", createdSharedObject->ID);
//
////	createdSharedObject->ID &= 0x7FFFFFFF;
////	printFramesStorage(createdSharedObject->framesStorage, numOfFrames);
//	cprintf("Share created: ID = %d, Name = %s, OwnerID = %d, numOfFrames: %d, isWritable: %d\n", createdSharedObject->ID, createdSharedObject->name, createdSharedObject->ownerID, numOfFrames, createdSharedObject->isWritable);
//	printShare(createdSharedObject, numOfFrames);
//	return createdSharedObject->ID;
//
////	create_share(ownerID, shareName, size,isWritable);
//}
//
//
////======================
//// [5] Get Share Object:
////======================
//int getSharedObject(int32 ownerID, char* shareName, void* virtual_address)
//{
//	struct Env* myenv = get_cpu_proc(); //The calling environment
//	//TODO: [PROJECT'24.MS2 - #21] [4] SHARED MEMORY [KERNEL SIDE] - getSharedObject()
//	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	//panic("getSharedObject is not implemented yet");
//	//Your Code is Here...
//	struct Share* current_share = get_share(ownerID,shareName);
//	if(current_share == NULL) return E_SHARED_MEM_NOT_EXISTS;
//
////	uint32 pa = kheap_physical_address((uint32) virtual_address);
//	uint32 size = getSizeOfSharedObject(ownerID, shareName);
//
//
//	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;
//	cprintf("Virtual Address deref: %d\n", *(uint32 *)virtual_address);
//
//	struct FrameInfo** framesStorage = current_share->framesStorage;
//
//	for(int i = 0; i < numOfFrames; i++)
//	{
//		struct FrameInfo* frame = framesStorage[i];
//		void* va = (void*) ((uint32*) virtual_address + i * PAGE_SIZE);
////		cprintf("%d# gotten Frame number: %d, deref: %d\n", i, to_frame_number(current_share->framesStorage[i]), *(uint32 *)va);
////
////		uint32* ptr_page_table = NULL;
////		get_page_table(myenv->env_page_directory, (uint32)va, &ptr_page_table);
////
////		uint32 index_page_table = PTX(va);
////		uint32 page_table_entry = ptr_page_table[index_page_table];
////
////		struct FrameInfo* frame = to_frame_info(EXTRACT_ADDRESS(page_table_entry));
////		cprintf("Frame#%d @ Address: %p\n", i, frame);
////		if((uint32)frame != (uint32)framesStorage[i]) continue;
//
//		int perm = current_share->isWritable ? PERM_WRITEABLE : 0;
//
//		if (map_frame(myenv->env_page_directory, frame, (uint32)va, perm) != 0) {
//		        return E_SHARED_MEM_NOT_EXISTS;
//		}
//		pt_set_page_permissions(myenv->env_page_directory, (uint32) va, PERM_MARKED | perm, PERM_PRESENT);
//	}
//	current_share->references++;
//
//	cprintf("Share used: ID = %d, Name = %s, OwnerID = %d, numOfFrames: %d, isWritable: %d\n", current_share->ID, current_share->name, current_share->ownerID, numOfFrames, current_share->isWritable);
//	printShare(current_share, numOfFrames);
//	return current_share->ID;
//
//}
//
////==================================================================================//
////============================== BONUS FUNCTIONS ===================================//
////==================================================================================//
//
////==========================
//// [B1] Delete Share Object:
////==========================
////delete the given shared object from the "shares_list"
////it should free its framesStorage and the share object itself
//void free_share(struct Share* ptrShare)
//{
//	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [KERNEL SIDE] - free_share()
//	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("free_share is not implemented yet");
//	//Your Code is Here...
//
//}
////========================
//// [B2] Free Share Object:
////========================
//int freeSharedObject(int32 sharedObjectID, void *startVA)
//{
//	//TODO: [PROJECT'24.MS2 - BONUS#4] [4] SHARED MEMORY [KERNEL SIDE] - freeSharedObject()
//	//COMMENT THE FOLLOWING LINE BEFORE START CODING
//	panic("freeSharedObject is not implemented yet");
//	//Your Code is Here...
//
//}

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

//	cprintf("VA: %p \t IsWritable: \%d \n",virtual_address, isWritable);
	struct Share* createdSharedObject = create_share(ownerID, shareName, size, isWritable);

	if (createdSharedObject == NULL) return 0;

	int numOfFrames = ROUNDUP(size, PAGE_SIZE) / PAGE_SIZE;

	if (createdSharedObject->framesStorage == NULL) return 0;

	struct FrameInfo* CreatingFrameForAllocation = NULL;
	for (int i = 0; i < numOfFrames; i++) {

		int Checking = allocate_frame(&CreatingFrameForAllocation);
		if (Checking != 0) return 0;

		createdSharedObject->framesStorage[i] = CreatingFrameForAllocation;
		uint32* va = (uint32*)((uint32) virtual_address + i * PAGE_SIZE);

//		cprintf("%d# created Frame number: %d, deref: %d\n", i, to_frame_number(createdSharedObject->framesStorage[i]), *(uint32 *)va);
//		uint32 pageNumber = ((uint32) va - USER_HEAP_START) / PAGE_SIZE;
//		frames_info_collection[pageNumber] = CreatingFrameForAllocation;

//		int perm = createdSharedObject->isWritable ? PERM_WRITEABLE : 0;

		int checkMapping = map_frame(myenv->env_page_directory, CreatingFrameForAllocation, (uint32) va, PERM_WRITEABLE | PERM_USER | PERM_PRESENT);

		if (checkMapping != 0){
			cprintf("FREEING FRAME: %p\n", CreatingFrameForAllocation);
			free_frame(CreatingFrameForAllocation);
			return 0;
		}
//		cprintf("Creating frame @: %p Virtual Address @: %p, DEREFERENCE FRAME: %d, DEREFERENCE VA: %d\n", CreatingFrameForAllocation, va, *CreatingFrameForAllocation, *va);

//		pt_set_page_permissions(myenv->env_page_directory, (uint32) va, PERM_MARKED | perm, PERM_PRESENT);
	}

	acquire_spinlock(&(AllShares.shareslock));
		LIST_INSERT_TAIL(&(AllShares.shares_list), createdSharedObject);
	release_spinlock(&(AllShares.shareslock));

	cprintf("Share created: ID = %d, Name = %s, OwnerID = %d, numOfFrames: %d, isWritable: %d\n", createdSharedObject->ID, createdSharedObject->name, createdSharedObject->ownerID, numOfFrames, createdSharedObject->isWritable);
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
	for(int i = 0; i < numOfFrames; i++)
	{


		struct FrameInfo* frame = framesStorage[i];
		uint32* va = (uint32*)((uint32*) virtual_address + i * PAGE_SIZE);

//		uint32 pageNumber = ((uint32)va - USER_HEAP_START) / PAGE_SIZE;
//		struct FrameInfo* frame_in_arr = frames_info_collection[pageNumber];
//
//		uint32* ptr_page_table = NULL;
//		get_page_table(myenv->env_page_directory, (uint32)va, &ptr_page_table);
//
//		uint32 index_page_table = PTX(va);
//		uint32 page_table_entry = ptr_page_table[index_page_table];
//
//		struct FrameInfo* frame = to_frame_info(EXTRACT_ADDRESS(page_table_entry));
//		cprintf("Frame#%d @ Address: %p\n", i, frame);
//		if(frame_in_arr != frame) continue;

		int perm = current_share->isWritable ? PERM_WRITEABLE : 0;

		if (map_frame(myenv->env_page_directory, frame, (uint32)va, perm | PERM_USER | PERM_PRESENT) != 0) {
			cprintf("FREEING FRAME: %p\n", frame);
			free_frame(frame);
			return E_SHARED_MEM_NOT_EXISTS;
		}
//		frame->references++;
//		*(uint32 *)frame = *va;
//		cprintf("Fetching frame @: %p Virtual Address @: %p, DEREFERENCE FRAME: %d, DEREFERENCE VA: %d\n", frame, va, *frame, *va);
//		pt_set_page_permissions(myenv->env_page_directory, (uint32) va, PERM_MARKED | perm, PERM_PRESENT);
	}
	current_share->references++;

	cprintf("Share used: ID = %d, Name = %s, OwnerID = %d, numOfFrames: %d, isWritable: %d\n", current_share->ID, current_share->name, current_share->ownerID, numOfFrames, current_share->isWritable);
//	printShare(current_share, numOfFrames);
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
