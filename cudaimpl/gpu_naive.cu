#include <stdio.h>
#include <cuda.h>
#include "gpu_naive.h"
#define BLOCK_WIDTH 64
cudaError_t err;
void createDeviceMatrixF(float **mat, int rows, int columns)
{
    err = cudaSuccess;
    err = cudaMalloc( mat, rows*columns*sizeof(float) );
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    err = cudaMemset((*mat), 0, rows*columns*sizeof(float));
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

void createDeviceMatrixI(int **mat, int rows, int columns)
{
    err = cudaSuccess;
    err = cudaMalloc( mat, rows*columns*sizeof(int) );
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    err = cudaMemset((*mat), 0, rows*columns*sizeof(int));
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

void transferToDeviceI(int *hostptr, int *deviceptr, int size)
{
    err = cudaSuccess;
    err = cudaMemcpy(deviceptr, hostptr, sizeof(float)*size, cudaMemcpyHostToDevice);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

void transferToDeviceF(float *hostptr, float *deviceptr, int size)
{
    err = cudaSuccess;
    err = cudaMemcpy(deviceptr, hostptr, sizeof(float)*size, cudaMemcpyHostToDevice);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

void transferFromDeviceI(int *hostptr, int *deviceptr, int size)
{
    err = cudaSuccess;
    err = cudaMemcpy(hostptr, deviceptr, sizeof(int)*size, cudaMemcpyDeviceToHost);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

void transferFromDeviceF(float *hostptr, float *deviceptr, int size)
{
    err = cudaSuccess;
    err = cudaMemcpy(hostptr, deviceptr, sizeof(float)*size, cudaMemcpyDeviceToHost);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*
   files along x and opcodes along y
 */
    __global__
void naiveTrainKernel(int *inmat, int *inclass, int *class_wise,float *outmat, float *class_prob, int inrows, int incolumns, int outrows)
{
    int index = blockIdx.x*BLOCK_WIDTH+threadIdx.x;
    int cls;
    if( index < incolumns)
    {
        cls = inclass[ index ];

        for ( int i=0; i<inrows; i++)
        {
            atomicAdd( &(class_wise[ cls ]), inmat[ i*incolumns + index]);
            atomicAdd( &(outmat[ cls*inrows + i]), (float)inmat[ i*incolumns + index]);
            atomicAdd( &(class_prob[ cls ]), (float)1);
        }
        __syncthreads();
        for ( int i=0; i<inrows; i++)
        {
            float temp = ( log10(( outmat[ cls*inrows+ i]+1)/ (class_wise[ cls ]+1)));
            outmat[ cls*inrows+ i] = (-1)*temp;
        }
        __syncthreads();
        class_prob[ cls ] = (-1)*log10( class_prob[ cls ]/incolumns );
    }
}

void pnaiveTrain( int *inmat, int *inclass, int *class_wise, float *outmat, float *class_prob, int inrows, int incolumns, int outrows)
{
    dim3 gridProp( ceil(incolumns/BLOCK_WIDTH)+1,1,1);
    dim3 blockProp(BLOCK_WIDTH,1,1);
    printf(" Running %d Threads.\n",BLOCK_WIDTH);
    printf(" Running %.0lf Blocks.\n",ceil(incolumns/BLOCK_WIDTH));
    err = cudaSuccess;
    naiveTrainKernel<<<gridProp,blockProp>>>( inmat, inclass, class_wise, outmat, class_prob, inrows, incolumns, outrows);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "%s, %d.\n %s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

__global__

void naiveTestKernel( float *in_probmat, float *in_class_prob, int*in_test_mat,
                 int in_test_mat_columns, int in_test_mat_rows, int in_probmat_rows, 
                 int in_probmat_columns, int *out_assigned_class)
{
    int index = blockIdx.x*BLOCK_WIDTH+threadIdx.x;
    float cls[2];
    if( index < in_test_mat_columns)
    {
        cls[0] = cls[1] =0;
        for( int i =0 ;i<in_test_mat_rows;i++)
        {
            if( in_test_mat[ i*in_test_mat_columns+index ] > 0)
            {
                for ( int j=0; j<in_probmat_rows; j++)
                {
                    cls[j] += (float)in_test_mat[ i*in_test_mat_columns+index]*in_probmat[
                    j*in_probmat_columns+ i];
                }
            }
        }
        out_assigned_class[ index ] = cls[0] > cls[1] ? 0 : 1;
    }
}

void pnaiveTest( float *in_probmat, float *in_class_prob, int*in_test_mat,
                 int in_test_mat_columns, int in_test_mat_rows, int in_probmat_rows, 
                 int in_probmat_columns, int *out_assigned_class)
{
    dim3 gridProp( ceil(in_test_mat_columns/BLOCK_WIDTH)+1,1,1);
    dim3 blockProp(BLOCK_WIDTH,1,1);
    printf(" Running %d Threads.\n",BLOCK_WIDTH);
    printf(" Running %.0lf Blocks.\n",ceil(in_test_mat_columns/BLOCK_WIDTH));
    err = cudaSuccess;
    naiveTestKernel<<<gridProp,blockProp>>>(in_probmat, in_class_prob, in_test_mat,
    in_test_mat_columns, in_test_mat_rows, in_probmat_rows, 
    in_probmat_columns, out_assigned_class);
    if (err != cudaSuccess)
    {
        fprintf(stderr, "%s, %d.\n %s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}
