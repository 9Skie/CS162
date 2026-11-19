As we have learnt, the OS is the middleman between the hardware and software.

![[Screenshot 2026-07-28 at 11.19.34 AM.jpg|500]]

But if we really think about it, the OS really is just a program itself, a program that controls programs, and a program that talks to hardware.

Then, if that's the case, isn't the OS itself subjected to the switching of programs as well? Then how does the CPU know to treat the OS as a 'special program' that's the master of all programs?

- there's only one lord of the rings...

![[Screenshot 2026-07-28 at 9.40.56 AM.jpg|500]]

So, we have to dive deeper into hardware to find the answer.


## Between Two Worlds

The CPU can perform a set of actions, based on the instruction set it is based on, and for these instruction sets, there is a special subset of instructions which we can define that not all processes can use, called **privilege instructions**.

![[Screenshot 2026-07-28 at 2.33.40 PM.jpg|500]]


As such, the CPU will have a bit wired into it that controls the 'mode' that it's running on, to determine if it has access to those instructions or not.
- When it's has access, we call it **kernel mode**
- When it doesn't have access, we call it **user mode**


The CPU under kernel mode has control over IO devices, memory, and interrupts.

![[Screenshot 2026-07-28 at 2.57.12 PM.jpg|400]]

 While in user mode, it can't do any of that.
 
![[Screenshot 2026-07-28 at 3.00.34 PM.jpg|400]]

It will be enforced in the hardware to allow/halt those instructions from unning using gates.

![[Screenshot 2026-07-28 at 2.40.36 PM.jpg|500]]


## Switching Between Modes

But, how do you swap between these modes? It's usually done by an interrupt.

An interrupt is a signal for the processor to pause the process, so that an event needs immediate attention from the processor can be attended to.

In practice, it just means normally your program counter is just incrementing as normal for some program... then boom, an interrupt occurs, we pause the process, and we immediately jump to a certain location in memory.

![[Screen Recording 2026-07-28 at 2.48.27 PM.mov.gif|500]]

At that memory location there'll be code to handle the interrupt, in roughly 4 parts:
- save state of interrupted process
- handle interrupt
- restore state of interrupted process
- resume execution of interrupted process

During this process, it also flips the mode bit to 1, giving code at that location complete control over the CPU, and that's where the OS sits in memory.


Now, we have more questions, as we just said, programs in user mode can't directly interact with the hardware, nor memory, but then how would we do even some simple actions like reading a file, if it doesn't have that permission?

Through APIs! Since user programs can't access the hardware itself, the OS provides APIs to the user programs to access hardware!
- These functions are known as system calls

![[Screenshot 2026-07-28 at 3.04.23 PM.jpg|300]]

For working with files, there's system calls on Unix systems called `open()`, `read()`, `write()`, `close()`.

How system calls work is as the name suggests, they are still functions, which is still code that user programs run, so it's still in user mode, but in running this code, it actively triggers an interrupt, which gives the control to the OS, which is in kernel mode.

![[Screenshot 2026-07-28 at 3.41.07 PM.jpg|500]]

And such, user programs use interrupts to switch the CPU to kernel mode, at the cost of interrupting themselves and giving the control of the CPU to the OS, the OS in return can use a privileged instruction to resume an interrupted process.

Is it a good idea to use lots of system calls? Not really, since system calls are slow and you have to keep handing permission back and fourth between the program and the OS
- This is called a non-preemptive operating system, but it's no longer used today


Why is it no longer used today? Because there's no guarantee control of the CPU gets back to the OS if the user program doesn't exit it's control, like a forever while true loop.

![[Screen Recording 2026-07-28 at 3.46.35 PM.mov.gif|500]]


So... we add a timer to force control back to the OS, such that if a certain amount of time has passed and the program still hasn't given control back to the OS in any way, an interrupt is forcefully called.

![[Screenshot 2026-07-28 at 3.49.02 PM.jpg|500]]


---
## Kernel Level Software

As we have stated, programs in user mode cannot directly access hardware, control must be given to the OS if it wants to access hardware.

![[Screenshot 2026-07-28 at 3.51.37 PM.jpg|500]]

However, the kernel itself does not inherently know how to control every possible hardware device. Different devices may use completely different commands, registers, and communication protocols.

The solution is a **device driver**. A driver is software written to control a specific hardware device, often provided by the hardware manufacturer.

The driver translates the operating system’s general request into the specific commands understood by that device.

![[Screenshot 2026-07-28 at 4.02.49 PM.jpg|500]]

Because directly controlling hardware usually requires privileged instructions and access to protected memory, many drivers run in **kernel mode**.
- This also goes to other programs, like anti-cheat engines, malware detection 

But since these programs are running all in kernel mode, if they are buggy, they'll fuck up the OS and fuck up your entire system. There's also concerns whether these systems collect personal data, mine bitcoin etc since they directly control your computer's hardware, but eh... live or die with it.


