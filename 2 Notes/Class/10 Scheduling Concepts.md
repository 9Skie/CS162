We’ve discussed how to switch between threads, but how do we decide which thread to switch to?

```C
if ( readyThreads(TCBs) ) {
    nextTCB = selectThread(TCBs); // (but how?)
    run( nextTCB );
} else {
    run_idle_thread();
}
```

This is the big question that we'll look at the next 3 classes.


A way that we can think about scheduling is that: imagine there's a bunch of people lining up to use one toilet. What would be a reasonable order for letting them use it?

![[Screenshot 2026-10-07 at 4.46.12 PM.jpg|500]]

Should the person who only needs to urinate go first because they’ll finish quickly?Or should the person with a stomachache who can’t hold it get priority?

Each choice follows a different rule, and there's always consequences that come with the choices of scheduling, and that’s why scheduling is a complicated topic in operating systems.


Again, funny story, this was a big area of research back the 1970s when computers were scarce, there were tons of people lining up with their programs waiting to be run on the computer, and the operators had to find an efficient way to make everyone (literally people waiting in line) to be happy in fair share of the computer.

Now, we don't have tons of people lining up to use a single computer, we have tons of programs lining up in your computer wanting to use the CPU, and the same problem holds.

![[Pasted image 20261007170642.png|500]]


There's phenomenons that the scheduling algorithms have to consider, like the alternation between CPU bursts and I/O bursts.

Usually, a program runs instructions on the CPU for a while, called a CPU burst. Then it performs or waits for I/O, such as reading from or writing to disk, called an I/O burst. After that, it returns to another CPU burst, then another I/O burst, and so on.

![[Pasted image 20261007165431.png|200]]

CPU bursts vary from process to process, and from program to program, but an extensive study shows frequency patterns for burst durations.

![[Pasted image 20261007165741.png|500]]

When one program is waiting for I/O, it makes sense for another to use the CPU.
- However, the scheduler cannot know exactly how long the next CPU burst will last, basically how long the program will run before it finishes or waits for I/O again (are we just gonna guess based on that distribution)?



A scheduling policy decides which ready thread gets the CPU next and how long it can run. We judge it using three main goals:

1. Minimize response time: reduce how long users wait for an operation, such as displaying a keystroke or compiling a program.
    
2. Maximize throughput: complete as many operations or jobs per second as possible. 
	- This means reducing overhead, such as excessive context switching, 
	- Using resources like the CPU and disk efficiently.
    
3. Maintain fairness: distribute CPU time equitably among users or programs, so some do not get neglected.

These goals can conflict, and it's just balance as we say it.


---

## First Come First Serve

The simplest version of a scheduling algorithm, where literally we run a program head to tail.

Suppose we have 3 little processes:

|Process|Burst time|
|---|---|
|$P_1$|24|
|$P_2$|3|
|$P_3$|3|

Suppose all processes are ready at time $0$, and we ran them in the order of $P_1, P_2, P_3$.

![[Screenshot 2026-10-07 at 5.24.36 PM.jpg|500]]

- Waiting time for each process: 
	- $P_1 = 0$, 
	- $P_2 = 24$
	- $P_3 = 27$

- Average waiting time: 
	- $(0 + 24 + 27)/3 = 17$.

- Completion time for each process: 
	- $P_1 = 24$
	- $P_2 = 27$
	- $P_3 = 30$

- Average completion time:
	- $(24 + 27 + 30)/3 = 27$.


The problem with this scheduling algorithm is we encounter something called the convey effect, where short processes get stuck behind long processes.

![[Pasted image 20261007173421.png|500]]



## Short Job First

A direct simple fix would just be letting the shorter jobs run before the longer job, so we can have a lower average waiting and completion time.

So instead, imagine if we ran it in the order of $P_2, P_3, P_1$...

- Waiting time for each process: 
	- $P_1 = 6$, 
	- $P_2 = 0¥
	- $, $P_3 = 3$.

- Average waiting time: 
	- $(6 + 0 + 3)/3 = 3$.

- Completion time for each process: 
	- $P_1 = 30$
	- $P_2 = 3$
	- $P_3 = 6$

- Average completion time: 
	- $(30 + 3 + 6)/3 = 13$.

![[Screenshot 2026-10-07 at 5.55.16 PM.jpg|500]]


But this encounters the opposite problem, the longer jobs will be constantly waiting and never get run since shorter jobs go first before it, this is called starvation.

---

## Round Robin

Round robin just goes 'shut up! everyone gets equal amount of time on the CPU!'
- Basically each process gets a small unit of cpu time, and after the cpu time expires, the process is preempted (interrupted, basically) and then thrown back to the end of the ready queue.

![[Pasted image 20261007180036.png|500]]


An example is as such:

|Process|Burst time|
|---|---|
|$P_1$|53|
|$P_2$|8|
|$P_3$|68|
|$P_4$|24|

Suppose all processes are ready at time $0$, with an initial queue order of $P_1, P_2, P_3, P_4$. We use round robin with a time quantum of $20$.

- Waiting time for each process:
    - $P_1 = (68 - 20) + (112 - 88) = 72$
    - $P_2 = 20 - 0 = 20$
    - $P_3 = (28 - 0) + (88 - 48) + (125 - 108) = 85$
    - $P_4 = (48 - 0) + (108 - 68) = 88$
- Average waiting time:
    - $(72 + 20 + 85 + 88)/4 = 66.25$
- Completion time for each process:
    - $P_1 = 125$
    - $P_2 = 28$
    - $P_3 = 153$
    - $P_4 = 112$
- Average completion time:
    - $(125 + 28 + 153 + 112)/4 = 104.5$


While round robin is fairly equitable, its performance depends on the size of the time quantum.
- If the time quantum is too large, it behaves like first come, first served. 
- If it is too small, frequent timer interrupts and context switches create high overhead, leaving less CPU time for useful work.

But like, how are we suppose to know what's a good time quantum? We don't, it's all dependent on herusitcs.

---

## Priority Based Scheduling

More problems, more solutions! 

Another idea is to give processes different priority levels and let those priorities change over time.

We could initially give every process the same priority, making the order look like first come, first served. 
- As execution continues, we could determine priority using a combination of the process’s execution time, its base priority, and how long it has been waiting. 
- The longer a process stays in the ready queue without running, the higher its priority becomes, helping prevent it from being continually passed over.

![[Pasted image 20261007183014.png|500]]

Another approach is to divide processes into separate queues based on their priority levels. 
- The scheduler always chooses a process from the highest-priority nonempty queue. 
- A lower-priority queue gets CPU time only when all higher-priority queues are empty.

![[Screenshot 2026-10-07 at 6.35.39 PM.jpg|500]]

This can be combined with dynamic priorities. 
- For example, the longer a process waits without running, the higher its priority becomes, eventually moving it into a higher-priority queue. 
- This technique, called aging, helps prevent starvation.

---

## Shortest Remaining Time First

An idea built on top of shortest time first, where we run the thread with the least CPU time remaining.

The problem comes from predicting the thread with the least CPU time remaining, but how does the scheduler know which thread that is?
- It needs to estimate how much longer each ready thread will run before finishing or blocking for I/O. 
- That’s future behavior, so it uses past CPU bursts to make a prediction (but again, estimates != reality)