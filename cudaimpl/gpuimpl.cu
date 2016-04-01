#include <stdio.h>
#include <stdlib.h>
#include "opcodeFile.h"
#include "trie.h"
#include "gpu_naive.h"
#include "naiveOperations.h"
#define NUM_GROUPS 100
#define NUM_FEATURES 900
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

    numfiles = adjustCountInEachGroup( groupCount, NUM_GROUPS);
    printf(" Found %d files.\n", numfiles);

    normalizeOpcodeFrequency( &filelist);
    doGrouping( filelist, groupCount, &grouplist);
    selectFeaturesForEachGroup( &grouplist, NUM_GROUPS, numopcode, NUM_FEATURES);
    int numtestfiles=numfiles/3;
    float *trainArray = createFloatMatrix( NUM_GROUPS*4, numopcode ); // MALWARE BENIGN MEAN VARIANCE  ... NUM_CLASSES * 2
    float *testArray  = createFloatMatrix( numtestfiles, numopcode ); // MALWARE BENIGN MEAN VARIANCE  ... NUM_CLASSES * 2
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

    //deleteGrouplist( &grouplist, NUM_GROUPS );
    //deleteFilelist( &filelist );
    //free( groupCount );
    float *d_trainArray=NULL, *d_testArray; 
    int *d_group_vect, *d_predict_vect, *H_predict_vect;

    createDeviceMatrixF( &d_trainArray, NUM_GROUPS*4, numopcode);
    createDeviceMatrixF( &d_testArray, numtestfiles, numopcode);

    createDeviceMatrixI( &d_group_vect, numtestfiles, 1);
    createDeviceMatrixI( &d_predict_vect, numtestfiles, 1);

    transferToDeviceF( trainArray, d_trainArray, NUM_GROUPS*4* numopcode);  
    transferToDeviceF( testArray, d_testArray, numtestfiles* numopcode);  

    transferToDeviceI( group_vect, d_group_vect, numtestfiles );  

    //// TODO convert featurelist to matrix, currently it is pointer to pointers stuff

    passignClassUsingMeanVarianceData( d_trainArray, d_testArray, NUM_GROUPS, numopcode, numtestfiles, d_group_vect, d_predict_vect);
    //assignClassUsingMeanVarianceData( trainArray, testArray, NUM_GROUPS, numopcode, numtestfiles, group_vect, predict_vect);
    ///* assignClassUsingMeanVarianceDataAndFeatureSelection( trainArray,
    //        testArray, featurelist, NUM_GROUPS, numopcode,
    //        numtestfiles, group_vect, predict_vect
    //        ); */
    //////print( cprob, 2, 1);
    H_predict_vect = createVector( numtestfiles );
    transferFromDeviceI( H_predict_vect, d_predict_vect, numtestfiles);
    printf(" Acuraccy is %f LOL :) :) :D :D\n", getAccuracy(class_vect, predict_vect, numtestfiles));
    printf(" Acuraccy is %f LOL :) :) :D :D\n", getAccuracy(class_vect, H_predict_vect, numtestfiles));

    //deleteTrie( &opcodelist ); 
    //free(testmat);
    //free(trainmat);
    //free(c_train_vect);
    //free(c_test_vect );

    free ( trainArray );
    free ( testArray );
    free ( class_vect );
    free ( group_vect );
    free ( predict_vect  );

 return 0;
}
