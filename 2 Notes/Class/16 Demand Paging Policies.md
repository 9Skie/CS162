Now that we understand demand paging, we know that the OS can move pages between disk and RAM, treating RAM as a cache for disk, much like cache is to RAM.

Even with demand paging, we can still encounter the problem that RAM becomes full. And when it's full, if we want to run a program, a page must be brought into RAM before the program can access its contents.

This brings us to the question: when we need to bring in another page, which page should we remove from RAM to make room? This is the problem of page replacement, and just like how we have many scheduling algorithms for what process to run next, we have page replacement algorithms to determine which page to 'evict' next.

---

## Working Set Model

The working set model says that, during a particular period, a process mainly uses a certain subset of its pages. That subset is its working set, and it changes as the process moves between different parts of its work.

![[Screenshot 2026-10-11 at 2.14.19 PM.jpg|500]]

And this actively explains our goal in page replacement, keep the pages the process is actively using in RAM, and evict pages it no longer needs right now.
- As we can see, the bigger the cache, the more the hit rate

![[Screenshot 2026-10-11 at 2.12.59 PM.jpg|500]]

---

## Page Replacement Policies

This is a skim through some of the basic page replacement ideas.

First in, first out (FIFO) evicts the page that has been in memory the longest.
- This treats pages equally based on when they entered memory, but doesn’t consider how they are used. A frequently used page may be evicted simply because it arrived before a rarely used page.

Second, MIN evicts the page whose next use farthest in the future.
- While this sounds good in paper, the problem is that we don't know the future accurately and can only make assumptions about it.


So a pretty good policy is LRU (Least Recently Used), which evicts the page that has not been accessed for the longest time.
- The idea is to use the past to predict the future. 
	- Because programs have temporal locality, recently used pages are likely to be used again soon, while pages unused for a while may no longer be needed.


We could implement this using a list:
1. Whenever a page is accessed, move its entry to the head.
2. The head represents the most recently used page, and the tail represents the least recently used.
3. When we need to evict a page, choose the tail.

![[Screenshot 2026-10-11 at 2.20.24 PM.jpg|500]]

The problem is the overhead: maintaining this exact order requires tracking every memory access and updating the list accordingly. That would make memory accesses expensive, so practical paging systems approximate LRU.



Suppose we have the following:
- 4 virtual pages: four chunks of the process’s virtual address space.
- 3 page frames: space in RAM to hold only three of those pages at once.
- `A B C A B D A D B C B`: the order in which the process accesses those pages.

We'll see how each page replacement strategy performs.


FIFO:

![[Screenshot 2026-10-11 at 2.23.18 PM.jpg|500]]

1. Load A, B, and C into the three empty page frames.
2. Access A and B again: both are already in memory. These accesses do not change their FIFO order.
3. Access D: evict A, which entered memory first, and replace it with D.
4. Access A: evict B, now the oldest page, and replace it with A.
5. Access D again: it is already in memory.
6. Access B: evict C, now the oldest page, and replace it with B.
7. Access C: evict D, now the oldest page, and replace it with C.
8. Access B again: it is already in memory.

In total, this causes 7 page faults, as we can see, when referencing D, replacing A is a bad choice as it's referenced again almost instantly.


LRU:

![[Screenshot 2026-10-11 at 2.26.02 PM.jpg|500]]

LRU:

1. Load A, B, and C into the three empty page frames.
2. Access A and B again: both are already in memory. These accesses make C the least recently used page.
3. Access D: evict C, which has gone the longest without being accessed, and replace it with D.
4. Access A, D, and B: all are already in memory. After these accesses, A is the least recently used page.
5. Access C: evict A and replace it with C.
6. Access B again: it is already in memory.

There are 5 page faults instead of 7.

---

## Page Fault And Frame Numbers

As the number of page frames increases, we generally expect fewer page faults because more pages can remain in memory. 

However, some policies, such as FIFO, can produce more page faults despite having more frames due to a phenomenon called Belady’s anomaly.

![[Screenshot 2026-10-11 at 2.29.07 PM.jpg|500]]

---

## Clock's Algorithm For Approximating LRU

The Clock algorithm approximates LRU: it tries to evict a page that hasn’t been used recently, without maintaining an exact order of accesses.

Imagine all the page frames arranged in a circle, with a “clock hand” pointing at one frame. Each page has a use bit:

- `1`: the page has been accessed since the bit was last cleared.
- `0`: it hasn’t been accessed since then.

Whenever a page is accessed, the hardware sets its use bit to `1`.

When the OS needs a frame for a new page:

1. Check the page under the clock hand.
2. If its use bit is `1`, clear it to `0` and move on. We give that page another chance because it was used recently.
3. If its use bit is `0`, evict that page and reuse its frame.
4. Advance the hand so the next search continues around the circle.


For example, suppose we have 10 physical frames, numbered `0` through `9`, all occupied. The clock hand starts at frame `0`, and their use bits are:

```
Frame:    0 1 2 3 4 5 6 7 8 9
Use bit:  1 1 0 1 0 1 1 0 1 0
          ↑
       Clock hand
```

When a new page needs a frame:

1. Frame `0` has use bit `1`: clear it to `0` and advance.
2. Frame `1` has use bit `1`: clear it to `0` and advance.
3. Frame `2` has use bit `0`: evict its page and load the new page into that frame.
4. Advance the hand to frame `3` and stop searching. The next replacement search starts there.

When the process accesses the newly loaded page, its use bit becomes `1`. If it accesses the pages in frames `0` or `1` again, their bits also become `1`.
- The hand eventually wraps around from frame `9` to frame `0`.


---

## N-th Clock Algorithm

The Nth-chance Clock algorithm approximates LRU by giving pages more chances before evicting them.

Imagine all the page frames arranged in a circle, with a “clock hand” pointing at one frame. Each page has a use bit and a counter:
- Use bit `1`: the page has been accessed since the bit was last cleared.
- Use bit `0`: it hasn’t been accessed since then.
- Counter: how many consecutive checks have found the use bit at `0`. It starts at `0`.

Whenever a page is accessed, the hardware sets its use bit to `1`.

When the OS needs a frame for a new page:

1. Check the page under the clock hand.
2. If its use bit is `1`, clear it to `0`, reset its counter to `0`, and move on. We give that page a fresh set of chances because it was used recently.
3. If its use bit is `0`, increase its counter by `1`. If the counter is still below `N`, move on.
4. If the counter reaches `N`, evict that page and reuse its frame.
5. Advance the hand so the next search continues around the circle.

With `N = 1`, this behaves like the basic Clock algorithm. A larger `N` gives pages more chances, but requires more scanning before finding a page to evict.