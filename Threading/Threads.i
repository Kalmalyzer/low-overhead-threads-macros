
		IFND	THREADS_I
THREADS_I	SET	1

MAX_THREADS	= 4	; Max number of threads supported by system; caps at 8

		IFGT	MAX_THREADS-8
		ERROR	"Current implementation supports no more than 8 threads"
		ENDC

IdleThreadId	= MAX_THREADS-1

		XREF	setupThread
		XREF	Threads_initializedFlags
		XREF	Threads_runnableFlags
		XREF	Threads_runnableFlags_word
		XREF	Threads_usps

		ENDC
