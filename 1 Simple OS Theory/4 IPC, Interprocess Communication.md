This vid is a bit less... hardcore.

As we recall, a process can be defined by it's 'state' of process memory state, cpu state, files accessed, IO used.

![[Screenshot 2026-07-28 at 4.06.31 PM.jpg|500]]

And on our computer, there's multiple of these processes that run simultaneously. 

![[Screenshot 2026-07-28 at 4.05.30 PM.jpg|500]]


Previously, we said all of these processes are independent, they can't talk to each other or access each other's memory space, but what if we want them to?

Like, I might be playing a video game program with some screen recording program going on at the same time, how does this work? We come to IPC, interprocess communication, there's 2 models of it, which we'll both discuss.

![[Screenshot 2026-07-28 at 4.15.07 PM.jpg|500]]

---
## Shared Memory

By default, processes have separate **virtual address spaces**, so one process cannot directly access another process’s memory. However, processes can ask the operating system to create a region of shared memory for inter-process communication.

![[Screenshot 2026-07-28 at 4.20.01 PM.jpg|500]]

The operating system can configure both processes’ page tables so that part of each virtual address space maps to the same physical memory:

```text
P1 virtual address ─┐
                    ├──→ same physical memory
P2 virtual address ─┘
```

The shared region may appear at different virtual addresses in each process, but both mappings refer to the same physical memory pages. Therefore, when Discord writes data into the shared region, OBS can read those same bytes directly.

But this comes to the same problem as the switching of processes by the OS initially, there must be some degree of control of reading & writing to/from this shared region, or else it's just a mess between these 2 programs.
- So it's not really used anymore

---
## Message Passing

The other IPC model keeps the address spaces of two processes separate while allowing them to exchange data through the operating system. This can be done using pipes, sockets, or higher-level mechanisms such as remote procedure calls.

![[Screenshot 2026-07-28 at 4.33.17 PM.jpg|200]]

Suppose processes A and B establish a communication channel. The operating system maintains a buffer for that channel. When A calls `write()` or `send()`, the kernel copies A’s message into the buffer. When B calls `read()` or `recv()`, the kernel copies the message from the buffer into B’s memory.

![[Screenshot 2026-07-28 at 4.36.03 PM.jpg|500]]

If B calls `read()` before A has sent anything, the kernel puts B to sleep until a message arrives. For communication in both directions, the channel must support both A-to-B and B-to-A data flow.

![[Screenshot 2026-07-28 at 4.37.00 PM.jpg|500]]

message passing is much more widely used since, if we get more advanced, we can have many different programs talking to many different programs.

![[Screenshot 2026-07-28 at 4.51.54 PM.jpg|300]]

Or even, these programs won't even need to be on the same machine to communicate to each other.

![[Screenshot 2026-07-28 at 4.52.40 PM.jpg|500]]

But it comes with it's downsides as well, as shown in the diagram, every communication step must pass through the operating system, and therefore, message passing usually has more overhead than shared memory, where the processes can directly read and write the same mapped memory region after it has been established.

![[Screenshot 2026-07-28 at 4.57.07 PM.jpg|500]]