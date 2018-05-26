# Build netcdf utils

CC = gcc
CFLAGS = -O6 -std=c99 -I/usr/include/udunits2/
LD = gcc
LDFLAGS = -lnetcdf -ludunits2

prefix=/packages/techsas/current

bins = get_vars get_time time_conv

.C.o:
	${CC} ${CFLAGS} -c $<

all: $(bins)

.PHONY: install
install: $(bins)
	install -m 755 $(bins) ${prefix}/bin 
	
.PHONY: clean
clean: 
	rm $(bins) *.o

get_vars: get_vars.o 
	${LD} -o $@ get_vars.o ${LDFLAGS}

get_time: get_time.o
	${LD} -o $@ get_time.o ${LDFLAGS}

time_conv: time_conv.o
	${LD} -o $@ time_conv.o ${LDFLAGS}
