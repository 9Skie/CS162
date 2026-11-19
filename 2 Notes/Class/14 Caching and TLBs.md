A process’s virtual address space often contains large unused regions. In a simple page table, the entries corresponding to those regions are marked invalid.

![[Screenshot 2026-10-10 at 8.15.47 PM.jpg|500]]

![[Screenshot 2026-10-10 at 8.16.05 PM.jpg|500]]

![[Screenshot 2026-10-10 at 8.16.17 PM.jpg|500]]

This leaves room for the stack and heap to grow during execution. When they need more memory, the OS can allocate physical frames wherever there is room and update the corresponding page-table entries.


The problem is that a simple page table needs an entry for every virtual page in the address range it covers, including unused pages.

For example, suppose the table covers a 4 MiB virtual address range. With a common page size of 4 KiB:

$\text{Number of entries} = \frac{4\text{ MiB}}{4\text{ KiB}} = 1024$

Each entry represents one virtual-to-physical mapping. If each entry is 4 bytes, the table occupies $1024 \times 4 = 4096$ bytes, or 4 KiB.

$\text{Page-table size} = \text{Number of entries} \times \text{Size of each entry}$


However, a process’s virtual address space often contains large unused gaps between its code, heap, and stack. A simple page table still stores an entry for every virtual page in the range it covers, including those unused pages.

Although unused pages do not require physical frames, their invalid page-table entries still occupy memory. This means a large portion of the page table can consume memory without providing any useful mappings.

So what can we do?

---

## Table In a Table

While we have discussed of these ideas in CS61C, we will discuss of them again here.

We will use a tree data structure to divide the page table into multiple levels, which a table points to another table, then finally points to a physical frame.

![[Pasted image 20261010202732.png|500]]


Using our 1,024-entry example, assume only the first 32 virtual pages are used. 

- In the original case, we still store all 1,024 entries, even though the 992 entries in between are invalid.
- In the two layer map table, we would divide those 1,024 entries into 64 smaller tables, each containing 16 entries, and we only allocate a second-level table when its group contains a used virtual page. 

In this example:
- The first 2 groups are used, so we allocate 2 16 entry tables.
- The rest 62 groups are unused, so we allocate no tables for them. 
	- Their first-level entries are simply marked invalid.

The total is therefore:

$64 \text{ first-level entries} + 2 \times 16 \text{ second-level entries} = 112 \text{ entries, not } 1024$

We still represent every used page, but each unused group now costs just one invalid first-level entry instead of 16 invalid entries.


A hierarchical page table saves memory by only creating page table structures for the parts of the virtual address space that a process actually uses. 
- It trades slightly more complex translation for much lower memory overhead.

---
## Multi-level Translation

So, how do we represent this tree of tables?

![[Screenshot 2026-10-10 at 8.58.31 PM.jpg|500]]

In this design, which combines segmentation and paging, a virtual address is divided into a virtual segment number, a virtual page number, and an offset.

The virtual segment number selects an entry in the first-level segment table. That entry’s base points to the second-level page table for that segment. The virtual page number then selects an entry in that page table.

At the first level, we check that the segment is valid and the page number is within its limit. At the second level, we check that the page is valid and the requested access is permitted.

The second-level entry gives us the physical frame number. We combine it with the unchanged offset to obtain the physical address.

---
## Inverted Page Tables

So, while multilevel tables save memory, looking through several tables (if we have more layers) makes address translation slower, how do we make it fast?

The simple answer is to just use a hash table!
- We only store mappings for pages currently in physical memory, rather than allocating entries for every possible virtual page.

![[Screenshot 2026-10-10 at 9.16.26 PM.jpg|500]]

We hash the virtual page number to locate its mapping, retrieve the physical frame number, and combine it with the unchanged offset to obtain the physical address.

---

## TLBs

Bro I'm not even gonna bother write this one again, we knew this from CS61C.

[[110 Learning/112 CS/112.2 SWE/2 What is a Computer/1 UCB CS61C/2 Notes/30 Virtual Memory 2/3 Translation Lookaside Buffer|3 Translation Lookaside Buffer]]

Accessing a page table takes time because it is stored in memory. With a single-level page table, one memory access can become two: first look up the physical frame number, then access the actual data.

The TLB is basically a cache for virtual-to-physical page translations, just speeds things up.
- If the translation is already in the TLB, we immediately obtain the physical frame number, called a **TLB hit**.
- If the translation is missing, called a **TLB miss**, the hardware walks the page table in the x86 design we are discussing.