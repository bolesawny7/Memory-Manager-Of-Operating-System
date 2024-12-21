// User-level Semaphore

#include "inc/lib.h"

struct semaphore create_semaphore(char *semaphoreName, uint32 value)
{
	//TODO: [PROJECT'24.MS3 - #02] [2] USER-LEVEL SEMAPHORE - create_semaphore
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	//panic("create_semaphore is not implemented yet");
	uint32 size = sizeof(struct __semdata);
	struct Env_Queue semQueue;
	struct semaphore newsem;
	struct __semdata* sem = (struct __semdata *)smalloc(semaphoreName, size, 1);
	if(sem == NULL)
		return newsem;
	strcpy(sem->name, semaphoreName);
	sem->count = value;
	sem->lock = 0;
	newsem.semdata = sem;
	sys_QueueOperations(&newsem, 3);

	return newsem;
}
struct semaphore get_semaphore(int32 ownerEnvID, char* semaphoreName)
{
	//TODO: [PROJECT'24.MS3 - #03] [2] USER-LEVEL SEMAPHORE - get_semaphore
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	//panic("get_semaphore is not implemented yet");
	//Your Code is Here...
	struct semaphore sem;
	struct __semdata * SemaphoreFound = (struct __semdata *)sget(ownerEnvID, semaphoreName);
	if (SemaphoreFound == NULL)
		return sem;
	sem.semdata = SemaphoreFound;
	return sem;
}

void wait_semaphore(struct semaphore sem)
{
	//[PROJECT'24.MS3]
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	//panic("wait_semaphore is not implemented yet");
	//Your Code is Here...
	while(xchg(&sem.semdata->lock, 1) != 0) ;
//	cprintf("Initialized done!");
	sem.semdata->count--;
	if(sem.semdata->count < 0)
	{
//		cprintf("Inside if!\n");
		sys_QueueOperations(&sem,1);
//		cprintf("after the sys_queueOperations case 1!\n");

	}
	sem.semdata->lock = 0;
//	cprintf("after if\n");
	//done wait!

}



void signal_semaphore(struct semaphore sem)
{
	//TODO: [PROJECT'24.MS3 - #05] [2] USER-LEVEL SEMAPHORE - signal_semaphore
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	//panic("signal_semaphore is not implemented yet");
	//Your Code is Here...

		while(xchg(&sem.semdata->lock, 1) != 0) ;
//		cprintf("Initialized and acquired Signal \n");
		sem.semdata->count++;
		if(sem.semdata->count <= 0)
		{
//			cprintf("inside if of signal");
			sys_QueueOperations(&sem, 2);
		}
		sem.semdata->lock = 0 ;

}

int semaphore_count(struct semaphore sem)
{
	return sem.semdata->count;
}
