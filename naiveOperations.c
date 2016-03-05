#include <stdio.h>
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
    int i,j;
    int sum;
    int class;
    for ( i=0; i<inrows; i++)
    {
        sum =0;
#define  INDEX(i,j,cols) ((i*cols)+j)
        for ( j=0; j<incolumns-1; j++)
            sum += inmat[ INDEX(i,j,incolumns) ];
        class = inmat[ INDEX(i,j,incolumns) ];
        for ( j=0; j<outcolumns; j++)
            outmat[ INDEX(class,j,outcolumns) ] += (float)inmat[ INDEX(i,j,incolumns) ]/(float)sum;
#undef index
    }
}

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
