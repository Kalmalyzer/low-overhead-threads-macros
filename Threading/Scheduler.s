
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

		section	code,code

;------------------------------------------------------------------------
; Run scheduler's dispatch
;
; The calling code should create at least one thread of its own before
;   calling this function.
; Calling this function will setup the current execution context as
;   the idle thread. Execution will then start on the idle thread.
; The function will return once all threads apart from the idle thread
;   have terminated.

runScheduler
		LOG_INFO_STR "Scheduler begins running threads"

		bset	#IdleThreadId&7,Threads_initializedFlags+(IdleThreadId/8)
		bset	#IdleThreadId&7,Threads_runnableFlags+(IdleThreadId/8)

.loop
;		DISABLE_INTERRUPTS
		bsr	switchToNonIdleThread
		bsr	anyThreadsAliveExceptIdleThread
;		ENABLE_INTERRUPTS
		tst.b	d0
		bne.s	.loop
		
.done
		LOG_INFO_STR "No live threads - scheduler exiting"
		
		rts

;------------------------------------------------------------------------
; Are any threads except the idle thread still alive?
;
; out	d0.l	1 = threads alive, 0 = all threads dead

anyThreadsAliveExceptIdleThread
		move.b	Threads_initializedFlags,d0
		and.b	#(1<<(MAX_THREADS-1))-1,d0
		bne.s	.alive_thread_found

		moveq	#0,d0
		rts

.alive_thread_found
		moveq	#1,d0
		rts

;------------------------------------------------------------------------
; Identify the highest-priority thread that is currently runnable
;
; Interrupts are expected to be disabled when this function is called


switchToNonIdleThread
		move.w	Threads_runnableFlags_word,d0
		lea	runnableFlagsToChosenThread,a0
		move.b	(a0,d0.w),d0
		bmi.s	.noRunnableThreads
		cmp.b	#IdleThreadId,d0
		beq.s	.onlyIdleThreadRunnable

		lea	Threads_usps,a0
		move.l	#.returnAddress,-(sp)
		move.l	sp,IdleThreadId*4(a0)

		lsl.w	#2,d0
		move.l	(a0,d0.w),sp
		rts

.returnAddress

.onlyIdleThreadRunnable
		rts

.noRunnableThreads
		LOG_ERROR_STR "No threads are in runnable state, including idle thread. The system has deadlocked."

;------------------------------------------------------------------------
; Disable scheduler interrupt, with reentrancy count

disableSchedulerInterrupt
		rts
		
;------------------------------------------------------------------------
; Enable scheduler interrupt, with reentrancy count

enableSchedulerInterrupt
		rts
		
;------------------------------------------------------------------------


		section	data,data

;------------------------------------------------------------------------
; Lookup table, answering: for a value in the range 0-255,
;   what is the position of the lowest set bit?
; For the value 0, no bits are set, and the corresponding position is -1.

runnableFlagsToChosenThread

RUNNABLE_FLAGS	SET	0
		REPT	256

RUNNABLE_FLAG_BIT 	SET	0
FOUND_FLAG_BIT		SET	-1
			REPT	8

				IFLT	FOUND_FLAG_BIT
					IFNE	RUNNABLE_FLAGS&(1<<RUNNABLE_FLAG_BIT)
FOUND_FLAG_BIT					SET	RUNNABLE_FLAG_BIT
					ENDC
				ENDC

RUNNABLE_FLAG_BIT		SET	RUNNABLE_FLAG_BIT+1
			ENDR

			dc.b	FOUND_FLAG_BIT
RUNNABLE_FLAGS		SET	RUNNABLE_FLAGS+1
		ENDR
