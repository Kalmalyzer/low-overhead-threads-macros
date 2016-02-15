# Low-overhead threading for 680x0 based systems

This library implements a small threading model, including a synchronization primitive and a simple scheduler.
All thread/synchronization operations are designed to be as low overhead as possible.
The intended use case is for threading within real-time applications.

The library is implemented as a set of macros, with some supporting subroutines.

# Threads

The library supports a fixed number of threads. Threads are identified by their ID.
You will need to assign application-wide unique IDs to each of your threads when writing the code.

You create a thread by calling M_setupThread, and providing a thread function and a stack.
The thread will be considered to be alive until the thread function returns.

In order to make any threads start processing, you must invoke the scheduler.

# Signals

The library supports a fixed number of signals. Signals are binary semaphores. Signals are identified by their IDs.
You will need to assign application-wide unique IDs to each of your signals when writing the code.

Signals have two primary operations: set, via M_setSignal, and wait, via M_waitAndClearSignal.
Waiting for a signal will suspend the current thread, until the signal gets set; this will also clear the signal. If the signal already was set, the wait operation will return immediately.

Setting a signal will unblock a thread that waits for that signal. Setting a signal more than once has no effect if no thread is waiting for the signal.

Only one thread at a time can wait for a given signal. Therefore, you should consider each signal to be associated with both the event itself and and the thread that is waiting for the event.

A thread can only wait for one signal at a time.

# Scheduling

You start the scheduler by invoking runScheduler. This function will return when no more threads are alive.

Threads have implicit priority based on their thread IDs. You choose thread priorities at compile time and do not change it later.
The scheduler will always run the highest-priority thread that is not waiting for any signal.
When all threads are waiting, the idle thread is running.

# Interrupts

Signals can be set from interrupts by calling M_setSignalFromInterrupt. Other than that, interrupts have no control over threads.

# Performance

Setting a signal when no thread is waiting for it: 100 cycles

Setting a signal when a thread is waiting for it, but it does not result in a context switch: 116 cycles

Setting a signal, when a thread is waiting for it, and it results in a context switch: 232 cycles

Waiting for a signal, which is already set: 72 cycles

Waiting for a signal, which results in a context switch: 264 cycles

Setting a signal from an interrupt, which does not result in a context switch: 28-132 cycles

Setting a signal from an interrupt, which results in a context switch: 696 cycles + 168 extra cycles at a future thread switch

