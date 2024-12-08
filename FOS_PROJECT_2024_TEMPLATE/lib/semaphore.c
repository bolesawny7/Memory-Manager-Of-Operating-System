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

	if(&(sem->queue) != NULL)
	{
		LIST_INIT(&(sem->queue));
	}
//	init_queue(&semQueue);
//	sem->queue = semQueue;

	newsem.semdata = sem;
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
//	struct spinlock *wait_lk;
//	/* Don't use:
//	 * get_cpu_proc()
//	 * init_spinlock()
//	 * acquire_spinlock()
//	 * enqueue()
//	 * release_spinlock()
//	 */
//    struct Env* currentProcess = get_cpu_proc();
//
//	char name[] = "lock_wait";
//	init_spinlock(wait_lk, name);
//	acquire_spinlock(wait_lk);
////	int keyw = 1;
////	do xchg(&keyw, &(sem.semdata->lock)) while (keyw != 0);
//	sem.semdata->count--;
//	if(sem.semdata->count < 0)
//	{
//		enqueue(sem.semdata->queue, currentProcess);
//		currentProcess->env_status = ENV_BLOCKED;
//		sem.semdata->lock = 0;
//	}
//	release_spinlock(wait_lk);
}

void signal_semaphore(struct semaphore sem)
{
	//TODO: [PROJECT'24.MS3 - #05] [2] USER-LEVEL SEMAPHORE - signal_semaphore
	//COMMENT THE FOLLOWING LINE BEFORE START CODING
	//panic("signal_semaphore is not implemented yet");
	//Your Code is Here...
}

int semaphore_count(struct semaphore sem)
{
	return sem.semdata->count;
}
