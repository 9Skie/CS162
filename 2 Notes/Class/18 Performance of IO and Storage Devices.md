Last class, we introduced how the CPU communicates with I/O devices through device controllers, this is a continuation of that, how data moves between devices and memory, how the OS knows an operation has finished, and how device drivers connect these hardware operations to the interfaces programs use.


## Transfer Data To/From Controller

Last class, we saw two ways for the CPU to interact with a device controller: port-mapped I/O and memory-mapped I/O. These let the CPU access the controller’s registers to issue commands and check its status.

Direct memory access (DMA) lets the controller transfer data directly to or from memory through the memory bus. 
- The CPU uses port-mapped or memory-mapped I/O to tell the controller where to transfer the data and how much, then the controller performs the transfer itself.

The process is described as such:


1. The device driver is asked to transfer data from the disk into a memory buffer at address X.
    
2. The device driver, running on the CPU, tells the disk controller to transfer C bytes from the disk into that buffer.
    
3. The disk controller initiates a DMA transfer.

![[Screenshot 2026-10-24 at 10.31.24 PM.jpg|500]]


4. The disk controller sends each byte to the DMA controller.
    
5. The DMA controller writes the bytes into memory, starting at address X. As it transfers each byte, it increases the destination address and decreases C until C = 0.
    
6. When C = 0, the DMA controller interrupts the CPU to signal that the transfer is complete.

![[Screenshot 2026-10-24 at 10.31.45 PM.jpg|500]]


Once the OS starts an I/O operation, it needs to know when the operation finishes or encounters an error, there are two ways to find out:

1. Interrupts: the device generates an interrupt, causing the CPU to run the OS’s interrupt handler. The handler checks what happened and can make a process waiting for the data ready to run.
	- Pros: handle unpredictable events well
	- Cons: interrupts create high overhead 
    
2. Polling: the OS repeatedly checks the device controller’s status register to see whether the operation is complete. Each check is cheap, but checking when nothing has happened wastes CPU time. 
	- Pro: low overhead (not interrupt)
	- Con: waste CPU usage due to polling

In reality, systems combine both.



## Standard Interfaces to IO Devices

Now that we understand how the CPU and I/O devices interact, we can ask how the OS provides a uniform interface for accessing different devices, this is made possible through device drivers.

A device driver is device-specific code that interacts directly with the device’s hardware through its controller. They provide a standard interface through which the kernel can request operations on different devices without knowing their hardware details. 

Programs request I/O through system calls such as `open()`, `close()`, `read()`, and `write()`, and the kernel calls the appropriate driver when device access is needed. 
- Each driver has a hardware-specific implementation of these operations: it knows what the requested operation means for its device and which commands will carry it out.

![[Pasted image 20261024232401.png|300]]



## Different IO Devices

Despite the desire for a universal interface, we still distinguish block, character, and network devices because their basic behavior differs:

- A block device transfers data in fixed-size blocks that can be individually addressed.
	- Like disk
    
- A character device transfers data as a sequential stream of bytes.
    - Like keyboard and mice

- A network device sends and receives data in packets.
	- Like ethernet and wifi



## Handling I/O Latency

Since I/O operations take time, the interface must define what happens to the calling program while it waits for data or an operation to finish.

- Blocking I/O: the call waits for the operation’s result. The calling thread sleeps while waiting, allowing the CPU to run other threads.
    
- Non-blocking I/O: the call returns immediately with whatever data could be transferred, or an indication that the device is not ready. The program must try again later if necessary.
    
- Asynchronous I/O: the program submits an operation, and the call returns before it finishes. The operation remains pending while the program continues running, and the OS notifies the program when it completes.


---

## Storage Devices

So far, we’ve covered how the OS communicates with devices and manages I/O requests. We now examine storage devices to understand what happens inside a device while a request is being carried out. 
- The mechanisms of hard disks and SSDs explain where I/O latency comes from and why different access patterns produce different performance.

Storage devices retain data even when power is off. Here, we distinguish two main types:

- Magnetic disks (HDDs) store data magnetically on spinning disks. They provide large capacity at low cost, but random access is slow; sequential access is much faster.
    
- Flash memory, used in SSDs, stores data electronically without moving parts. It provides fast reads and random access, but writing is more complicated

I believe here the class spends way too much detail in terms of talking about HDDs and SSD internals that are irrelevant to I/O, don't know why, maybe he's setting up for file systems? But I just think it's a load of nothing, so I'm skipping for now.


- HDD performance: accessing a new location has substantial overhead, so small, scattered requests are slow. Sequential access and larger transfers spread that overhead over more data, improving effective throughput. Keeping related data together therefore matters.
    
- SSD performance: access latency is much lower, so random reads are far faster than on HDDs. Writes are more complicated because space must be erased before reuse, and reclaiming old space can add overhead. Repeated writes and erasures also cause wear, which the controller manages by spreading writes across the device.


---

## Performance of I/O Devices


The performance of an IO device can be looked at in these 4 aspects:

- Latency: time to complete a task.
- Response time: time from submitting a request until receiving its result.
- Throughput: tasks completed, or data transferred, per unit time.
- Overhead: the setup and handling cost beyond the useful operation itself.



The startup-cost problem is that a fast device can transfer data quickly, but each operation still has a fixed cost to get started. For small transfers, that overhead can dominate the total time.

Let's look at say, a network, consider it has:
- The link transfers data at 125 MB/s.
- Each transfer has a startup cost of 1 ms.

$\text{Latency} = \text{startup cost} + \dfrac{\text{data size}}{\text{transfer rate}}$

$\text{Effective bandwidth} = \dfrac{\text{data size}}{\text{latency}}$

For 125 KB, transferring the data takes 1 ms. Add the 1 ms startup cost, and the operation takes 2 ms, giving only 62.5 MB/s, half the link’s capacity.

- Smaller transfers spend a larger fraction of their time on startup. 
- Larger transfers spread that same fixed cost over more data, bringing effective bandwidth closer to the link’s maximum bandwidth.

![[Screenshot 2026-10-25 at 10.33.56 AM.jpg|500]]

But if the startup cost is much higher, say like 10ms (which is reasonable for an I/O device like a disk), the effective bandwidth would need much more data to get closer to the links's maximum bandwidth.

![[Screenshot 2026-10-25 at 10.38.59 AM.jpg|500]]

