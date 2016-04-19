/*! \file gpu_naive.h */
#ifndef __gpunaive_H_
#define __gpunaive_H_

void createDeviceMatrixF(float **mat, int rows, int columns);
void createDeviceMatrixI(int **mat, int rows, int columns);
void transferFromDeviceI(int *hostptr, int *deviceptr, int size);
void transferFromDeviceF(float *hostptr, float *deviceptr, int size);
void transferToDeviceF(float *hostptr, float *deviceptr, int size);
void transferToDeviceI(int *hostptr, int *deviceptr, int size);
void pnaiveTrain( int *inmat, int *inclass, int *class_wise, float *outmat, float *class_prob, int inrows, int incolumns, int outrows);
void pnaiveTrain(
        int *inmat,     /*!< [in] input matrix */
        int *inclass,     /*!< [in] input class, for each file */
        int *class_wise,    /*!< [out] class wise total opcodes */
        float *outmat,     /*!< [out] probablity of each opcode in each class */
        float *class_prob,     /*!< [out] probility of each class */
        int inrows,     /*!< [in] number of opcodes*/
        int incolumns,     /*!< [in] total number of files*/
        int outrows    /*!< [in] number of classes */
        );
void passignClassUsingMeanVarianceData( 
        float *in_trainedMatrix,
        float *in_testMatrix,
        int in_numgropus,
        int in_numopcode,
        int in_numtestfiles,
        int *in_groupindexvector,
        int *out_predictvector
        );
void passignClassUsingMeanVarianceDataUsingFeatureSelection( 
        float *in_trainedMatrix, 
        float *in_testMatrix, 
        int *in_featureMatrix,
        int in_numgroups, 
        int in_numopcode, 
        int in_numfeatures,
        int in_numtestfiles, 
        int *in_groupindexvector, 
        int *out_predictvector
        );

float getCudaTime();
void startCudaTimer();
void endCudaTimer();
#endif//__gpunaive_H_
