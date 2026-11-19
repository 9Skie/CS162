An I/O request travels from a user thread through the OS to the controller and I/O device.

![[Screenshot 2026-10-26 at 10.50.04 AM.jpg|500]]

Response time includes both the time spent waiting in a queue and the time needed to handle the request. Throughput measures how much work the system completes per second.

$\text{Response Time} = \text{Queue} + \text{I/O device service time}$

$\text{Effective BW} = \frac{\text{transfer size}}{\text{response time}}$

As requests arrive more frequently, the device spends more time busy, increasing utilization. Throughput rises toward maximum capacity, but requests increasingly have to wait, causing longer response times.

![[Screenshot 2026-10-26 at 11.03.42 AM.jpg|300]]

To understand this behavior, we model the device as a server and examine how its capacity and arrival rate affect performance.

## IO as a Server

### Sequential Server

A sequential server handles one request at a time. If servicing a request takes $L$ seconds, it must finish those $L$ seconds before beginning the next.

![[Screenshot 2026-10-26 at 10.56.14 AM.jpg|500]]

With requests always available, maximum throughput is:

$\text{Maximum Throughput} \leq \frac{1}{L}$

### Pipelined Server

Sometimes, we can split $L$ into a series of operations and pipeline them (like CS61C), allowing different requests to occupy different stages simultaneously.

![[Screenshot 2026-10-26 at 10.58.16 AM.jpg|500]]

If each stage takes $\frac{L}{k}$, one request still takes $L$ to pass through the entire pipeline. Once full, the pipeline completes one request every $\frac{L}{k}$, giving maximum throughput:

$\text{Maximum Throughput}\leq \frac{k}{L}$

### Parallel Servers

Similarly, $k$ independent servers, each taking $L$ per request, can handle $k$ requests simultaneously.

![[Screenshot 2026-10-26 at 11.10.10 AM.jpg|500]]

Each request still takes $L$, but total throughput resembles pipelining:

$\text{Maximum Throughput} \leq \frac{k}{L}$

## System Performance Model

We can view the whole system as requests flowing through a watermill. Two measures describe how much work passes through and how long it takes:

- Bandwidth: operations passing through per second.
- Latency: time for one operation to pass through.

![[Screenshot 2026-10-26 at 11.15.38 AM.jpg|500]]

At 2 requests per second and 3 seconds of latency, 6 requests are in the system on average.

Little’s law gives the average number of requests inside:

$N=\lambda L$

- $N$: average number of requests inside the system.
- $\lambda$: average arrival rate, in requests per second.
- $L$: average time from arrival to departure, including waiting and service.

Requests accumulate while earlier ones pass through. More arrivals or longer stays mean more requests inside. In a stable system, departures match arrivals on average, so the number inside does not keep growing—like a McDonald’s drive-through where cars cannot pile up indefinitely.

![[Pasted image 20261026112143.png|500]]

The watermill model then becomes more detailed, separating the system into two parts: a reservoir where requests wait, and a wheel that processes them.

![[Screenshot 2026-10-26 at 11.29.27 AM.jpg|500]]

- Request rate $\lambda$: requests entering the reservoir per second.
- Queueing delay $d$: time waiting while the wheel is busy.
- Operation time $t$: time the wheel takes to process one request.
- Latency $L$: total waiting and processing time: $L=d+t$.
- Service rate $\mu$: requests the wheel processes per second.

If requests arrive faster than the system can process them, the bottleneck stays fully busy. Throughput reaches maximum capacity, but the queue keeps growing because arrivals outpace completions.

If requests arrive more slowly than maximum capacity, throughput matches the arrival rate. The server has some idle time, keeping utilization below $100\%$.

## Deterministic and Bursty Worlds

With fixed arrival intervals and service times, each request can arrive exactly when the previous one finishes. The device stays fully utilized without queueing.

Consider requests arriving, waiting, receiving service, and departing from a single server:

![[Screenshot 2026-10-26 at 2.03.34 PM.jpg|500]]

- $T_A$: time between arrivals, giving arrival rate $\lambda=1/T_A$.
- $T_S$: service time per request, giving maximum service rate $\mu=1/T_S$.
- $T_Q$: queueing time, depending on whether the server is busy.
- $L=T_Q+T_S$: total request latency.

The ratio $\rho=\lambda/\mu=T_S/T_A$ describes workload relative to capacity.

![[Screenshot 2026-10-26 at 2.03.46 PM.jpg|500]]

When $\rho<1$, each request finishes before the next arrives. Assuming an initially empty queue, there is no queueing delay, and delivered throughput increases linearly with the arrival rate.

At $\rho=1$, each request arrives just as the previous one finishes. The server is fully utilized and delivers maximum throughput without a growing queue.

When $\rho>1$, arrivals exceed capacity. Throughput stays at maximum, while queue length and successive requests’ waiting times grow linearly over time.

In practice, I/O requests often arrive in bursts: many requests arrive close together, followed by periods with few or none. During a burst, requests wait because the device cannot process them all immediately; during quiet periods, it may be idle. Recall that processes alternate between CPU execution and I/O activity or waiting.

![[Pasted image 20261026141257.png|500]]

Service time $T_S$ remains fixed, but queueing time $T_Q$ varies depending on how much unfinished work is ahead of each request. Therefore, total latency $L=T_Q+T_S$ also varies. Bursts cause waiting even when average arrivals remain below capacity.

We model arrival intervals with an exponential distribution: short intervals are common, and long gaps less frequent. The average interval is $1/\lambda$.

This distribution is memoryless: how long we have already waited provides no information about how much longer we will wait for the next request.

![[Pasted image 20261026141409.png|500]]

## Queuing Theory

In a real OS, arrivals are often bursty, and service times may vary. Waiting depends on unfinished work ahead, so the average arrival rate alone cannot determine delay.

Queueing theory models arrival intervals and service times, including their averages and variability, to calculate average queueing delay and queue length.

Consider requests waiting for a single server, receiving service, and departing.

![[Screenshot 2026-10-26 at 2.48.48 PM.jpg|500]]

Assume:

- Equilibrium: average arrival and departure rates match, and the queue does not grow indefinitely. This requires $\rho<1$.
- Unlimited queue capacity.
- Random, exponentially distributed intervals between arrivals.

The variables are:

- $\lambda$: average arrivals per second.
- $T_S$: average service time.
- $\mu=1/T_S$: maximum server processing rate.
- $\rho=\lambda/\mu=\lambda T_S$: server utilization.
- $\sigma^2$: service-time variance.
- $C=\sigma^2/T_S^2$: squared coefficient of variation, measuring service-time variability relative to the mean.
- $T_Q$: average waiting time before service.
- $L_Q$: average number waiting, excluding the request being serviced.

Average total latency is $L=T_Q+T_S$. Here, $L$ denotes latency; $L_Q$ denotes queue length.

For an M/M/1 queue, both arrival intervals and service times are exponential and memoryless, with one server. Memoryless service means that time already spent processing does not change the distribution of the remaining service time.

$T_Q=\frac{\rho}{1-\rho}T_S$

For an M/G/1 queue, arrivals remain memoryless, but service times follow a general distribution:

$T_Q=\frac{1+C}{2}\cdot\frac{\rho}{1-\rho}T_S$

Fixed service times give $C=0$. Greater service-time variability increases average queueing time at the same mean service time and utilization.

Applying Little’s law to the queue gives:

$L_Q=\lambda T_Q$

Substituting the queueing-time formulas:

- M/M/1: $L_Q=\frac{\rho^2}{1-\rho}$
- M/G/1: $L_Q=\frac{1+C}{2}\cdot\frac{\rho^2}{1-\rho}$

As utilization approaches $100\%$, the denominator $1-\rho$ approaches zero, so average waiting time and queue length grow without bound.

![[Screenshot 2026-10-26 at 2.50.13 PM.jpg|500]]

### Why Queueing Delay Grows Near Full Utilization

Random arrivals can temporarily exceed capacity, creating a backlog even when average arrivals remain below capacity. The server needs spare capacity afterward to clear it.

As utilization approaches $100\%$, less spare capacity remains. Bursts take longer to recover from, and new requests continue arriving while earlier ones wait. Idle time during previous quiet periods cannot be saved to handle future bursts.

For example, a server processing 100 requests per second has spare capacity of 10 requests per second at 90 arrivals per second, but only 1 at 99 arrivals per second.

Under these models, average delay is finite for every fixed $\rho<1$. As $\rho\to1$, spare capacity approaches zero and $\rho/(1-\rho)$ grows without bound, so average queueing delay approaches infinity.