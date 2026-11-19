## Transactions

Transactions extend atomic updates from as we know synchronizing threads in memory for avoid race conditions, to persistent data in file systems, even if the system crashes for some reason.

A single filesystem operation may require several changes, for example, creating a file involves marking an inode as used and adding a directory entry pointing to it. 
- If a crash leaves only some changes completed, the filesystem could become inconsistent.

A transaction groups those changes into one all-or-nothing updat: after recovery, either all of them take effect or none do.

![[Screenshot 2026-11-01 at 3.24.28 PM.jpg|500]]

The typical steps are:
1. **Begin** a transaction and get a transaction ID.
2. **Perform updates.** Roll back if any update fails or conflicts with another transaction.
3. **Commit** the transaction.
	- Once we commit, the changes are made

---

## Logging and Journaling

A journaling filesystem is the most common way to achieve a transactional filesystem. It uses a log (also called a journal), a reserved area on disk where changes are recorded before they are applied.

Instead of writing changes directly to their real locations, the OS:

1. Writes a description of every change in the transaction to the log.
2. Writes a commit record to the log, marking the transaction as complete.

![[Screenshot 2026-11-01 at 3.42.09 PM.jpg|500]]

3. Applies the changes to their real locations on disk
4. Once all changes are applied, the log entry can be discarded.

![[Screenshot 2026-11-01 at 3.42.37 PM.jpg|500]]


If the system crashes, the OS reads the log during recovery:

- A transaction with a commit record is replayed, so its changes are completed.

![[Screenshot 2026-11-01 at 3.44.49 PM.jpg|500]]


- A transaction without a commit record is ignored, as if it never started.

![[Screenshot 2026-11-01 at 3.44.36 PM.jpg|500]]


Either way, every transaction ends up fully applied or not applied at all, which is the all-or-nothing guarantee transactions require.

---

## I'm Done Thinking About File Systems Bro