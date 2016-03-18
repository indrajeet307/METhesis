#include <stdio.h>
#include <stdlib.h>
#include "opcodeFile.h"
#include "trie.h"
#include "gpu_naive.h"
#include "naiveOperations.h"
int main(int argc, char**argv)
{
    if( argc < 4 )
    {
        printf("Usage:  ./main.out <opcode_file> <benign_freq_csv1> <malware_freq_csv2c>.\n");
        printf("Use:  -DEQUALGROUPS to take equal number of benign and maliciousfiles \
        while compiling\n");
        printf("Use:  -DTESTING to take 2/3 samples for training and 1/3 samples for testing.\n"); 
        return 0;
    }
    char *opcode_file = argv[1];
    char *freq_csv1   = argv[2];
    char *freq_csv2   = argv[3];

    int numopcode=0;
    int numfiles=0;
    s_trie *opcodelist = initTrie();
    s_files *filelist;
    s_filelist *testlist, *trainlist;

    initFiles(&filelist);
    initFileList(&testlist);
    initFileList(&trainlist);
    numopcode = readOpcodeFile( opcode_file, &opcodelist);
    printf(" Found %d opcodes.\n", numopcode);

    int *groupCount = createVector( 100);
    numfiles  = readCSVFile( freq_csv1, numopcode, &filelist, groupCount, &trainlist, &testlist);
    numfiles += readCSVFile( freq_csv2, numopcode, &filelist, groupCount, &trainlist, &testlist);
    printf(" Found %d files.\n", numfiles);
    printf(" NUmber of testingFiles %d Number of traning files %d\n", testlist->count, trainlist->count);

    int *testmat = createMatrix( testlist->count, numopcode);
    int *rotated_testmat = createMatrix( testlist->count, numopcode);
    int *trainmat = createMatrix( trainlist->count, numopcode);
    int *rotated_trainmat = createMatrix( trainlist->count, numopcode);
    //float*probmat = createFloatMatrix( trainlist->count, numopcode);
    float *probmat = createFloatMatrix( 2, numopcode);
    int *c_train_vect = createVector( trainlist->count);
    float *cprob = (float*) calloc (sizeof(float) , 2);
    int *c_test_vect = createVector( testlist->count);
    //int *pridict= createVector( testlist->count);
    int *pridict= createVector( trainlist->count);

    //fillTheMatrix( &filelist, mat, p_cvect, numfiles, numopcode);
    fillTheMatrixFromList( &trainlist, trainmat, c_train_vect, trainlist->count, numopcode);
    fillTheMatrixFromList( &testlist, testmat,   c_test_vect, testlist->count, numopcode);

    float *d_probmat, *d_class_prob;
    int *d_freqmat, *d_classvect, *d_classwise;
    //int inrows, incolumns, outrows;

    createDeviceMatrixI( &d_freqmat, trainlist->count, numopcode);
    createDeviceMatrixF( &d_probmat, 2, numopcode);// there are only two classes malware, benign
    createDeviceMatrixF( &d_class_prob, 2, 1);     // there are only two classes malware, benign
    createDeviceMatrixI( &d_classwise, 2, 1);      // there are only two classes malware, benign
    createDeviceMatrixI( &d_classvect, trainlist->count, 1); // there are only two classes malware, benign
    
    rotateMatrix( trainmat, rotated_trainmat, trainlist->count, numopcode);
    transferToDeviceI( rotated_trainmat, d_freqmat,trainlist->count*numopcode);
    transferToDeviceI( c_train_vect, d_classvect, trainlist->count);

    pnaiveTrain( d_freqmat, d_classvect, d_classwise, d_probmat, d_class_prob, numopcode, trainlist->count, 2);
    float *H_probmat = createFloatMatrix( 2, numopcode);
    int *d_testmat;
    int *d_predictvect;
    createDeviceMatrixI( &d_predictvect, testlist->count, 1);
    createDeviceMatrixI( &d_testmat, testlist->count, numopcode);
    rotateMatrix( testmat, rotated_testmat, testlist->count, numopcode);
    //printIntMatrix( rotated_testmat, numopcode,testlist->count);
    transferToDeviceI( rotated_testmat, d_testmat,testlist->count*numopcode);

    transferFromDeviceF( H_probmat, d_probmat, 2*numopcode);
    //print( H_probmat, 2, numopcode);

    pnaiveTest( d_probmat, d_class_prob, d_testmat, 
                testlist->count, numopcode, 2,
                numopcode, d_predictvect);
    
    int *H_class_predict = createMatrix( testlist->count, 1);
    transferFromDeviceI( H_class_predict, d_predictvect, testlist->count);

    //printIntMatrix( H_class_predict, testlist->count, 1);
    //printIntMatrix( c_test_vect, testlist->count, 1);
    printf(" Accuracy is %f\n",getAccuracy( H_class_predict, c_test_vect, testlist->count));

    return 0;
}
