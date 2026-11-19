We are back to looking at concurrency!

A race condition arises when multiple processes or threads are simultaneously trying to **modify and retrieve shared data**, resulting in unforeseen and unintentional outcomes.
- This occurs when the synchronization and sequencing of these processes or threads are not coordinated.

It's very much similar to the context switching problem, and this video... just introduced it by a bit.

Here is the demonstrated program for the race condition example:

![[Screenshot 2026-08-04 at 8.51.57 AM.jpg|500]]

Basically, there's a shard variable, some hard coded sentences, and a writer thread cycles through this fixed list of sentences, updating the shared variable as it goes.

A reader thread (not shown) logs what is inside the variable down into a text file, but inside the text file's millions of logged lines... there are bugged lines that don't match the hard coded sentences.

![[Screenshot 2026-08-04 at 8.55.32 AM.jpg|500]]

To be more exact, it became a mix of the sentences, but why?

![[Screenshot 2026-08-04 at 8.57.03 AM.jpg|500]]

---
## The Race Condition

In C, strings are stored as a continuous list of characters, with a null terminating character.

![[Screenshot 2026-08-04 at 8.58.23 AM.jpg|500]]

If we are printing a string, what's going on underneath is that the computer iterates through the characters 1 by 1, printing each one out in the console until it encounters the null character.

![[Screen Recording 2026-09-17 at 9.56.50 AM.mov.gif|500]]

If we are copying a string, it's a similar idea, looping through each character and copying them, this could be sped up by copying in chunks.

![[Screen Recording 2026-09-17 at 9.58.38 AM.mov (1).gif|500]]

![[Screen Recording 2026-09-17 at 9.58.38 AM.mov.gif|500]]

But in this case, the writer thread got interrupted mid-copy due to concurrency, where the OS gave control of the CPU from the writer thread to another process, and thus the string overwrite wasn't completed, and the reader thread read the incomplete string.

![[Screen Recording 2026-08-04 at 9.06.39 AM.mov.gif|500]]

We need to ensure that only one thread can access `shared_string` at a time while it is being read or modified. This can be done using a **mutex**, short for mutual exclusion.

While the writer holds the lock, the reader cannot access `shared_string`. If the reader tries to lock the mutex, it is put to sleep until the writer finishes copying the complete sentence and releases the lock.

So while modifying the strong, the write thread was interrupted and the thread handling client requests ended copying the string while it was incomplete.


So in the TLDR, race conditions are a software bug that occurs when the outcome of a program depends on the unpredictable order in which multiple threads/processes access/modify shared resources.
- A preemptive operating system is one that forcibly interrupts running processes from time to time so other processes get access to the CPU

If a data modification takes longer than 1 time quantum, the data will inveitiably will enter en invalid state due to interrupts.

![[Screenshot 2026-09-17 at 10.04.30 AM.jpg|500]]

Even if a data modification is within a time quantum, race conditions can still occur, say because it was near the end/beginning of the time quantum such that the modification happens.

![[Screenshot 2026-09-17 at 10.05.39 AM.jpg|500]]

But the CPU could be interrupted by many other things within the time quantum, as other interrupts could occur within the time quantum as well, here is just to list a few of them.

![[Screenshot 2026-09-17 at 10.12.21 AM.jpg|500]]

