#ifndef __gpunaive_H_
#define __gpunaive_H_

void createDeviceMatrixF(float **mat, int rows, int columns);
void createDeviceMatrixI(int **mat, int rows, int columns);
void transferFromDeviceI(int *hostptr, int *deviceptr, int size);
void transferFromDeviceF(float *hostptr, float *deviceptr, int size);
void transferToDeviceF(float *hostptr, float *deviceptr, int size);
void transferToDeviceI(int *hostptr, int *deviceptr, int size);
void pnaiveTrain( int *inmat, int *inclass, int *class_wise, float *outmat, float *class_prob, int inrows, int incolumns, int outrows);
void pnaiveTest( float *in_probmat, float *in_class_prob, int*in_test_mat,
                 int in_test_mat_columns, int in_test_mat_rows, int in_probmat_rows, 
                 int in_probmat_columns, int *out_assigned_class);
#endif//__gpunaive_H_
