This vid is a bit less... hardcore.

We already know that a process contains resources such as its address space, open files, and I/O devices, while the operating system tracks its execution state through a Process Control Block.

![[Screenshot 2026-07-28 at 5.27.45 PM.jpg|500]]

The operating system can switch the CPU between different processes.

![[Screenshot 2026-07-28 at 9.40.56 AM.jpg|500]]

But we have a problem, it doesn't mean the process is utilizing the CPU even if the CPU assigned to it. 

For example, if one process begins a slow I/O operation, such as reading a large file, allocating the CPU to that process is inefficient, as it can't execute any instructions until the requested IO resource finishes the operation.

![[Screenshot 2026-07-28 at 5.57.08 PM.jpg|500]]

Threads solve this problem by allowing multiple execution flows inside the same process. When one thread blocks on a slow I/O operation, another thread from the same process can continue running while sharing the same address space and resources.

![[Screen Recording 2026-07-28 at 6.00.46 PM.mov.gif|500]]


But how does this happen? There's usually just 1 single program counter tracked per process, we can't keep track of more than 1 task at a time happening inside a process.

So what we can do instead is assign a program counter to every thread inside the process.

![[Screenshot 2026-07-28 at 5.50.48 PM.jpg|500]]

By no longer limiting each process to a single program counter, we can now create a new thread whenever we need code within the same process to run concurrently. Say, if one of the threads needs an IO resource such as reading a file, it won't stop the other threads from execution of the same process.
- Yes, I am showing the same demo
- 
![[Screen Recording 2026-07-28 at 6.00.46 PM.mov.gif|500]]


Beyond just program counters, each thread keeps track of it's own CPU state as well, and their own stack pointers.

![[Screenshot 2026-07-28 at 6.03.47 PM.jpg|500]]


Now, from our understanding of processes to processes with threads, we would have to re-design the PCB, where for example in the Linux kernel, they both fall under the data structure called `task`.

![[Screenshot 2026-07-29 at 10.23.57 AM.jpg|500]]


Regardless, this would change how our processes work:

1. they would have 1 main thread to begin with
	- ![[Screenshot 2026-07-29 at 10.24.41 AM.jpg|500]]

2. threads are spawned at runtime if needed from the main thread
	- ![[Screenshot 2026-07-29 at 10.25.23 AM.jpg|500]]

3. if the main thread is killed, every other thread is killed
	- ![[Screenshot 2026-07-29 at 10.26.03 AM.jpg|500]]

---

I know, threads are confusing things! It still makes me wonder sometimes why we use them in the first place.

The best analogy to think is this:
- On our computer, we probably have multiple programs running at the same time concurrently, they do different things at the same time, the OS controls which program to run on the CPU.
- But who said 1 program has to only be able to do 1 thing? What stops 1 program from being able to do multiple things concurrently? That's threads, it allows 1 program to do multiple things concurrently.


A program starts with a **main thread** that executes code sequentially.
- When another activity needs to make progress concurrently, the program can create a separate thread to run a particular function while the main thread continues its work.

**Each thread still executes its own code sequentially**, but their execution can overlap.
- Because threads share the program’s memory, they may need **synchronization** to coordinate access to shared data and ensure that operations happen in the correct order.