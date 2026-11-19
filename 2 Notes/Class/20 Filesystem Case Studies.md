A disk provides persistent storage, which the operating system accesses through an I/O interface. At this level, storage is a large collection of numbered, fixed-size blocks, and the basic operations are to read or write those blocks.

![[Pasted image 20261026152811.png|500]]

However, this is not how we logically organize our data. We think in terms of named files, organized into directories, whose contents we can read or modify a few bytes at a time. The storage device itself does not know what a file is or which blocks belong to it.

![[Pasted image 20261026152852.png|500]]

So far, we have looked at storage from the hardware’s perspective: a disk has a certain capacity, divided into numbered, fixed-size blocks that we can read and write through an I/O interface.

But this looks very different from how we experience storage on a computer. We see named files organized into directories. Each file contains a sequence of bytes, can have a different size, and can grow as we add data.

How do these two views fit together? How can a collection of physical storage blocks represent files and directories? Given a filename and a position within that file, how do we find the blocks containing the data?

These are the questions that motivate a file system: the layer of the operating system that connects our familiar view of files and directories to the blocks provided by the storage device.


We encountered a similar problem with virtual memory. A program uses virtual addresses, which are translated into physical memory locations. Here, a program identifies a file and a byte position within it, and we need to translate that into the storage blocks containing the data:

- Virtual memory: `virtual address -> physical page + offset within the page`
- File system: `file + byte offset -> storage block + offset within the block`

For example, a program might ask to read 30 bytes starting at byte 100 of `notes.txt`. Something must locate the blocks containing those bytes, arrange for them to be read, and copy the requested bytes into the program’s memory buffer.

A file system is the layer of the operating system that connects these two views. It organizes persistent data into files and directories, tracks which blocks contain each file’s contents, and translates file operations into operations on those blocks.

---

## Disk Management

The fundamental 2 basic entities that we store on a disk are files and directories:

1. A file is a sequence of bytes, stored sequentially in blocks.
	- A block is a fixed-size chunk of storage that the filesystem manages.
	- They can be stored at different locations on disk, the filesystem remembers their order.

2. A directory is a special kind of file whose contents map names to files or other directories.

For example, a directory named `School` might contain:

```
notes.txt → file containing your notes
CS162     → another directory
```

The directory stores these name-to-file mappings.


The disk physically is accessed as a linear array of sectors, to identify a sector, we use logical block addressing, where each sector is assigned an integer address and the disk IO controller translates from address to physical position on disk.


Now, for what a file system needs in order to work? It needs to:

1. Track free disk blocks, so it knows where to put newly written data.
2. Track which blocks contain each file’s data, so it knows where to read the file’s contents.
3. Track names in directories, so it can find a file and locate its blocks given its name.

All of this bookkeeping is metadata. It must also be stored on disk, so after a shutdown or restart, the operating system can reconstruct the organization of files and directories.


---

## An Abstract File System

This is our first abstract view as to how to connect the logical file system we know with the data blocks on disk.

A file system connects a file’s name to the blocks storing its contents through directories and inodes.

1. Directory structure: maps names to file numbers.
    - Given a file path, the filesystem looks through the directories to find the file’s number, called its “inumber.”

2. File header structure (inode): describes the file and locates its blocks.
    - The filesystem uses the inumber to find the corresponding inode. The inode stores information about the file, including how to locate the data blocks containing its contents.
    
3. Data blocks: store the file’s actual contents.
    - Following the information in the inode, the filesystem finds the blocks and reads or writes the requested data.

Access therefore follows this chain:

```
File path -> directory lookup -> inumber -> inode -> data blocks
```

![[Screenshot 2026-10-26 at 4.30.31 PM.jpg|500]]

---
## A Directory Structure

As we saw from the above example, to get a file number, we first need to look inside the directory structure.

A directory structure containing dictionary like mappings of `{file_name : file_number}`, for example, a list of entries like:

```
("notes.txt", 42)
("homework.pdf", 81)
("CS162", 103)
```

To look up `homework.pdf`, the filesystem reads the directory’s data blocks and searches the entries linearly, comparing each name with `homework.pdf`. When it finds a match, it gets the corresponding file number, `81`.


A directory has a specific format that the filesystem manages, so processes use operations provided by the OS to inspect or change its entries.

`open` and `creat` look up names through directories. `readdir` returns directory entries. `mkdir` and `rmdir` create and remove directories, while `link` and `unlink` add and remove names.

This lets the OS maintain the directory structure correctly, instead of allowing programs to overwrite its bytes arbitrarily.



Here's an example of how we locate a directory:

- To resolve `/my/book/the_little_prince.pdf`, the filesystem begins with its known way of locating root’s file header.

Root -> my
1. Search root’s entries -> obtain my’s file number
2. Use that file number -> locate and read my’s file header
3. Use that file header -> locate and read my’s directory entries

My -> book
1. Search my’s entries -> obtain book’s file number
2. Use that file number -> locate and read book’s file header
3. Use that file header -> locate and read book’s directory entries

Book -> the_little_prince.pdf
1. Search book’s entries -> obtain the_little_prince.pdf’s file number
2. Use that file number -> locate and read the_little_prince.pdf’s file header
3. Use that file header -> locate and read the_little_prince.pdf's file contents

---
## Characteristics Of Files

As a tangent, we'll look at a paper in 2007 of a study on file systems, as this study found some interesting observations that will help us design the file system to handle efficiently?

1. Most files are small. If you count the files, small files dominate. The filesystem should therefore handle small files efficiently, with little overhead.

![[Screenshot 2026-10-27 at 3.45.08 PM.jpg|500]]

2. Most bytes are in large files. Although large files are fewer, they account for most of the stored data. The filesystem must also efficiently support files that occupy many blocks.

![[Screenshot 2026-10-27 at 3.45.44 PM.jpg|500]]

---

## An Actual File System, FAT

So, with all of those properties in mind:
- fast access to small files
- efficient storage of large files

And the rough access idea of a file to be:

```
File path -> directory lookup -> inumber -> inode -> data blocks
```

We are going to look at `FAT` (File Allocation Table) as a case study.


By default, a disk provides many data blocks.

![[Screenshot 2026-10-27 at 3.57.52 PM.jpg|150]]


In the FAT file system, the File Allocation Table has one entry per data block.

![[Screenshot 2026-10-27 at 4.02.33 PM.jpg|250]]


The file’s data is stored in the blocks themselves.

![[Screenshot 2026-10-27 at 4.03.38 PM.jpg|250]]


The FAT stores the links between them. Starting from the file’s first block and following these links gives us its blocks in order, even if they are scattered across the disk.
- It's literally a linked list!

![[Screenshot 2026-10-27 at 4.04.19 PM.jpg|350]]

The file number points to the start of the file, and the accessed file block is put into memroy.

![[Screenshot 2026-10-27 at 4.08.47 PM.jpg|350]]


Unused blocks are marked 'free'.

![[Screenshot 2026-10-27 at 4.16.48 PM.jpg|350]]


Now, lets think about some properties of FAT, starting with a file number, we know the file’s first block, the remaining blocks follow from the linked-list structure. 

|Question|FAT’s behavior|
|---|---|
|Time to find a specific block?|To reach the kth block from the start, follow k−1 links: O(k). The first block is immediately available.|
|Block layout?|Blocks can be anywhere free space was available when the file grew. Their physical locations need not follow their logical order.|
|Sequential access?|Once at a block, finding the next takes one FAT lookup. Reading n blocks takes O(n) block visits, but scattered blocks can cause expensive seeks on an HDD.|
|Random access?|Poor in the basic design: jumping far into a file requires traversing the preceding links.|
|Fragmentation?|A file’s blocks can become scattered as files are created, grown, and deleted. How much depends on allocation and usage history.|
|Small files?|Reasonably efficient: their chains are short, so there are few links to follow.|
|Large files?|They can grow by adding blocks, but long chains make random access costly, and scattered placement can hurt sequential reading.|

So, that's FAT! It's rather easy to implement as we just need to dedicate a specific part of disk to it, embedded into hardware.

---

## Unix File System

In the Unix file system, the file number's purpose changes in what it identifies:
- In FAT, it identifies the file’s first data block.
- In Unix, it acts as an index to find an array header in an array of file headers.

Each file header corresponds to a different file with its metadata, and the file headers maintain a multi-level tree structure to find storage blocks for it's respective.
- It's apparently really good for working with small/large files!


So, what is this tree structure? We need to look more into this file header:

![[Screenshot 2026-10-27 at 4.47.29 PM.jpg|500]]


The file header contains metadata and pointers used to locate the file’s data.

A direct pointer goes straight to a data block:

```
File header -> data block
```

An indirect pointer goes to a block containing more pointers. Those pointers lead to data blocks:

```
File header -> block of pointers -> data blocks
```


So, why separate into direct pointers and indirect pointers? And how do the indirect pointers work?


Direct pointers make accessing small files efficient. For example, with eight direct pointers and 4 KB data blocks, the file header can directly address up to 32 KB of file contents.

As we saw in the file-size distribution, most files are smaller than this limit, so direct pointers are sufficient for many files. 

![[Screenshot 2026-10-27 at 4.51.37 PM.jpg|500]]

- Once the file header is available, we can locate any of these data blocks in constant time by selecting its corresponding direct pointer.


Indirect pointers make accessing large files possible without drastically increasing the size of the file header.
- Assume each block is 4 KB and each pointer occupies 4 bytes. A pointer block therefore contains 1,024 pointers.

With single indirection, the file header points to one pointer block. Its 1,024 entries point to data blocks, allowing it to address:

```
1,024 data blocks × 4 KB = 4 MB
```

With double indirection, the file header points to a pointer block whose entries reference 1,024 additional pointer blocks, and each of those references 1,024 data blocks:

```
1,024 × 1,024 data blocks × 4 KB = 4 GB
```

With triple indirection, another pointer-block level is added:

```
1,024 × 1,024 × 1,024 data blocks × 4 KB = 4 TB
```

Each additional level multiplies the amount of addressable file data by 1,024. This lets a fixed-size file header support increasingly large files.

![[Screenshot 2026-10-27 at 5.22.46 PM.jpg|500]]



Now, how would we search through these different layers of indirection block trees to find a specific block? Here's an example:

First, determine which part of the structure contains block 10,758.

1. The direct pointers cover blocks 0–7
2. The single-indirect pointer covers the next 1,024 blocks (8–1,031)
3. Our target block therefore falls within the double-indirect region of 1,024² = 1,048,576 blocks (1,032–1,049,607)


Subtract the blocks covered by the earlier regions:

```
10,758 - 8 - 1,024 = 9,726
```

So we need position 9,726 within the double-indirect region.


Each entry in its first pointer block leads to another pointer block covering 1,024 data blocks. Division tells us which entry to select:

```
9,726 // 1,024 = 9
```

Read the pointer block referenced by the file header’s double-indirect pointer, then select entry `[9]`. That entry tells us where the next pointer block is.


The remainder tells us which entry to select within that next block:

```
9,726 % 1,024 = 510
```

Read that pointer block and select entry `[510]`. This entry gives us the location of file block 10,758.

The complete path is:

```
File header’s double-indirect pointer
    -> first pointer block: entry[9]
    -> second pointer block: entry[510]
    -> requested data block
```

Both entries are selected by direct array indexing.


---

## But Is This Good For The Hardware?

FAT and the Unix file system provide logical ways to organize files and locate their data blocks. However, these structures alone do not ensure that the blocks are physically arranged for efficient disk access.

On a hard disk, accessing scattered blocks requires seeking and waiting for rotation, while accessing sequentially placed blocks can be much faster. A file system therefore needs to consider both how it locates blocks and where it places them.

Next class, we’ll revisit how disks work and examine how the Fast File System (FFS) uses those hardware properties to improve data placement and access performance.