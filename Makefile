main: Main.idr Data/Bytes.idr
	idris Main.idr -o main --warnreach

test: main
	./main

clean:
	-rm -f main
	find -name \*.ibc -delete
