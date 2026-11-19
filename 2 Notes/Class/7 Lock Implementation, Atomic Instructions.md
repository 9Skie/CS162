Last class, we saw how locks protect shared data and how semaphores let threads wait until they can proceed.

This class first combines those ideas into a working producer–consumer solution.
- Then, we move from using locks to understanding how the OS and hardware actually implement them.

---

## Too Much Milk

The idea that we will use is 'too much milk' to start building this solution, it's a simple coordination problem between people.

Say you got home and saw that the fridge is out of milk, you go out and but the milk. Your roommate, who came back later and also saw the fridge is out of milk, buys milk as well, and so both of you bought milk and that caused too too much milk to be bought.


| Time | Person A                     | Person B                     |
| ---- | ---------------------------- | ---------------------------- |
| 3:00 | Look in fridge. Out of milk. |                              |
| 3:05 | Leave for store.             |                              |
| 3:10 | Arrive at store.             | Look in fridge. Out of milk. |
| 3:15 | Buy milk.                    | Leave for store.             |
| 3:20 | Arrive home, put milk away.  | Arrive at store.             |
| 3:25 |                              | Buy milk.                    |
| 3:30 |                              | Arrive home, put milk away.  |

How do we solve this problem?


Solution 1: Let's use locks!

- Leave a note before buying (lock)
- remove note after buying (unlock)

```C
Thread A                    Thread B

if (noMilk) {               if (noMilk) {
    if (noNote) {               if (noNote) {
        leave Note;                 leave Note;
        buy Milk;                   buy Milk;
        remove Note;                remove Note;
    }                           }
}                           }
```

But, both threads can check `noMilk` and `noNote` before either leaves a note.
1. A sees no milk and no note.
2. The CPU switches to B, which also sees no milk and no note.
3. Both have passed the checks, so both leave a note and buy milk.

Checking for a note and leaving one are separate operations; another thread can run between them.


Solution 2: Let’s use separate, labeled locks!

- Each thread gets it's own labeled note.
- Each leaves its note before checking whether the other thread has left one.

```C
Thread A                    Thread B

leave note A;               leave note B;
if (noNote B) {             if (noNote A) {
    if (noMilk) {               if (noMilk) {
        buy Milk;                   buy Milk;
    }                           }
}                           }
remove note A;              remove note B;
```

For example:
1. A leaves note A and sees no note B, so A starts buying milk.
2. B leaves note B, but sees note A, so B skips buying.

This prevents the previous situation where both passed the checks before either left a note.

But it can still fail, as both leave their notes, both see the other’s note, and both skip buying milk, this is called starvation.


Solution 3: Let's just keep waiting when there's a note!

- Each thread, when it sees that the other thread has left a note, just wait


```C
Thread A                    Thread B

leave note A;               leave note B;
while (note B) {            if (noNote A) {
    do nothing;                 if (noMilk) {
}                                   buy milk;
if (noMilk) {                   }
    buy milk;               }
}                           remove note B;
remove note A;
```

We can see that this works regardless of the order of operations, let's take a look at the 2 cases.

- If A leaves note A before B checks `noNote A`, B skips buying and removes note B. A then stops waiting and buys the milk.

![[Screenshot 2026-10-03 at 5.42.59 PM.jpg|500]]


- If B checks `noNote A` before A leaves its note, B proceeds to buy. A waits while note B exists. Once B removes it, A checks the fridge, finds milk, and skips buying.

![[Screenshot 2026-10-03 at 5.43.42 PM.jpg|500]]

---

## Lock Implementation

All of this work went to just making sure we don't encounter dead/live locks in a simple piece of code:

```C
if (noMilk) {
	buy milk;
}
```

We came up with a while loop for A as a solution, but it's really inefficient, as while A is waiting, it is consuming CPU time, this is called "busy-waiting".

Our target code should look as simple as this:

```C
acquire(milkLock);
if (noMilk) {
    buy milk;
}
release(milkLock);
```

The question becomes: how do we implement `acquire()` and `release()` so only one thread enters, and a waiting thread can sleep instead of wasting CPU time?

On a single CPU/core, this prevents timer interrupts from switching execution to another thread, allowing the current thread to finish the critical section as long as it does not voluntarily yield or block.

How this is achieved is the idea is that we set a global variable lock:
- 
- Acquire:
	1. disable interrupts
	2. if:
		- the lock is busy, put thread on wait queue and let it sleep
		- otherwise, set the lock to busy
	3. resume interrupts

- Release:
	1. disable interrupts
	2. if:
		- if there's any thread on the wait queue, take (?) off the wait queue onto the ready queue
		- otherwise, set the lock to free
	3. resume interrupts

```C
int value = FREE;

Acquire() {                        Release() {
    disable interrupts;                disable interrupts;
    if (value == BUSY) {                if (anyone on wait queue) {
        put thread on wait queue;           take thread off wait queue
        Go to sleep();                      Place on ready queue;
    } else {                            } else {
        value = BUSY;                       value = FREE;
    }                                   }
    enable interrupts;                  enable interrupts;
}                                  }
```


But there's a problem in acquire, when we disable interrupts and put the thread to sleep, there's never a time where we re-enable interrupts after sleeping, so how do we do that?
- Going to sleep causes the scheduler to switch to another ready thread, when this happens, that thread should directly enable interrupts when it starts running.


So the idea is that the outgoing thread disables interrupts, the context switch happens with interrupts disabled, and the incoming thread re-enables them as it resumes.
 - or in other words, whenever sleep wakes up, enable interrupts.

![[Screenshot 2026-10-04 at 6.38.18 PM.jpg|500]]


---

## Example

Consider this example where we have thread A and thread B, thread A is running, and thread B is ready.

![[Screenshot 2026-10-04 at 6.45.26 PM.jpg|500]]


Thread A begins by acquiring the lock:
1. it disables interrupts
2. sees the value is 0
3. sets it to 1
4. it enables interrupts

![[Screenshot 2026-10-05 at 12.05.28 PM.jpg|500]]


Then during the running of the critical section of thread A, a timer interrupt goes off and thread B starts running, thread A is set to ready.

![[Screenshot 2026-10-05 at 12.09.18 PM.jpg|500]]


Thread B tries to acquire the lock:
- it disables interrupts
- sees the value is 1
- goes to sleep
	- it's now in waiting queue

![[Screenshot 2026-10-05 at 12.11.56 PM.jpg|500]]


Control is returned to thread A, which finishes it's critical section, and it gets to releasing the lock:
1. it disables interrupts
2. it checks if there's any thread in the waiting queue
3. yes, thread B exists, so it's placed into the ready queue.
4. enable interrupts

![[Screenshot 2026-10-05 at 12.19.18 PM.jpg|500]]


Since thread A finished, control is given to thread B (which disables interrupts), which wakes up from sleep and continues execution.
1. it enables interrupts
2. it runs it's critical section
3. and then releases it's lock

![[Screenshot 2026-10-05 at 12.26.37 PM.jpg|500]]



That was a lot of work! A lot of work! And it involves repeatedly coming in and outside of the kernel, and this slows the code down a lot.


Just image the amount of context switching just following one thread through one critical section! The lock implementation runs in the kernel, but the thread’s actual work runs in user mode. So the thread must cross between them:

```
User code
    ↓ User → Kernel switch
Kernel acquires the lock
    ↓ Kernel → User switch
User code performs the exclusive work
    ↓ User → Kernel switch
Kernel releases the lock
    ↓ Kernel → User switch
User code continues
```

Recall that system calls are much more expensive than ordinary function calls. The lecture shows an example where a minimal system call costs roughly $25$ times as much; scheduling can add even more overhead.

There are also two problems with disabling interrupts:
- We cannot let user programs disable interrupts directly, because they could prevent the OS from regaining control.
- On a multiprocessor, disabling interrupts on one core does not stop threads on other cores. Coordinating interrupt disabling across cores would be expensive.

The alternative is hardware-supported atomic read-modify-write instructions. They read a value and update it as one indivisible operation, with the hardware enforcing atomicity, which is for another day.