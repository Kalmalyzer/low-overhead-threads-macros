
		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"

		include <hardware/custom.i>
		include <hardware/intbits.i>
		
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

		bsr	installSchedulerInterruptHandler

		DISABLE_INTERRUPTS
		bsr	switchToNonIdleThread
		ENABLE_INTERRUPTS
.loop
		DISABLE_INTERRUPTS
;		bsr	switchToNonIdleThread
		bsr	anyThreadsAliveExceptIdleThread
		ENABLE_INTERRUPTS
		tst.b	d0
		bne.s	.loop
		
.done
		LOG_INFO_STR "No live threads - scheduler exiting"
		
		bsr	removeSchedulerInterruptHandler
		rts

;------------------------------------------------------------------------
; Install scheduler interrupt handler as a level-1 interrupt (SOFTINT)

installSchedulerInterruptHandler
		DISABLE_INTERRUPTS

		bsr	getVBR
		move.l	d0,a0
		move.l	$64(a0),oldLevel1InterruptHandler
		
		move.l	#schedulerInterruptHandler,$64(a0)
		
		ACKNOWLEDGE_SCHEDULER_INTERRUPT
		ENABLE_SCHEDULER_INTERRUPT

		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------
; Remove scheduler interrupt handler

removeSchedulerInterruptHandler
		DISABLE_INTERRUPTS

		ACKNOWLEDGE_SCHEDULER_INTERRUPT
		DISABLE_SCHEDULER_INTERRUPT

		bsr	getVBR
		move.l	d0,a0
		move.l	oldLevel1InterruptHandler,$64(a0)
		
		ENABLE_INTERRUPTS
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
		subq.b	#1,schedulerInterruptEnableCount
		bmi.s	.done
		DISABLE_SCHEDULER_INTERRUPT
.done
		rts
		
;------------------------------------------------------------------------
; Enable scheduler interrupt, with reentrancy count

enableSchedulerInterrupt
		addq.b	#1,schedulerInterruptEnableCount
		ble.s	.done
		ENABLE_SCHEDULER_INTERRUPT
.done
		rts
		
;------------------------------------------------------------------------
; Scheduler interrupt handler
;
; The interrupt handler will perform a context switch, if necessary.
; If no context switch is needed, it is a no-op.

schedulerInterruptHandler
		btst	#(INTB_SOFTINT&7),intreqr+(1-(INTB_SOFTINT/8))+$dff000
		beq.s	.nSoftInt

		tst.b	desiredThread
		bmi.s	.noThreadSwitchRequired

		move.l	a6,temp
		move	usp,a6
		
		move.l	2(sp),-(a6)
		move.w	(sp),-(a6)
		move.l	temp,-(a6)
		movem.l	d0-a5,-(a6)
		move.l	#.restoreRegisters,-(a6)

		move.w	currentThread_word,d0
		lea	Threads_usps,a0
		lsl.w	#2,d0
		move.l	a6,(a0,d0.w)
		move.w	desiredThread_word,d0
		lsl.w	#2,d0
		move.l	(a0,d0.w),a6
		move	a6,usp
		move.l	#.return,2(sp)

		st	desiredThread

.noThreadSwitchRequired
	
		ACKNOWLEDGE_SCHEDULER_INTERRUPT
		rte
.nSoftInt
		move.l	oldLevel1InterruptHandler,-(sp)
		rts

.return
		rts

.restoreRegisters
		movem.l	(sp)+,d0-a6
		rtr
		
;------------------------------------------------------------------------


		section	data,data

temp		dc.l	0

desiredThread_word
		dc.b	0
desiredThread	dc.b	-1
currentThread_word
		dc.b	0
currentThread	dc.b	-1

schedulerInterruptEnableCount dc.b	1

		cnop	0,4

oldLevel1InterruptHandler dc.l	0

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
