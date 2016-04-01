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

__device__
float getTheProbablityD( 
        float in_vval,  /*!< [in] x as in above formulae */
        float in_vmean, /*!< [in] mean value */
        float in_vvar   /*!< [in] variance value */
        )
{

    float result=0.0;
    float val1 =  1/sqrt( 2.0* M_PI* in_vvar);
    float val2 = (in_vval-in_vmean)*(in_vval-in_vmean)/(2.0*in_vvar);
    val2 = 1 / exp( val2);
    result = log10( val1*val2);
    if( isnan(result) || isinf(result) ) return 0.0;
    return result;
}
    __global__
void assignClassUsingMeanVarianceDataKernel(
        float *in_trainedMatrix,
        float *in_testMatrix,
        int in_numgropus,
        int in_numopcode,
        int in_numtestfiles,
        int *in_groupindexvector,
        int *out_predictvector
        )
{
    int tid = threadIdx.x + blockIdx.x * BLOCK_WIDTH;
    int index_in_trainedMatrix = tid*4;
    int im=0, iv=1;
    float bprob=0.0, mprob=0.0;

    __syncthreads();

    for( int i=0; i<in_numopcode; i++)
    {
        float x, bvar, bmean, mvar, mmean;
        x = in_testMatrix[ i*in_numtestfiles + tid ];
        bmean = in_testMatrix[ i*in_numtestfiles + index_in_trainedMatrix+0+im ];
        bvar  = in_testMatrix[ i*in_numtestfiles + index_in_trainedMatrix+0+iv ];
        bprob += getTheProbablityD( x, bmean, bvar);

        mmean = in_testMatrix[ i*in_numtestfiles + index_in_trainedMatrix+2+im ];
        mvar  = in_testMatrix[ i*in_numtestfiles + index_in_trainedMatrix+2+iv ];
        mprob += getTheProbablityD( x, mmean, mvar);

    }
    __syncthreads();

    if( bprob > bprob ) 
        out_predictvector[ tid ] = 0;
    else
        out_predictvector[ tid ] = 1;
}

void passignClassUsingMeanVarianceData( 
        float *in_trainedMatrix,
        float *in_testMatrix,
        int in_numgropus,
        int in_numopcode,
        int in_numtestfiles,
        int *in_groupindexvector,
        int *out_predictvector
        )
{
    /*
TODO: try checking if we can get speed up by making trainedMatrix go to 
constant memory
     */
    dim3 gridProp( ceil(in_numtestfiles/BLOCK_WIDTH)+1,1,1);
    dim3 blockProp(BLOCK_WIDTH,1,1);
    printf(" Running Kernel %d Threads.\n",BLOCK_WIDTH);
    printf(" Running %.0lf Blocks.\n",ceil(in_numtestfiles/BLOCK_WIDTH));
    err = cudaSuccess;
    assignClassUsingMeanVarianceDataKernel<<<gridProp,blockProp>>>(
            in_trainedMatrix,
            in_testMatrix,
            in_numgropus,
            in_numopcode,
            in_numtestfiles,
            in_groupindexvector,
            out_predictvector
            );
    if (err != cudaSuccess)
    {
        fprintf(stderr, "%s, %d.\n %s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

}
