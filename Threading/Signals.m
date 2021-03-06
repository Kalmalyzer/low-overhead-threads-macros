
		IFND	SIGNALS_M
SIGNALS_M	SET	1

		INCLUDE	"Threading/Interrupts.i"
		INCLUDE	"Threading/Signals.i"
		INCLUDE	"Threading/Threads.i"
		INCLUDE	"Threading/Scheduler.i"

;------------------------------------------------------------------------
; Set signal
; If a higher-priority thread is already waiting on the signal,
;   it will also immediately switch to that thread

M_setSignal	MACRO	currentThreadId,targetThreadId,signalId

		DISABLE_INTERRUPTS

		bset	#\3&7,Signals_signalledFlags+(\3/8)
		bne.s	.alreadySet\@

		bclr	#\3&7,Signals_waitedOnFlags+(\3/8)
		beq.s	.noWaitingThread\@

		IFD	DEBUG
		btst	#\2&7,Threads_initializedFlags+(\2/8)
		bne.s	.threadInitialized\@
		LOG_ERROR_STR "Attempted to send a signal to wake up a thread which is not initialized"
.threadInitialized\@

		btst	#\2&7,Threads_runnableFlags+(\2/8)
		beq.s	.threadWaiting\@
		LOG_ERROR_STR "Attempted to send a signal to a thread that is waiting on a flag, but in runnable state at the same time"
.threadRunning\@
		ENDC
		
		bset	#\2&7,Threads_runnableFlags+(\2/8)

		IFLT	\2-\1
		
		move.b	#\2,currentThread

		move.l	#.returnAddress\@,-(sp)
		move.l	sp,Threads_usps+\1*4

		move.l	Threads_usps+\2*4,sp
		rts

.returnAddress\@

		ENDC

.noWaitingThread\@

.alreadySet\@

		ENABLE_INTERRUPTS

		ENDM

;------------------------------------------------------------------------
; Set signal (callable from within an interrupt context)
; If a higher-priority thread is already waiting on the signal,
;   it will switch to that thread once interrupt processing has completed

M_setSignalFromInterrupt	MACRO	targetThreadId,signalId

		bset	#\2&7,Signals_signalledFlags+(\2/8)
		bne.s	.alreadySet\@

		bclr	#\2&7,Signals_waitedOnFlags+(\2/8)
		beq.s	.noWaitingThread\@

		bset	#\1&7,Threads_runnableFlags+(\1/8)

		cmp.b	#\1,currentThread
		bls.s	.higherPriorityThreadAlreadyRunning\@

		cmp.b	#\1,desiredThread
		bls.s	.higherPriorityThreadAlreadyRequested\@

		move.b	#\1,desiredThread
		REQUEST_SCHEDULER_INTERRUPT

.higherPriorityThreadAlreadyRequested\@

.higherPriorityThreadAlreadyRunning\@

.noWaitingThread\@

.alreadySet\@

		ENDM

;------------------------------------------------------------------------
; Wait for signal to become set, and clear it
; If the signal is not yet set, the current thread will change to
;   waiting state, and the highest-priority runnable thread will begin
;   executing
;
; NOTE: All registers and condition codes will be modified by this call.

M_waitAndClearSignal	MACRO	currentThreadId,signalId

		DISABLE_INTERRUPTS

		bclr	#\2&7,Signals_signalledFlags+(\2/8)
		bne.s	.alreadySet\@

		bset	#\2&7,Signals_waitedOnFlags+(\2/8)
		
		bclr	#\1&7,Threads_runnableFlags+(\1/8)

		lea	runnableFlagsToChosenThread,a0
		move.w	Threads_runnableFlags_word,d0
		move.b	(a0,d0.w),d0
		move.b	d0,currentThread
		lsl.w	#2,d0
		lea	Threads_usps,a0

		move.l	#.returnAddress\@,-(sp)
		move.l	sp,\1*4(a0)

		move.l	(a0,d0.w),sp
		rts
	
.returnAddress\@
		bclr	#\2&7,Signals_signalledFlags+(\2/8)
	
.alreadySet\@

		ENABLE_INTERRUPTS

		ENDM

;------------------------------------------------------------------------

		ENDC