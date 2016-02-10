
VBLANKS_BETWEEN_EACH_SIGNAL	=	1*50

		include	"Threading/Interrupts.i"
		include	"Threading/Log.i"
		include	"Threading/Scheduler.i"
		include	"Threading/Signals.i"
		include	"Threading/Threads.i"
		include	"Threading/VBR.i"

		include	"Threading/Threads.m"
		include	"Threading/Signals.m"

		include	<lvo/exec_lib.i>
		include	<lvo/dos_lib.i>

		include <hardware/custom.i>
		include <hardware/intbits.i>
		
RandomThreadId = 1

ActivateRandomThreadSignalId = 3

		section	code,code

start:
		bsr	installLevel3Handler

		M_setupThread RandomThreadId,#randomThreadFunc,#randomUserStackEnd

		bsr	runScheduler

		bsr	removeLevel3Handler
		
		moveq	#0,d0
		rts

;------------------------------------------------------------------------

installLevel3Handler
		DISABLE_INTERRUPTS
		bsr	getVBR
		move.l	d0,a0
		move.l	$6c(a0),oldLevel3InterruptHandler
		move.l	#level3InterruptHandler,$6c(a0)
		ENABLE_INTERRUPTS
		rts

;------------------------------------------------------------------------

removeLevel3Handler
		DISABLE_INTERRUPTS
		bsr	getVBR
		move.l	d0,a0
		move.l	oldLevel3InterruptHandler,$6c(a0)
		ENABLE_INTERRUPTS
		rts
		
;------------------------------------------------------------------------

level3InterruptHandler
		btst	#INTB_VERTB,intreqr+(1-(INTB_VERTB/8))+$dff000
		beq.s	.nVertB
		
		addq.w	#1,TriggerVBlankCounter
		cmp.w	#VBLANKS_BETWEEN_EACH_SIGNAL,TriggerVBlankCounter
		bne.s	.nTriggerProduction
		clr.w	TriggerVBlankCounter

		movem.l	d0-d1/a0-a1,-(sp)
		M_setSignalFromInterrupt RandomThreadId,ActivateRandomThreadSignalId
		movem.l	(sp)+,d0-d1/a0-a1
		
.nTriggerProduction
		
.nVertB
		move.l	oldLevel3InterruptHandler,-(sp)
		rts

;------------------------------------------------------------------------

randomThreadFunc

		LOG_INFO_STR "Random thread starts"

.loop
		move.l	#140000/16-1,d0
.wait
		dbf	d0,.wait

		LOG_INFO_STR "Random thread waiting on signal"

		M_waitAndClearSignal RandomThreadId,ActivateRandomThreadSignalId

.color
		move.w	d0,$dff180
		add.w	#$123,d0
		bne.s	.color
		
		LOG_INFO_STR "Random thread woken up"
		
		bra.s	.loop

.done

;------------------------------------------------------------------------

		section	data,data

oldLevel3InterruptHandler
		dc.l	0

TriggerVBlankCounter
		dc.w	0

exampleRegisterContents
CNTR		SET	0
		REPT	15
		dc.l	CNTR
CNTR		SET	CNTR+$13577531
		ENDR
		
		section	bss,bss

randomUserStackBeginning
		ds.b	4096
randomUserStackEnd
