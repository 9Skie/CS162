## Monitors

A monitor combines a lock with condition variables to coordinate access to shared data.

1. The lock protects the data while a thread checks or changes it.
2. If a condition needed to proceed is false, the thread waits on a condition variable, releasing the lock and sleeping. 
3. Another thread changes the data and explicitly signals the condition variable to wake a waiter. 
4. The awakened thread reacquires the lock and checks the condition again before continuing.

---

## Reader Writer Problem

The readers/writers problem is how to allow multiple readers together while ensuring every writer has exclusive access.

Imagine threads sharing a database:
- Readers only read it, so several can read simultaneously.
- Writers change it, so a writer needs exclusive access: no other writers or readers while it writes.

The challenge is to design a synchronization scheme that ensures:
1. Multiple readers can access data together if no writer is writing.
2. Writers have exclusive access no other reader or writer can enter during writing.


Reader:
1. wait until there are no writers
2. access database
3. wake up a waiting writer

Writer:
1. wait until no active readers or writers
2. access database
3. wake up waiting reader or writer


`AR` / `AW` count active readers / writers. 
`WR` / `WW` count waiting readers / writers. 

Reader code: 

```C
Reader() {
    // First check self into system
    acquire(&lock);

    while ((AW + WW) > 0) {             // Is it safe to read?
        WR++;                          // No. Writers exist
        cond_wait(&okToRead, &lock);    // Sleep on cond var
        WR--;                          // No longer waiting
    }

    AR++;                              // Now we are active!
    release(&lock);

    // Perform actual read-only access
    AccessDatabase(ReadOnly);

    // Now, check out of system
    acquire(&lock);
    AR--;                              // No longer active
    if (AR == 0 && WW > 0)              // No other active readers
        cond_signal(&okToWrite);       // Wake up one writer
    release(&lock);
}
```

Roughly, the reader:

1. Acquires the lock to safely check and update the shared counters.
2. If any writer is active or waiting, records itself as waiting and sleeps. `cond_wait` releases the lock while sleeping and reacquires it before returning. The reader then rechecks the condition.
3. When allowed in, increases `AR`, releases the lock, and reads the database. Multiple readers can do this together.
4. When finished, acquires the lock and decreases `AR`. If it is the last active reader and writers are waiting, it signals one writer, then releases the lock.


Writer code:

```C
Writer() {
    // First check self into system
    acquire(&lock);

    while ((AW + AR) > 0) {             // Is it safe to write?
        WW++;                          // No. Active users exist
        cond_wait(&okToWrite, &lock);   // Sleep on cond var
        WW--;                          // No longer waiting
    }

    AW++;                              // Now we are active!
    release(&lock);

    // Perform actual read/write access
    AccessDatabase(ReadWrite);

    // Now, check out of system
    acquire(&lock);
    AW--;                              // No longer active
    if (WW > 0) {                      // Give priority to writers
        cond_signal(&okToWrite);       // Wake up one writer
    } else if (WR > 0) {                // Otherwise, wake reader
        cond_broadcast(&okToRead);     // Wake all readers
    }
    release(&lock);
}
```

Roughly, the writer:

1. Acquires the lock to safely check and update the shared counters.
2. If any reader or writer is active, records itself as waiting and sleeps. As with the reader, waiting releases the lock, and returning reacquires it before the condition is rechecked.
3. When nobody is active, increases `AW`, releases the lock, and accesses the database exclusively. `AW` prevents other readers or writers from entering during this access.
4. When finished, acquires the lock and decreases `AW`. It signals one waiting writer first; otherwise, it wakes all waiting readers because they can read together. Then it releases the lock.


In class, there was a long example running this code with how the code behaves when multiple readers and writers arrive at different times:
- the order is 1 reader, 1 reader, 1 writer, 1 reader

In TLDR:
- `R1` and `R2` read together.
- `W1` waits until both readers finish.
- `R3` waits because `W1` is waiting.
- The last active reader signals `W1`; after writing, `W1` wakes the waiting reader `R3`

---

## The Kernel

The kernel is the core of the operating system that manages hardware resources and provides services to programs. It maintains its own memory and tracks the execution of processes and threads.

In simple, each process has one thread. 

![[Screenshot 2026-10-07 at 4.32.30 PM.jpg|300]]

The process has its own code, globals, heap, and a user stack for that thread.
- Inside the kernel, there is a process control block (PCB) describing the process and a kernel stack for its thread. 
- When the thread enters the kernel through a system call, it executes kernel code using its kernel stack.


However, a process can also have multiple threads.

![[Screenshot 2026-10-07 at 4.33.25 PM.jpg|300]]

These threads share the process’s code, globals, and heap, but each has its own user stack. 
- The kernel maintains a thread control block (TCB) and a kernel stack for each thread, alongside the PCB for the process as a whole.
- Separate kernel stacks allow one thread to pause inside the kernel while another continues running.


Threads can also exist entirely inside the kernel, without belonging to a user process.

![[Screenshot 2026-10-07 at 4.34.12 PM.jpg|500]]

These kernel-only threads perform internal kernel work, each has its own TCB and kernel stack, but no corresponding user stack.


## What

From here on it's like a mix of talking about Linux and comparing it to Pintos... uhm, I'm not so into the details, and I think the problems will naturally emerge as we write the code.


