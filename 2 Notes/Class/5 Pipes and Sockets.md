To understand today's lecture, we need a mental model of a web server. Imagine your browser asks a server for **`hello.html`**. The server must receive that request, fetch the file, and send its contents back.

First, distinguish the three layers:

- **Server process:** An ordinary program running in user space. It understands the request and builds the response.
- **Kernel:** Handles access to the network and disk, buffers data, and puts waiting threads to sleep.
- **Hardware:** The network interface receives and sends packets; the disk stores the file.

![[Screenshot 2026-10-01 at 2.44.16 PM.jpg|500]]


1. The server waits for a request

The server has a connected **socket**, which is its endpoint for communicating with the browser.

It calls read socket, which is a system call, if no request has arrived, the server thread waits


```C
read(socket_fd, request_buffer, ...);
```

![[Screenshot 2026-10-01 at 2.47.40 PM.jpg|500]]


2. The request arrives and wakes the server

The browser’s request reaches the network interface. The hardware transfers the incoming data into memory and signals the kernel with an **interrupt**.

![[Screenshot 2026-10-01 at 10.57.22 PM.jpg|500]]

The kernel makes the data available in the socket’s receive buffer. The thread wakes up, and  the kernel copies it into the request buffer that the server supplied to `read()`.

![[Screenshot 2026-10-01 at 11.15.15 PM.jpg|500]]


 3. The server builds its reply

Usually, handling a request involves getting something something from a disk, which is another `read()`. 

![[Screenshot 2026-10-01 at 11.37.53 PM.jpg|500]]

This syscall asks for a disk request, which could make the read wait a little since it takes some time.

![[Screenshot 2026-10-01 at 11.40.20 PM.jpg|500]]



4. The server sends its reply

The disk returns data and interrupts the kernel, which then copies the data to the server, and the server builds the response.

![[Screenshot 2026-10-01 at 11.47.09 PM.jpg|500]]

The server network socket calls `write()`:

```
write(socket_fd, reply_buffer, ...);
```

The kernel copies the reply into its outgoing network buffer, and then it formats the outgoing packet and sends it.

![[Screenshot 2026-10-01 at 11.55.56 PM.jpg|500]]

---

## Communication Between Processes

The whole point of understanding that network model is to serve as an intro to today's class, how do processes talk to each other?


As we recall, the OS keeps processes isolated, each process normally cannot access another process’s memory, this is memory protection.

But sometimes processes need to cooperate and exchange data. We therefore need to “punch a hole” in that isolation, a controlled communication channel provided by the OS, while keeping the rest of their memory protected.
- This is called interprocess communication (IPC).

---

## How 2 IPC

One simple way is to have a producer and a consumer running as separate processes.
- The producer writes data into a file on persistent storage, and the consumer reads that data from the file. They communicate through the file without accessing each other’s memory directly.

![[Screenshot 2026-10-02 at 12.15.16 AM.jpg|500]]

This idea could work, but it's incredibly slow, as we are going from memory to disk, then back from disk to memory from every communication.

So another idea is to have an in-memory queue inside the kernel's address space that is only accessible through system calls.

![[Screenshot 2026-07-28 at 4.37.00 PM.jpg|500]]

![[Screenshot 2026-10-02 at 12.24.05 AM.jpg|500]]


Now, what happens when there is an imbalance between supply and demand? 
- like consumer consumes data faster than producer can produce it (empty queue)
- or producer produces data faster than consumer can consume it (full queue)

Well, simple!
- Consumer sleeps when the queue is empty. It wakes when the producer adds data.
- Producer sleeps when the queue is full. It wakes when the consumer removes data, freeing space.

After waking, each checks its condition again before proceeding.


This is one process writing and then reading its own message, just to demonstrate the mechanism:

```
msg → write end → kernel pipe buffer → read end → buf
```

```C
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFSIZE 1024

int main(int argc, char *argv[])
{
    char *msg = "Message in a pipe.\n";
    char buf[BUFSIZE];
    int pipe_fd[2];

    if (pipe(pipe_fd) == -1) {
        fprintf(stderr, "Pipe failed.\n");
        return EXIT_FAILURE;
    }

    ssize_t writelen = write(pipe_fd[1], msg, strlen(msg)+1);
    printf("Sent: %s [%ld, %ld]\n", msg, strlen(msg)+1, writelen);

    ssize_t readlen = read(pipe_fd[0], buf, BUFSIZE);
    printf("Rcvd: %s [%ld]\n", msg, readlen);

    close(pipe_fd[0]);
    close(pipe_fd[1]);
}
```

So in the code, we made a pipe with  `pipe(pipe_fd)` and we put just 2 indexes to it, where  `pipe_fd[0]` = read end and `pipe_fd[1]`= write end.

Then,  `write()` copies the message into the pipe. And `read()` copies data from the pipe into `buf`.  Both descriptors are closed afterward.



But... this isn't between processes, what about between processes?

Well, it's simple as well! When we have a process with a pipe and fork it, the pipe doesn't get forked, and they are still using the same pipe!

![[Screenshot 2026-10-02 at 12.52.03 AM.jpg|300]]

![[Screenshot 2026-10-02 at 12.52.19 AM.jpg|500]]

If you create the pipe before calling `fork()`, the child inherits copies of the pipe’s file descriptors, but both processes’ descriptors refer to the same pipe inside the kernel.
- The parent can then write into that pipe, and the child can read the data from it, vice versa


Here's an example:

```C
// continuing from earlier
pid_t pid = fork();

if (pid < 0) {
    fprintf(stderr, "Fork failed.\n");
    return EXIT_FAILURE;
}

if (pid != 0) { // if it's the parent
    ssize_t writelen = write(pipe_fd[1], msg, msglen);
    printf("Parent: %s [%zu, %zd]\n", msg, (size_t)msglen, writelen);
    close(pipe_fd[0]);
} else {
    ssize_t readlen = read(pipe_fd[0], buf, BUFSIZE);
    printf("Child Rcvd: %s [%zd]\n", buf, readlen);
    close(pipe_fd[1]);
}
```

`fork()` creates a child that shares the existing kernel pipe with the parent. The parent writes the message, and the child reads it into `buf`. If the child reads before data arrives, it waits.


So now `fork()` creates a child process, and both the parent and child share the pipe created earlier.

Depending on the pid of the process:
- The parent writes `msg` into the pipe, prints what it sent, and closes its unused read end.
- The child reads from the pipe into `buf`, prints what it received, and closes its unused write end. If the child reads before the parent writes, it waits until data arrives.


---

## Protocols

Now we understand how to establish communication, we need a protocol for communication, what we shown is just a raw version of this back and fourth communication that's not reusable.

![[Screenshot 2026-10-02 at 1.11.54 PM.jpg|500]]

How the OS does it is very similar to web communication client server protocols.

Abstractly, each process has a socket, which are just queues to temporarily hold results, and we can do everything to it just like a queue:
- write adds to the output queue
- read removes from the input queue


And the rest looks very much similar to the original mental model of the web-server.


1. The server is always on, it tries to read it's socket, if it's empty, it goes to sleep.

![[Screenshot 2026-10-02 at 1.19.15 PM.jpg|500]]

2. The client writes a request to it's socket

![[Screenshot 2026-10-02 at 1.20.46 PM.jpg|500]]

3. The client reads for the return response, if it gets nothing, it goes to sleep

![[Screenshot 2026-10-02 at 1.22.29 PM.jpg|500]]

4. the server's read process gets waken up since there's data in the socket now, it writes a response back to the client

![[Screenshot 2026-10-02 at 1.23.49 PM.jpg|500]]

5. client wakes up and does something with that response

![[Screenshot 2026-10-02 at 1.24.33 PM.jpg|500]]

Now, if this process entirely just repeats, this is a basic protocol between the 2 processes.


In code, it looks something like this:

![[Screenshot 2026-10-02 at 1.27.48 PM.jpg|600]]

Simply, we can see that the read of the client wakes up the write of the server, and the write of the server wakes up the read of the client, looping forever.

But this assumes the loop never breaks and always the sequence is in the same order, which... well, we'll learn later on doesn't always happen.


---

## To Make A Socket

So, we've seen clients and servers and how processes talk, but how do we actually define a socket for a process?

We saw a simple example of a pipe, but that's not a socket, it's just a one way communication for parent and child.


Sockets, on the other hand are usually introduced in computer networking, where programs send and receive streams of data.
- The OS uses addresses and port numbers to direct incoming network data to the appropriate socket, which a program can read from.

But a socket is actually an OS abstraction for communication between processes.
- Berkeley developed the socket interface to provide a common way for processes to communicate, whether they are on the same computer or on different computers across a network.


So, the server client socket setup process looks like:

1. The server sets up a listening socket and calls `accept()` to wait for a connection.
2. A client calls `connect()` to request a connection.
3. `accept()` returns a new connected socket for communicating with that client.
4. The original listening socket remains available to accept more clients.

![[Screenshot 2026-10-02 at 1.53.56 PM.jpg|500]]


This is all TCP/IP, for TCP/IP communication, each connection is identified by five things: 
1. the client’s IP address and port number
2. the server’s IP address and port number
3. and the protocol, TCP.

IP addresses identify the machines, while port numbers identify communication endpoints on those machines. Together, these let the OS direct incoming data to the correct connected socket.

If both processes run on the same computer, they can use the same loopback IP address, `127.0.0.1` (this means local machine), with different port numbers.


God this just gets more complicated, I'm just going to throw an image here for how it works:

![[Screenshot 2026-10-02 at 2.13.29 PM.jpg|500]]

This diagram shows how a server handles several clients at once: the parent accepts connections, while child processes handle the conversations.

1. The server creates its listening socket, binds it to an address and port, and waits for connections.
2. A client connects. The server’s `accept()` returns a new connected socket for that client.
3. The server calls `fork()`, creating a child. Both initially have access to the listening and connected sockets.
4. The child closes its copy of the listening socket. It reads the client’s request, writes a response, then closes the connected socket when finished.
5. The parent closes its own copy of that connected socket and immediately goes back to `accept()` for another client.