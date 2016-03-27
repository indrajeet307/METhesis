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

float getAccuracy(int *pmat, int *cvect, int total)
    {
        int i;
        float ans=0.0;
        for ( i=0; i<total; i++)
        {
            if( pmat[i] == cvect[i])
                ans ++;
        }
        return ans/total;
    }

void rotateMatrix( int *inmat, int *outmat, int inrows, int incolumns)
{
    int outrows=incolumns;
    int outcolumns=inrows;
    int i,j;

    for ( i=0; i<inrows; i++)
    {
        for ( j=0;j<incolumns;j++)
        {
            outmat[ j*outcolumns + i ] = inmat[ i*incolumns+j ];
        }
    }
}

void createProbablityMatrixUsingMeanVariance( float *in_data_matrix, int in_num_groups, 
                                              int in_num_opcodes, int in_num_classes, 
                                              int *in_clss_vect, int *out_prob_vector )
{
    int mean=0,var=1;
    int i,j;
    for ( i=0; i<in_num_groups*2; i+=2)
    {
       for ( ; ; )
       {
           
       } 
    }
}


float getTheProbablity( float vval, float vmean, float vvar)
{

    float result=0.0;
    float val1 =  1/sqrt( 2.0* M_PI* vvar);
    float val2 = (vval-vmean)*(vval-vmean)/(2.0*vvar);
    val2 = 1 / exp( val2);
    result = log10( val1*val2);
    if( isnan(result) || isinf(result) ) return 0.0;
    return result;
}

void assignClassUsingMeanVarianceData(
                                       float *in_trainArray,
                                       float *in_testArray,
                                       int in_num_groups,
                                       int in_num_opcodes,
                                       int in_numtestfiles,
                                       int *in_group_index,
                                       int *out_predict_vect )
{
    int i,j,k;
    float pmal=0.0, pben=0.0;
    int mean =0, var =1;
    float vmean =0, vvar =1;
    int index=0;
    for ( i=0; i<in_numtestfiles; i++)
    {
        index = in_group_index[i]*4;
        pmal=0.0; 
        pben=0.0;
        for ( j=0; j<in_num_opcodes; j++)
        {
            if( in_testArray[j] > 0 ) 
            {
                vmean = in_trainArray[(index+0+mean)*in_num_opcodes+j];
                vvar  = in_trainArray[(index+0+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                pmal += getTheProbablity( in_testArray[j], vmean, vvar);

                vmean = in_trainArray[(index+2+mean)*in_num_opcodes+j];
                vvar  = in_trainArray[(index+2+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                pben += getTheProbablity( in_testArray[j], vmean, vvar);
            }
        }
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
void assignClassUsingMeanVarianceDataAndFeatureSelection(
                                       float *in_trainArray,
                                       float *in_testArray,
                                       int **in_feature_list,
                                       int in_num_groups,
                                       int in_num_opcodes,
                                       int in_numtestfiles,
                                       int *in_group_index,
                                       int *out_predict_vect )
{
    int i,j,k;
    float pmal=0.0, pben=0.0;
    int mean =0, var =1;
    float vmean =0, vvar =1;
    int index=0;
    int grpindex=0;
    for ( i=0; i<in_numtestfiles; i++)
    {
        grpindex = in_group_index[i];
        index = grpindex*4;
        pmal=0.0; 
        pben=0.0;
        for ( j=0; j<in_num_opcodes; j++)
        {
            if( in_testArray[j] > 0 && in_feature_list[grpindex][j] ) 
            {
                vmean = in_trainArray[(index+0+mean)*in_num_opcodes+j];
                vvar  = in_trainArray[(index+0+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                pmal += getTheProbablity( in_testArray[j], vmean, vvar);

                vmean = in_trainArray[(index+2+mean)*in_num_opcodes+j];
                vvar  = in_trainArray[(index+2+var )*in_num_opcodes+j];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                pben += getTheProbablity( in_testArray[j], vmean, vvar);
            }
        }
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
