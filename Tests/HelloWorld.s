
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Threads.i"
		include	"Threading/Threads.m"

HelloWorldThreadId = 1

		section	code,code
		
;------------------------------------------------------------------------------		

start:

; Setup a single "Hello world" thread
		
		M_setupThread HelloWorldThreadId,#HelloWorldThreadFunc,#HelloWorldUserStackEnd

; Run thread

		bsr	runScheduler

		moveq	#0,d0
		rts

;------------------------------------------------------------------------------		
		
HelloWorldThreadFunc

; Print string to standard output

		LOG_INFO_STR "Hello world"

		M_terminateCurrentThread	HelloWorldThreadId
		
		section	bss,bss

HelloWorldUserStackBegin
		ds.b	4096
HelloWorldUserStackEnd
