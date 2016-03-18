BIN=./bin

all: init gpu

# implementation with GPU code
gpu: gpuimpl.cu naiveop trie opcfile gpu_naive
	nvcc -arch=sm_20 -g $(BIN)/naiveOperations.o $(BIN)/trie.o  $(BIN)/opcodeFile.o $(BIN)/gpu_naive.o gpuimpl.cu -o $(BIN)/gpuimpl.o -lm

naiveop: naiveOperations.cu 
	nvcc -g -c naiveOperations.cu -o $(BIN)/naiveOperations.o -lm 

trie: trie.cu  
	nvcc -g -c trie.cu -o $(BIN)/trie.o -lm 

opcfile: opcodeFile.cu 
	echo "Use:  -DEQUALGROUPS to take equal number of benign and maliciousfiles while compiling\n"
	echo "Use:  -DTESTING to take 2/3 samples for training and 1/3 samples for testing.\n" 
	nvcc -g -c opcodeFile.cu -o $(BIN)/opcodeFile.o -lm -DTESTING=1

gpu_naive: gpu_naive.cu
	nvcc -g -c -arch=sm_20 gpu_naive.cu -o $(BIN)/gpu_naive.o -lm 

init:
	mkdir -p $(BIN)
	ctags --langmap=c++:+.cu *

clean: 
	rm -rf ./bin/
