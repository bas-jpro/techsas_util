# Build netcdf utils

CC = gcc
CFLAGS = -O6
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
	${LD} ${LDFLAGS} -o $@ get_vars.o

get_time: get_time.o
	${LD} ${LDFLAGS} -o $@ get_time.o

time_conv: time_conv.o
	${LD} ${LDFLAGS} -o $@ time_conv.o
