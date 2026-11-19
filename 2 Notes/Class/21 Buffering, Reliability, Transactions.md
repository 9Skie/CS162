For early Unix/FAT file systems, formatting a disk creates a fixed number of inode (file header) slots in the outermost cylinders of the disk.
- That limits how many files and directories that filesystem can hold.

This introduces 2 other problems:

1. All inodes are concentrated in one area.
	- An inode tells you where a file’s data blocks are. If the inode is on the outer tracks but its data is elsewhere, reading the file require moving the disk head to the inode, then moving it again to the data, and those seeks take a lot of time.
    - It also concentrates risk: physical damage to the inode area could destroy the information needed to locate many files, even if their data blocks survive.
    
2. Files grow, but we don’t know their final size.
    - We want a file’s blocks next to each other for fast sequential access. Suppose a file initially occupies blocks 10–12. Another file might take blocks 13–15. When the first file grows, its new blocks must go elsewhere.
    - Reserving extra space could help, but how much? Too little and the file still outgrows it; too much and we leave space reserved that it may never use.
    

So FFS needs a placement strategy that keeps inodes near their data and lets growing files retain good locality.

---


## How Magnetic Disks Work Again

A magnetic disk stores bits as magnetic patterns on spinning platters. A read/write head detects those patterns to read data or changes them to write data.

Each platter surface is divided into circular tracks, and each track is divided into sectors.

![[Screenshot 2026-10-27 at 6.51.00 PM.jpg|500]]


To read or write a sector:

1. The arm moves the head over the correct track. This takes seek time.
2. The platter keeps spinning until the desired sector reaches the head. This waiting is rotational latency.
3. As the sector passes underneath, the head reads or writes its bits. This takes transfer time.

Accessing consecutive sectors is fast because they pass under the head one after another. Accessing scattered sectors can require moving the arm and waiting for rotation again.
- It's like accessing an array vs a linked list


Disk latency = queueing time + controller time + seek time + rotational latency + transfer time.

![[Screenshot 2026-10-27 at 6.51.58 PM.jpg|500]]

---

## FFS (Fast File System):

FFS improves disk access performance by keeping related information physically close together. 
- It retains the inode structure with direct and indirect pointers, but changes where inodes and data blocks are placed on disk.

Side note: this is utilizing space locality within magnetic disks, obviously, we have storage that's faster than that these days, SSDs.
- F2FS (Flash-Friendly File System) is a direct example of a filesystem designed around flash storage, but that we won't go into detail in this class.


So, roughly how does this locality work?

1. Divide the disk into block groups.
    - Each block group covers a nearby set of tracks. 
	    - Accessing blocks within the same group generally requires less head movement than accessing blocks spread across the disk.
	
2. Store inodes, data blocks, and allocation information within each group.
    
    - Each block group contains:
	    - An inode area holding metadata and data-block pointers for files and directories.
	    - Data blocks holding file contents and directory contents.
	    - A free-space bitmap recording which blocks in the group are free or occupied.
    - The bitmap helps the filesystem find available blocks.
    
3. Place related files and directories together.
    
	- FFS tries to place a directory, its files’ inodes, and their data blocks in the same group. 
		- When accessing those files, the disk head can stay within a nearby region instead of repeatedly moving between a distant inode area and data area.

4. Use first-free allocation for new file blocks.
    - For small or newly created files, FFS fills available holes in the local block group, trying successive free blocks as the file grows.
    - Once the file crosses a size threshold, FFS continues allocating in another block group with a large run of free blocks.
    - This allows large files to occupy long sequential runs. Reading them may require occasional jumps between groups, rather than a seek for every block.

5. Keep roughly 10% of the space free.
    - Free space gives FFS room to choose good block locations.
    - If the disk becomes almost completely full, the remaining free blocks are likely to be scattered, making long sequential allocations difficult.
    - Keeping about 10% free increases the chance of finding a large run of consecutive free blocks, helping preserve performance as files are created, expanded, and deleted.

This arrangement also distributes inodes across the disk. Physical damage to one inode area may affect files in that region, but no longer necessarily destroys the inode information for the entire filesystem.

![[Screenshot 2026-10-27 at 6.56.24 PM.jpg|500]]

FFS uses a bitmap to track occupied (`1`) and free (`0`) blocks. It finds a few free blocks for small writes or a consecutive run of free blocks for large files.

![[Screenshot 2026-10-27 at 10.50.42 PM.jpg|500]]


---

## Hard Links, Soft Links

Can we give another name to an existing file? Yeah, it comes in the form of hard/symbolic links.
- Hard links: another directory entry pointing to the same inode.
- Soft (Symbolic) links: a special file that refers to another path.

Assume we have the following file structure:

![[Pasted image 20261027231207.png|300]]


Suppose `/usr/lib4.3/foo` is a regular file whose inode number is `42`. We want to also access it through `/usr/lib/foo`. There are two ways to do that.

1. Create a hard link.
    - Add an entry named `foo` inside `/usr/lib`, pointing to the same inode:

```
/usr/lib4.3/foo ──→ inode 42 ──→ file data
                      ↑
/usr/lib/foo ─────────┘ ```
```

Both paths name the same file. Neither name depends on the other. Removing `/usr/lib4.3/foo` leaves the file accessible through `/usr/lib/foo`.


2. Create a soft link instead.
    - Add a special file named `foo` inside `/usr/lib` that stores the target path `/usr/lib4.3/foo`:

```
/usr/lib/foo
    - stores the path "/usr/lib4.3/foo"
    - OS looks up that path
    - inode 42 -> file data
```

Accessing `/usr/lib/foo` redirects the lookup to `/usr/lib4.3/foo`. If that target path is removed, the soft link remains, but its target can no longer be found

---

## Windows NTFS (New Technology File System)

In the Unix filesystem we studied, each data-block pointer identifies one fixed-size block. NTFS instead describes consecutive runs of blocks using variable-length extents. 

So for example:
- In Unix, a file occupying blocks 100–104 therefore needs five individual block pointers.
- In Windows NTFS, each extent records a starting block and a length, so those same blocks can be represented by one extent: start at block 100, length 5 blocks.

```
Individual block pointers: 100, 101, 102, 103, 104

One extent: start at 100, length 5 blocks
```


NTFS organizes information about files in the Master File Table (MFT). Each file has a numbered record in this table, similar to how each Unix file has an inode.

The record describes the file, it's metadata, name, and where its contents are stored.

![[Screenshot 2026-10-27 at 11.34.22 PM.jpg|500]]

For a tiny file, NTFS can store the contents directly inside the MFT record alongside the metadata. This is called resident data.

If the contents are too large to fit, they are stored outside the record and become nonresident. The record instead stores extent information: the starting locations and lengths of the runs of blocks containing the data.

![[Screenshot 2026-10-27 at 11.46.01 PM.jpg|500]]

If that extent information also exceeds the space in one record, additional MFT records hold it.

![[Screenshot 2026-10-27 at 11.47.28 PM.jpg|500]]


---


## Memory Mapped Files

Now, we’re moving from how a filesystem stores and locates a file to how a process accesses its contents.
- Memory mapping lets a process access a file’s contents as a region of its virtual memory.

Normally, you call `read()` to copy file data into a buffer, then `write()` to send changes back. With `mmap()`, you map the file into your address space and access its contents through ordinary memory reads and writes.

The OS brings the needed parts of the file into RAM as you access them, using demand paging. So the file remains on disk, but the process works with its contents through memory addresses.



Recalling how virtual memory access works:

1. The CPU executes an instruction that accesses a virtual address. The MMU uses the page table to translate that address into a physical address.
    
2. If the page is already in RAM, the translation succeeds and the memory access proceeds.
    
3. If the page is not in RAM, the MMU raises a page-fault exception, transferring control to the kernel’s page-fault handler.
    
4. The handler arranges for the missing page to be loaded from disk into a physical frame in RAM. While the read is pending, the faulting thread waits and the scheduler can run another thread.
    
5. Once the read finishes, the kernel updates the page-table entry to identify the physical frame and mark the page as present. The waiting thread becomes ready to run.
    
6. When the thread is scheduled again, it retries the instruction. The MMU can now translate the address, and the memory access succeeds.


This same idea can be applied for files:

1. The process calls `mmap()` to map a portion of a file into its virtual address space.
    
2. The kernel records which virtual pages correspond to which portions of the file.
    
3. The process accesses an address in the mapped region. The MMU uses the page table to translate that virtual address.
    
4. If the page is not in RAM, the MMU raises a page-fault exception, transferring control to the kernel’s page-fault handler.
    
5. The handler uses the mapping information to identify the required file data and loads it into a physical frame in RAM. 
	- The thread waits while the disk read completes.
    
6. The kernel updates the page-table entry to point to that frame and makes the thread ready to run.
    
7. When scheduled again, the thread retries the instruction. The MMU translates the address successfully, and the thread accesses the file data in RAM.



Sharing through mapped files lets two processes access the same data in RAM.

1. Both processes map the same portion of a file using a shared mapping (`MAP_SHARED`).
2. The OS maps their virtual pages to the same physical pages in RAM.
3. When process A writes to that memory, process B can read the changed data through its own mapping.

```
Process A’s virtual address ──┐
                             ├──→ Same physical page in RAM
Process B’s virtual address ──┘
```

Their virtual addresses can differ, but both mappings lead to the same physical memory. The data does not have to travel through disk for one process to see the other’s changes.

![[Screenshot 2026-10-28 at 12.26.47 AM.jpg|500]]

---

## Buffer Cache

So far, we've seen how a filesystem stores files and how mmap lets a process reach file contents through memory. Now we look at how the kernel avoids going to disk over and over.

The idea is simple: disk is slow and RAM is fast. When the kernel reads a block from disk, it keeps a copy in RAM. The next time anyone needs that block, the kernel uses the copy in RAM instead of reading the disk again.
- That collection of kept blocks is the **buffer cache**. It holds file contents and also the filesystem's own data, like inodes and directory entries. 
- It works like a TLB, but for disk blocks instead of address translations.

If we look at this image:
- The right side shows the disk, which is divided into block groups.
- The bottom row shows the buffer cache in memory, where each box is a slot that can hold a copy of one disk block. 
- The row underneath tracks each slot's state: white slots are free and empty, while blue slots are in use.
- The arrow between them shows blocks being copied from disk into the cache and written back later.

![[Screenshot 2026-11-01 at 2.30.43 PM.jpg|500]]

---

## Making File Systems More Durable

Now, we go off into the tangent of making file systems more durable. Because caching writes creates a problem: the updated data may be in RAM while the disk still holds the old version. If the machine crashes before those changes reach disk, they’re lost.
- That includes metadata. Losing an updated inode or directory block can leave the filesystem inconsistent, not just lose a few bytes of file contents.


One approach to recovering corrupted data is to use error-correcting codes, such as Reed–Solomon codes. These store redundant information that allows the original data to be reconstructed when a limited amount of corruption occurs.

This is for example, why even when part of a QR code is missing or covered, you can still scan it's original information out.

![[Pasted image 20261101145359.png|500]]

To protect against the failure of an entire disk, another approach is to replicate the data. RAID 1, also called disk mirroring, maintains a complete copy of each disk on another disk, and whenever we update a disk, we update another disk at the same time.

But if one disk fails, its data remains available on the surviving copy.

