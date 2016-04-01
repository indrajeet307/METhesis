#include <stdio.h>
#include <stdlib.h>
#include "opcodeFile.h"
#include "trie.h"
#include "naiveOperations.h"
#define NUM_CLASSES 2
#define NUM_GROUPS 100 // file of size upto 500kb, group of 5kb each
#define NUM_FEATURES 100
int main(int argc, char **argv)
{
    if ( argc < 4 )
    {
        printf("Usage:  ./main.out <opcode_file> <benign_freq_csv1> <malware_freq_csv2c>.\n");
        return 0;
    }
    char *opcode_file = argv[1];
    char *freq_csv1   = argv[2]; //benign CSV
    char *freq_csv2   = argv[3]; //malware CSV

    int i,j;
    int numopcode=0;
    int numfiles=0;
    s_trie *opcodelist = initTrie();
    s_files *filelist;
    s_filelist *testlist, *trainlist;
    s_group *grouplist;

    initFiles(&filelist);
    initFileList(&testlist);
    initFileList(&trainlist);
    initGroups( &grouplist, 100);
    numopcode = readOpcodeFile( opcode_file, &opcodelist);
    printf(" Found %d opcodes.\n", numopcode);

    int *groupCount = createVector(NUM_GROUPS * NUM_CLASSES);
    numfiles  = readCSVFile( freq_csv1, numopcode, &filelist, groupCount);
    numfiles += readCSVFile( freq_csv2, numopcode, &filelist, groupCount);
    //showFiles( filelist);
    //printf(" Found %d files.\n", numfiles);
    //printf(" NUmber of testingFiles %d Number of traning files %d\n", testlist->count, trainlist->count);
    numfiles = adjustCountInEachGroup( groupCount, NUM_GROUPS);
    normalizeOpcodeFrequency( &filelist);
    doGrouping( filelist, groupCount, &grouplist);
    selectFeaturesForEachGroup( &grouplist, NUM_GROUPS, numopcode, NUM_FEATURES);
    //showGroupWiseStats( grouplist, NUM_GROUPS); 

    int numtestfiles=0;
    float *trainArray = createFloatMatrix( NUM_GROUPS*4, numopcode ); // MALWARE BENIGN MEAN VARIANCE  ... NUM_CLASSES * 2
    float *testArray  = createFloatMatrix( numfiles/3, numopcode ); // MALWARE BENIGN MEAN VARIANCE  ... NUM_CLASSES * 2
    int *class_vect = createVector( numfiles/3 );
    int *group_vect = createVector( numfiles/3 );
    int *predict_group_vect = createVector( numfiles/3 );
    int **featurelist = (int**) malloc(sizeof(int**)); 
    createFeatureListForEachGroup( &featurelist, NUM_GROUPS);
    assignFeatureListForEachGroup( &featurelist, grouplist, NUM_GROUPS);
    fillGroupWiseData( grouplist, trainArray, NUM_GROUPS, numopcode, testArray, class_vect, group_vect );
    showGroupWiseProcessedValues( trainArray, NUM_GROUPS, numopcode );
    
    //int *testmat = createMatrix( testlist->count, numopcode);
    //int *trainmat = createMatrix( trainlist->count, numopcode);
    ////float*probmat = createFloatMatrix( trainlist->count, numopcode);
    //float *probmat = createFloatMatrix( 2, numopcode);
    //int *c_train_vect = createVector( trainlist->count);
    //float *cprob = (float*) calloc (sizeof(float) , 2);
    //int *c_test_vect = createVector( testlist->count);
    ////int *pridict= createVector( testlist->count);
    //int *pridict= createVector( trainlist->count);

    ////fillTheMatrix( &filelist, mat, p_cvect, numfiles, numopcode);
    //fillTheMatrixFromList( &trainlist, trainmat, c_train_vect, trainlist->count, numopcode);
    //fillTheMatrixFromList( &testlist, testmat,   c_test_vect, testlist->count, numopcode);

    ////createProbablityMatrix( trainmat, probmat, c_train_vect, cprob, trainlist->count, numopcode, 2, numopcode);
    //createProbablityMatrix( testmat, probmat, c_test_vect, cprob, testlist->count, numopcode, 2, numopcode);
    ////assignClass( testmat, probmat, cprob, pridict, testlist->count, 2, numopcode);
    ////printIntMatrix( groupCount, 100, 1);
    ////printIntMatrix( c_test_vect, testlist->count, 1);
    ////printIntMatrix( c_train_vect, trainlist->count, 1);
    ////print( probmat, 2, numopcode);
    assignClassUsingMeanVarianceData(
        trainArray,
        testArray,
        NUM_GROUPS,
        numopcode,
        numtestfiles,
        group_vect,
        predict_group_vect
        );
 /*assignClassUsingMeanVarianceDataAndFeatureSelection( trainArray,
            testArray,
            featurelist,
            NUM_GROUPS,
            numopcode,
            numfiles/3,
            group_vect,
            predict_group_vect
            );*/
    ////print( cprob, 2, 1);
    printf(" Acuraccy is %f LOL :) :) :D :D\n", getAccuracy(class_vect, predict_group_vect, numfiles/3));

    //deleteTrie( &opcodelist ); 
    //free(testmat);
    //free(trainmat);
    //free(c_train_vect);
    //free(c_test_vect );
    return 0;
}
