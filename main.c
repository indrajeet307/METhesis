#include <stdio.h>
#include <stdlib.h>
#include "opcodeFile.h"
#include "trie.h"
#include "naiveOperations.h"
int main(int argc, char **argv)
{
    if ( argc < 4 )
    {
        printf("Usage:  ./main.out <opcode_file> <freq_csv1> <freq_csv2>.\n");
        return 0;
    }
    char *opcode_file = argv[1];
    char *freq_csv1   = argv[2];
    char *freq_csv2   = argv[3];

    int i,j;
    int numopcode=0;
    int numfiles=0;
    s_trie *opcodelist = initTrie();
    s_files *filelist;

    initFiles(&filelist);
    numopcode = readOpcodeFile( opcode_file, &opcodelist);
    printf(" Found %d opcodes.\n", numopcode);

    int *groupCount = createVector( 100);
    numfiles  = readCSVFile( freq_csv1, numopcode, &filelist, groupCount);
    numfiles += readCSVFile( freq_csv2, numopcode, &filelist, groupCount);
    printf(" Found %d files.\n", numfiles);

    int *mat = createMatrix( numfiles, numopcode);
    int *p_cvect = createVector( numfiles);

    fillTheMatrix( &filelist, mat, p_cvect, numfiles, numopcode);
    //showFiles( filelist);
    //printIntMatrix( mat, numfiles, numopcode);
    //printIntMatrix( p_cvect, numfiles, 1);
    //printIntMatrix( groupCount, 100, 1);

    deleteTrie( &opcodelist ); 
    free( mat );
    free( p_cvect );
    return 0;
}
