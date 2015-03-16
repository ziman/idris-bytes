main: Main.idr Data/Bytes.idr bytes.o
	idris Main.idr -o main --warnreach

bytes.o: bytes.c bytes.h
	cc -O2 -c -o bytes.o bytes.c

test: main
	./main

clean:
	-rm -f main
	find -name \*.ibc -delete
