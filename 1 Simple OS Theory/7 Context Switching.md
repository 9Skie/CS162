In this note, we'll take a detailed look at context switching in detail, but we are first met with a dilemma.

It's a combination of software and hardware working together! Let's first look at the software side of things.


Context switching begins when an interrupt transfers control to a specific interrupt handler in the operating system.

However, the CPU must execute instructions to save the current process’s context and load another one. Those instructions will themselves modify registers, creating a problem: how can the operating system save the original register values without overwriting them first?

Just thinking about it, we could push the values of registers and the flags onto the interrupt's stack.

![[Screenshot 2026-07-29 at 12.17.20 PM.jpg|500]]

However, the current stack pointer still points to the user program’s stack rather than a protected interrupt stack. At the same time, entering the interrupt handler replaces the program counter, so the original execution address must be preserved before it is lost. 

This creates a chicken-and-egg problem that software alone cannot solve, meaning hardware assistance is required.


Any architecture that supports interrupts provides some mechanism to avoid losing the state of the interrupted process, and we'll look at 2 different ideas.
1. Multiple register sets
2. Hardware assisted switching


For the 1st, instead of keeping track of 1 set of register set, we just keep multiple register sets, and can be assigned to different processes respectively.

![[Screen Recording 2026-07-29 at 6.36.57 PM.mov.gif|500]]

But this still isn't the final solution, as the number of processes don't match the number of register sets, too little, and we have empty register sets sitting around, too much, and we have processes that can't be tracked.

In total, 2 is enough in practice, we have 1 for processes in user mode, and 1 for processes in kernel mode.

When an interrupt occurs, the CPU switches to kernel mode, deactivates the common register set, and starts using the privileged register set.

![[Screenshot 2026-07-29 at 6.49.50 PM.jpg|500]]

And so, as the common register set is frozen, the interrupt handler routine using the privilege register set can simply copy over those values over to the stack of the OS's address space.

![[Screen Recording 2026-07-29 at 6.55.51 PM.mov.gif|500]]


And then it can load existing values stored on the stack into the common register set.

![[Screen Recording 2026-07-29 at 6.55.51 PM.mov (1).gif|500]]


In practice, duplicating the entire register set solely for context switching is usually not worth the hardware cost. Each CPU core already requires its own register set, so an eight-core processor would need eight additional privileged register sets as well. 

Instead, processors typically preserve only a small amount of critical state in hardware and let the operating system save the remaining registers to memory.

![[Screenshot 2026-07-29 at 7.15.45 PM.jpg|500]]


As for hardware assisted stack management... the idea is simple, when an interrupt occurs, critical registers like the program counter and stack pointer are automatically pushed into the OS's stack, right before the program counter is overwritten to jump to the interrupt handler.

![[Screenshot 2026-07-29 at 7.19.43 PM.jpg|500]]

But.. for some reason this feature is avoided for most modern OS's.