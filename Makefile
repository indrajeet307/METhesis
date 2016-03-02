BIN=./bin
all: init naive.c
	gcc -ggdb -pg naive.c -o $(BIN)/naive.o

init:
	mkdir -p $(BIN)

clean: 
	rm -f ./bin/
