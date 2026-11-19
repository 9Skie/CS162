## Fork and Exec

This is way to make new processes from processes.

**`fork()` creates a new child process from the calling parent process.** 

The child initially has a copy of the parent’s memory contents—including its code, global variables, heap, and the calling thread’s stack, but in a **separate address space**.

Both processes continue **immediately after the `fork()` call**, they are basically the same expect having different process IDs.

- **Parent:** Receives the child’s process ID.
- **Child:** Receives `0`.
- **Failure:** Returns `-1` to the parent; no child is created.


**`exec()` replaces the current process’s program with a new executable**, specified by its path and arguments. The old code, heap, and stack are replaced with those of the new program, while the **process keeps its existing process ID**. Successful execution starts the new program and never returns to the code that called `exec()`; returning indicates failure.

Together, these form the pattern introduced at the end of lecture 3: **the parent calls `fork()` to create a child, then the child calls `exec()` to run another program.**


Here's an example:

```C
int i;
pid_t cpid = fork();

if (cpid > 0) {
    for (i = 0; i < 10; i++) {
        printf("Parent: %d\n", i);
        // sleep(1);
    }
} else if (cpid == 0) {
    for (i = 0; i > -10; i--) {
        printf("Child: %d\n", i);
        // sleep(1);
    }
} else {
    /* ERROR! */
}
```

Initially, only one process is running. When it calls `fork()`, the OS creates a new process, the **child**, with a copy of the original process’s memory in a separate address space. 
- The original process is now called the parent.

Both continue immediately after `fork()`, but receive different return values:

- **Parent:** `cpid` contains the child’s positive process ID, so it prints `Parent: 0` through `Parent: 9`.
- **Child:** `cpid` is `0`, so it prints `Child: 0` through `Child: -9`.
- **Failure:** `cpid` is `-1`; no child was created.

Each process has its own copy of `i`, so their loops do not change each other’s variable. 


Beyond that, we have `wait()`, `wait()` lets a parent process wait for one of its children to finish.

If no child has finished yet, the calling thread blocks stops running without wasting CPU time. Once a child finishes, `wait()` returns that child’s process ID and stores its exit status through the pointer you provide.

```C
int status;
pid_t finished_child = wait(&status);
```

The parent then continues with the next statement. If a child has already finished, `wait()` returns immediately; if there are no children to wait for, it returns `-1`.


---

## Everything is a File

Now let's talk about the Unix idea: everything is a file
- geez, reminds me of deepseek harness of 'everything is a plugin'

But what does that mean? 'Everything is a file' means Unix lets programs interact with many different things using the same basic operations: open, read, write, and close.

- Open: Ask the OS for access to a resource. It gives you a number, called a file descriptor, to refer to it.
- Read: Bring data into your program, from a file, keyboard, or another resource.
- Write: Send data out of your program, to a file, terminal, or another resource.
- Close: Release that access when you’re finished.

The same operations work across different resources; the OS handles their differences.
- For special device settings that don’t fit reading or writing, there’s an extra operation called ioctl.


So what's even a file?

A file is a named collection of data in a file system, the posix file data is just a sequence of bytes, and how we interpret the sequences of bytes makes the different file format.

![[Pasted image 20260930234433.png|300]]

A file could have all sorts of metadata, it's the stuff that prints when you type `ls -l` in your terminal, it shows details about the file itself

For example, `ls -l` might print:

```
-rw-r--r--  1  alex  staff  1234  Sep 30 14:20  notes.txt
```

|Part|Meaning|
|---|---|
|`-`|File type: `-` means a regular file; `d` means a directory.|
|`rw-r--r--`|Permissions for the owner, group, and everyone else. `r` = read, `w` = write, `x` = execute, `-` = permission absent.|
|`1`|Number of hard links: names referring to this file.|
|`alex`|The user who owns the file.|
|`staff`|The group associated with the file.|
|`1234`|File size in bytes.|
|`Sep 30 14:20`|When the file’s contents were last modified.|
|`notes.txt`|File name.|


Outside of just things about a file itself, there's also a 'directory', as we know, there's hierarchy between files through folders. A directory is a folder that maps names to files or other directories. Directories can contain other directories, creating the hierarchy we navigate.

For example, in `/home/alex/notes.txt`, the directory `/` contains `home`, `home` contains `alex`, and `alex` contains the file `notes.txt`. The path tells the OS how to find the file through that hierarchy.

![[Pasted image 20260930235748.png|500]]


Every process has a current working directory (CWD), absolute paths ignore this cwd, while relative paths, as the name suggests is relative to the CWD.

![[Pasted image 20260930235810.png|500]]

---

## IO and Storage Layers

So, how do processes actually interact with files? Streams.

We open a file with `fopen()`, reading and writing through a `FILE*` stream, and closing it with `fclose()`.

```C
#include <stdio.h>

FILE *fopen(const char *filename, const char *mode);
int fclose(FILE *fp);
```

These are function declarations showing how to open and close a file in C.

- `fopen()` takes a file name and a mode: `"r"` for reading, `"w"` for writing (clears existing contents), or `"a"` for appending. It returns a FILE* pointing to a structure used to manage the open stream, or NULL if opening fails.
- `fclose()` takes that FILE*, flushes any buffered output, and closes the stream. It returns 0 on success or EOF on failure.
- `stdio.h` provides these declarations and the FILE type.


There are 3 pre determined streams that are opened implicitly when the program is executed, standard input, standard output, and standard error. C provides these three streams automatically:

- stdin: Where the program receives input, usually what you type in the terminal.
- stdout: Where the program sends its normal output, usually displayed in the terminal.
- stderr: Where the program sends error messages, usually also displayed in the terminal.

All of them can be redirected, in the shell, redirection changes where a program receives input or sends output, called a pipe.

```bash
cat hello.txt | grep "world!"
```

cat reads hello.txt and sends its contents to stdout. The pipe passes that output into grep’s stdin. grep then prints only the lines containing “world!”.


---

## High Level Streams

At a high level, we can work with streams as characters, strings, or blocks of bytes, using `fgetc()`/`fputc()`, `fgets()`/`fputs()`, or `fread()`/`fwrite()`, respectively. 
- In the function names, c means character, s means string, d means bttes

Using `fgetc()`, suppose the file contains:

```
ABCDE
```

```C
FILE *fp = fopen("input.txt", "r");

char first = fgetc(fp);       // Reads 'A'; position advances to 1
fseek(fp, 3, SEEK_SET);       // Moves to byte offset 3
char next = fgetc(fp);        // Reads 'D'; position advances to 4

fclose(fp);
```

Normally, the next read after ‘A’ would get ‘B’. fseek() moves the position, so the next read gets ‘D’ instead.


A stream keeps track of its current position in a file. Reading or writing normally advances that position.

`fseek()` lets you move that position yourself. For example:

```C
fseek(fp, 10, SEEK_SET);
```

This moves to byte offset 10, the file’s eleventh byte, so the next read or write starts there.

The last argument determines where you count from:

- SEEK_SET: The beginning of the file.
- SEEK_CUR: The current position.
- SEEK_END: The end of the file.

`fseek()` changes the position; it doesn’t itself read or write data.


---

## Low Level IO

Low-level I/O lets a program request work from the kernel through system calls. It uses integer file descriptors instead of FILE* streams.

- `open()` checks access permissions, sets up the open file’s state in the kernel, and returns a file descriptor. 
- `creat()` creates or clears a file and opens it for writing.
- `read()` and `write()` use that descriptor to transfer bytes between the resource and the program’s memory. 
	- They return how many bytes were actually transferred.
- `lseek()` changes the file position tracked in the kernel.
- `close()` releases the descriptor.

The kernel keeps the underlying file information protected; the program supplies a descriptor number, which the kernel looks up and validates.


Here is an example:

```C
int main() {
    char buf[1000];

    int fd = open("lowio.c", O_RDONLY, S_IRUSR | S_IWUSR);
    ssize_t rd = read(fd, buf, sizeof(buf));
    int err = close(fd);
    ssize_t wr = write(STDOUT_FILENO, buf, rd);
}
```

This reads up to 1,000 bytes from lowio.c and sends those bytes to standard output, usually the terminal.

---

Compare between high/low level IO, why have the 2 differ? 

Well, the main idea is buffering: instead of making a system call for every small read or write, the C library keeps a chunk of data in memory and serves multiple operations from it.

Suppose you request one character at a time:

- Low-level `read()`: Each call enters the kernel to request that byte.
- High-level `fgetc()`: The library might fetch 4 KB through one system call, keep it in a user-space buffer, and return one character. 
	- Later calls take characters from that buffer, entering the kernel again when it needs refilling.

So high-level I/O still uses the kernel, but buffering lets many function calls share fewer system calls, which, system calls are slow, so this speeds up things usually.

