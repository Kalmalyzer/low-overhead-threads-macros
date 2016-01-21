
		include	"Threading/Signals.i"

		section	data,data

;----------------------------------------------------------------------------------

Signals_flags
		dcb.b	(MAX_SIGNALS+7)/8,0

		even
