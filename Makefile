all: bytes.o array.o

main: Main.idr Data/Bytes.idr Data/ByteArray.idr array.o bytes.o
	idris Main.idr -o main --warnreach

array.o: array.c array.h
	cc -O2 -c -o array.o array.c `idris --include`

bytes.o: bytes.c bytes.h
	cc -O2 -c -o bytes.o bytes.c `idris --include`

test: main
	./main

clean:
	-rm -f main *.o
	find -name \*.ibc -delete
