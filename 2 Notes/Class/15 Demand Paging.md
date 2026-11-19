Why is so much of this just CS61C stuff... a lot of it is review.

---
## TLB Context Switching

So now that we understand how a TLB works, there is a problem that we encounter when using it with multiple processes switching back and fourth.

When we switch from one process to another, we also switch address spaces. The old process's TLB mappings can't be applied to the new process, and we have to start from scratch again.

We could invalidate the TLB and refill it as the new process accesses memory, but this causes extra page-table lookups. 
- Instead, we can tag each TLB entry with an address-space identifier (ASID), allowing different processes’ mappings to coexist and be reused


So, the TLB would now have to match two things: the virtual page number and the current process’s ASID.

For example, it could contain:

|ASID|Virtual page|Physical frame|
|---|---|---|
|A|5|100|
|B|5|200|

1. Process A is running, so the CPU’s current ASID is A. 
	- Accessing virtual page 5 matches `(A, 5)` to physical frame 100.

2. On a switch to process B, the OS changes the page-table pointer and the CPU’s current ASID to B.

3. Accessing virtual page 5 now matches `(B, 5)` to physical frame 200. 
	- A’s entry stays in the TLB but cannot match B’s lookup.

This needs hardware support because the TLB hardware must store the ASID with each entry and check it during every lookup.

---
## Putting Everything Together For Address Translation


We start off with a virtual address of say, a 2 layer table, it looks like:
- `[ Virtual P1 index | Virtual P2 index | Offset ]`

![[Screenshot 2026-10-10 at 10.23.38 PM.jpg|500]]


The offset if directly attached to the physical address.

![[Screenshot 2026-10-10 at 10.23.58 PM.jpg|500]]


Then the `Virtual P1 index` points us to the 1st level of the page table, and `Virtual P2 index` points us to the 2nd level of the page table.
- That points us to the physical table

![[Screenshot 2026-10-10 at 10.26.10 PM.jpg|500]]


But to speed up this process, we use a TLB to directly find matching virtual/physical address pairs.

![[Screenshot 2026-10-10 at 10.37.48 PM.jpg|500]]


Now that the TLB gives us the physical address, we still need to fetch the actual data at that address.

We first obtain `[ Physical Page # | Offset ]`. Then we interpret that same physical address as `[ tag | index | byte ]` to look for the data in the cache.

![[Screenshot 2026-10-10 at 10.50.44 PM.jpg|500]]


---

## Demand Paging

Modern programs require a lot of memory, but much of it isn’t being used at any particular moment.

A rough heuristic called the 90–10 rule says that programs spend 90% of their time running 10% of their code. It is therefore wasteful to require all of a program’s code to remain in physical memory.

So... can we just, place that code on the disk and put it into memory when needed? That's demand paging, extending the idea of caching to main memory.

CPU caches hold frequently used data from DRAM, while DRAM holds the currently needed pages backed by disk. 
- When something is missing from a faster level, it is fetched from a slower level, replacing something else if necessary.

![[Screenshot 2026-10-10 at 11.08.35 PM.jpg|500]]


So, what does this mean at all for our memory address translation? Well, imagine we went to the MMU and got a cache miss.

This means that we have a virtual page that didn't map to a physical frame yet, and the only possibility of that happening is when parts of the program doesn't even exist on RAM.

![[Screenshot 2026-10-10 at 11.18.41 PM.jpg|500]]

Like, as we said, that just means part of the program exists on disk but isn’t currently in RAM. So we go to the disk and load the page from the disk.

![[Screenshot 2026-10-10 at 11.19.25 PM.jpg|500]]

Then we retry the instruction again.