#ifndef __NAIVEOPS_H_
#define __NAIVEOPS_H_
int createClassWiseData( int *, int *, int , int , int );
int createProbablityMatrix( int *, float *, int*,float*,int , int , int , int );
int normalize( int *, float*, int , int );
void print( float *, int , int );
void printIntMatrix( int *, int , int );
void assignClass( int *, float *,float*, int *, int , int , int );
int *createMatrix( int , int );
int *createVector(int );
float *createFloatMatrix( int , int );
float getAccuracy(int *pmat, int *cvect, int total);
void rotateMatrix( int *inmat, int *outmat, int inrows, int incolumns);
void assignClassUsingMeanVarianceData(
                                       float *in_trainArray,
                                       float *in_testArray,
                                       int in_num_groups,
                                       int in_num_opcodes,
                                       int in_numtestfiles,
                                       int *in_group_index,
                                       int *out_predict_vect );
void assignClassUsingMeanVarianceDataAndFeatureSelection(
                                       float *in_trainArray,
                                       float *in_testArray,
                                       int **in_feature_list,
                                       int in_num_groups,
                                       int in_num_opcodes,
                                       int in_numtestfiles,
                                       int *in_group_index,
                                       int *out_predict_vect );
#endif //__NAIVEOPS_H_
