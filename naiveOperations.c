#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
/*
 *	@DESC   : Normalizes the given matrix along the row
 *	@PRAM   : matrix, num of rows, num of columns
 *	@RETURN : Modifies the supplied matrix
 *   
 *                            old(x) - min
 *   Normalized value(x) = -----------------------
 *                            max - min
 */
int normalize( int *mat, int rows, int columns)
{
    int i,j;
    int max, min;
    for ( i=0; i<rows; i++)
    {
        max = INT_MIN;
        min = INT_MAX;
        for ( j=0;j<columns; j++)
        {
            if( min > mat[(i*columns)+j] )
                min = mat[(i*columns)+j] ;

            if( max < mat[(i*columns)+j] )
                max = mat[(i*columns)+j];
        }
        for (  j=0; j<columns; j++)
        {
            mat[(i*columns)+j] =(mat[(i*columns)+j] - min)/(max-min)   ;
        }
    }
}
/*
 *	@DESC   : Takes a matrix with class as the last column, returns a matrix with
 *           : classwise info the returned matrix is num of classes x num of columns
 *	@PRAM   : old matrix, new matrix, num of rows (old matrix), num of columns( old/new
 *           : matrix, num of rows(new matrix) == num of classes
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
 *           :
 *	@RETURN : the probably matrix is modified
 *	
 */
int createProbablityMatrix( int *inmat, float *outmat, int inrows, int incolumns, int outrows, int outcolumns)
{
#define  INDEX(i,j,cols) ((i*cols)+j)
    int i,j;
    int sum;
    int class;
    for ( i=0; i<inrows; i++)
    {
        sum =0;
        for ( j=0; j<incolumns-1; j++)
            sum += inmat[ INDEX(i,j,incolumns) ];
        class = inmat[ INDEX(i,j,incolumns) ]; // the last column in the matrix
        for ( j=0; j<outcolumns-1; j++)
            outmat[ INDEX(class,j,outcolumns) ] +=  ( (float)inmat[ INDEX(i,j,incolumns) ]/(float)sum );
        outmat[ INDEX(class,j,outcolumns) ] += 1;
    }
    // Update the probablity for each class
    for ( i=0; i<outrows; i++)
    {
        outmat[ INDEX(i,outcolumns-1,outcolumns) ] /= inrows;
    }
#undef index
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
 *           : matrix, num of rows in probablity matrix, num of columns in both the matrices
 *	@RETURN :
 *	
 */
void assignClass( int *mat, float *prob, int *pridict, int rows, int classes, int columns)
{
#define  INDEX(i,j,cols) ((i*cols)+j)
    int i,j,k;
    double *classprob =  (double*) malloc( sizeof(double)* classes);
        for ( k=0; k<classes; k++)
            classprob[k] = 1;
    for ( i=0; i<rows; i++)
    {
        for ( j=0; j<columns; j++)
        {
            for ( k=0; k<classes; k++)
            {
                if ( prob [ INDEX(k,j,columns) ] > 0 ) 
                    classprob[ k ] += prob [ INDEX(k,j,columns) ];
                //printf(" %lf", prob [ INDEX(k,j,columns) ] );
            }
        }
        int maxClass=0;
        for ( k=0; k<classes; k++)
        {
            printf(" %lf", classprob[k] );
            if( classprob[ maxClass ] < classprob[k] )
                maxClass = k;
        }
        pridict[i] = maxClass;
    }
    free(classprob);
#undef INDEX
}
