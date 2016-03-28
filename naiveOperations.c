#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

/*
 *	@DESC   : Normalizes the given matrix along the row
 *	@PRAM   : matrix, num of rows, num of columns
 *	@RETURN : Modifies the supplied matrix
 *   
 *                            old(x) - min
 *   Normalized value(x) = -----------------------
 *                            max - min
 */
int normalize( int *inmat, float *outmat, int rows, int columns)
{
    int i,j;
    int max, min;
    for ( i=0; i<rows; i++)
    {
        max = INT_MIN;
        min = INT_MAX;
        for ( j=0;j<columns; j++)
        {
            if( min > inmat[ (i*columns)+j ] )
                min = inmat[ (i*columns)+j ] ;

            if( max < inmat[ (i*columns)+j ] )
                max = inmat[ (i*columns)+j ];
        }
        for (  j=0; j<columns; j++)
        {
            outmat[(i*columns)+j] =(float)(inmat[(i*columns)+j] - min)/(float)(max-min)   ;
        }
    }
}

/*
 *	@DESC   : Takes a matrix with class as the last column, returns a matrix with
 *          : classwise info the returned matrix is num of classes x num of columns
 *	@PRAM   : old matrix, new matrix, num of rows (old matrix), num of columns( old/new
 *          : matrix, num of rows(new matrix) == num of classes
 *	@RETURN : new matrix pointer is modified
 *	
 */
int createClassWiseData( int *mat, int *outmat, int inrows, int incolumns, int outrows)
{
    int i,j;
    int sum=0;
    for (  i=0; i<inrows; i++)
    {
        sum = 0;
        for ( j=0; j<incolumns-1; j++)
        {
            outmat[ (i*incolumns)+j ] += mat [ (i*incolumns)+j ];
            sum += mat[ (i*incolumns)+j ];
        }
        outmat[j] = sum;
    }
}

/*
 *	@DESC   : creates a probability matrix from the given matrix
 *	@PRAM   : input matrix, probability matrix, num of rows, num of columns, num of classes
 *          :
 *	@RETURN : the probably matrix is modified
 *	
 */
int createProbablityMatrix( int *inmat, float *outmat, int *cvect, 
                            float *cprob, int inrows, int incolumns, 
                            int outrows, int outcolumns)
{
#define  INDEX(i,j,cols) ((i*cols)+j)
    int i,j;
    int sum;
    int class;
    float *class_wise_total=(float*) calloc(sizeof(float),outrows);
    assert(class_wise_total != NULL );
    for ( i=0; i<inrows; i++)
    {
        sum =0;
        class = cvect[ i ];
        for ( j=0; j<outcolumns; j++)
        {
            outmat[ INDEX(class,j,outcolumns) ] +=   (float)inmat[ INDEX(i,j,incolumns) ];
            class_wise_total [ class ] +=   (float)inmat[ INDEX(i,j,incolumns) ];
        }
        cprob[ class ] += 1;
    }
    for ( i=0; i<outrows; i++)
    {
        for ( j=0; j<outcolumns; j++)
        {
             float temp = (log10((outmat[ INDEX(i,j,outcolumns) ]+1) / (class_wise_total[ i ]+1) ));
                outmat[ INDEX(i,j,outcolumns) ] = (-1)*temp; // multiply by -1 because decimal numbers give negative log values
        }
        cprob[ i ] = (-1)*log10(cprob[ i ]/ inrows); // multiply by -1 because decimal numbers give negative log values
        //printf("  %lf \t", class_wise_total[ i ]);
    }
    free(class_wise_total);
#undef INDEX
}

/*
 *	@DESC   : Print the Integer Matrix
 *	@PRAM   : matrix ptr, num of rows, num of columns
 *	@RETURN :  
 *	
 */
void print( float *mat, int rows, int columns)
{
    int i,j;
    for ( i=0; i<rows; i++)
    {
        for ( j=0; j<columns; j++)
        {
            printf(" %f",mat[ (i*columns)+j ]);
        }
        printf("\n");
    }
}

/*
 *	@DESC   : Print the float matrix
 *	@PRAM   : matrix ptr, num of rows, num of columns
 *	@RETURN : 
 *	
 */
void printIntMatrix( int *mat, int rows, int columns)
{
    int i,j;
    for ( i=0; i<rows; i++)
    {
        for ( j=0; j<columns; j++)
        {
            printf(" %d",mat[ (i*columns)+j ]);
        }
        printf("\n");
    }
}

/*
 *	@DESC   : Assgins classes to the the test matrix
 *	@PRAM   : matrix ptr, probablity matrix, predict vector, num of rows in testing
 *          : matrix, num of rows in probablity matrix, num of columns in both the matrices
 *	@RETURN :
 *	
 */
void assignClass( int *mat, float *prob, float *cprob, int *pridict, int rows, int classes, int columns)
{
#define  INDEX(i,j,cols) ((i*cols)+j)
    int i,j,k;
    double *classprob =  (double*) calloc( sizeof(double), classes);
    for ( i=0; i<rows; i++)
    {
        for ( k=0; k<classes; k++)
            classprob[ k ] = cprob[k];
        for ( j=0; j<columns; j++)
        {
            for ( k=0; k<classes; k++)
            {
                if ( mat [ INDEX(i,j,columns) ] > 0 ) 
                    classprob[ k ] += mat [ INDEX(i,j,columns) ]*prob [ INDEX(k,j,columns) ];
            }
        }
        int maxClass=0;
        for ( k=0; k<classes; k++)
        {
            if( classprob[ maxClass ] > classprob[k] )
                maxClass = k;
        }
        pridict[i] = maxClass;
    }
    free(classprob);
#undef INDEX
}

/*
*	@DESC   : Creates a matrix of rows and columns
*	@PRAM   : rows, columns
*	@RETURN : pointer to the matrix
*	
*/
int* createMatrix( int rows, int columns)
{
    int *temp = (int*) calloc ( sizeof(int) , rows*columns );
    return temp;
}

int *createVector(int size)
{
    int *temp = (int*) calloc( sizeof(int), size);
    return temp;
    }

float* createFloatMatrix( int rows, int columns)
{
    float *temp = (float*) calloc( sizeof(float), columns*rows);
        return temp;
}

/*!
*	\brief Gives accuracy of current configuration
*
*   More Details ...
*	\return ratio of correct preditions to number of predictions
*	
*/
float getAccuracy( 
        int *in_pmat,   /*!< [in] predicated class vector */
        int *in_cvect,  /*!< [in] actual class vector */
        int in_total    /*!< [in] length of the vector */
        )
{
    int i;
    float ans=0.0;
    for ( i=0; i<in_total; i++)
    {
        if( in_pmat[i] == in_cvect[i])
            ans ++;
    }
    return ans/in_total;
}

/*!
*	\brief  Gives transpose of a matrix
*
*   The rows of in_mat are converted to columns of the out_mat, and columns of in_mat are
*   converted to rows of out_mat
*                                                                                       
*	in_mat    =   in_rows      X   in_columns
*	out_mat   =   in_columns   X   in_rows
*	\return   
*	
*/
void rotateMatrix( 
        int *in_mat,     /*!< [in] input matrix */
        int *out_mat,    /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in input matrix */
        int in_columns   /*!< [in] number of columns in output matrix */
        )
{
    int outrows=in_columns;
    int outcolumns=in_rows;
    int i,j;

    for ( i=0; i<in_rows; i++)
    {
        for ( j=0;j<in_columns;j++)
        {
            out_mat[ j*outcolumns + i ] = in_mat[ i*in_columns+j ];
        }
    }
}

/*!
*	\brief Gives the probablity for the current in_val
*                                         (x - mean)^2
*                                       ---------------
*                      1                 2*variance
*	probablity = -------------------- e 
*	             sqrt( 2*pi*variance)
*
*	\return probablity in float
*	\see 
*	
*/
float getTheProbablity( 
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
*	\brief Assigns class to the test inputs
*
*   For all the test files in testArray, gets the group index from in_group_index( which
*   is decided based on file size), selects the probablites from in_trainMatrix only for
*   those opcodes whose normalized occurances are greater than 0
*   
*   in_trainMatrix:
*     four rows in in_trainMatrix are considered as one row, structure is as follows
*
*   |               |         |          | in_num_opcodes number of columns |
*   |:-------------:|:-------:|:--------:|:--------------------------------:|
*   | group [0-99]  | benign  | mean     |                                  |
*   | in_num_groups |         | variance |                                  |
*   |               | malware | mean     |                                  |
*   |               |         | variance |                                  |
*
*    in_testMatrix:
*   |                 | in_num_opcodes number of columns |
*   |:---------------:|:--------------------------------:|
*   | inumber of rows=n_numtestfiles  ||
*
*   in_group_index:
*   has in_numtestfiles number of values containg group number of file, can be thought of
*   extra column in in_testMatrix 
*
*   \return predicted class for files in in_testMatrix
*	  
*/
void assignClassUsingMeanVarianceData(
        float *in_trainMatrix, /*!< [in] trained probablity matrix */
        float *in_testMatrix,  /*!< [in] testing matrix */
        int in_num_groups,     /*!< [in] number of groups / number of rows in train matrix */
        int in_num_opcodes,    /*!< [in] number of opcodes / number of columns in test,train matrix */
        int in_numtestfiles,   /*!< [in] number of test files / number of rows in test matrix */
        int *in_group_index,   /*!< [in] vector containing group index of each file in test matrix( 1:1 mapping) */
        int *out_predict_vect  /*!< [out] predicted class  */
         )
        
{
    int i,j,k;
    float pmal=0.0, pben=0.0;
    int mean =0, var =1; /// \todo make this genric or avoid it somehow
    float vmean =0, vvar =1;
    int index=0;
    // Iterate through each file in in_testMatrix
    for ( i=0; i<in_numtestfiles; i++)
    {
        index = in_group_index[i]*4;
        pmal=0.0; 
        pben=0.0;
        // For all the opcodes
        for ( j=0; j<in_num_opcodes; j++)
        {
            // If any opcode in current file has normalized freq > 0
            if( in_testMatrix[i*in_num_opcodes+j] > 0 ) 
            {
                // get vmean and var considering it is a benign
                vmean = in_trainMatrix[(index+0+mean)*in_num_opcodes+j];
                vvar  = in_trainMatrix[(index+0+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                // add the probablity in benign
                pben += getTheProbablity( in_testMatrix[i*in_num_opcodes+j], vmean, vvar);

                // get vmean and var considering it is a malware
                vmean = in_trainMatrix[(index+2+mean)*in_num_opcodes+j];
                vvar  = in_trainMatrix[(index+2+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                // add the probablity in malware
                pmal += getTheProbablity( in_testMatrix[i*in_num_opcodes+j], vmean, vvar);
            }
        }

        // assign class depending on which probability is higher
        if( pmal > 0 && pben > 0)
        out_predict_vect[i] = pmal > pben ? 1 : 0;
        else
        {
            if( pmal > 0 ) out_predict_vect[i] = 1;
            else if ( pben > 0 ) out_predict_vect[i] = 0;
            else //( pmal < 0 && pben < 0)
                out_predict_vect[i] = pmal > pben ? 1 : 0;

        }
    }
}

/*!
*	\brief This function assigns class based on the selective features
*
*   Most of the details similar to function assignClassUsingMeanVarianceData, except for
*   addition of in_feature list
*
*   in_feature_list:
*   contains list of prominant features for each group
* |                         | each row points to the feature vector in s_group   |
* | :----------------------:| :------------------------------------------------: |
* | rows = number of groups |                                                    |
*
*   the feature vector is in_num_opcodes in len, vector has bit set only if the opcode
*   having id = index of this vector is amongst the prominant feature
*
*   \todo huge dependency !!! try and remove it viz feature list is pointing to feature vector
*   in s_group
*
*	\return predicted class matrix
*	
*/
void assignClassUsingMeanVarianceDataAndFeatureSelection(
        float *in_trainMatrix,  /*!< [in] trained probability matrix */
        float *in_testMatrix,   /*!< [in] testing matrix */
        int **in_feature_list,  /*!< [in] array of list of feature vector for each group, number of lists = number of groups */
        int in_num_groups,      /*!< [in] number of groups / number of rows in train matrix */
        int in_num_opcodes,     /*!< [in] number of opcodes / number of columns in test,train matrix */
        int in_numtestfiles,    /*!< [in] number of test files / number of rows in test matrix */
        int *in_group_index,    /*!< [in] vector containing group index of each file in test matrix( 1:1 mapping) */
        int *out_predict_vect   /*!< [out] predicted class  */
        )
{
    int i,j,k;
    float pmal=0.0, pben=0.0;
    int mean =0, var =1; /// \todo make this genric or avoid it somehow
    float vmean =0, vvar =1;
    int index=0;
    int grpindex=0;
    // for each file in in_testMatrix
    for ( i=0; i<in_numtestfiles; i++)
    {
        grpindex = in_group_index[i];
        index = grpindex*4;
        pmal=0.0; 
        pben=0.0;
        // for each opcode
        for ( j=0; j<in_num_opcodes; j++)
        {
            // if the normalized frequency in in_testMatrix is greater than 0 and current
            // opcode is amongst the prominent opcode for the group,to which the current
            // file belongs.
            if( in_testMatrix[i*in_num_opcodes+j] > 0 && in_feature_list[grpindex][j] ) 
            {
                // get variance and mean assuming it is a benign file
                vmean = in_trainMatrix[(index+0+mean)*in_num_opcodes+j];
                vvar  = in_trainMatrix[(index+0+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                // add to probability of file being benign
                pben += getTheProbablity( in_testMatrix[i*in_num_opcodes+j], vmean, vvar);

                // get variance and mean assuming it is a malware file
                vmean = in_trainMatrix[(index+2+mean)*in_num_opcodes+j];
                vvar  = in_trainMatrix[(index+2+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                // add to probability of file being malware
                pmal += getTheProbablity( in_testMatrix[i*in_num_opcodes+j], vmean, vvar);
            }
        }
        /// assign class whos probablity is greater
        if( pmal > 0 && pben > 0)
        out_predict_vect[i] = pmal > pben ? 1 : 0;
        else
        {
            if( pmal > 0 ) out_predict_vect[i] = 1;
            else if ( pben > 0 ) out_predict_vect[i] = 0;
            else //( pmal < 0 && pben < 0)
                out_predict_vect[i] = pmal > pben ? 1 : 0;

        }
    }
}
