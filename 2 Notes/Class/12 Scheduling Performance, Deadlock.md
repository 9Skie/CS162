## More On CFS

As we recall, CFS tries to track how much CPU service each thread has received, then tries to balance the CPU service per thread by prioritizing the ones behind.

![[Screenshot 2026-10-09 at 10.49.13 PM.jpg|500]]

This is, sure, absolutely fair, but doesn't acknowledge priorities in jobs. What if we want to give more CPU to some and less to others in CFS (proportional share)?

A weight represents how much CPU service a thread should receive relative to other threads. A thread with four times the weight should receive four times as much CPU time.

How would we do this? Through nice values and weights.


1. Express priority using `nice` values and weights.

    - Each thread has a `nice` value ranging from −20 to 19. A lower value means higher priority; a higher value means being “nicer” by allowing other threads more CPU time.
    
    - CFS converts this into a weight using the lecture’s formula:
	    - $w_i = \frac{1024}{1.25^{\text{nice}_i}}$
    
    - Lower `nice` values therefore produce larger weights.


2. Use weights to divide CPU time.

    - The basic equal share gives every thread the same time slice:
	    - $Q_i = \text{Target Latency}\cdot\frac{1}{N}$
		    - $N$ is the number of runnable threads

    - The weighted share gives each thread a time slice proportional to its weight:
		- $Q_i = \text{Target Latency}\cdot\frac{w_i}{\sum_p w_p}$
		    -  $w_i$ is thread $i$’s weight
			- $\sum_p w_p$ is the total weight of all runnable threads. 
			- Their ratio tells us what fraction of the CPU time thread $i$ should receive.


3. Track virtual runtime to measure progress relative to these shares.
    - Virtual runtime simply means a ratio between actual runtime and weight, the higher the weight, the lower virtual runtime, and the more frequent the thread gets picked.
	    - $\Delta\text{virtual runtime} = \frac{\text{actual time run}}{\text{weight}}$

4. Choose the runnable thread with the lowest virtual runtime.
    - CFS believes that thread (with the lowest virtual runtime) is furthest behind relative to its intended share, and so it selects it.
    - ![[Screenshot 2026-10-10 at 1.03.08 AM.jpg|500]]

---

## Deadlock

Simply, deadlock is a starvation situation that cannot resolve without external intervention because it involves circular waiting for resources.

- Thread A owns resource 1 and waits for resource 2, which is held by thread B. -
- Meanwhile, thread B owns resource 2 and waits for thread A to release resource 1.

Neither thread can proceed to release its resource, so both remain blocked.

![[Screenshot 2026-10-10 at 2.25.35 PM.jpg|500]]


Here is an example:

Suppose two threads need locks `x` and `y` before doing their work, but acquire them in opposite orders:

```C
Thread A:              Thread B:
x.Acquire();           y.Acquire();
y.Acquire();           x.Acquire();

... do work ...        ... do work ...

y.Release();           x.Release();
x.Release();           y.Release();
```

Deadlock occurs with this execution order:

1. A acquires `x`.
2. B acquires `y`.
3. A tries to acquire `y`, but B holds it, A gets blocked while still holding `x`.
4. B tries to acquire `x`, but A holds it, B gets blocked while still holding `y`.

Both threads are now waiting for each other. Neither can reach its `Release()` calls, so neither lock becomes available.

---

## When Deadlock Occur

Now that we understand what a dead lock is, how does it occur? There are 4 cases.

Using our two-lock example:

1. Mutual exclusion  
    - Only one thread can hold a particular lock at a time. If A holds `x`, B cannot acquire `x` until A releases it.
    
2. Hold and wait  
    - A thread keeps what it already holds while waiting for something else. A holds `x` while waiting for `y`; B holds `y` while waiting for `x`.
    
3. No preemption  
    - A lock cannot be forcibly taken away from its owner. A must release `x` itself, and B must release `y` itself.
	    - There is no other mechanism for the lock to be forcefully released.
    
4. Circular wait  
    - The waiting forms a cycle: A waits for B’s lock, while B waits for A’s lock. Neither can proceed first.
    

All four are necessary for deadlock.


---

## Detecting Deadlock

The four conditions above help us understand how our code could allow deadlock to occur. As programmers, we can prevent deadlock by designing our code so that at least one of these conditions cannot hold.

However, if deadlock does occur, we need a way to detect it before we can resolve it. This leads to the next question: how can we identify threads that are stuck waiting for resources held by one another?


First, we model the system using a resource-allocation graph containing:

- A set of threads: $T_1, T_2, \ldots, T_n$.
- A set of resource types: $R_1, R_2, \ldots, R_m$, such as memory space or I/O devices.
- Each resource type $R_i$ has $W_i$ instances, individual units of that resource type.

Each thread uses a resource in three stages:
1. Request: ask to acquire an instance of the resource, waiting if necessary.
2. Use: perform the work that requires the acquired resource.
3. Release: give up the resource so another thread can acquire it.


A simple resource allocation graph would look as such:

- Request edge: $T_i \rightarrow R_j$ means thread $T_i$ is requesting an instance of resource type $R_j$ and is waiting to acquire it.

- Assignment edge: $R_j \rightarrow T_i$ means an instance of resource type $R_j$ has been granted to thread $T_i$, which currently holds it.

Once a request is granted, its request edge is replaced by an assignment edge. When the thread releases the resource, the assignment edge is removed.


This is a normal resource allocation graph:

![[Screenshot 2026-10-10 at 2.39.28 PM.jpg|200]]


This is a graph with a deadlock, the deadlock involves all three threads:

![[Screenshot 2026-10-10 at 2.45.30 PM.jpg|200]]

- $T_1$ holds one instance of $R_3$ and waits for $R_1$, which $T_2$ holds.
- $T_2$ holds $R_1$ and the other instance of $R_3$. It waits for $R_2$, which $T_3$ holds.
- $T_3$ holds $R_2$ and waits for an instance of $R_3$. Both instances are held by the blocked threads $T_1$ and $T_2$.

So $T_1$ waits for $T_2$, $T_2$ waits for $T_3$, and $T_3$ waits for $T_1$ or $T_2$ to release an $R_3$ instance.

None can proceed and release what it holds, so all three remain blocked.


With this understanding, how can we detect deadlocks? We can check this on paper by pretending threads finish.

This psudocode checks whether the threads could finish one by one. Each time it finds one that could finish, it pretends that thread releases its resources.

```C
[FreeResources]  // Number of currently free instances of each resource type.
[Request_X]      // Number of instances of each type currently requested by thread X.
[Alloc_X]        // Number of instances of each type currently held by thread X.

[Avail] = [FreeResources]
Add all threads to UNFINISHED
do {
    done = true  // Assume this pass will make no progress.

    for each thread X in UNFINISHED {

        // Check whether every requested resource can be supplied.
        if ([Request_X] <= [Avail]) {

            // Pretend X finishes and releases the resources it holds.
            remove X from UNFINISHED
            [Avail] = [Avail] + [Alloc_X]

            done = false  // We made progress; check again.
        }
    }
} until (done)

// Any threads remaining in UNFINISHED are deadlocked.
```


---

## How to avoid Deadlocks

The big idea for avoiding deadlock is that when a thread requests a resource, the OS should check if it would result in an unsafe state that would end in a deadlock.
- if no, the OS grants it
- if so, it waits for other threads to release resources

Banker’s algorithm (the one that tries to solve deadlocks based on the idea we discussed above) checks before granting a resource: if we grant this request, will there still be an sequence of events in which every thread can finish?


The big idea goes as such:

1. Every time a thread tries to acquire resources, we consider each thread’s declared maximum resource needs, the resources currently assigned to it, its remaining needs, and the resources currently available.

2. We then pretend to grant the request and check whether the resulting available resources could satisfy some thread’s remaining needs, allowing it to finish and release its resources. We repeat this process to see whether those released resources could eventually allow every thread to finish.

3. If every thread could finish, we grant the request. Otherwise, we delay


For the actual computations, we need some numbers to track per thread, for each thread X, we track:

- $\text{Max}_X$: the maximum number of instances of each resource type that X might need at once, which the thread declares in advance.

- $\text{Alloc}_X$: the number of instances of each resource type that X currently holds.

- $\text{Remaining Need}_X$: the additional resources X might still need before finishing:
    - $\text{Remaining Need}_X = \text{Max}_X - \text{Alloc}_X$

 - $\text{Avail}$: the number of currently available instances of each resource type.


When a thread requests resources:

1. If the requested resources are available, pretend to grant them. Decrease $\text{Avail}$, increase that thread’s $\text{Alloc}$, and recalculate its remaining need.
    
2. Look for a thread whose remaining need can be satisfied by $\text{Avail}$. There must be enough of every resource type it might still need.
    
3. Pretend that thread receives what it needs, finishes, and releases all its resources. Mark it as finished. The resources it previously held now become available to other threads.
    
4. Repeat this check for the unfinished threads, using the updated available resources.
    
5. If every thread can be marked finished, the proposed allocation is safe, so grant the original request. If threads remain and none can finish, do not grant it; make the requesting thread wait.

This is very similar to the deadlock detection algorithm we mentioned above.


For our two-lock example, both A and B declare that they need `x` and `y`:
- Both threads declare $\text{Max}=[1,1]$ , since each needs both locks.
	- We write resource counts as $x,y$.

```C
Thread A:              Thread B:
x.Acquire();           y.Acquire();
y.Acquire();           x.Acquire();

... do work ...        ... do work ...

y.Release();           x.Release();
x.Release();           y.Release();
```

Assume A runs first.

1. A requests `x`.
    - We pretend to grant it, A’s $\text{Alloc}=[1,0]$, so its remaining need is $[0,1]$

2. We check the current availability of resources to see if A could acquire `x`: 
	-  $\text{Avail}=[0,1]$, meaning `y` is free
	- A could receive `y`, finish, and release both locks. 
	- B could then receive both and finish. 
	- The check succeeds, so A acquires `x`.

3. B requests `y`.
    - Pretending to grant it produces the following table:

| Thread | Max   | Alloc | Remaining need |
| ------ | ----- | ----- | -------------- |
| A      | $1,1$ | $1,0$ | $0,1$          |
| B      | $1,1$ | $0,1$ | $1,0$          |

$\text{Avail}=[0,0]$, meaning none would be free.
- A needs `y`, and B needs `x`. Neither remaining need can be satisfied, so neither can be marked finished.
- The check fails. B does not acquire `y`; it waits inside `y.Acquire()`. `y` remains free.

4. A requests `y`.
    - Pretend to grant it. A would hold both locks, so its remaining need becomes $0,0$.
    - A can therefore be marked finished, returning both locks. B’s remaining need can then be satisfied, so B can also be marked finished.
    - The check succeeds, so A acquires `y`.

5. The actual execution continues.
    - A does its work and releases both locks. B can then acquire `y`, acquire `x`, do its work, and release them.
    

Banker’s algorithm intervenes at B’s first acquisition: it makes B wait even though `y` is free, because granting it would leave no possible completion sequence.
