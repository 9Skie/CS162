An OS, at the highest level:
- provides consistent abstractions to applications regardless of software
- manages sharing of resources among applications

There's a lot that goes in building an OS:
- processes
- threads (concurrency & scheduling)
- protection and isolation of address spaces
- communication between processes
- persistent storage
- a universal interface to all devices


As we recall from simple OS theory, the OS is like the one program running at all times on the computer (the kernel)
- everything else is either a systems program or an application program, with either kernel level access or not respectively.

But why is it called a 'system'? How does a system differ from a program? A **program** is a set of instructions a computer can execute. A **system** is a collection of interacting parts that work together to provide some overall function, so a 'system' is like a program that's made up by many programs.

---

## Virtualizing the Machine

To connect our understanding of hardware from CS61C to this class, we learnt all about the hardware of a computer.

![[Screenshot 2026-09-14 at 11.44.38 AM.jpg|500]]

The operating is the next layer that provides a clan abstraction of these physical resources.

![[Screenshot 2026-09-14 at 11.47.55 AM.jpg|500]]

| Physical resource         | OS abstraction     | What a program sees                                                    |
| ------------------------- | ------------------ | ---------------------------------------------------------------------- |
| **Processor (CPU)**       | **Threads**        | Execution paths that the OS schedules onto CPUs.                       |
| **Physical memory (RAM)** | **Address spaces** | Its own set of virtual memory addresses, which map to physical memory. |
| **Storage device**        | **Files**          | Named collections of data instead of raw disk blocks.                  |
| **Network hardware**      | **Sockets**        | Endpoints for sending and receiving data over a network.               |

A **process** brings these together: it provides an execution environment containing threads, an address space, and access to resources such as files and sockets.

On our computer, there's many processes running at the same time.

![[Screenshot 2026-09-14 at 2.17.59 PM.jpg|500]]


