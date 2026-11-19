As we said from last class, while we have a working lock, it's too slow due to constant context switches , so, we put the small atomic operations needed to build a lock into hardware, and so this speeds up the process much faster (less overhead, no context switches)

The following are examples of these atomic instructions.

```C
test&set(&address) {
    result = M[address];
    M[address] = 1;
    return result;
}
```

`test&set` reads the old value at a memory address, sets that location to `1`, and returns the old value.

For a lock, suppose `0` means free and `1` means busy:
- If it was `0`, you set it to `1` and receive `0`: you acquired the lock.
- If it was `1`, it stays `1` and you receive `1`: the lock was already busy.


```C
swap(&address, register) {
    temp = M[address];
    M[address] = register;
    register = temp;
}
```

`swap` exchanges the value at a memory address with the value in a register.

For a lock, suppose `0` means free and `1` means busy:
- The thread swaps its `1` into the lock and gets the lock’s old value back.
- If it gets `0`, it acquired the lock. If it gets `1`, the lock was already busy, so it failed to acquire it.


```C
compare&swap(&address, reg1, reg2) {
    if (reg1 == M[address]) {
        M[address] = reg2;
        return success;
    } else {
        return failure;
    }
}
```

Compare-and-swap checks whether the value at a memory address matches an expected value, `reg1`.
- If they match, it replaces the memory value with `reg2` and returns success.
- If they do not match, it leaves memory unchanged and returns failure.

For a lock, suppose `0` means free and `1` means busy. 
- `compare&swap` uses `reg1 = 0` and `reg2 = 1`:
	- If the lock is `0`, it changes it to `1`: you acquired the lock.
	- If the lock is already `1`, it leaves it unchanged: you failed to acquire it.


```C
load-linked&store-conditional(&address) {
loop:
    ll r1, M[address];
    movi r2, 1;
    sc r2, M[address];
    beqz r2, loop;
}
```

Load-linked reads the value at a memory address into `r1` and establishes a hardware reservation. Store-conditional attempts to write `1` there, succeeding only if the reservation is still valid.

For a lock, suppose `0` means free and `1` means busy:
- First, check the value read by load-linked. If it is `1`, the lock is busy, so retry.
- If it is `0`, attempt to store `1` using store-conditional.
- If the write succeeds, you acquired the lock. If it fails, retry.

---

## Implementing Locks With Atomic Instructions

These instructions let us implement `acquire()` and `release()` using test-and-set, without going inside the kernel.

```C
// (Free) Can access this memory location from user space!
int mylock = 0; // Interface: acquire(&mylock);
                //            release(&mylock);

acquire(int *thelock) {
    while (test&set(thelock)); // Atomic operation!
}

release(int *thelock) {
    *thelock = 0;              // Atomic operation!
}
```

You understand the logic of a lock at this point, so I'm not going to explain it again, but this is a busy waiting lock, which wastes CPU time.

So can we implement the same idea without busy-waiting? Obviously.

The idea is to spin briefly on a `guard` while checking the lock’s state, then put the thread to sleep if the actual lock is busy. This removes the long busy wait.

 ```C
int guard = 0;
int mylock = FREE;

acquire(int *thelock) {
    while (test&set(guard));
    if (*thelock == BUSY) {
        put thread on wait queue;
        go to sleep() & guard = 0;
        // guard == 0 on wakup!
    } else {
        *thelock = BUSY;
        guard = 0;
    }
}
 ```

As for release, it acquires the guard, moves one waiting thread to the ready queue or marks the lock free if nobody is waiting, then releases the guard.

```C
release(int *thelock) {
    // Short busy-wait time
    while (test&set(guard));
    if anyone on wait queue {
        take thread off wait queue
        Place on ready queue;
    } else {
        *thelock = FREE;
    }
    guard = 0;
}
```


The logic of this is very similar to what we've implemented last class, it's just using atomic, hardware operations instead of our manual implementation.

Basically we replaced:
- `disable interrupts` -> `while (test&set(guard));`
- `enable interrupts` -> `guard = 0;`

![[Screenshot 2026-10-05 at 4.06.20 PM.jpg|500]]

![[Screenshot 2026-10-05 at 4.06.41 PM.jpg|500]]

---

## Linux Futex

We already know how to use hardware atomic instructions to acquire a free lock without entering the kernel. But when the lock is busy, we want the waiting thread to sleep instead of wasting CPU time.

Our earlier code simply said “go to sleep.” User code cannot do that by itself: the kernel must put the thread to sleep and later make it ready to run again. Linux provides futex as the interface for requesting this.

The two operations we’ll use are:
- Wait: ask the kernel to put the thread to sleep, but only if the shared integer still has the expected value.
- Wake: ask the kernel to wake threads waiting on that integer’s address.

The interface looks like this:

```C
#include <linux/futex.h>
#include <sys/time.h>

int futex(int *uaddr, int futex_op, int val,
          const struct timespec *timeout);
```

- `uaddr`: address of the shared integer.
- `futex_op`: operation, such as wait or wake.
- `val`: expected value for wait, or maximum number of threads to wake.
- `timeout`: how long to wait before timing out, or `NULL` for no timeout.


Now, combining this with our atomic operations, lets write out the locks!

```C
int mylock = 0; // Interface: acquire(&mylock);
                //            release(&mylock);

acquire(int *thelock) {
    while (test&set(thelock)) {
        futex(thelock, FUTEX_WAIT, 1);
    }
}

release(int *thelock) {
    thelock = 0; // unlock
    futex(&thelock, FUTEX_WAKE, 1);
}
```

For `acquire()`:
1. `Test-and-set` sets the lock to `1` and returns its old value.
2. If the old value was `0`, we acquired the lock and exit the loop.
3. If it was `1`, the lock was busy, so we call `FUTEX_WAIT`.
4. The kernel checks whether the lock is still `1`. If so, we sleep, otherwise, we return immediately.
5. After returning or being woken, we retry test-and-set until we acquire the lock.

For `release()`:
1. Set the lock back to `0`, making it free.
2. Call `FUTEX_WAKE` to wake at most one thread waiting on that lock’s address.
3. The awakened thread retries acquisition; it does not automatically own the lock.


However in this implementation, on release, we always call futex to wake someone even if nobody is waiting, so we can have more states for a thread for avoiding unnecessary wakeup system calls.

So... we should only do the waking if someone is sleeping, if no one is sleeping we don't try to wake anything up? That sounds logical.

These are three states of the lock:
- `UNLOCKED`: no thread holds the lock.
- `LOCKED`: a thread holds the lock, with no possible sleepers recorded.
- `CONTESTED`: a thread holds the lock, and another thread may be sleeping or preparing to sleep, so release should attempt a wakeup.

```C
typedef enum { UNLOCKED, LOCKED, CONTESTED } Lock;
Lock mylock = UNLOCKED;

acquire(Lock *thelock) {
    // If unlocked, grab lock!
    if (compare&swap(thelock, UNLOCKED, LOCKED))
        return;

    // Keep trying to grab lock, sleep in futex
    while (swap(thelock, CONTESTED) != UNLOCKED) {
        futex(thelock, FUTEX_WAIT, CONTESTED);
    }
}

release(Lock *thelock) {
    // Unlock; wake a waiter if someone might be sleeping
    if (swap(thelock, UNLOCKED) == CONTESTED)
        futex(thelock, FUTEX_WAKE, 1);
}
```

For `acquire()`:
1. `Compare-and-swap` tries to change `UNLOCKED` to `LOCKED`. If successful, we acquired the lock and return.
2. Otherwise, swap sets the state to `CONTESTED` and returns the old state.
3. If the old state was `UNLOCKED`, we acquired the lock and exit the loop, leaving its state as `CONTESTED`.
4. Otherwise, futex puts us to sleep only if the state is still `CONTESTED`.
5. After returning or being woken, we retry the swap until we acquire the lock.

For `release()`:
1. Swap changes the state to `UNLOCKED` and returns the old state.
2. If it was `CONTESTED`, call futex to wake at most one waiter.
3. Otherwise, release finishes without a system call.

---
## Conditional Variables

A lock lets a thread safely access shared data, but the thread may still need to wait, for example, if a consumer finds the buffer empty.

A condition variable allows you to take one thread off the scheduling queue until there is a signal from another thread that it should put back on.
- This is useful if we don't want one thread to continue it's work until the work of another thread is finished

It's operations are:
- `Wait(&lock)`: atomically release the lock and sleep; reacquire the lock before returning.
- `Signal()`: wake one thread waiting on this condition variable, if any.
- `Broadcast()`: wake all threads waiting on it.


So, why a conditional variable? It's easiest to see it's purpose in a producer consumer model where threads are passing data to each other through a queue.

Sharing this queue creates two problems: threads must safely access it, and a consumer must wait when there is nothing to take. This makes it a useful example for seeing how a lock and a condition variable work together.

```C
lock buf_lock;          // Initially unlocked
condition producer_CV;  // Initially empty
condition consumer_CV;  // Initially empty
queue queue;

Producer(item) {
    acquire(&buf_lock);              // Get Lock
    while (isFull(&queue)) {
        cond_wait(&producer_CV, &buf_lock); // If full, sleep
    }
    enqueue(&queue, item);           // Add item
    cond_signal(&consumer_CV);       // Signal any waiters
    release(&buf_lock);              // Release Lock
}

Consumer() {
    acquire(&buf_lock);              // Get Lock
    while (isEmpty(&queue)) {
        cond_wait(&consumer_CV, &buf_lock); // If empty, sleep
    }
    item = dequeue(&queue);          // Get next item
    cond_signal(&producer_CV);       // Signal any waiters
    release(&buf_lock);              // Release Lock
    return(item);
}
```

Here, `queue` stores the items, and `buf_lock` protects access to them. Producers wait on `producer_CV` for space; consumers wait on `consumer_CV` for an item. “Initially empty” for each condition variable means no threads are waiting on it yet.

Suppose the queue is empty and the consumer runs first:

1. The consumer acquires `buf_lock` and checks the queue. Access is safe, but there is nothing to take.
2. It calls `cond_wait()` on `consumer_CV`. This atomically releases `buf_lock` and puts the consumer to sleep.
3. The producer acquires `buf_lock`, checks that there is space, adds an item, and signals `consumer_CV`, making one waiting consumer ready.
4. The producer releases `buf_lock`. Before the consumer returns from `cond_wait()`, it must reacquire that lock.
5. The consumer checks the queue again. If an item is available, it removes it, signals `producer_CV` because space is now available, releases the lock, and returns the item.