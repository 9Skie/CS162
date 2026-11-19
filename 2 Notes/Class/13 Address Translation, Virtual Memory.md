Back in Class 2, we discussed fundamental OS concepts, especially memory isolation: each process should have its own protected address space. One simple way to achieve this is base-and-bound:

$physical\ address = base + virtual\ address$

However, this approach requires each process’s memory to occupy a contiguous chunk of physical memory, which can become difficult to allocate as free memory gets fragmented. 
- If you’ve seen how `malloc` is implemented, this resembles the heap fragmentation problem, extended to multiple processes across the entire system.


A more flexible approach is paging. We divide the virtual address space into equal-sized pages and physical memory into equally sized page frames. A page table maps each virtual page to a physical frame, so consecutive virtual pages do not need to occupy consecutive physical frames.

To locate a particular byte, we split its virtual address into a virtual page number and an offset. The virtual page number identifies which page we want, while the offset identifies the byte’s position within that page.

We use the virtual page number to look up the corresponding physical frame number in the page table. Then:

$physical\ address = physical\ frame\ number \times page\ size + offset$

The physical frame number multiplied by the page size gives us the frame’s starting physical address. Adding the offset takes us to the specific byte within that frame. 


Today’s lecture builds on the memory isolation idea from Class 2, as we've already have the basic idea of memory isolation and virtual-to-physical address translation, today’s lecture looks more closely at how the OS and hardware implement it.

---

## Memory Multiplexing

When we have multiple programs use the same memory (in different addresses), there's 3 main concerns we have to worry about:

1. Protection: each process should access only memory it is permitted to use. This protects other processes and the kernel, and even stop a process from accidentally overwriting itself.
    
2. Translation: convert the virtual addresses a process uses into actual physical addresses. Two processes can both use virtual address `0`, while their data lives at different physical locations. Each process therefore gets its own view of memory, independent of where it is physically placed.
    
3. Controlled overlap: separate processes’ private data must not accidentally occupy the same physical locations. But when sharing is intended, we can map selected parts of their virtual address spaces to the same physical memory, for example, to let them communicate through a shared buffer.


But, how can we let the OS interpose on process's memory accesses?
- We allowed the OS to interpose on process's IO operation through system calls, and CPU usage through scheduling, but what about memory?

---

Apparently a lot of this class is just... older stuff, like base and bound, simple segmentation (of a process's address space into regions, which each can be placed separately in physical memory using base and bound)

Which uh... I think is not really needed? We understand the simple concepts of base and bound and basic paging, we need something new from there on, which does't seem to be in this class.

If you are interested in looking at how segmentation works (we won't ever use this) feel free to look into it's details.

There's 1 little thing about page sharing, I'll put it here.

---

## Page Sharing

By default, private memory is kept separate: process A’s virtual pages and process B’s virtual pages map to different physical frames, so their private data does not overlap.
- Each process has its own page table, which the OS maintains.
    
When we want page sharing, the OS deliberately maps virtual pages from different processes to the same physical frame. This lets them access the same data, either to communicate or to share common content such as read-only code.

Shared memory is itself a form of IPC. Instead of sending data through a communication channel such as a pipe, one process writes to the shared memory and another reads from it.

The processes can have different permissions for that shared frame. For example, process A might have read/write access while process B has read-only access. Mapping to the same physical frame creates the sharing; permissions control what each process can do with it.