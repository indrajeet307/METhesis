BIN=./bin

all: init main

# implementation with malware data
main : main.c 
	gcc -g trie.c naiveOperations.c helper.c opcodeFile.c main.c -o $(BIN)/main.o -lm

# implementation with document data
naive: naive.c 
	gcc -ggdb -pg trie.c naiveOperations.c helper.c naive.c -o $(BIN)/naive.o -lm

init:
	mkdir -p $(BIN)

clean: 
	rm -f ./bin/
