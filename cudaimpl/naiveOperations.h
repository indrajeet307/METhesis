/*! \file naiveOperations.h */
#ifndef __NAIVEOPS_H_
#define __NAIVEOPS_H_

void assignClass( 
        int *in_mat,     /*!< [in] input matrix */
        float *in_prob,     /*!< [in] probability matrix */
        float *in_cprob,     /*!< [in] class probability matrix */
        int *out_pridict,     /*!< [out] predicted class */
        int in_rows,     /*!< [in] number of input rows */
        int in_classes,     /*!< [in] number of classes */
        int in_columns    /*!< [in] number of columns */
        );

int normalize( 
        int *in_mat,     /*!< [in] input matrix */
        float *out_mat,     /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in the input matrix */
        int in_columns    /*!< [in] number of columns in the output matrix */
        );

int createClassWiseData( 
        int *in_mat,     /*!< [in] input matrix */
        int *out_mat,     /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in input matrix */
        int in_columns,     /*!< [in] number of columns in input matrix */
        int in_outrows    /*!< [in] number of rows in output matrix */
        );

int createProbablityMatrix( 
        int     *in_inmat,    /*!< [in] input matrix */
        float   *out_outmat,    /*!< [out] output matrix */
        int     *in_cvect,    /*!< [in] class vector */
        float   *out_cprob,    /*!< [out] probability of each class */
        int     in_inrows,    /*!< [in] number of rows in input matrix */
        int     in_incolumns,    /*!< [in] number of columns in input matrix */
        int     in_outrows,    /*!< [in] number of rows in output matrix */
        int     in_outcolumns    /*!< [in] number of columns in output matrix */
        );

void printFloatMatrix(
        float *in_mat,     /*!< [in] pointer to the matrix */
        int in_rows,     /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        );

void printIntMatrix(
        int *in_mat,     /*!< [in] pointer to the matrix */
        int in_rows,     /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        );
int *createVector(
        int in_size      /*!< [in] length of the vector */
        );
float* createFloatMatrix(
        int in_rows,     /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        );
int* createIntMatrix( 
        int in_rows,     /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        );
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
void rotateMatrixF( 
        float *in_mat,     /*!< [in] input matrix */
        float *out_mat,    /*!< [out] output matrix */
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
        int *in_feature_list,  /*!< [in] array of list of feature vector for each group, number of lists = number of groups */
        int in_num_groups,      /*!< [in] number of groups / number of rows in train matrix */
        int in_num_opcodes,     /*!< [in] number of opcodes / number of columns in test,train matrix */
        int in_num_features,     /*!< [in] number of prominent features */
        int in_numtestfiles,    /*!< [in] number of test files / number of rows in test matrix */
        int *in_group_index,    /*!< [in] vector containing group index of each file in test matrix( 1:1 mapping) */
        int *out_predict_vect   /*!< [out] predicted class  */
        );
#endif //__NAIVEOPS_H_
