As we recall, by default, no process should be able to access another process's memory, or else it can steal data or alter data in unexpected ways.

But how would this be enforced? We just said 'it's kinda there' and never looked into the details of what happens under the hood.

It can't be that the CPU runs manual checks for illegal memory access for each process that is currently running on it, right? So what happens?

---

This could be done directly in hardware during the communication of the CPU and the main memory.

![[Screenshot 2026-08-04 at 10.26.44 AM.jpg|500]]

There's 2 special registers used to enforced memory boundaries, the base register and the limit register.
- the base register points to the smallest legal physical memory address of the process
- the limit register defines the size of the addressable range of the process

![[Screenshot 2026-08-04 at 10.34.30 AM.jpg|500]]

Note, The **operating system decides and configures the base and limit registers** for each process.

A normal program cannot directly modify these registers. They are **privileged registers**, meaning they can only be written while the CPU is running in kernel mode. Otherwise, a malicious program could simply expand its own memory range and access another process’s memory.

![[Screenshot 2026-08-04 at 11.15.42 AM.jpg|500]]


Then in logic, we just need to do this check for any memory operation:

```python
if (address >= base) and (register < (base + limit)
```

In hardware logic, this means we can just compute the logical statement above using circuits.

![[Screenshot 2026-08-04 at 10.51.17 AM.jpg|500]]

The binary comparators check whether the requested memory address falls within the valid range defined by the base and limit registers, allowing the memory operation only when the address is legal.

![[Screenshot 2026-08-04 at 10.52.20 AM.jpg|500]]

This could be further enhanced with the read/write/interrupts and other operations regarding to memory access.

![[Screenshot 2026-08-04 at 11.12.43 AM.jpg|500]]
