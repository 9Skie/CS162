From the beginning, we knew that CPU scheduling is a core part of the OS's purpose, but we never looked into how this process is achieved, or how it is optimized.

CPU scheduling is a technique used by the operating system to determine which process gets to use the CPU at a given time, based on some criteria.

As we recall, when a program is executed, it becomes a process, the OS reserves a chunk of memory for it, and recall from computer architecture, this is the layout of a process in memory.

![[Screenshot 2026-07-28 at 9.46.29 AM.jpg|200]]

- text is the executable file itself
- data is the global variables and constant values
- then there's the heap and stack
	- heap stores generated data in runtime
	- stack store information returned by function calls

When a process is being executed by the CPU, inside it, there are many registers, a process uses these components to manipulate data.

![[Screenshot 2026-07-28 at 10.14.48 AM.jpg|300]]

A process's state is described by a process control block, it tracks a process's every aspect, which abstractly looks something like this:

![[Screenshot 2026-07-28 at 11.11.25 AM.jpg|400]]

with all of this background knowledge, we can finally start looking at the topic today CPU scheduling.

---
## CPU & IO Bursts

Say we were given a program that writes from a file to another file, 8 bytes at a time to avoid large use of memory.

![[Screen Recording 2026-07-30 at 9.59.32 AM.mov.gif|500]]

Now, it might seem like the instructions inside the loop for this copying just executes sequentially and then loop as usual...

![[Screen Recording 2026-07-30 at 10.01.16 AM.mov.gif|500]]

But in reality, as we recall, due to delays of system calls, the loop actually looks more like this.

![[Screen Recording 2026-07-30 at 10.02.21 AM.mov.gif|500]]

This is because system calls are slow, as they invoke usually IO operations, the following instructions after system calls just cannot be executed immediately, as they have to wait for the system call to return.


With this understanding, we can map out a program's CPU use over time, as we can see, it doesn't use the CPU continuously at all, these gaps are the norm.
- The green blocks are when the CPU is used for execution over time, it's called a CPU burst
- The grey blocks are when the CPU is idle over time, but the IO is working to return some value, it's called an IO burst

![[Screenshot 2026-07-30 at 10.05.34 AM.jpg|500]]

Every computer program follows the norm of a CPU burst to begin, then an IO burst, then a CPU burst, then an IO burst... and ending with a CPU burst to terminate the process.

The duration of these CPU bursts have been extensively measured, and they follow a distribution like this:

![[Screenshot 2026-07-30 at 10.07.59 AM.jpg|500]]

- As we can see, most CPU bursts are rather short, but it doesn't mean long CPU bursts don't exist
- Also, that means processes spend a lot of time waiting on IO operations
	- ![[Screenshot 2026-07-30 at 10.11.31 AM.jpg|500]]

With this understanding, we can now go look at the life cycle of a CPU program.

---
## Life Cycle of a CPU Program

1. Every program begins in the `new` state
2. Once the program is fully loaded, the process enter the `ready` state
3. When the CPU is assigned to a process, it is in the `running` state
4. When the process make a system call (IO request), or wait for some event, the process turns into the `waiting` state
5. When the request (IO or event) is finished, it gets back into the `ready` state
	- It doesn't go back directly to running since the CPU likely is allocated to another process while it is waiting
6. Eventually, a process enters a `terminated` state

![[Screenshot 2026-07-30 at 10.31.12 AM.jpg|500]]

There are many processes running at the same time of the computer, and so all processes waiting to be in the `new`, `ready`, `waiting`, `terminated` state are all in queues.
- The running state cannot be a queue, as 1 CPU core can only execute 1 running state at a time

![[Screenshot 2026-07-30 at 10.33.07 AM.jpg|500]]


There is another component of the operating system, called the dispatcher, which performs the context switching of moving currently interrupted process at the end of the waiting queue.

![[Screen Recording 2026-07-30 at 10.40.59 AM.mov.gif|250]]

And then moving the next process in the ready queue into the running queue.

![[Screen Recording 2026-07-30 at 10.42.50 AM.mov.gif|250]]


And such, this process for context switching itself will inevitably create overhead for the CPU, this is called the dispatch latency.

![[Screenshot 2026-07-30 at 10.45.17 AM.jpg|500]]

---
## CPU Scheduler

Now as we said, `new`, `ready`, `waiting`, `terminated` state are all in queues, so isn't the problem of scheduling solved already? Not quite, the `ready` queue is the special one that must be looked into detail.

The `ready` queue contains all processes that are prepared to run, but the operating system still needs to decide **which one should run next**. Simply choosing the process at the front is only one possible strategy. Different scheduling algorithms make different trade-offs between responsiveness, fairness, throughput, and CPU utilization.

![[Screenshot 2026-07-30 at 10.53.23 AM.jpg|500]]

---
## First Come First Served

The simplest idea is for the `ready` queue to just be... a queue, where the first processing coming is first served.

To be more precise, it's not necessarily that we finish running the 1st process, we still do the context switching when a process is interrupted, so to be more precise, it's first (CPU-burst) come first served

![[Screen Recording 2026-07-30 at 10.56.04 AM.mov.gif|500]]

This is not optimal due to a problem called 'convoy' effect, let's start from the background information first.

While we have said most processes have lots of short duration CPU bursts, it's not impossible that a process have lots of long duration CPU bursts.
 - we call the ones with lots of short duration CPU bursts as IO bound processes (as their speed is usually dragged behind by how fast the IO can be)
 - we call the ones with lots of long duration CPU burst as CPU bound processes (as their speed is usually dragged behind by how fast the CPU can be)

![[Screenshot 2026-07-30 at 11.00.51 AM.jpg|500]]


These CPU bound processes are the bottleneck to this very simple algorithm, imagine if we have 1 CPU bound process and multiple IO bound processes, the CPU bound process will always get and hold the CPU for a long time before giving the CPU access to the other IO bound processes.
- During this time, the IO bound processes already have finished their IO operations and are waiting in the ready queue, just being idle.

![[Screen Recording 2026-07-30 at 11.11.28 AM.mov.gif|500]]

---
## Shortest Job First

Now, this is just assigning the CPU to the process with the shortest next CPU burst, if there's a tie, first come first served breaks the tie.

![[Screen Recording 2026-07-30 at 11.14.50 AM.mov.gif|500]]

While this is the mathematically most optimal scheduling algorithm, we can already see an issue, for the very long CPU burst processes, it always just sits in the waiting queue, never to be executed as there's constantly shorter CPU burst processes that appear from the waiting queue.
- This is called starvation

![[Screenshot 2026-07-30 at 11.39.02 AM.jpg|500]]


Another issue is that there's no way we can guess 'the next cpu burst duration', and hense no way to determine 'the longest/shortest next cpu burst duration'.

![[Screenshot 2026-07-30 at 11.18.58 AM.jpg|500]]

The best we can do is estimate the next cpu burst duration as an exponential moving average (yes, just like the optimizer Adam) of the previous measured cpu bursts.

![[Screenshot 2026-07-30 at 11.25.11 AM.jpg|500]]
- a is just a tweaked parameter 

While this approach isn't perfect, it works decently

![[Screenshot 2026-07-30 at 11.27.22 AM.jpg|500]]

---
## Round Robin

To avoid starvation, this scheduling algorithm is created, where it is similar to first come first served, but we add a timer to force control to switch between processes, just like how we have interrupts to force control back to the OS.
- this time is called a time quantum

When a cpu process goes into the running state, 1 of 2 things will happen to it:
- the process has a cpu burst time of less than 1 time quantum
	- it gets released voluntarily
- the process has a cpu burst time of more than 1 time quantum
	-  the timer goes off and causes an interrupt, putting it back to the end of the ready queue
		- why the ready queue, you might ask? Since it didn't call any IO operation

![[Screen Recording 2026-07-30 at 11.55.49 AM.mov.gif|500]]


And so, we have to update the diagram a bit, as now processes can directly go back from the running state to the ready state.

![[Screenshot 2026-07-30 at 11.57.20 AM.jpg|500]]

While round robin fairly distributes CPU time, the context switching overhead is hard to manage, if the time quantum is too quick, there's too much context switching, if the time quantum is too slow, it just behaves like first come first serve.

---
## Priority Scheduling

The problem with round robin is that there is no priority given to processes, as it treats the CPU evenly to all processes, but this is unlike real computer systems, where clearly user experience matters most, and what is showing on screen to the user should be given the utmost priority.

![[Screenshot 2026-08-03 at 9.29.36 PM.jpg|500]]

If we can correctly identify which processes need higher priority, we can significantly improve overall CPU responsiveness, and such is called priority scheduling.

It's implemented with a priory queue, where each process is given an integer value representing it's priory.
- it could be higher values are higher priory, or lower values are higher priory, depends on the system

![[Screenshot 2026-08-03 at 9.41.25 PM.jpg|500]]

Basically, processes with a higher priority goes before processes with low priory, and for processes with the same priority, it's just first come first serve, which can be combined with round robin to give equal attention to processes with equal priority.

But again, raw priory scheduling suffers from starvation as processes with lower priory might never run in the queue.

![[Screenshot 2026-08-03 at 9.41.49 PM.jpg]]


So one idea called `aging` tries to solve this by making processes that sit in the priority queue become higher as the process starves longer inside the queue, so it eventually becomes a high priority process and runs ahead of other processes .

![[Screenshot 2026-08-03 at 9.42.42 PM.jpg|500]]

Going more complicated, we could set up multi-level queue scheduling, where we have multiple queues each with their own respective priory level processes, and scheduling jsut dispatches the process in the highest priory non empty queue.

Or do it round robin style... Or even going crazier, diving processes queues by functionality and then giving each queue it's own scheduling algorithm

I think it's good stop here, there was more talk on more advanced scheduling algorithms by a bit, but you get the gist.

