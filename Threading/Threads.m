
		IFND	THREADS_M
THREADS_M	SET	1

		INCLUDE	"Threading/Scheduler.i"
		INCLUDE	"Threading/Threads.i"

;------------------------------------------------------------------------
; Initialize a thread
;
; This function sets up initial register content and makes a thread
;   runnable.
; You need to provide both a starting execution point and a stack area
;   for the thread.
; The thread must terminate itself by calling M_terminateCurrentThread.

M_setupThread	MACRO	threadId,entryPoint,userStackEnd

;		DISABLE_INTERRUPTS

		bset	#\1&7,Threads_initializedFlags+(\1/8)
		IFD	DEBUG
		beq.s	.threadAvailable\@
		LOG_ERROR_STR "The application has attempted to setup a thread which is already in-use"
.threadAvailable\@
		ENDC

		bset	#\1&7,Threads_runnableFlags+(\1/8)

		move.l	\2,-(sp)		; store entryPoint
		move.l	\3,-(sp)		; store userStackEnd
		move.l	a0,-(sp)
		move.l	1*4(sp),a0
		move.l	2*4(sp),-(a0)
		move.l	a0,Threads_usps+\1*4
		move.l	(sp)+,a0
		addq.l	#8,sp

;		ENABLE_INTERRUPTS

		ENDM

;------------------------------------------------------------------------
; Terminate current thread.
;
; There is no way to terminate another thread -- you must make each
;   thread terminate itself.

M_terminateCurrentThread	MACRO	currentThreadId
;		DISABLE_INTERRUPTS

		bclr	#\1&7,Threads_runnableFlags+(\1/8)
		bclr	#\1&7,Threads_initializedFlags+(\1/8)

		lea	runnableFlagsToChosenThread,a0
		move.w	Threads_runnableFlags_word,d0
		move.b	(a0,d0.w),d0
		move.b	d0,currentThread
		lsl.w	#2,d0
		lea	Threads_usps,a0

		move.l	(a0,d0.w),sp
		rts

		ENDM

;------------------------------------------------------------------------

		ENDC
