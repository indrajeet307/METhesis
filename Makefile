BIN=./bin

all: init main test

# implementation with malware data
main : opcodefile main.c
	gcc -g trie.c naiveOperations.c helper.c $(BIN)/opcodeFile.o main.c -o $(BIN)/main.o -lm

opcodefile : opcodeFile.c 
	gcc -c opcodeFile.c -o $(BIN)/opcodeFile.o -lm

# implementation with document data
naive: naive.c 
	gcc -ggdb trie.c naiveOperations.c helper.c naive.c -o $(BIN)/naive.o -lm

init:
	mkdir -p $(BIN)
	ctags *.c *.h

clean: 
	rm -rf ./bin/
	rm -f *.out

test:
	./bin/main.o ./waste/opcodelist ./waste/benign_2.csv ./waste/malicia_2.csv
