Now that we understand a few different scheduling algorithms and their tradeoffs, now we have to ask: how do we actually make a scheduler that handles a mixture of interactive and compute-heavy applications?


Imagine you’re playing a video game while a network service runs in the background. You also occasionally move your mouse or press a key.

The threads handling your input spend much of their time waiting, since you act slowly compared with the CPU. But when you do press a key, you want the game to react immediately. The network service also waits for data, then needs CPU time when something arrives. Meanwhile, the game has demanding work to do and wants plenty of CPU time.

So the OS must decide how to share the CPU: respond quickly to input and incoming data while allowing the game’s computation to keep moving.

---

## Multi Level Feedback Scheduling

Lets start by looking at a common structure in scheduling, where we have multiple levels (priorities) of queues.

For higher priority queues, we call them 'foreground' tasks, and for lower priority queues, we call them 'background' tasks.

Each queue has it's own scheduling algorithm, for example:
- foreground tasks -> first come first serve
- background tasks -> round robin

![[Screenshot 2026-10-07 at 10.52.09 PM.jpg|500]]

We adjust each job's priority in the following heuristic:
- Every job starts in the highest-priority queue.
	- If it uses its entire CPU time slice, move it down one level
		- it seems to need lots of computation.
	- If it stops early to wait for I/O, move it up one level
		- it seems to need short bursts and should respond quickly when it wakes up.


While this seems to work nicely, there's a problem, we made the assumption the job will/wont use up it's whole slice quantum, and our scheduling priority is highly based on that outcome.

But this could be manually manipulated, say a process wants to fool the OS to pretend to be a constant high priority process, it can fill the rest of it's time quantum with meaningless IO operations for the OS to move it up levels in priority.

---

## Case Study, Linux Scheduler

Roughly, Linux’s old O(1) scheduler combines priority queues with rounds of CPU time.

For ordinary tasks:
1. Each CPU keeps two sets of priority queues: active and expired.
2. It selects the highest-priority runnable task from the active set.
	- Tasks at the same priority take turns.
3. When a task uses up its allotted CPU time, it normally moves to the expired set, meaning “you’ve had your turn this round.”
4. When the active set becomes empty, the two sets swap. 
	- Everyone in the expired set can now take another turn.
5. It adjusts priorities using past behavior: tasks that sleep a lot get a boost, while tasks that compute continuously get less preference.

The O(1) part means it can find the next task quickly without searching through every task; it tracks which priority queues contain runnable tasks.


Well Linux did move on to something called the completely fair scheduler, we will discuss about later.

---

## Multi Core Scheduling

By the default model, each process contains 1 thread, but as we know (and have leant previously based on thread synchronization) one process can obviously have multiple threads.

And we know the OS really is switching between threads and threads on a core, when we have multiple cores, the idea is similar, but several threads can run simultaneously, so the OS now chooses which group of ready threads should run at the same time. 

If a thread runs on a core, sleeps, and later returns to that same core, it may reuse data still in the cache. 
- The OS therefore tries to keep it on the same core, this is affinity scheduling.
- But if one core is busy while others are idle, moving the thread may be better. 

---
## Real Time Scheduling

Now we’ve reached another scheduling requirement: how should we choose threads when finishing on time matters?

Assume each task has:

- A computation time (C): how much CPU time it needs to complete, assume this is known
- A deadline (D): the time by which it must finish.

For example, a task becomes ready at time 0, needs 2 ms of CPU time, and must finish by time 10 ms.

It doesn’t have to run immediately or continuously. The OS can run other tasks too, as long as this task receives its required 2 ms before its deadline.

![[Screenshot 2026-10-07 at 11.57.49 PM.jpg|500]]


The difficulty comes when several tasks need CPU time during overlapping periods. The OS must choose their order carefully so they finish on time.

Earliest deadline first (EDF) uses a simple rule: among tasks currently ready to run, choose the one whose deadline comes soonest.


Assume we have periodic tasks with Period $P$ and computation $C$ in each period $(P_i, C_i)$ for each task $i$, and we have 3 tasks: 

- $T_1=(4,1)$: every 4 time units, a new job needs 1 unit of CPU time.
- $T_2=(5,2)$: every 5 units, a new job needs 2 units.
- $T_3=(7,2)$: every 7 units, a new job needs 2 units.

![[Screenshot 2026-10-08 at 12.30.03 AM.jpg|500]]

---

## Starvation and Solutions

We’re now asking: does every runnable thread eventually get CPU time, or can some threads be kept waiting forever?
- Starvation means a thread keeps failing to make progress, even though other work may be running.


A simple idea would be to use a stack to queue tasks, giving us last-come, first-served scheduling. In this case, earlier tasks can wait indefinitely as new tasks keep arriving and taking priority.

This starvation can occur when the arrival rate exceeds the service rate and continues to do so.

![[Pasted image 20261009214506.png|500]]


---

## Priority Inversion

Priority inversion happens when a high-priority thread needs a lock held by a low-priority thread.

Assume (higher numbers mean higher priority)
- Job 1 has priority 1
- Job 2 has priority 2
- Job 3 has priority 3.


And this happens: 
1. Job 1 runs and acquires a lock.
2. Job 3 becomes ready and takes over the CPU because it has higher priority.
3. Job 3 needs the same lock, but it gets blocked because Job 1 holds it.
4. Job 2 now runs because its priority is higher than Job 1’s
	- Job 2 doesn't need the lock
5. Job 1 cannot run to release the lock, so Job 3 keeps waiting, and instead it's Job 2 that is actually running instead of Job 3 despite it's lower priority 

That is priority inversion: Job 2 indirectly delays Job 3, despite having lower priority.

![[Screenshot 2026-10-09 at 9.49.48 PM.jpg|500]]

Priority donation solves priority inversion by temporarily raising the priority of the thread holding a needed lock.

Since Job 3 is waiting for Job 1’s lock, Job 1 temporarily receives priority 3. 
- It can then run ahead of Job 2 and release the lock, allowing Job 3 to continue. 
- After releasing the lock, Job 1 returns to its original priority, assuming no other donations remain.

![[Screenshot 2026-10-09 at 10.03.50 PM.jpg|500]]

---

## Proportional Share Scheduling

Priority donation solves the problem of a high-priority job waiting for a lock held by a low-priority job. However, priority-based scheduling can still cause starvation: if higher-priority jobs keep running, lower-priority jobs may never receive CPU time.

We therefore want to favor some jobs while still ensuring that every runnable job makes progress. 
- Instead of always running higher-priority jobs first, we use priority to determine each job’s share of CPU time, where:
	- Higher-priority jobs receive a larger share.
	- Lower-priority jobs receive a smaller but positive share.

This allows us to favor certain jobs while preventing others from being completely excluded from the CPU.


But how is this possible? An idea is lottery scheduling, where each job gets a certain number of lottery tickets in proportion to it's priority (the higher the more tickets)

1. Whenever the scheduler chooses the next job, randomly draw one ticket from the runnable jobs’ tickets.
2. The job owning that ticket gets a CPU time slice. Repeat for the next scheduling decision.


While this gives some sort of proportionality, it also gives randomness, a job can lose many draws in a row, and so there's no fixed maximum waiting time.

That motivates the next approach: stride scheduling.

---

## Stride Scheduling

Stride scheduling gives jobs proportional CPU shares using counters instead of random draws.

Each job has:
- Tickets: determine its intended CPU share.
	- Stride: how much its counter increases after each turn, calculated as $\text{stride}=W/\text{tickets}$.
		- $W$ is a fixed number chosen by the scheduler to calculate strides
- Pass: the running counter used to choose the next job.

The scheduler repeatedly:
1. Picks the runnable job with the smallest pass.
2. Gives it a CPU time slice.
3. Adds that job’s stride to its pass.

With $W=10{,}000$:

|Job|Tickets|Stride|
|---|---|---|
|A|100|100|
|B|50|200|
|C|250|40|

C’s pass increases by only 40 each turn, while B’s increases by 200. Since the scheduler always chooses the smallest pass, C gets more turns before its counter catches up.

---

## Linux Completely Fair Scheduler

CFS uses an idea similar to stride scheduling: track how much CPU service each thread has received, then favor the runnable thread that is furthest behind.

Start with equally weighted threads:

1. Ideally, $n$ threads would each receive $1/n$ of the CPU.
	- ![[Screenshot 2026-10-09 at 10.49.13 PM.jpg|500]]

2. Since one core takes turns running them, CFS tracks their CPU runtime, this will inevitably cause imbalance.

3. It selects the runnable thread with the smallest runtime so that thread can catch up.
	-  ![[Screenshot 2026-10-09 at 10.50.09 PM.jpg|500]]

For example, if A has received 6 ms, B 2 ms, and C 4 ms, B should run next.