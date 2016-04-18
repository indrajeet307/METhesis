#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include "opcodeFile.h"
#include "trie.h"
#include "gpu_naive.h"
#include "naiveOperations.h"
#define NUM_GROUPS 100
#ifndef NUM_FEATURES
#define NUM_FEATURES 808 
#endif
#ifndef EQUAL_NUM_FILES 
#define EQUAL_NUM_FILES 0
#endif
#define NUM_CLASSES 2 
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
    struct timeval start_seq, end_seq, diff_seq;
    

    int numopcode=0;
    int numfiles=0;
    s_trie *opcodelist = initTrie();
    s_files *filelist;
    s_group *grouplist;

    initFiles(&filelist);
    initGroups( &grouplist, NUM_GROUPS);
    numopcode = readOpcodeFile( opcode_file, &opcodelist);
    printf(" Found %d opcodes.\n", numopcode);

    int *groupCount = createVector( NUM_GROUPS * NUM_CLASSES);
    numfiles = readCSVFile( freq_csv1, numopcode, &filelist, groupCount);
    numfiles += readCSVFile( freq_csv2, numopcode, &filelist, groupCount);
    printf(" Found %d files.\n", numfiles);

    if( EQUAL_NUM_FILES )
    {
        printf("Same number of files\n");
        numfiles = adjustCountInEachGroup( groupCount, NUM_GROUPS);
    }
    else
    {
        printf("Diff number of files\n");
    }
    //printf(" Found %d files.\n", numfiles);

    normalizeOpcodeFrequency( &filelist);
    doGrouping( filelist, groupCount, &grouplist);
    selectFeaturesForEachGroup( &grouplist, NUM_GROUPS, numopcode, NUM_FEATURES);
    int numtestfiles=numfiles/3;
    printf(" Number of train files %d, Number of test files %d.\n", numfiles-numtestfiles, numtestfiles);
    float *trainArray = createFloatMatrix( NUM_GROUPS*4, numopcode ); // MALWARE BENIGN MEAN VARIANCE  ... NUM_CLASSES * 2
    float *testArray  = createFloatMatrix( numtestfiles, numopcode );
    int *class_vect = createVector( numtestfiles );
    int *group_vect = createVector( numtestfiles );
    int *predict_vect = createVector( numtestfiles );

    int **featurelist = (int**) malloc(sizeof(int**)); 
    createFeatureListForEachGroup( &featurelist, NUM_GROUPS );

    fillGroupWiseData( grouplist, trainArray, NUM_GROUPS, numopcode, testArray, class_vect, group_vect );

    selectFeaturesForEachGroup(
            &grouplist,
            NUM_GROUPS,
            numopcode,
            NUM_FEATURES
            );

    assignFeatureListForEachGroup( 
            &featurelist,
            grouplist,
            NUM_GROUPS
            );

    float *d_trainArray=NULL, *d_testArray; 
    int *d_group_vect, *d_predict_vect, *H_predict_vect;
    float *rotated_test_matrix;
    int *d_featureMatrix, *h_featureMatrix;

    h_featureMatrix = createIntMatrix( NUM_GROUPS , numopcode );
    spillFeatureMatrix( featurelist, h_featureMatrix, NUM_GROUPS, numopcode);

    rotated_test_matrix = createFloatMatrix( numtestfiles, numopcode);
    rotateMatrixF( testArray, rotated_test_matrix, numtestfiles, numopcode);

    spillMatrixToFile( trainArray, NUM_GROUPS, numopcode,"/tmp/r_trainArry");

    createDeviceMatrixF( &d_trainArray, NUM_GROUPS*4, numopcode);
    createDeviceMatrixF( &d_testArray, numtestfiles, numopcode);

    createDeviceMatrixI( &d_group_vect, numtestfiles, 1);
    createDeviceMatrixI( &d_predict_vect, numtestfiles, 1);
    createDeviceMatrixI( &d_featureMatrix, NUM_GROUPS, numopcode);

    transferToDeviceF( trainArray, d_trainArray, NUM_GROUPS*4* numopcode);  
    transferToDeviceF( rotated_test_matrix, d_testArray, numtestfiles* numopcode);  

    transferToDeviceI( group_vect, d_group_vect, numtestfiles );  
    transferToDeviceI( h_featureMatrix, d_featureMatrix, NUM_GROUPS*numopcode);  


    
        printf(" Features:%d\n", NUM_FEATURES);
        passignClassUsingMeanVarianceDataUsingFeatureSelection( d_trainArray, d_testArray, d_featureMatrix,NUM_GROUPS, numopcode, numtestfiles, d_group_vect, d_predict_vect);
        gettimeofday(&start_seq, NULL );
        assignClassUsingMeanVarianceDataAndFeatureSelection( trainArray,
                testArray, featurelist, NUM_GROUPS, numopcode,
                numtestfiles, group_vect, predict_vect
                );
        gettimeofday(&end_seq, NULL );
        timersub(&end_seq,&start_seq,&diff_seq);
        printf(" Time required for Seq is %f\n", diff_seq.tv_sec*1000.0+ diff_seq.tv_usec/1000.0);

    H_predict_vect = createVector( numtestfiles );
    transferFromDeviceI( H_predict_vect, d_predict_vect, numtestfiles);
    printf(" Acuraccy is %f LOL :) :) :D :D\n", getAccuracy(class_vect, predict_vect, numtestfiles));
    printf(" Acuraccy is %f LOL :) :) :D :D\n", getAccuracy(class_vect, H_predict_vect, numtestfiles));


    free ( trainArray );
    free ( testArray );
    free ( class_vect );
    free ( group_vect );
    free ( predict_vect  );

 return 0;
}
