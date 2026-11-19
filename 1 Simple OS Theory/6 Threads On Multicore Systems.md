Threads enable a process to run multiple tasks concurrently on the os, just like how the os enables multiple processes to run concurrently.

![[Screenshot 2026-07-29 at 10.29.58 AM.jpg|500]]

An example would be like an email app, it concurrently needs to:
- display UI
- listen for user keyboard IO inputs
- perform grammar checks
- monitor for incoming emails


Today, we'll be looking at parallelism, why? Because concurrency is hard, if the number of concurrent threads get too much, there will be a point where it takes too long for each thread to regain access to the CPU
- Hense, lag, it's directly noticeable to the human senses

![[Screenshot 2026-07-29 at 10.41.26 AM.jpg|500]]


To address this, there's 3 possible solutions:
1. directly increase CPU clock speeds
	- this has gotten really hard, going beyond 5 Gigahertz has became physically constrained on the current chips using electricity
2. more smarter scheduling
	- really hard as well, a detailed look on 'smarter' algorithms of scheduling is a note for itself
3. just have more processors so each processor works on less number of threads
	- ![[Screenshot 2026-07-29 at 10.41.05 AM.jpg|500]]


Parallelism is the future, baby! We can do this either by:
1. adding multiple CPUs to a motherboard
	- ![[Screenshot 2026-07-29 at 10.42.31 AM.jpg|300]]
2. adding multiple cores to a CPU
	- ![[Screenshot 2026-07-29 at 10.43.17 AM.jpg|500]]



One important note we have to say right now is, concurrent is not parallel:
- Concurrent: Multiple tasks make progress during the same period by the OS rapidly interleaving between them.
	- ![[Screen Recording 2026-07-29 at 10.49.48 AM.mov.gif|500]]
- Parallel: Multiple tasks execute at exactly the same time on different CPU cores.
	- ![[Screen Recording 2026-07-29 at 10.50.52 AM.mov.gif|500]]


Parallelism is 'truly' faster than concurrency, but is much harder to implement.

![[Screenshot 2026-07-29 at 10.52.45 AM.jpg|300]]

![[Screenshot 2026-07-29 at 10.53.01 AM.jpg|300]]


For programmers, this just means spawning threads, as with N cores up to N threads can be executed in parallel. The OS can ensure fair distribution of CPU resources across all threads.
- this is all faster than just multiple threads on a single core

![[Screenshot 2026-07-29 at 10.54.53 AM.jpg|500]]


Parallelism could be roughly divided down into 2 categories:
- data parallelism: distributing subsets of the same data across multiple computing cores and performing the same operation on each core
- task parallelism: distributing tasks across multiple computing cores, each thread performs a unique operation


Say we have a large dataset of numbers in an array, and our task is to find all the prime numbers in that array.

We can use data parallelism in this task, say if given a 4 core processor, we can divide the array into 4 subsets and individually search each subset.

![[Screen Recording 2026-07-29 at 11.06.19 AM.mov.gif|500]]


If instead the task is 4 separate ones, like finding the:
- lowest value
- highest value
- arithmetic mean
- check if the set contains 101

We can use task parallelism in this case, as each operation requires access to the entire dataset for the result.

![[Screen Recording 2026-07-29 at 11.09.05 AM.mov.gif|500]]