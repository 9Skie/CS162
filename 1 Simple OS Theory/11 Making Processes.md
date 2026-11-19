https://www.youtube.com/watch?v=SwIPOf2YAgI (The Weird Way Linux Creates Processes)

Electron applications under the hood are web applications, which mean they use a multi-process architecture, which means multiple processes run in the background and communicate to one another when we run one of these apps

![[Screenshot 2026-09-25 at 4.19.12 PM.jpg|500]]

We only usually only interact with the GUI process, while the rest are unforeseen, but how are these processes started? Like can one process just call another process to start? We'll dive into how it works.

---

Many applications are designed in mind to spawn more processes during their execution automatically.

Say, P1 wants to spawn P2, it should load P2's code onto it's address space, then 'create' an address space for P2 to start execution.

But... shouldn't this be illegal for a process to do? A process should only has access to it's own process address space, and it's the OS's ability to create processes.

![[Screenshot 2026-09-25 at 4.23.51 PM.jpg|500]]


So... it's just another system call, right? Yeah! But apparently the idea works very differently based on the operating system that you are on.

![[Screenshot 2026-09-25 at 4.26.00 PM.jpg|500]]

But... if we look at this, this looks so weird! On the windows side of things, this looks like a normal system call, but what the heck is happening on the Linux side of things?


Let's first look on the windows side of things, ignoring some details, the basic idea is we have:
- image: the full path to the executable file on disk
- command_line: the exact string describing how the program should be invoked, including all arguments

![[Screenshot 2026-09-25 at 4.33.40 PM.jpg|500]]


Then, simply speaking:


1. the user process just sends this system call to the OS

![[Screen Recording 2026-09-25 at 4.31.51 PM.mov.gif|500]]

1. the os finds the file on disk
2. the os finds a new memory region for the process and load it in there
3. new user process made

![[Screen Recording 2026-09-25 at 4.34.14 PM.mov.gif|500]]



This sounds all rather reasonable, but take a look at what Linux does instead, when the OS receives the fork request, it clones the calling process entirely! Like the address space size, the stuff in memory, and the CPU state of the process.

![[Screen Recording 2026-09-25 at 4.37.04 PM.mov.gif]]


Now, what the heck is this behavior? What's the point of cloning processes if all that happens is they just do the same thing as they have the exact same code?

The trick is that `fork()` returns different values in the two processes, so they can follow different branches even though they have the same code. Both resume immediately after the `fork()` call:

- Parent: receives the child’s process ID.
- Child: receives `0`.

```C
pid = fork();

if (pid == 0) {
    // Child: replace this process's program with another program
    exec(...);
} else {
    // Parent: continue running the original program
}
```


Do you see a new little system call that appeared? That's called `exec()`, and it replaces the calling process’s current program with a new program loaded from an executable file.


In simple, `exec()` take 2 system arguments:
- path: similar to the windows sys call, it's the full path to the executable file on disk
- argv: also similar to the windows sys call, it's an array of pointers to C strings that defines the command line argument passed to the new program

When a process calls `exec()`, it replaces the program currently running inside the running process.

1. user process calls `exec()` to OS
2. OS locates the specified file on disk (similar to windows)

![[Screen Recording 2026-09-25 at 5.11.18 PM.mov.gif|500]]

4. It resets the calling process entirely and loads the specified file into the process's memory

![[Screen Recording 2026-09-25 at 5.11.18 PM.mov (1) 1.gif|500]]


At this point, you can see the 1 system call for a process to create another process on windows, is broken down into 2 system calls on linux, where one makes a duplicate of the process, and the other overwrites the process with the new process.
- fork clones a process
- exec transforms a process



Now, how do we have the parent and child process behave differently?

We've also already seen how a parent process and child process are distinguished a little earlier, as we can have a conditional to run a check on it's process ID (pid) to see whether it's the parent or child.

![[Screenshot 2026-09-25 at 5.19.41 PM.jpg|500]]