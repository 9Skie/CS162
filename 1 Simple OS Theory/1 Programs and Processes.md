This is an entire series of notes from a great Youtuber who made simple to understand theory about operating systems.

Back in the days, early computers were shared amongst many different people, and they had to write the program by hand, punch it out onto cards, and wait in a queue for using the computer, where an machine operator fed the cards in.

![[Pasted image 20260707154632.png|500]]

So... why not let the machine do the loading, unloading, and queueing of programs? And that's how 'operating system' got it's name.

Multiple users trying to share one expensive computer, with an operator in between controlling the switching of programs, so computing power itself became a shared service. 

![[Screenshot 2026-07-28 at 9.39.08 AM.jpg|500]]

But nowadays, it's not usually multiple users on a computer, we all have home computers, but many different applications run on it at the same time.

![[Screenshot 2026-07-28 at 9.40.56 AM.jpg|500]]


Looking further ahead, operating systems are no longer just for human users, they're also increasingly for AI, which effectively exists as a user operating solely through a CLI.

This means we now have to consider sharing our computers with AI as well as with other humans. What will operating systems look like in the future, given this? We don't know yet.

![[Pasted image 20260717151640.png|500]]


But anyways! Back to the computer stuff, we don't call these programs 'programs', we call them 'processes'.

---
## What is A Process

Every program, despite their different purposes, must be a set of universal instructions carried out by the CPU.

Recall from computer architecture, this is the layout of a process in memory.

![[Screenshot 2026-07-28 at 9.46.29 AM.jpg|200]]

- text is the executable file itself
- data is the global variables and constant values
- then there's the heap and stack
	- heap stores generated data in runtime
	- stack store information returned by function calls

The heap usually grows upward as more memory is allocated, while the stack usually grows downward as functions are called.

![[Screenshot 2026-07-28 at 9.52.51 AM.jpg|400]]

And this is the memory layout of 1 process.


Say you have 2 text files, and you used a text editor to open up both of them, that creates 2 separate processes, the text is the same (since it's the same program), the data however is completely different.

![[Screenshot 2026-07-28 at 9.58.25 AM.jpg|500]]


Although 2 processes might be using the same program, they are considered 2 different processes to the OS, and requires constant switching back and fourth.

![[Screen Recording 2026-07-28 at 10.00.16 AM.mov.gif|500]]