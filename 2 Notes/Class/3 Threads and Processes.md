As we understand, threads are basically programs acting on virtual CPU cores, whenever you run an executable, it runs it's own threads.

A thread is a sequence of instructions being executed within a process, with its own program counter, registers, and stack to keep track of its execution state. 

A process can have multiple threads, each carrying out a different task while sharing the process’s memory and resources.

Notice how multiprocessing is different from multi-programming, multiprocessing means running multiple things simultaneously, while multiprogramming means interleaving between various programs.

![[Screenshot 2026-09-30 at 5.19.18 PM.jpg|500]]

The motivation for threads is to let multiple tasks make progress independently.
- Even on a single CPU core, one thread can do useful work while another waits for disk or network I/O. 
- With multiple cores, threads can also execute simultaneously. Thus, threads provide a mechanism for **concurrency**, which can also enable **parallelism**.

---

## How Threads Work

Imagine the following program:

```C
main() { 
	ComputePI(“pi.txt”); 
	PrintClassList(“classlist.txt”); }
```

The idea is that the program computes PI, then accesses a file and prints it out.

If this were to execute sequentially, we would never have `PrintClassList` run since `ComputePI` never finishes.

Now, what if we have 2 threads that worked on each of these separately, what would happen?

```C
main() {
    create_thread(ComputePI, "pi.txt");
    create_thread(PrintClassList, "classlist.txt");
}
```

Although the two `create_thread()` calls occur sequentially, they create two threads that can execute concurrently. 

On a single CPU core, the OS can interleave their execution, giving computing π some CPU time and then allowing the class list to print. 
- Since these tasks are independent, printing the class list does not have to wait for computing π to finish.

![[Screenshot 2026-09-30 at 5.33.14 PM.jpg|500]]


So, as we can see, there's states between threads, it could be:
- running (as the name suggests, me use CPU)
- ready (hey me can go now, but me not use CPU yet)
- blocked (me can't go until something happens, some dependency like waiting for IO, once that happens I'll be ready)


Why IO? Since it's costly! Look at this program:

```C
main() {
    ReadLargeFile("large_file.txt");
    Print(2 + 3);
}
```

At first glance, it might look similar to the PI program, but it's really different! Because an IO operation doesn't require the CPU to do anything! It's just pure wasted time for the CPU.

![[Screenshot 2026-09-30 at 5.41.16 PM.jpg|500]]

- All the time should be given to the blue thread, since the pink thread is waiting for IO operations.

---

## MultiThreading

Hm... feels like we are going this over from CS61C, but since we didn't learn it very well there, here we go!

When we make a C executable program and run it, this new process initially has 1 thread in it's own address space.

Just as we saw in the examples above, once the process starts, we can create system calls for new threads.

We've uh... up to this point, never really saw system calls in programming (we assume), you haven't worked with the OS!

The simplest way to think about a system call is like a library function, it takes arguments and may return a result. 
- The key difference is that a system call transfers control into the kernel mode to perform an operation.


POSIX is a standard for how programs interact with operating systems, making programs easier to move between compatible systems.
- Pthreads (POSIX threads) is the threading interface defined by that standard.
	- In C, you use it through `<pthread.h>`


To create a thread, we use `pthread_create()` , which takes four arguments:

```
pthread_create(&thread, NULL, task, argument);
```

- `&thread`: Where to store the new thread’s identifier, so we can refer to it later.
- `NULL`: Use the default thread settings.
- `task`: The function the new thread should execute.
- `argument`: A pointer passed to that function; use `NULL` if it needs no input.
- 

To exit the **current thread**, we use `pthread_exit()`:

```
pthread_exit(return_value);
```

- `return_value`: A pointer representing the thread’s result; use `NULL` if there is no result to return.
- This ends the calling thread, allowing other threads in the process to continue.
- Returning from the thread’s `task` function also ends that thread.


To wait for a **specific thread to finish**, we use `pthread_join()`:

```
pthread_join(thread, &return_value);
```

- `thread`: The identifier of the thread we want to wait for.
- `&return_value`: Where to store the result returned by that thread. Use `NULL` if we don’t need its result.
- If the target thread hasn’t finished, the calling thread blocks until it does.


You can think the relationship between create, exit, and join as such:

![[Screenshot 2026-09-30 at 6.14.43 PM.jpg|500]]

It's like we observe millions of worlds, but we only find 1 to beat Thanos...

![[dr-strange-doctor-strange.gif|200]]


Anyways, here's an example for threading.

```C
#include <pthread.h>
#include <stdio.h>

void *PrintNumber(void *argument) {
    int number = *(int *)argument;
    printf("%d\n", number);

    pthread_exit(NULL);  // Finish this thread without returning a result
}

int main(void) {
    pthread_t thread;
    int number = 5;

    pthread_create(&thread, NULL, PrintNumber, &number);
    pthread_join(thread, NULL);

    return 0;
}
```

1. **Create  `pthread_create()`**  
    - The main thread creates a new thread that runs `PrintNumber`, passes it the address of `number`, and stores its identifier in `thread`. Both threads can now execute concurrently.
    
2. **Exit  `pthread_exit(NULL)`**  
    - The new thread reads `number`, prints `5`, and exits. `NULL` means it returns no result. This ends only the calling thread, not the entire process.
    
3. **Join  `pthread_join(thread, NULL)`**  
    - The main thread waits for the created thread to finish. If it has already finished, the call returns without waiting. Here, `NULL` means we don’t need to collect its result.

If there was a result (we don't have a result in this example, because we exited with `NULL`), we can have some variable save that result of the thread.

```C
void *result;
pthread_join(thread, &result);
```

Only after the join returns does `main` reach `return 0`, ending the process. This also ensures its local variable `number` remains alive while the other thread uses it.

---

## So What's In Each Thread?


We understand the layout of a program, from computer architecture.

![[Pasted image 20260930182053.png|300]]

And we roughly know what's inside a CPU.

![[Pasted image 20260930182243.png|200]]

But then... with the introduction of multiple threads, things get messy! We know only 1 thread can run at a time on 1 CPU, but then, how is the state of a thread defined?

A thread’s state is the information needed to pause its execution and later resume where it left off. The image separates this into what threads share and what each thread needs individually.

![[Screenshot 2026-09-30 at 6.24.35 PM.jpg|500]]

On the left, threads share the process’s code, global variables, and heap. 
- Creating another thread doesn’t create another copy of these, it creates another execution sequence that can use the same code and data.

On the right, each thread has its own:
- Stack: Holds its active function calls, return addresses, and local variables stored on the stack.
- Thread Control Block (TCB): A record the OS maintains to track the thread (with details I'm going to gloss over)


The layout of a program gets changed to something like this:

![[Screenshot 2026-09-30 at 6.47.30 PM.jpg|500]]

---

## Interleaving

With the introduction of multi-threading, programs no longer run sequentially.

![[Screenshot 2026-09-30 at 6.48.39 PM.jpg|500]]

Without knowing how threads go in order (so far), they could have many switching mechanisms between them.

![[Screenshot 2026-09-30 at 6.50.03 PM.jpg|500]]

![[Screenshot 2026-09-30 at 6.50.18 PM.jpg|500]]

---

## Race Conditions

Now, we'll see problems with using threads, one of such is race conditions of threads.

Suppose we have a program like this, where we start with  `x = 0` and `y = 0`, shared between two threads, and they execute different things.

```
// Thread A          // Thread B
x = y + 1;           y = 2;
                     y = y * 2;
```

Thread A’s result depends on when it reads `y`. 

|When A reads `y`|Value it reads|Result of `x = y + 1`|
|---|---|---|
|Before B changes it|`0`|`x = 1`|
|Between B’s two statements|`2`|`x = 3`|
|After B finishes both statements|`4`|`x = 5`|

Within thread B, its statements still execute in order. But A can run before, between, or after them, so the same code can produce different results depending on the scheduling.

This is the race: A reads shared data while B modifies it, without coordination. 


To solve this, we use synchronization, coordinating among threads regarding shared data to prevent race conditions.

In order to perform synchronization, there's more vocabulary involved:

- **Mutual exclusion:** Allowing only one thread at a time to access a shared resource.

- **Critical section:** The part of the code that accesses shared data and needs this protection.

- **Lock:** A mechanism that provides mutual exclusion. 
	- The idea is that a thread acquires the lock before entering the critical section and releases it afterward. Other threads needing the same lock must wait.

We'll get in touch with them in detail much later