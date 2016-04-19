#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

/*!
 *	\brief calculate normalized frequency matrix 
 *
 *   Normalized value(x) = \f$ \frac{ X - min }{ max - min }\f$
 *	\return normalized matrix
 *	
 */
int normalize( 
        int *in_mat,     /*!< [in] input matrix */
        float *out_mat,     /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in the input matrix */
        int in_columns    /*!< [in] number of columns in the output matrix */
        )
{
    int i,j;
    int max, min;
    for ( i=0; i<in_rows; i++)
    {
        max = INT_MIN;
        min = INT_MAX;
        for ( j=0;j<in_columns; j++)
        {
            if( min > in_mat[ (i*in_columns)+j ] )
                min = in_mat[ (i*in_columns)+j ] ;

            if( max < in_mat[ (i*in_columns)+j ] )
                max = in_mat[ (i*in_columns)+j ];
        }
        for (  j=0; j<in_columns; j++)
        {
            out_mat[(i*in_columns)+j] =(float)(in_mat[(i*in_columns)+j] - min)/(float)(max-min)   ;
        }
    }
    return 0;
}

/*!
 *	\brief Calculates the total frequency of each file for each class
 *
 *	function goes through all the files, calculates total frequency of each total 
 *	frequency for each file is stored in last column of the output matrix
 *	in_mat:
 *	    numfiles X totalnumopcodes matrix, containing frequency of each opcode
 *	out_mat:
 *	    numclass X totalnumopcodes+1 matrix, containing total frequency of each opcode and
 *	    each file in last column
 *	in_inrows:
 *	    = numfiles
 *	in_incolumns:
 *	    = totalnumopcodes
 *	in_outrows:
 *	    = number of classes 
 *
 *	\return modified outmat contains total frequency for each opcode and each file
 *	
 */
int createClassWiseData( 
        int *in_mat,     /*!< [in] input matrix */
        int *out_mat,     /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in input matrix */
        int in_columns,     /*!< [in] number of columns in input matrix */
        int in_outrows    /*!< [in] number of rows in output matrix */
        )
{
    int i,j;
    int sum=0;
    // for each file
    for (  i=0; i<in_rows; i++)
    {
        sum = 0;
        // for each opcode
        for ( j=0; j<in_columns-1; j++)
        {
            // add the frequency for each opcode
            out_mat[ (i*in_columns)+j ] += in_mat [ (i*in_columns)+j ];
            // save the frequency for total collection
            sum += in_mat[ (i*in_columns)+j ];
        }
        out_mat[j] = sum;
    }
    return 0;
}

/*!
 *	\brief gives probability of occurrence of each opcode in each class
 *
 *   takes as input a matrix containing normalized frequencies of each opcode in a file, 
 *   probability of opcode occurring in a class is found, by adding frequencies of each
 *   opcode in each file of each class and then dividing by sum of all frequencies in that
 *   class. We take log so the values are in a smaller range
 *
 *	in_inmat:
 *	    numfiles X totalnumopcodes matrix, has normalized frequency value for each opcode
 *
 *	in_cvect:
 *	    numfiles in length, contains,class ,the current row in in_inmat belongs to
 *
 *	in_inrows:
 *	    = numfiles
 *
 *	in_incolumns:
 *	    = totalnumopcodes
 *
 *	in_outrows:
 *	    = number of classes 
 *
 *	in_outcolumns:
 *	    = totalnumopcodes
 *
 *	out_outmat:
 *	    in_outrows X in_outcolumns, probability of each opcode in each class
 *
 *	out_cprob:
 *	    probability of each class
 *
 *	\return out_outmat is the modified matrix which contains the required probabilities
 *	
 */
int createProbablityMatrix( 
        int     *in_inmat,    /*!< [in] input matrix */
        float   *out_outmat,    /*!< [out] output matrix */
        int     *in_cvect,    /*!< [in] class vector */
        float   *out_cprob,    /*!< [out] probability of each class */
        int     in_inrows,    /*!< [in] number of rows in input matrix */
        int     in_incolumns,    /*!< [in] number of columns in input matrix */
        int     in_outrows,    /*!< [in] number of rows in output matrix */
        int     in_outcolumns    /*!< [in] number of columns in output matrix */
        )
{
#define  INDEX(i,j,cols) ((i*cols)+j)
    int i,j;
    int cls;
    float *class_wise_total=(float*) calloc(sizeof(float),in_outrows);
    assert(class_wise_total != NULL );
    // For each file
    for ( i=0; i<in_inrows; i++)
    {
        // get class for current file
        cls = in_cvect[ i ];
        // For each opcode
        for ( j=0; j<in_outcolumns; j++)
        {
            // add frequency of each opcode to appropriate a class opcode
            out_outmat[ INDEX(cls,j,in_outcolumns) ] +=   (float)in_inmat[ INDEX(i,j,in_incolumns) ];
            // add frequency to current class frequency
            class_wise_total [ cls ] +=   (float)in_inmat[ INDEX(i,j,in_incolumns) ];
        }
        // increase the count of file in current class
        out_cprob[ cls ] += 1;
    }
    // For each class
    for ( i=0; i<in_outrows; i++)
    {
        // For each opcode
        for ( j=0; j<in_outcolumns; j++)
        {
            // store the probability of current opcode
            float temp = (log10((out_outmat[ INDEX(i,j,in_outcolumns) ]+1) / (class_wise_total[ i ]+1) ));
            out_outmat[ INDEX(i,j,in_outcolumns) ] = (-1)*temp; // multiply by -1, because log[0-1] < 0
        }
        // save probability of current class
        out_cprob[ i ] = (-1)*log10(out_cprob[ i ]/ in_inrows); // multiply by -1 because log[0-1] < 0
    }
    free(class_wise_total);
    return 0;
#undef INDEX
}

/*!
 *	\brief Displays the float matrix
 *
 *   Should not be used on huge matrices
 *
 *	\return 
 *	
 */
void printFloatMatrix(
        float *in_mat,     /*!< [in] pointer to the matrix */
        int in_rows,     /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        )
{
    int i,j;
    for ( i=0; i<in_rows; i++)
    {
        for ( j=0; j<in_columns; j++)
        {
            printf(" %f",in_mat[ (i*in_columns)+j ]);
        }
        printf("\n");
    }
}

/*!
 *	\brief Displays the int matrix
 *
 *   Should not be used on huge matrices
 *
 *	\return 
 *	
 */
void printIntMatrix( 
        int *in_mat,     /*!< [in] pointer to the matrix */
        int in_rows,     /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        )
{
    int i,j;
    for ( i=0; i<in_rows; i++)
    {
        for ( j=0; j<in_columns; j++)
        {
            printf(" %d",in_mat[ (i*in_columns)+j ]);
        }
        printf("\n");
    }
}

/*!
 *	\brief Assigns class to all the test files
 *
 *   takes a matrix of normalized frequency values for each test file, and probability
 *   matrix for each opcode of each class, calculates probability of each opcode for each
 *   class, assigns a class to a file with maximum probability
 *
 *   in_mat:
 *       numfiles X total_number_of_opcodes matrix, containing normalized frequencies
 *
 *   in_cprob:
 *       numclass wide vector, containing probability of each class
 *
 *   out_pridict:
 *       numfiles wide vector, containing assigned class for each file
 *
 *   in_rows:
 *       numfiles
 *
 *   in_classes:
 *       numclasses
 *
 *   in_columns:
 *       total number of opcodes
 *
 *	\return predicted class vector
 *	
 */
void assignClass( 
        int *in_mat,     /*!< [in] input matrix */
        float *in_prob,     /*!< [in] probability matrix */
        float *in_cprob,     /*!< [in] class probability matrix */
        int *out_pridict,     /*!< [out] predicted class */
        int in_rows,     /*!< [in] number of input rows */
        int in_classes,     /*!< [in] number of classes */
        int in_columns    /*!< [in] number of columns */
        )
{
#define  INDEX(i,j,cols) ((i*cols)+j)
    int i,j,k;
    double *classprob =  (double*) calloc( sizeof(double), in_classes);
    // for each file
    for ( i=0; i<in_rows; i++)
    {
        // for each class
        for ( k=0; k<in_classes; k++)
            classprob[ k ] = in_cprob[k];
        // for each opcode
        for ( j=0; j<in_columns; j++)
        {

            // for each class
            for ( k=0; k<in_classes; k++)
            {
                // for opcodes having normalized frequency greater than 1
                if ( in_mat [ INDEX(i,j,in_columns) ] > 0 ) 
                {
                    // add the probability to current class ( add because we already have
                    // log10 of those values)
                    // TODO remove multiplication and check
                    classprob[ k ] += in_mat [ INDEX(i,j,in_columns) ]*in_prob [ INDEX(k,j,in_columns) ];
                }
            }
        }
        int maxClass=0;
        // for each class 
        for ( k=0; k<in_classes; k++)
        {
            // save the max class
            if( classprob[ maxClass ] > classprob[k] )
                maxClass = k;
        }
        // assign the max class
        out_pridict[i] = maxClass;
    }
    free(classprob);
#undef INDEX
}

/*!
 *	\brief creates a int matrix of row X column dimensions
 *
 *   This is actually a vector of size rows X columns X sizeof(int)
 *   use the traditional way for accessing the vector elements
 *
 *	\return pointer to the allocated matrix
 *	
 */
int* createIntMatrix( 
        int in_rows,      /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        )
{
    int *temp = (int*) calloc ( sizeof(int) , in_rows*in_columns );
    return temp;
}

/*!
 *	\brief creates a float matrix of row X column dimensions
 *
 *   This is actually a vector of size rows X columns X sizeof(float)
 *   use the traditional way for accessing the vector elements
 *
 *	\return pointer to the allocated matrix
 *	
 */
float* createFloatMatrix(
        int in_rows,      /*!< [in] number of rows in the matrix */
        int in_columns    /*!< [in] number of columns in the matrix */
        )
{
    float *temp = (float*) calloc( sizeof(float), in_columns*in_rows);
    return temp;
}

/*!
 *	\brief creates a integer vector of length size
 *
 *   More Details ...
 *	\return pointer to the newly created vector
 *	
 */
int *createVector(
        int in_size      /*!< [in] length of the vector */
        )    
{
    int *temp = (int*) calloc( sizeof(int), in_size);
    return temp;
}


/*!
 *	\brief Gives accuracy of current configuration
 *
 *   More Details ...
 *
 *	\return ratio of correct predictions to number of predictions
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
 *
 *	out_mat   =   in_columns   X   in_rows
 *
 *	\return transpose of a matrix in out_mat
 *	
 */
void rotateMatrix( 
        int *in_mat,     /*!< [in] input matrix */
        int *out_mat,    /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in input matrix */
        int in_columns   /*!< [in] number of columns in output matrix */
        )
{
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
void rotateMatrixF( 
        float *in_mat,     /*!< [in] input matrix */
        float *out_mat,    /*!< [out] output matrix */
        int in_rows,     /*!< [in] number of rows in input matrix */
        int in_columns   /*!< [in] number of columns in output matrix */
        )
{
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
 *
 *   probability = \f$ \frac{1}{\sqrt{2\Pi\sigma^{2}}}\exp^{\frac{(x-\mu)^{2}}{2\sigma^{2}}} \f$
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
    int i,j;
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
        int *in_feature_list,  /*!< [in] array of list of feature vector for each group, number of lists = number of groups */
        int in_num_groups,      /*!< [in] number of groups / number of rows in train matrix */
        int in_num_opcodes,     /*!< [in] number of opcodes / number of columns in test,train matrix */
        int in_num_features,     /*!< [in] number of prominent features */
        int in_numtestfiles,    /*!< [in] number of test files / number of rows in test matrix */
        int *in_group_index,    /*!< [in] vector containing group index of each file in test matrix( 1:1 mapping) */
        int *out_predict_vect   /*!< [out] predicted class  */
        )
{
    int i,j;
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
        for ( j=0; j<in_num_features; j++)
        {
            int opcindex = in_feature_list[grpindex*in_num_features+j];
            // if the normalized frequency in in_testMatrix is greater than 0 and current
            // opcode is amongst the prominent opcode for the group,to which the current
            // file belongs.
            if( in_testMatrix[i*in_num_opcodes+opcindex] > 0 ) 
            {
                // get variance and mean assuming it is a benign file
                vmean = in_trainMatrix[(index+0+mean)*in_num_opcodes+opcindex];
                vvar  = in_trainMatrix[(index+0+var )*in_num_opcodes+opcindex];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                // add to probability of file being benign
                pben += getTheProbablity( in_testMatrix[i*in_num_opcodes+opcindex], vmean, vvar);

                // get variance and mean assuming it is a malware file
                vmean = in_trainMatrix[(index+2+mean)*in_num_opcodes+opcindex];
                vvar  = in_trainMatrix[(index+2+var )*in_num_opcodes+opcindex];
                assert( vmean >= 0.0f && vvar >= 0.0f );
                // add to probability of file being malware
                pmal += getTheProbablity( in_testMatrix[i*in_num_opcodes+opcindex], vmean, vvar);
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
