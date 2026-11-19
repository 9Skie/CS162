We never really talked about the fundamental problem of paging in the first place: how should the OS divide physical memory among different processes?

Previously, we assumed a process had a certain number of frames throughout it's lifespan, but that's not true, we need to understand how the OS decides and adjusts that number when multiple processes share RAM.

To understand how this division works, suppose several processes have filled RAM, and one process needs to bring in a page from disk. We need a frame to hold it, but whose page should we evict to make room?

This introduces two possible approaches:

- Global replacement: choose a page to evict from across all processes. If we evict another process’s page, the requesting process gains a frame and the other process loses one. Their shares of RAM change through replacement.
    
- Local replacement: each process replaces only its own pages. Bringing in a new page means removing one of its existing pages, so its number of frames stays the same during replacement.

These describe which pages are eligible for eviction. Algorithms such as Clock still determine which eligible page to choose.


## Deciding Each Process’s Allocation

With local replacement, we need a separate policy to decide how many frames each process gets. Each process needs a minimum number to execute instructions and make progress, but how should we divide the available memory?

1. Equal allocation: give each process the same number of frames. For example, 100 frames divided among 5 processes gives each 20.

2. Proportional allocation: give larger processes more frames.
	- However, program size may poorly reflect actual needs: a program might include large libraries while using only a small part of them.

3. Priority allocation: give higher-priority processes a larger share of memory.



These policies use properties such as size or priority, but a process’s actual memory needs can change during execution.

Instead, we can monitor its page-fault rate, with more frames allocated to a process, the less likely a page fault is to occur for the process.

![[Screenshot 2026-10-24 at 12.26.27 PM.jpg|500]]

- If the rate is above an upper threshold, give it more frames.
- If the rate is below a lower threshold, consider taking some frames away.
- Between the thresholds, leave its allocation unchanged.

This allows the OS to adjust memory shares according to how processes behave while running, which links to our next topic: thrashing.


## Thrashing

Thrashing occurs when a process has too few physical frames to hold the pages it is actively using, causing it to repeatedly evict and reload needed pages. It spends most of its time waiting for disk transfers and makes little useful progress.

For example, suppose a process actively and repeatedly accesses 120 virtual pages, but has only 100 physical frames available:

1. RAM holds 100 of its pages, while the remaining 20 are on disk.
    
2. When the process accesses a page on disk, a page fault occurs. The OS evicts one of its resident pages and loads the needed page into the freed frame.
    
3. However, the evicted page is still actively needed. When the process accesses it again, another page fault occurs, requiring another eviction and disk transfer.
    
4. This cycle repeats: pages are evicted only to be needed again shortly afterward.

Performance drops drastically because the process spends much of its time waiting for pages to move between RAM and disk instead of executing useful work.

![[Screenshot 2026-10-24 at 12.43.34 PM.jpg|500]]


How do you solve thrashing? The simplest is just get more memory for more physical pages, or else like... this is never a permanent solution.


----

## IO (Input Output)

Finally moving on to another new topic! 

Io is literally how we as humans interact with the computer, right? We input commands, the computer runs them, and outputs results.

The problem with IO is that.... there's a lot of them, and in many flavors! We got like disks, keyboards, displays, networks... and they behave so differently, each with distinct speeds and activity patterns.
- A keyboard generates occasional input, often only a few keystrokes per second. 
- A network interface may handle intermittent background traffic or sustained, high-volume transfers. 
- A display refreshes regularly, but the amount of new content varies considerably between say, my word document compared to a video game.

How can the OS provide a consistent interface to these devices while managing their different behaviors efficiently? We somehow need to find a common ground for all these different I\Os.


The CPU communicates with I/O devices through I/O controllers, where the CPU communicates with an I/O device by reading and writing registers in its controller.

![[Screenshot 2026-10-24 at 1.34.50 PM.jpg|500]]


There are multiple I/O controllers, each managing a particular device or type of device. In this diagram, several controllers connect to a shared PCI bus, which provides a communication pathway that the CPU accesses through a bridge.

![[Screenshot 2026-10-24 at 1.38.02 PM.jpg|500]]


## PCI Bus

**PCI (Peripheral Component Interconnect)** is a standard for connecting peripheral devices, such as network cards and sound cards, to a computer.

The original PCI bus connected multiple devices through a **shared set of wires**. These wires carried data in parallel: a 32-bit PCI bus, for example, could transfer 32 bits simultaneously across 32 data wires.

Because devices used the same wires, they had to take turns communicating. Only one device could control the bus at a time, so the available bandwidth was shared among the connected devices.

As devices became faster, the original PCI design became a bottleneck due to shared bandwidth: when several devices needed to transfer data, they competed for access to the same bus.

Increasing performance therefore required a different connection design.

![[Screenshot 2026-10-24 at 2.09.16 PM.jpg|500]]


## PCI Express

**PCI Express (PCIe)** connects devices through **dedicated, point-to-point links built from high-speed serial lanes**. Instead of several devices sharing one set of data wires, each link connects two endpoints, for example, a device and a PCIe port on the computer.

Each lane sends bits sequentially and has separate paths for sending and receiving, allowing communication in both directions simultaneously. A link can combine multiple lanes for greater bandwidth: ×1 has one lane, ×4 has four, and ×16 has sixteen.

Although each lane is serial, multiple lanes can operate simultaneously. PCIe gains performance by running individual lanes at high speeds and combining them when a device needs more bandwidth.

Devices on separate links can communicate at the same time without competing for the original PCI bus’s shared wires. They can still share bandwidth farther upstream, such as when several links feed into one connection toward the processor.

![[Screenshot 2026-10-24 at 2.08.57 PM.jpg|500]]



## So Is the GPU an IO device?

This is a side talk unrelated to the class, but when we think PCIe, we usually think of this guy:

![[Pasted image 20261024142315.png|500]]

And you usually stick a graphics card in there.

![[Pasted image 20261024142355.png|500]]

So is a GPU an I/O device? Both discrete GPUs on graphics cards and integrated GPUs within the CPU’s chip are managed as distinct compute devices.

The CPU communicates with them through a device interface, so that communication falls under I/O even when the GPU is integrated into the same chip.

So from the OS's perspective, it's safe to think the gpu as a I\O device.



## How CPU Accesses IO Controller Registers

The processor communicates with a device through its device controller, which contains hardware that knows how to operate that particular device. The CPU interacts with the controller by reading and writing its registers. 

How does the CPU instructions actually access the controller’s registers? There are two methods:

- Port-mapped I/O: special instructions such as `in` and `out` access registers identified by port numbers.

- Memory-mapped I/O: The device controller’s registers are assigned particular addresses in the computer’s physical address space. The CPU accesses them using ordinary load/store instructions, just as it accesses RAM. 
	- However, the hardware routes accesses to these addresses to the controller’s registers instead of RAM.

For example, imagine this simplified address map:

|Address range|What the address refers to|
|---|---|
|`0x0000–0x7FFF`|RAM|
|`0x8000–0x80FF`|A controller’s registers|

When the CPU executes a store:

- To `0x1000`, the hardware routes the write to **RAM**, storing the value there.
- To `0x8000`, the hardware routes the write to **the controller's registers**