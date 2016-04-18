BIN=./bin

all: init gpu

# implementation with GPU code
gpu: gpuimpl.cu naiveop trie opcfile gpu_naive
	nvcc -arch=sm_20 -g $(BIN)/naiveOperations.o $(BIN)/trie.o  $(BIN)/opcodeFile.o $(BIN)/gpu_naive.o gpuimpl.cu -o $(BIN)/gpuimpl.o -lm
	echo "Compilation Complete" | flite && notify-send "Compilation Complete !!"

naiveop: naiveOperations.cu 
	nvcc -g -c -arch=sm_20 naiveOperations.cu -o $(BIN)/naiveOperations.o -lm 

trie: trie.cu  
	nvcc -g -c -arch=sm_20 trie.cu -o $(BIN)/trie.o -lm 

opcfile: opcodeFile.cu 
	nvcc -g -c -arch=sm_20 opcodeFile.cu -o $(BIN)/opcodeFile.o -lm

gpu_naive: gpu_naive.cu
	nvcc -g -c -arch=sm_20 gpu_naive.cu -o $(BIN)/gpu_naive.o -lm 

init:
	mkdir -p $(BIN)
	ctags --langmap=c++:+.cu *

clean: 
	rm -rf ./bin/
