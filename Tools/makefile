# makefile - Simple makefile to build the various RosBE tools.

.PHONY: all clean

CC := gcc
CFLAGS := ${HOST_CFLAGS} -Wall -O2 -o
STRIP := strip

ifeq ($(word 1,$(shell gcc -dumpmachine)),mingw32)
	# Windows host
	RM := del /f
	SUFFIX := .exe
	LDFLAGS += -lshell32
else
    ifeq ($(word 1,$(shell gcc -dumpmachine)),i686-w64-mingw32)
	    # Windows host
	    RM := del /f
	    SUFFIX := .exe
	    LDFLAGS += -lshell32
    else
	    # Unix host
	    RM := rm -f
	    SUFFIX :=
    endif
endif

all: cpucount scut

cpucount:  cpucount.c
	${CC} ${CFLAGS} cpucount$(SUFFIX) cpucount.c
	$(STRIP) cpucount$(SUFFIX)

scut:  scut.c
	${CC} ${CFLAGS} scut$(SUFFIX) scut.c $(LDFLAGS)
	$(STRIP) scut$(SUFFIX)

clean:
	$(RM) cpucount$(SUFFIX)
	$(RM) scut$(SUFFIX)
