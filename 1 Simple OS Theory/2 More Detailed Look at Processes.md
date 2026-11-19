How does the CPU actually allow alternate access of CPU resources from different processes?

By default, processes are placed in a queue, and at any given moment, only 1 process can use the CPU while all others wait.

![[Screenshot 2026-07-28 at 10.12.11 AM.jpg|500]]

Inside the CPU we have registers and ALU, like general purpose ones, instruction register, program counter, stack pointer, flags... many registers, and a process uses these components to manipulate data.

![[Screenshot 2026-07-28 at 10.14.48 AM.jpg|300]]

Now, we encounter our first problem, the problem that when a new process takes over the CPU, the previous process's register values are still sitting there in the CPU, these are not the right values to be manipulated for the new program, so how do we solve this?

Let's look at a simple example, say the process switching mechanism we have is simply we switch processes whenever we execute 2 instructions from a process.

![[Screenshot 2026-07-28 at 10.24.22 AM.jpg|500]]

After completing 2 instructions from process 1, the register states looks as such:

![[Screenshot 2026-07-28 at 10.33.09 AM.jpg|500]]


Now, we switch over to process 2, as the address register is now switched over to 1013

![[Screenshot 2026-07-28 at 10.36.02 AM.jpg|500]]

All these 2 lines did was return back 100 to register 0 and 35 to register 1, and now control is back at process 1, line 1005, and we can instantly see the bug.

Originally, it was suppose to add the value of 12 and 20 stored in register 1 and 2, but instead because control was given to process 2, the value at register 0 and 1 is 100 and 35 respectively, this causes the result of 1005, `ADD R0 R1` to be wrong.

![[Screenshot 2026-07-28 at 10.40.46 AM.jpg|500]]


You might've guessed the solution at this point... before switching execution to another process, the operating system takes a 'snapshot' of the current register states of the CPU.

![[Screen Recording 2026-07-28 at 10.46.23 AM.mov.gif|500]]

Then it stores the content of these registers somewhere in memory, such that when this program regains control, it's corresponding register values are put back into the CPU.
- This is similar to function calls in the stack: different functions temporarily take control of the CPU’s registers, so register values must be saved and later restored when control returns.
- This register state is stored for all processes on the computer.

![[Screenshot 2026-07-28 at 10.47.28 AM.jpg|300]]

This action of capturing a CPU's register states, storing it into memory, and restoring the state of another process is called **context switching**.


Within memory, the OS needs to track the address space allocated to each process, and processes should only be able to alter it's own allocated address space, and cannot interfere with other processes, this is enforced by the OS.

![[Screenshot 2026-07-28 at 11.07.45 AM.jpg|500]]


It also has the job of allocating new address space for a process (kinda like malloc needs to find free space in the heap).

![[Screenshot 2026-07-28 at 11.10.42 AM.jpg|300]]

![[Screenshot 2026-07-28 at 11.10.21 AM.jpg|300]]


But it doesn't end there! A process can have a list of open files, a list of IOs that it's using right now... those are all parts of a process.

![[Screenshot 2026-07-28 at 10.58.55 AM.jpg|400]]

But now with this much 'context' for a process, how is it possible to put it all in a queue? 

The operating system creates a special data structure called a **Process Control Block**, or **PCB**, not to be confused with a printed circuit board, it serves as a representation of the state of a process.

It tracks a process's every aspect, which abstractly looks something like this:

![[Screenshot 2026-07-28 at 11.11.25 AM.jpg|400]]


