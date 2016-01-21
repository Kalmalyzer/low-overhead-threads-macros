
		include	"Threading/Threads.i"

		section	data,data

;----------------------------------------------------------------------------------
; Threads_*flags represent the possible states which a thread can be in.
; If a thread with a given ID has not been setup, or it has terminated,
;  it will be in state Uninitialized. This means that it is not part of 
;  scheduling.
; A thread which has been setup, and is not currently waiting for any signal,
;  will be in state Runnable.
; A thread which is currently waiting for a signal will be in state Waiting.
;
; There is no distinction in thread state between the currently running thread,
;  and any other threads which are ready to run but waiting for their share of
;  CPU -- the scheduler tracks this internally.
;
; Uninitialized: initialized = 0, runnable = 0
; Runnable: initialized = 1, runnable = 1
; Waiting: initialized = 1, runnable = 0

Threads_initializedFlags
		dc.b	0

		even
		
Threads_runnableFlags_word
		dc.b	0
Threads_runnableFlags
		dc.b	0

Threads_usps	dcb.l	MAX_THREADS,0
		
