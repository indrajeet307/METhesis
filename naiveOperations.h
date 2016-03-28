/*! \file naiveOperations.h */
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
float getAccuracy( 
        int *in_pmat,   /*!< [in] predicated class vector */
        int *in_cvect,  /*!< [in] actual class vector */
        int in_total    /*!< [in] length of the vector */
        );
void rotateMatrix( 
        int *in_mat,     /*!< [in] input matrix */
        int *out_mat,    /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in input matrix */
        int in_columns   /*!< [in] number of columns in output matrix */
        );
float getTheProbablity( 
        float in_vval,  /*!< [in] x as in above formulae */
        float in_vmean, /*!< [in] mean value */
        float in_vvar   /*!< [in] variance value */
        );
void assignClassUsingMeanVarianceData(
        float *in_trainMatrix, /*!< [in] trained probablity matrix */
        float *in_testMatrix,  /*!< [in] testing matrix */
        int in_num_groups,     /*!< [in] number of groups / number of rows in train matrix */
        int in_num_opcodes,    /*!< [in] number of opcodes / number of columns in test,train matrix */
        int in_numtestfiles,   /*!< [in] number of test files / number of rows in test matrix */
        int *in_group_index,   /*!< [in] vector containing group index of each file in test matrix( 1:1 mapping) */
        int *out_predict_vect  /*!< [out] predicted class  */
        );
void assignClassUsingMeanVarianceDataAndFeatureSelection(
        float *in_trainMatrix,  /*!< [in] trained probability matrix */
        float *in_testMatrix,   /*!< [in] testing matrix */
        int **in_feature_list,  /*!< [in] array of list of feature vector for each group, number of lists = number of groups */
        int in_num_groups,      /*!< [in] number of groups / number of rows in train matrix */
        int in_num_opcodes,     /*!< [in] number of opcodes / number of columns in test,train matrix */
        int in_numtestfiles,    /*!< [in] number of test files / number of rows in test matrix */
        int *in_group_index,    /*!< [in] vector containing group index of each file in test matrix( 1:1 mapping) */
        int *out_predict_vect   /*!< [out] predicted class  */
        );
#endif //__NAIVEOPS_H_
