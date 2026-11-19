Last class, we discussed inter-process communication (IPC): how separate processes communicate, including through a client server model using sockets.
- This class looks more closely at how the OS makes that interaction work.

As we said in the last class, after the client process sends a request, it then 'waits' for a response, or when the server process listens for requests, and 'sleep' when there are no requests, and then 'wake up' when one arrives.
- This leads us into the lifecycle of a process or thread. Now we will examine how they transition between these states and how the OS saves and restores their state to switch execution between them.


The state of a process/thread can be described as such:

![[Screenshot 2026-10-02 at 2.55.11 PM.jpg|500]]

|State|Meaning|
|---|---|
|New|The process/thread is being created.|
|Ready|The process/thread is waiting to run on the CPU.|
|Running|Its instructions are being executed.|
|Waiting|The process/thread is waiting for an event to occur.|
|Terminated|The process/thread has finished execution.|


How the processes change state is all through scheduling, as seen in this image:

![[Screenshot 2026-10-02 at 3.00.17 PM.jpg|500]]

We can see that beyond just a ready queue for using the CPU, there's multiple other routes which a process can take.

Whenever it requires an IO, it gives up the CPU and goes inside an I/O queue, and then goes back to the ready queue, or when an interrupt occurs, it goes back to the ready queue.
- Scheduling is a very detailed problem, we will get into this later

---

## Context Switching

 How do we even run 1 thread? How do we switch between threads?
 

You probably know the answer at this point... you load it's state, and jump the program counter to it's code.

Then, there two ways the OS gets control of the CPU back after starting a thread

|Event|What happens|Examples|
|---|---|---|
|Internal|The thread voluntarily gives up the CPU.|Calling `yield()`, blocking on I/O, or waiting for another thread.|
|External|An interrupt makes the CPU enter the kernel, even though the thread didn’t give up control.|A timer interrupt or a device interrupt.|

Once the OS has control again, it can choose another thread to run.


In code of `pthreads` for internal events, it goes something like this.

1. Suppose thread A is running.
2. A calls `pthread_yield()`, telling the OS: “I can still run, but I’ll let another thread have a turn.”
3. The OS saves A’s state and can select another ready thread, B, to run.
4. A stays ready, when the OS selects A again, it resumes just after the `pthread_yield()` call.


Suppose we have a function called `ComputePI`:

```C
ComputePI() {
    while (true) {
        ComputeNextDigit();
        yield();
    }
}
```

The CPU executes these functions in user mode, using the thread’s user stack to hold their call frames.

When `yield()` makes a system call, control enters the kernel and execution switches to this thread’s kernel stack. The kernel’s `kernel_yield()` can then call something like:

```C
run_new_thread() {
    newThread = PickNewThread();
    switch(curThread, newThread);
}
```

Here, the kernel selects another ready thread. `switch()` saves the current thread’s state and restores the selected thread’s state so it can resume execution.


So, what does switch do exactly? Three things:

1. Saves the current thread’s registers, stack pointer, and return address into its thread control block (TCB).
2. Loads those saved values from the next thread’s TCB into the CPU.
3. Executes `return`, using the next thread’s restored stack and return address to resume its execution.

---

## External Events

So far, we have seen how a thread voluntarily gives up the CPU by calling `yield()`. The same switching mechanism also lets a thread wait for I/O. 
- These are internal events: the thread gives up control of the CPU to the kernel through its own execution.

But what if a thread never gives up control? Suppose it is malicious and just keeps mining Bitcoin on your machine without ever yielding or waiting. 
- The OS must have a built-in mechanism to regain control of the CPU, even without the thread’s cooperation, called external events.


An idea of such an external event is a timed interrupt, after every x seconds, the process is forced to interrupt and control is returned to the kernel, which launches a new thread afterward (could just be continuing the thread we just ran).

![[Screenshot 2026-10-02 at 11.24.17 PM.jpg|200]]

```C
TimerInterrupt() {
    DoPeriodicHouseKeeping();
    run_new_thread();
}
```


---

## Thread Control Blocks

Whether control returns through `yield()`, blocking on I/O, or a timer interrupt, the kernel can use `switch()` to change which thread runs.

But where does it save the current thread’s state, and where does it find the next thread’s state?

The kernel keeps a Thread Control Block (TCB) for each thread. It records information such as the thread’s saved registers, stack pointer, and where execution should resume.

When switching threads, the kernel saves the current thread’s CPU state into its TCB and restores the selected thread’s state from its TCB.


---

### Starting a New Thread

So far, this explains how we resume a thread that has already been running. Its TCB holds the state saved when it last gave up the CPU.

But what about a brand-new thread? It has never run, so there is no previous state to restore.

The kernel prepares a starting state for the new thread. It allocates its stacks and fills in its TCB so that:
- The saved stack pointer points to its prepared stack.
- The saved return address points to a startup function called `ThreadRoot`.


The kernel then puts the thread in the ready queue. When the scheduler selects it, `switch()` loads this prepared state just as it would restore an existing thread’s state.

However, this time, the `return` from `switch()` takes execution to the beginning of `ThreadRoot`. That function performs startup work and starts the function this thread was created to execute.

This lets the same switching mechanism both resume existing threads and start new ones.


---

## Correctness of Concurrent Threads

Moving on from threads and interrupts, we already see some problems with this execution model.

The scheduler can run threads in any order (to some scheduling algorithm), and the scheduler can switch threads at any time (to either internal events or external events), and we had threads that talk to each other...
- this seems like a nightmare to debug and keep track whaat can go wrong in the code

To understand concurrent programs, we need to know what the underlying indivisible operations are.

We call these operations atomic operations, an operation that always runs to completion or doesn't run at all.
- It is indivisible with respect to other threads: they cannot observe or interfere with its intermediate state, so the operation appears to happen as one complete step.


To make operations on shared data atomic, we use locks. The idea is that:
- You lock before entering the critical section and accessing shared data.
- You unlock when leaving, after accessing shared data.
- You wait if the lock is already held.

Locks themselves provide two atomic operations:
- `acquire(mylock)`: waits until the lock is free, then marks it as busy.
    - After this returns, we say the calling thread holds the lock.

- `release(mylock)`: marks the lock as free. It should only be used by the thread holding the lock.
    - After this returns, the calling thread no longer holds the lock.

(This should be review guys)


We fix concurrency issues by identifying critical sections where we need atomic instruction sequences and adding locks.

```C
Deposit(acctId, amount) {
    acquire(&mylock)  // Wait if someone else in critical section!
    acct = GetAccount(actId);
    acct->balance += amount;
    StoreAccount(acct);
    release(&mylock)  // Release someone into critical section
}
```

So as we can see, only 1 thread is allowed to run this critical section at 1 time.

![[Screenshot 2026-10-03 at 12.48.18 AM.jpg|500]]

---

## Why Locks Aren't Enough

He ran out of time in class lol, and therefore we have a supplemental class for this class's topic.

Locks protect shared data by allowing one thread into a critical section at a time, but that might not be enough.
- Look at the producer consumer example, holding the lock gives exclusive access to the buffer, but the operation’s condition must also be satisfied:
	- producer: there must be an empty slot.
	- consumer: there must be an available item.

While waiting for that condition, they must let the other thread access the buffer so it can make the condition true. That leads to semaphores, which help coordinate that waiting and waking.


Let's first understand the buffer's data structure, which simply is just a circular queue.

```C
typedef struct buf {
    int write_index;
    int read_index;
    <type> *entries[BUFSIZE];
} buf_t;
```

The buffer is a circular queue:
- `entries` stores the items.
- `write_index` identifies the next position to insert into.
- `read_index` identifies the next position to remove from.
- Both indices wrap around when they reach the end of the array.

However, operating on this shared buffer raises several questions:
1. How do we tell whether it is full before inserting, or empty before removing?
2. What should the producer or consumer do when it cannot proceed?
3. Which steps need to happen atomically so other threads cannot interfere?


Well, if we think simply about the enqueue/dequeue operation, it should look something like this:

1. acquire the lock
2. while the buffer is full/empty, wait for slot to insert into/slot to read from
3. insert the item/read the item
4. release the lock


The main problem is waiting while still holding the lock, called a deadlock.

- For example, the consumer acquires the lock but finds the buffer empty, so it loops indefinitely while waiting for an item. The producer needs that same lock to insert an item, but the consumer continues holding it.

- The consumer cannot proceed until the producer inserts something, and the producer cannot proceed until the consumer releases the lock, neither can make progress.

![[Screenshot 2026-10-03 at 2.33.06 PM.jpg|500]]


So, the next idea is to release and reacquire the lock inside the waiting loop:

1. Acquire the lock.
2. While the buffer is full/empty:
    - Release the lock.
    - Reacquire it and check again.
3. Insert/remove the item.
4. Release the lock.

Releasing gives the other thread a chance to change the buffer, and this avoids holding the lock indefinitely.

But it still wastes CPU time repeatedly checking, so, can the thread sleep until it can proceed, instead of repeatedly checking and wasting CPU time?
- That's something semaphores solve


that remaining problem motivates semaphores.

![[Screenshot 2026-10-03 at 3.38.17 PM.jpg|500]]

---

## Semaphores

A semaphore tracks available resources:

- `P` / down: an atomic operation that waits wait until its value is positive, then decrement it by 1
	- think this similar to the `wait()` of a lock
- `V` / up: an atomic operation that increment the semaphore value by 1, and wake a waiting thread if there is one.
	- think of this similar to the `signal()` operation

So how to use it? It depends on the initial value of the semaphore.


1. Mutual Exclusion: Initial Value = 1

Here, the semaphore acts like a lock:

1. A thread calls `P`, changing the value from `1` to `0`, and enters the critical section.
2. Other threads calling `P` must wait while the value is `0`.
3. When the thread leaves, it calls `V`, allowing another thread to enter.
    

```C
semaP(&mysem);
// Critical section goes here
semaV(&mysem);
```

So, it looks very much like a lock.


2. Waiting for an Event: Initial Value = 0

Setting the semaphore’s initial value to `0` allows Thread 1 to wait for a signal from Thread 2. When a given event occurs, Thread 2 calls `V`, making Thread 1 ready to run. The OS scheduler then decides when Thread 1 actually runs.


```C
// Initial value of semaphore = 0
ThreadJoin {
    semaP(&mysem);
}
ThreadFinish {
    semaV(&mysem);
}
```

1. Thread 1 calls `ThreadJoin`. Its `P` finds the semaphore at `0`, so Thread 1 sleeps.
2. Thread 2 continues working. When it finishes, it calls `ThreadFinish`.
3. `V` increments the semaphore and wakes Thread 1.
4. When scheduled, Thread 1 completes `P`, decrementing the value back to `0`, and returns from `ThreadJoin`.
