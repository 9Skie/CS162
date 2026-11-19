The 3 big ideas that we'll talk about in class today is:

A process fully defines the CURRENT program state,  the current program state is everything that describes what the running program is doing at that moment (for every thread):

- **Program counter:** where it is in the instructions.
- **Registers:** values the CPU is currently working with.
- **Stack:** active function calls, local variables, and return addresses.
- **Memory contents:** the program’s code and stored data.
- **Execution flags:** CPU status information, such as whether a comparison produced zero.

When execution is interrupted by a system call, interrupt, or exception, the necessary context is saved so the thread can resume, provided the event allows execution to continue.

![[Screenshot 2026-09-14 at 3.05.36 PM.jpg|500]]

An **address space** is the set of memory addresses available to a program. Each process typically has its own virtual address space, with a process-specific mapping from **virtual addresses to physical addresses**.

The **OS kernel** runs in kernel mode, giving it privileges beyond those of ordinary programs. With hardware support, it can isolate programs from each other and protect itself from regular programs.

---

We start with the question, say we have 1 core, how are we able to have many threads that look like they are running at the same time?

On a single CPU core, the OS creates the illusion of multiple processors by switching between threads, giving each a turn to execute. Each thread acts as a “virtual core,” with its own program counter, stack pointer, and registers. When a thread is running, this state is loaded onto the physical core; when it is paused, the state is saved in memory in a **Thread Control Block (TCB)** so it can resume later.

![[Screenshot 2026-09-14 at 3.19.25 PM.jpg|500]]

This process is usually called multi-programming, where each process (thread) has their respective chunk of the DRAM (physical memory), and believe that they all have 100% of the memory to themselves (virtual memory).

![[Pasted image 20260914154332.png|500]]

But when each process tries to read from or write to memory, it could potentially access regions that belong to other processes or to the operating system. 

![[Pasted image 20260914155042.png|500]]

Therefore, the system needs built-in memory protection to isolate the physical memory used by each process. A process should only be able to access the physical memory pages that the OS has mapped into its own virtual address space, while accesses to unmapped or protected pages are blocked by the hardware and operating system.


Base and bound is one of the earliest mechanisms for exactly this problem. Each process is given a contiguous region of physical memory. The base register stores where that process’s memory begins, and the bound register stores how large that region is. 

When the process generates an address, the hardware checks that the address is within the bound, then adds the base to translate it into a physical address. So if a process tries to access memory outside its assigned region, the hardware traps instead of allowing it to read another process’s memory or the kernel’s memory.

$\text{physical address} = \text{base} + \text{virtual address}$

$\begin{cases} \text{Valid access} & \text{base} \le \text{physical address} < \text{base} + \text{bound} \\  \text{Invalid access}, & \text{otherwise} \end{cases}$


![[Pasted image 20260914155236.png|500]]


Now, what if we break the entire virtual address space into equal size chunks?

Instead of giving each process one contiguous physical-memory region, we split its virtual address space into equal-sized pages, and physical memory into equal-sized page frames. Each virtual page can then map to a different physical frame through the page table.

A virtual address is split into:

$\text{virtual address} = (\text{virtual page number},\ \text{offset})$

The virtual page number indexes the page table. The corresponding page-table entry tells us which physical frame contains that page, plus protection information such as valid/invalid and read/write permissions.

$\text{physical address} = \text{physical frame number} \times \text{page size} + \text{offset}$

So the same protection idea still works, but now it works per page rather than for one large contiguous region. This is much more flexible than base-and-bound because a process's physical memory no longer needs to be contiguous.

![[Pasted image 20260914160656.png|500]]


But, Branch and Bound is too simplistic for real systems to use memory protection for.

One simple reason is that each process must fit into one contiguous block of physical memory. As processes are created and removed, this can lead to fragmentation and inefficient use of memory.

It also raises another problem: if every process is strictly confined to its own memory region, how can processes communicate with one another? Real operating systems therefore need more flexible memory-management mechanisms that still provide protection while allowing controlled sharing between processes.

The better alternative is paging with virtual memory.

Instead of forcing each process into one large contiguous block of physical memory, the OS divides its address space into small fixed-size pages. Those pages can be placed anywhere in physical memory and mapped using a page table.

This solves both problems: a process no longer needs one contiguous block of RAM, and the OS can deliberately map the same physical page into multiple processes when it wants them to share memory.

![[Pasted image 20260919225047.png|500]]


---

Memory protection stops a process from accessing memory that belongs to another process or the OS. But that is not enough: processes also should not be allowed to change page tables, disable interrupts, control hardware directly, or modify kernel memory. Otherwise, a process could bypass the protections and effectively take over the computer.

This is why CPUs have user mode and kernel mode. Normal programs run in user mode with restricted privileges, while the OS runs in kernel mode with full privileges.

There are three main ways to enter kernel mode: system calls, interrupts, and exceptions.

$\text{User Mode} \xrightarrow{\text{system call / interrupt / exception}} \text{Kernel Mode} \xrightarrow{\text{return}} \text{User Mode}$