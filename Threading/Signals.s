
		include	"Threading/Signals.i"

		section	data,data

;----------------------------------------------------------------------------------

Signals_signalledFlags
		dcb.b	(MAX_SIGNALS+7)/8,0

Signals_waitedOnFlags
		dcb.b	(MAX_SIGNALS+7)/8,0

		even
