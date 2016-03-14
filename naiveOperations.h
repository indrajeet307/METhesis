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
#endif //__NAIVEOPS_H_
