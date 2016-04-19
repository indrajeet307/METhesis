#include <stdio.h>
#include <cuda.h>
#include "gpu_naive.h"
#define BLOCK_WIDTH 64
cudaError_t err;
cudaEvent_t starttimer, endtimer;
/*!
*	\brief Allocates rows X columns size of float matrix on device
*
*   Need to pass address of the pointer
*	\return  
*	
*/
void createDeviceMatrixF(
        float **mat,    /*! [out] Matrix pointer on device  */
        int rows,       /*!< [in] number of rows in the matrix */
        int columns     /*!< [in] number of columns in the matrix */
        )
{
    err = cudaSuccess;
    err = cudaMalloc( mat, rows*columns*sizeof(float) );
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    // set all the values to zero 
    err = cudaMemset((*mat), 0, rows*columns*sizeof(float));
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*!
*	\brief Allocates rows X columns size of int matrix on device
*
*   Need to pass address of the pointer
*	\return  
*	
*/
void createDeviceMatrixI(
        int **mat,     /*! [out] Matrix pointer on device  */
        int rows,      /*!< [in] number of rows in the matrix */
        int columns    /*!< [in] number of columns in the matrix */
        )
{
    err = cudaSuccess;
    err = cudaMalloc( mat, rows*columns*sizeof(int) );
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    // set all the values to zero 
    err = cudaMemset((*mat), 0, rows*columns*sizeof(int));
    if ( err != cudaSuccess )
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*!
*	\brief Transfer an Integer vector of size from host to the device memory
*
*   More Details ...
*	\return  
*	
*/
void transferToDeviceI(
        int *hostptr,     /*!< [in] host memory pointer */
        int *deviceptr,     /*!< [in] device memory pointer */
        int size    /*!< [in] size of data to be transfered in bytes */
        )
{
    err = cudaSuccess;
    err = cudaMemcpy(deviceptr, hostptr, sizeof(int)*size, cudaMemcpyHostToDevice);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*!
*	\brief Transfer an Float vector of size from host to the device memory
*
*   More Details ...
*	\return  
*	
*/
void transferToDeviceF(
        float *hostptr,     /*!< [in] host memory pointer */
        float *deviceptr,     /*!< [in] device memory pointer */
        int size    /*!< [in] size of data to be transfered in bytes */
        )
{
    err = cudaSuccess;
    err = cudaMemcpy(deviceptr, hostptr, sizeof(float)*size, cudaMemcpyHostToDevice);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*!
*	\brief Transfer an Integer vector of size from device to the host memory
*
*   More Details ...
*	\return  
*	
*/
void transferFromDeviceI(
        int *hostptr,     /*!< [in] host memory pointer */
        int *deviceptr,     /*!< [in] device memory pointer */
        int size    /*!< [in] size of data to be transfered in bytes */
        )
{
    err = cudaSuccess;
    err = cudaMemcpy(hostptr, deviceptr, sizeof(int)*size, cudaMemcpyDeviceToHost);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*!
*	\brief Transfer an Integer vector of size from device to the host memory
*
*   More Details ...
*	\return  
*	
*/
void transferFromDeviceF(
        float *hostptr,     /*!< [in] host memory pointer */
        float *deviceptr,     /*!< [in] device memory pointer */
        int size    /*!< [in] size of data to be transfered in bytes */
        )
{
    err = cudaSuccess;
    err = cudaMemcpy(hostptr, deviceptr, sizeof(float)*size, cudaMemcpyDeviceToHost);
    if(err != cudaSuccess)
    {
        fprintf(stderr, "#Error %s, %d.\n%s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/*!
*	\brief Creates the probability matrix on the device from the input matrix
*
*   Takes input a matrix containing normalized opcode frequency values, genrates one
*   matrix and a vector, matrix is num_classes X num_opcodes wide and has probability of
*   opcode for that class, the vector contains ratio of number of files of a class to
*   total number of files
*
*   inmat: input matrix, opcodes(along y) X num_files(along x)
*
*   inclass: vector, containg class to which the current file belongs
*
*   class_wise: total opcodes in each class
*
*   outmat: matrix is num_classes X num_opcodes wide and has probability of
*   opcode for that class
*
*   class_prob: the vector contains ratio of number of files of a class to
*   total number of files
*
*   inrows: total number of opcodes
*   incolumns: total number of files for training 
*   outrows: total number of classes 
*
*	\return 
*	
*/
__global__
void naiveTrainKernel(
        int *inmat,     /*!< [in] input matrix */
        int *inclass,     /*!< [in] input class, for each file */
        int *class_wise,    /*!< [out] class wise total opcodes */
        float *outmat,     /*!< [out] probablity of each opcode in each class */
        float *class_prob,     /*!< [out] probility of each class */
        int inrows,     /*!< [in] number of opcodes*/
        int incolumns,     /*!< [in] total number of files*/
        int outrows    /*!< [in] number of classes */
        )
{
    // thread for each file
    int index = blockIdx.x*BLOCK_WIDTH+threadIdx.x;
    int cls;
    if( index < incolumns)
    {
        cls = inclass[ index ];

        // for each opcode
        for ( int i=0; i<inrows; i++)
        {
            // increment the count of total opcodes in current class by the frequency in
            // input matrix
            atomicAdd( &(class_wise[ cls ]), inmat[ i*incolumns + index]);
            // increment the count of opcode in current class by the frequency in input 
            // matrix
            atomicAdd( &(outmat[ cls*inrows + i]), (float)inmat[ i*incolumns + index]);
            // increment the number of files in current class
            atomicAdd( &(class_prob[ cls ]), (float)1);
        }
        __syncthreads();
        for ( int i=0; i<inrows; i++)
        {
            // save the probability of each opcode
            float temp = ( log10(( outmat[ cls*inrows+ i]+1)/ (class_wise[ cls ]+1)));
            outmat[ cls*inrows+ i] = (-1)*temp;
        }
        __syncthreads();
        // save the probability of each class 
        class_prob[ cls ] = (-1)*log10( class_prob[ cls ]/incolumns );
    }
}

/*!
*	\brief Wrapper funtion for traning the kernel
*
*   For variable description refer the kernel documentation
*	\return  
*	
*/
void pnaiveTrain(
        int *inmat,     /*!< [in] input matrix */
        int *inclass,     /*!< [in] input class, for each file */
        int *class_wise,    /*!< [out] class wise total opcodes */
        float *outmat,     /*!< [out] probablity of each opcode in each class */
        float *class_prob,     /*!< [out] probility of each class */
        int inrows,     /*!< [in] number of opcodes*/
        int incolumns,     /*!< [in] total number of files*/
        int outrows    /*!< [in] number of classes */
        )
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

/*!
*	\brief Assigns classes to the unassigned files, using the probability matrix genrated
*	by the training kernel
*
*   in_probmat : probability matrix, genrated by training kernel
*
*   in_class_prob : vector containing, ratio of number of files in a class to total number
*   of files
*
*   in_test_mat : opcode frequency matrix for test file
*
*   in_test_mat_columns : number of files for testing
*
*   in_test_mat_rows : total number of opcodes
*
*   in_probmat_rows : number of classes 
*
*   in_probmat_columns : total number of opcodes 
*
*   out_assigned_class : predicted class for the test files
*   
*	\return 
*	
*/
__global__
void naiveTestKernel(
        float *in_probmat,          /*!< [in] pobability of each opcode in each class */
        float *in_class_prob,       /*!< [in] probability of each class */
        int *in_test_mat,           /*!< [in] input test files */
        int  in_test_mat_columns,   /*!< [in] number of files in test matrix */
        int  in_test_mat_rows,      /*!< [in] number of opcodes in test matrix */
        int  in_probmat_rows,       /*!< [in] number of classes */
        int  in_probmat_columns,    /*!< [in] number of opcodes */
        int *out_assigned_class     /*!< [out] class assigned to input files */
        )
{
    int index = blockIdx.x*BLOCK_WIDTH+threadIdx.x;
    float cls[2];
    if( index < in_test_mat_columns)
    {
        cls[0] = cls[1] = 0;
        // for each opcode
        for( int i =0 ;i<in_test_mat_rows;i++)
        {
            // if the opcode is present in the test file
            if( in_test_mat[ i*in_test_mat_columns+index ] > 0)
            {
                // for each class
                for ( int j=0; j<in_probmat_rows; j++)
                {
                    // update the probability 
                    cls[j] += (float)in_test_mat[ i*in_test_mat_columns+index]*in_probmat[ j*in_probmat_columns+ i];
                }
            }
        }
        // assign the class with maximum probability
        out_assigned_class[ index ] = cls[0] > cls[1] ? 0 : 1;
    }
}

/*!
*	\brief Wrapper funtion for testing the kernel genrated by training
*
*   For variable description refer the kernel documentation
*	\return  
*	
*/
void pnaiveTest(
        float *in_probmat,          /*!< [in] pobability of each opcode in each class */
        float *in_class_prob,       /*!< [in] probability of each class */
        int *in_test_mat,           /*!< [in] input test files */
        int  in_test_mat_columns,   /*!< [in] number of files in test matrix */
        int  in_test_mat_rows,      /*!< [in] number of opcodes in test matrix */
        int  in_probmat_rows,       /*!< [in] number of classes */
        int  in_probmat_columns,    /*!< [in] number of opcodes */
        int *out_assigned_class     /*!< [out] class assigned to input files */
        )
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

/*!
 *	\brief Gives the probablity for the current in_val
 *
 *   probability = \f$ \frac{1}{\sqrt{2\Pi\sigma^{2}}}\exp^{\frac{(x-\mu)^{2}}{2\sigma^{2}}} \f$
 *
 *	\return probablity in float
 *	\see 
 *	
 */
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

/*!
*	\brief Assigns class based on mean and variance of the frequency of opcode occurance
*	in the file
*
*   Threads equal to number of test files are created, each calculates the probability of
*   current file being benign or malware, the class with maximum probability is assigned
*   Each thread goes through each opcode if the normalized value of current opcode is
*   greater than 0, calulate and add the probability
*
*   in_trainedMatrix : matrix containing the groupwise mean and variance values
*
*   in_testMatrix : test files normalized opcode frequency values 
        numtesfiles X numopcodes
*
*   in_numgroups : total number of groups    
*
*   in_numopcode : total number of opcodes    
*
*   in_numtestfiles : number of test files  
*
*   in_groupindexvector : group index of the current file
*
*   out_predictvector : vector of predicted class
*
*	\return What does it return?
*	
*/
__global__
void assignClassUsingMeanVarianceDataKernel(
        float *in_trainedMatrix,    /*!< [in] trained Matrix, containing mean variance
        values */
        float *in_testMatrix,    /*!< [in] test files */
        int in_numgroups,    /*!< [in] number of groups */
        int in_numopcode,    /*!< [in] number of opcodes */
        int in_numtestfiles,    /*!< [in] number of test files */
        int *in_groupindexvector,    /*!< [in] vector containing group index of test files
        based on its size*/
        int *out_predictvector    /*!< [out] predicted class for each input file */
        )
{
    int tid = threadIdx.x + blockIdx.x * BLOCK_WIDTH;
    if( tid < in_numtestfiles )
    {

        int group_index = in_groupindexvector[tid];
        int index_in_trainedMatrix = group_index*4;
        int im=0, iv=1;
        float bprob=0.0, mprob=0.0;

        __syncthreads();

        // for each opcode
        for( int i=0; i<in_numopcode; i++)
        {
            float x;
            x = in_testMatrix[ i*in_numtestfiles + tid ];
            // if the test file has the current opcode
            if( x > 0) 
            {
                float bvar, bmean, mvar, mmean;
                bmean = in_trainedMatrix[ (0+im+index_in_trainedMatrix)*in_numopcode + i];
                bvar  = in_trainedMatrix[ (0+iv+index_in_trainedMatrix)*in_numopcode + i];
                // get probability of file being benign
                bprob += getTheProbablityD( x, bmean, bvar);

                mmean = in_trainedMatrix[ (2+im+index_in_trainedMatrix)*in_numopcode+ i];
                mvar  = in_trainedMatrix[ (2+iv+index_in_trainedMatrix)*in_numopcode+ i];
                // get probability of file being malware
                mprob += getTheProbablityD( x, mmean, mvar);
            }

        }
        __syncthreads();

        // assign class with maximum probability
        if( bprob > mprob) 
            out_predictvector[ tid ] = 0;
        else
            out_predictvector[ tid ] = 1;
    }
    __syncthreads();
}

/*!
*	\brief Wrapper funtion for testing using the mean and variance data 
*
*   For variable description refer the kernel documentation
*	\return  
*	
*/
void passignClassUsingMeanVarianceData( 
        float *in_trainedMatrix,    /*!< [in] trained Matrix, containing mean variance
        values */
        float *in_testMatrix,    /*!< [in] test files */
        int in_numgroups,    /*!< [in] number of groups */
        int in_numopcode,    /*!< [in] number of opcodes */
        int in_numtestfiles,    /*!< [in] number of test files */
        int *in_groupindexvector,    /*!< [in] vector containing group index of test files
        based on its size*/
        int *out_predictvector    /*!< [out] predicted class for each input file */
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
    startCudaTimer();
    assignClassUsingMeanVarianceDataKernel<<<gridProp,blockProp>>>(
            in_trainedMatrix,
            in_testMatrix,
            in_numgroups,
            in_numopcode,
            in_numtestfiles,
            in_groupindexvector,
            out_predictvector
            );
    endCudaTimer();
    printf(" Time required for parallel is %f\n",getCudaTime());
    if (err != cudaSuccess)
    {
        fprintf(stderr, "%s, %d.\n %s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }

}

/*!
*	\brief Assigns class based on mean and variance of the frequency of opcode occurance
*	in the file, only opcodes belonging to the prominent group (feature list) are taken into
*	consideration
*
*   Threads equal to number of test files are created, each calculates the probability of
*   current file being benign or malware, the class with maximum probability is assigned
*   Each thread goes through each opcode if the normalized value of current opcode is
*   greater than 0 and the opcode belongs to the prominent opcode( freature list), 
*   calulate and add the probability
*
*   in_trainedMatrix : matrix containing the groupwise mean and variance values
*
*   in_testMatrix : test files normalized opcode frequency values 
*        numtesfiles X numopcodes
*
*   in_featureMatrix : (promenent opcodes) features for each group
*
*   in_numgroups : total number of groups    
*
*   in_numopcode : total number of opcodes    
*
*   in_numtestfiles : number of test files  
*
*   in_groupindexvector : group index of the current file
*
*   out_predictvector : vector of predicted class
*
*	\return What does it return?
*	
*/
    __global__
void assignClassUsingMeanVarianceDataUsingFeatureSelectionKernel(
        float *in_trainedMatrix,    /*!< [in] trained Matrix, containing mean variance
        values */
        float *in_testMatrix,    /*!< [in] test files */
        int *in_featureMatrix,       /*!< [in] feature vector, for each group*/
        int in_numgroups,    /*!< [in] number of groups */
        int in_numopcode,    /*!< [in] number of opcodes */
        int in_numfeatures,    /*!< [in] number of feature*/
        int in_numtestfiles,    /*!< [in] number of test files */
        int *in_groupindexvector,    /*!< [in] vector containing group index of test files
        based on its size*/
        int *out_predictvector    /*!< [out] predicted class for each input file */
        )
{
    int tid = threadIdx.x + blockIdx.x * BLOCK_WIDTH;
    int group_index = in_groupindexvector[tid];
    int index_in_trainedMatrix = group_index*4;
    int im=0, iv=1;
    float bprob=0.0, mprob=0.0;
    __syncthreads();

    if( tid < in_numtestfiles)
    {
    // for each opcode
    for( int i=0; i<in_numfeatures; i++)
    {
        int featureindex;
        float x;
        featureindex = in_featureMatrix[ group_index*in_numfeatures+ i];
        x = in_testMatrix[ featureindex*in_numtestfiles + tid ];
        // if opcode present in test file
        if( x > 0) 
        {
            float bvar=0, bmean=0, mvar=0, mmean=0;
            bmean = in_trainedMatrix[ (0+im+index_in_trainedMatrix)*in_numopcode + featureindex];
            bvar  = in_trainedMatrix[ (0+iv+index_in_trainedMatrix)*in_numopcode + featureindex];
            // get the probability of file being benign
            bprob += getTheProbablityD( x, bmean, bvar);
            // multiplied with feature(0/1), will account only if the feature is amongst
            // the selected feature

            mmean = in_trainedMatrix[ (2+im+index_in_trainedMatrix)*in_numopcode+ featureindex];
            mvar  = in_trainedMatrix[ (2+iv+index_in_trainedMatrix)*in_numopcode+ featureindex];
            // get the probability of file being malware 
            mprob += getTheProbablityD( x, mmean, mvar);
        }
    }
    __syncthreads();

    // assign the class
    if( bprob > mprob ) 
        out_predictvector[ tid ] = 0;
    else
        out_predictvector[ tid ] = 1;
    }
}

/*!
*	\brief Wrapper funtion for testing using the mean and variance data and feature
*	selection vector
*
*   For variable description refer the kernel documentation
*	\return  
*	
*/
void passignClassUsingMeanVarianceDataUsingFeatureSelection( 
        float *in_trainedMatrix,    /*!< [in] trained Matrix, containing mean variance
        values */
        float *in_testMatrix,    /*!< [in] test files */
        int *in_featureMatrix,       /*!< [in] feature vector */
        int in_numgroups,    /*!< [in] number of groups */
        int in_numopcode,    /*!< [in] number of opcodes */
        int in_numfeatures,    /*!< [in] number of features*/
        int in_numtestfiles,    /*!< [in] number of test files */
        int *in_groupindexvector,    /*!< [in] vector containing group index of test files
        based on its size*/
        int *out_predictvector    /*!< [out] predicted class for each input file */
        )
{
    /*
TODO: try checking if we can get speed up by making trainedMatrix go to 
constant memory
     */
    dim3 gridProp( ceil(in_numtestfiles/BLOCK_WIDTH)+1,1,1);
    dim3 blockProp(BLOCK_WIDTH,1,1);
    //printf(" Running Kernel %d Threads.\n",BLOCK_WIDTH);
    //printf(" Running %.0lf Blocks.\n",ceil(in_numtestfiles/BLOCK_WIDTH));
    err = cudaSuccess;
    startCudaTimer();
    assignClassUsingMeanVarianceDataUsingFeatureSelectionKernel<<<gridProp,blockProp>>>(
            in_trainedMatrix,
            in_testMatrix,
            in_featureMatrix,
            in_numgroups,
            in_numopcode,
            in_numfeatures,
            in_numtestfiles,
            in_groupindexvector,
            out_predictvector
            );
    if (err != cudaSuccess)
    {
        fprintf(stderr, "%s, %d.\n %s.", __FILE__, __LINE__, cudaGetErrorString(err));
        exit(EXIT_FAILURE);
    }
    endCudaTimer();
    printf(" %5.5f\t",getCudaTime());
}

void startCudaTimer()
{
    cudaEventCreate(&starttimer);
    cudaEventCreate(&endtimer);
    cudaEventRecord(starttimer);

}
void endCudaTimer()
{
    cudaEventRecord(endtimer);
}
float getCudaTime()
{
    float time;
    cudaEventSynchronize(endtimer);
    cudaDeviceSynchronize();
    cudaEventElapsedTime(&time, starttimer,endtimer);
    return time;
}
