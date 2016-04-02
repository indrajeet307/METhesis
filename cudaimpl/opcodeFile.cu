#include "opcodeFile.h"
#include "trie.h"
#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// TODO update all enums with
// http://stackoverflow.com/questions/1102542/how-to-define-an-enumerated-type-enum-in-c
enum classId{ BENIGN=0, MALWARE=1, UNKNOWN };
int getClassId( 
        char * cls
        )
{
    if ( strcmp( cls, "MALWARE") == 0 ) return MALWARE;
    if ( strcmp( cls, "BENIGN") == 0 ) return BENIGN;
    return -1;
}

void initFiles( 
        s_files ** p_files
        )
{
    *p_files = (s_files*) malloc ( sizeof(s_files) );
    (*p_files)->list = NULL;
    (*p_files)->garb = NULL;
}

void initFileList( 
        s_filelist ** p_list
        )
{
    (*p_list) = (s_filelist*) malloc ( sizeof( s_filelist) ) ;
    (*p_list)->count = 0;
    (*p_list)->list = NULL;
}

void initGroups( 
        s_group ** out_groups, 
        int in_count
        )
{
    (*out_groups) = (s_group*) calloc(sizeof(s_group), in_count);
    int i;
    for ( i=0; i<in_count; i++)
    {
        (*out_groups)[i].list[0] = NULL;
        (*out_groups)[i].list[1] = NULL;
        (*out_groups)[i].features = NULL;
    }     
}

s_fileProp* createFileNode( 
        char *filename, 
        int filesize, 
        char *data_type, 
        char *cls, 
        int numopcode, 
        int totalopcodes
        )
{
    int err =0;
    s_fileProp* temp = (s_fileProp*) malloc( sizeof(s_fileProp) );
    err = errno;
    if( temp == NULL || errno )
    {
        printf(" Malloc Failed %s\n", strerror(err));
        exit(1);
        return NULL;
    }
    temp->name = (char*) malloc( sizeof(char) * (strlen(filename)+1) );
    strcpy( temp->name ,filename);
    temp->numopcode = numopcode;
    temp->size = filesize;
    temp->classId   = getClassId(cls);
    temp->opcodes = (s_opcodenode*) calloc ( sizeof(s_opcodenode) , numopcode);
    temp->normalized_opcodes = (float*) calloc ( sizeof(float) , numopcode);
    return temp;
}

void createFeatureListForEachGroup( 
        int ***out_feature_list, 
        int in_num_groups
        )
{
    (*out_feature_list) = (int**) calloc( sizeof(int*), in_num_groups);
}

void addToFiles(
        s_files ** p_files, 
        s_fileProp ** p_fileprop
        )
{
    (*p_files)->numFiles ++;
    if( (*p_files)->list== NULL )
    {
        (*p_files)->list = (*p_fileprop);
        return;
    }
    (*p_fileprop)->next = (*p_files)->list;
    (*p_files)->list = (*p_fileprop);
    return;
}

void addToList( 
        s_filelist ** p_list, 
        s_fileProp * p_prop
        )
{
    s_filelistnode *temp = NULL;
    temp = (s_filelistnode*) malloc (sizeof(s_filelistnode) );
    temp->prop = p_prop;
    temp->next = NULL;
    if( (*p_list)->list == NULL)
    {
        (*p_list)->list =temp;
        (*p_list)->count+=1;
    }
    temp->next = (*p_list)->list;
    (*p_list)->list = temp;
    (*p_list)->count+=1;
}

void addToGroup( 
        s_group ** out_groups, 
        int in_gropup_index, 
        s_fileProp *in_fileprop
        )
{
    s_filelistnode *temp,*new_node;
    s_group *currgrp;
    int currClassId = in_fileprop->classId;

    currgrp =&( (*out_groups)[in_gropup_index] );

    temp = (*out_groups)[in_gropup_index].list[  currClassId ];

    new_node = (s_filelistnode*) malloc (sizeof(s_filelistnode) );
    new_node->prop = in_fileprop;
    new_node->next = NULL;

    if( temp == NULL )
    {
        currgrp->list[ currClassId ] = new_node;
        currgrp->list[ currClassId ]->next  = NULL;

        currgrp->count = 1;
        currgrp->max = in_fileprop->numopcode;
        currgrp->min = in_fileprop->numopcode;

        return;
    }
    new_node->next = currgrp->list[ currClassId ];
    currgrp->list[ currClassId ] = new_node;

    currgrp->count += 1;
    currgrp->max = (in_fileprop->numopcode > currgrp->max) ? in_fileprop->numopcode : currgrp->max ;
    currgrp->min = (in_fileprop->numopcode < currgrp->min) ? in_fileprop->numopcode : currgrp->min ;
}

int readOpcodeFile( 
        char* fname, 
        s_trie** opcodelist
        )
{
    FILE *fp;
    int err;
    int numopcodes=0;
    err = errno = 0;
    fp = fopen( fname, "r");
    err = errno;
    if( fp == NULL )
    {
        printf("[ Error ] %s.\n", strerror(err));
        return -1;
    }
    char  *buff=NULL;
    //char  *opcode=NULL;
    size_t count=0;
    size_t readlen=0;
    while( !feof( fp ) )
    {
        readlen = getline( &buff, &count, fp);
        if( readlen == (size_t)-1 ) break ;
        //opcode = strtok( buff, "\n" ); // TODO construct a opcode word list
        numopcodes++;
    }
    fclose( fp );
    return numopcodes;
}

s_fileProp * convertLineToFileProp(
    char *buff,
    int *out_groupcount,
    int in_totalnumopcodes,
    int *out_numFiles
)
{
        char *filename = strtok( buff, "," );
        char *filesize = strtok( NULL, "," );
        char *data_set = strtok( NULL, "," );
        char *cls    = strtok( NULL, "," );
        char *numopc   = strtok( NULL, "," );
        int numopcode = atoi( numopc );
        int size = atoi( filesize );
        int index = size/5;
        int max = INT_MIN;
        int min = INT_MAX;

        if( numopcode > 10 && size < 500 )
        {
            out_groupcount[ index*2 + getClassId(cls) ] += 1; // TODO replace 2 with NUM_CLASSES
            s_fileProp *tempfile = createFileNode( filename, size, data_set, cls,
            numopcode, in_totalnumopcodes);
            char *freq;
            int numopcodes=0;
            int id=0;
            while( (freq = strtok(NULL,",\n")) != NULL )
            {
                int currfreq = atoi(freq);
                if( currfreq > 0)
                {
                    if (  currfreq> max ) max = currfreq;
                    if ( currfreq< min ) min = currfreq;
                    tempfile->opcodes[ numopcodes ].id = id;
                    tempfile->opcodes[ numopcodes++ ].freq = currfreq ;
                    assert( atoi(freq) > 0 );
                }
                id++;
            }
            // THIS IS REALLY WEIRED NEED TO DO SOMETHING ABOUT THIS
            if( numopcodes < numopcode  ) // Just in case the CSV  as an opcode 
            {
                tempfile->numopcode = numopcodes;
            }
            tempfile->min_opcodefreq = min;
            tempfile->max_opcodefreq = max;
            tempfile->next = NULL;
            (*out_numFiles)++;
            return tempfile;
        }
        return NULL;
}
int readCSVFile( 
        char* in_filename, 
        int in_numopcode, 
        s_files ** out_fillist, 
        int *out_groupcount
        )
{
    FILE *fp;
    int err;
    int numfiles=0;
    err = errno = 0;
    fp = fopen( in_filename, "r");
    err = errno;
    if( fp == NULL )
    {
        printf("[ Error ] %s.\n", strerror(err));
        return -1;
    }
    size_t count=0;
    char  *buff=NULL;

    while( getline(&buff, &count, fp) > 0 )
    {
        s_fileProp *tempfile = convertLineToFileProp( buff, out_groupcount, in_numopcode, &numfiles);
        if( tempfile != NULL)
            addToFiles( out_fillist, &tempfile);
    }
    free( buff );
    fclose( fp );
    return numfiles;
}

void cleanUp( 
        s_garbage * p_garbage
        )
{
}

void deleteFiles( 
        s_files ** p_files
        )
{
    cleanUp( (*p_files)->garb );
    free( *p_files );
    (*p_files) = NULL;
}


void fillTheMatrix( 
        s_files ** p_files, 
        int * p_mat, 
        int * p_cvect, 
        int rows, 
        int columns
        )
{
    s_fileProp * list = (*p_files)->list;
    int i=0,j=0;
    while( list!= NULL)
    {
        for( j=0; j<list->numopcode; j++)
        {
            p_mat[ (i*columns)+ list->opcodes[j].id ] = list->opcodes[j].freq;
        }
        p_cvect[i] = list->classId;
        list= list->next;
        i++;
    }
}

void fillTheMatrixFromList( 
        s_filelist ** p_files, 
        int * p_mat, 
        int * p_cvect, 
        int rows, 
        int columns
        )
{
    s_filelistnode * list = (*p_files)->list;
    int i=0,j=0;
    while( list!= NULL && i<rows)
    {
        for( j=0; j<list->prop->numopcode; j++)
        {
            p_mat[ (i*columns)+ list->prop->opcodes[j].id ] = list->prop->opcodes[j].freq;
        }
        p_cvect[i] = list->prop->classId;
        list= list->next;
        i++;
    }
}


int adjustCountInEachGroup(
        int* out_groupcount, 
        int num_groups
        )
{
    int i;
    int count=0;
    for(  i=0; i<num_groups*2; i+=2)
    {
        if( out_groupcount[ i+0 ] > out_groupcount[ i+1 ])
        {
            out_groupcount[ i+0 ] = out_groupcount[ i+1 ];
            count += out_groupcount[i+0];
        }
        else
        {
            out_groupcount[ i+1 ] = out_groupcount[ i+0 ];
            count += out_groupcount[i+1];
        }
    }
    return count*2;
}

/*
 *	@DESC   : Does grouping for only 2 classes
 *          : TODO make it genric for n classes
 *	@PRAM   : What are the parameters?
 *	@RETURN : What does it return?
 *	
 */
void doGrouping( 
        s_files* in_files, 
        int* in_groupcount, 
        s_group ** out_groups
        )
{
    s_fileProp *temp = in_files->list;
    int groupIndex=0;
    int classId=-1;
    int index=0;
    while( temp != NULL )
    {
        groupIndex = temp->size/5;
        classId = temp->classId;
        index = groupIndex*2+ classId;
        if( in_groupcount[ index ] > 0 )
        {

            addToGroup( out_groups, groupIndex, temp );
            in_groupcount[ index ]--;
        }
        temp = temp->next;
    }
}



void normalizeOpcodeFrequency( 
        s_files ** out_filelist
        ) 
{
    s_fileProp * temp;
    temp = (*out_filelist)->list;
    int numfiles = (*out_filelist)->numFiles;
    int i=0, j=0;
    int min=0, max=0;
    for ( i=0; i<numfiles; i++)
    {
        min = temp->min_opcodefreq;
        max = temp->max_opcodefreq;
        s_opcodenode *opc = temp->opcodes; 
        float *nopc = temp->normalized_opcodes;
        for ( j=0; j<temp->numopcode; j++)
        {
            nopc[j] = (float)(opc[j].freq - min)/(float)(max - min);
            assert( nopc[j] >= 0.0f ); // TODO can decide a threshold, right now checks only for +ve values
        }
        temp=temp->next;
    }
}

int fillGroupWiseData(
        s_group   *in_groups,
        float     *out_trainArray,
        int       in_num_groups,
        int       in_num_opcodes,
        float     *out_testArray,
        int       *out_class_vect,
        int       *out_group_vect
        )
{
    int mean =0, var =1;
    int i,j,k,opcindex;
    float x;
    int fcount=0;
    int numtestfiles=0;

    for ( i=0; i<in_num_groups; i++)
    {
        for ( j=0; j<2; j++)
        {
            s_filelistnode *file = in_groups[i].list[j];
            int numfiles = in_groups[i].count*2;
            if( numfiles > 0)
            {
                while( file != NULL )
                {
                    fcount++;
                    if ( fcount%3 != 0)
                    {
                        for ( k=0; k< file->prop->numopcode; k++)
                        {
                            //printf(" %f", file->prop->normalized_opcodes[k]);
                            x = file->prop->normalized_opcodes[k];
                            opcindex = file->prop->opcodes[k].id;
                            float m = x/numfiles;
                            float v = (m-x)*(m-x)/numfiles;
                            int row = i*4;
                            int cls = file->prop->classId*2;
                            assert( m >= 0.0f && v >= 0.0f);
                            out_trainArray[((row+cls+mean)*in_num_opcodes)+opcindex] += m;
                            out_trainArray[((row+cls+var )*in_num_opcodes)+opcindex] += v;
                        }
                    }
                    else // fcount%3 == 0
                    {
                        fcount = 0;
                        for ( k=0; k< file->prop->numopcode; k++)
                        {
                            opcindex = file->prop->opcodes[k].id;
                            x = file->prop->normalized_opcodes[k];
                            out_testArray[ (numtestfiles*in_num_opcodes) + opcindex] += x;
                            out_class_vect[numtestfiles] = file->prop->classId;
                            out_group_vect[numtestfiles] = (file->prop->size)/5;
                        }
                        numtestfiles++;
                    }
                    file = file->next;
                }
            }
        }
    }
    return numtestfiles;
}


void resetVector( 
        float * out_vector, 
        int in_num_columns
        )
{
    int i;
    for ( i=0; i<in_num_columns; i++)
    {
        out_vector[i] = 0.0;
    }
}

void selectFeaturesForEachGroup(
        s_group ** out_group,
        int in_num_groups,
        int in_num_opcodes,
        int in_num_features 
        )
{
    int i,j,k,l;
    float **features=(float**) calloc( sizeof( float* ) , 2 );
    features[0]=(float*) calloc( sizeof( float ) , in_num_opcodes );
    features[1]=(float*) calloc( sizeof( float ) , in_num_opcodes );

    s_group *grp_ptr;
    for ( i=0; i<in_num_groups; i++)
    {
        grp_ptr = &((*out_group)[i]);
        if( grp_ptr->count > 0 )
        {
            resetVector( features[0], in_num_opcodes);
            resetVector( features[1], in_num_opcodes);

            for ( j=0; j< grp_ptr->count; j++)
            {
                for ( k=0; k<2; k++) // TODO NUM_CLASSES
                {
                    s_filelistnode *file = grp_ptr->list[k];
                    while( file != NULL )
                    {
                        s_fileProp *fileprop_ptr = file->prop;
                        for ( l=0; l<file->prop->numopcode; l++)
                        {
                            int opcindex = fileprop_ptr->opcodes[l].id;
                            int freq = fileprop_ptr->opcodes[l].freq;
                            features[k][opcindex] += (freq/grp_ptr->count) ; // TODO divided by number of files in each class
                        }
                        file=file->next;
                    }
                }

            }
            setFeatureVector( features, grp_ptr, 2, in_num_opcodes, in_num_features); // TODO NUM_CLASSES
        }
    }
    free( features[0] );
    free( features[1] );
    free( features );
}

int cmpopcodenode( 
        const void * opc1, 
        const void *opc2
        )
{
    s_diffnode a = *(s_diffnode const*) opc1;
    s_diffnode b = *(s_diffnode const*) opc2;

    if( a.diff < b.diff ) return 1; /// sorts in ascending order
    else return 0;
}

void setFeatureVector( 
        float **in_features, 
        s_group * out_group , 
        int in_num_list, 
        int in_num_columns, 
        int in_num_features 
        )
{
    s_diffnode * diffvector = (s_diffnode*) calloc( sizeof(s_diffnode), in_num_columns);
    int j=0;
    for ( j=0; j<in_num_columns; j++)
    {
        diffvector[j].id = j;
        diffvector[j].diff = abs( in_features[0][j] - in_features[1][j] ); // TODO NUM_CLASSES
    }

    /// sort in ascending order
    qsort( diffvector, in_num_columns, sizeof(s_opcodenode), cmpopcodenode);

    out_group->features = (int*) calloc( sizeof(int), in_num_columns);

    for ( j=0; j<in_num_features; j++)
    {
        int opcindex = diffvector[j].id;
        out_group->features[ opcindex ] = 1;
        //printf(" %d", opcindex);
    }
    //printf(" \n");
    free( diffvector );
}

void assignFeatureListForEachGroup( 
        int ***out_feature_list, 
        s_group *in_groups, 
        int in_num_groups
        )
{
    int i;
    for ( i=0; i<in_num_groups; i++)
    {
        if( in_groups[i].count > 0 )
            (*out_feature_list)[i] = in_groups[i].features;
            else
                (*out_feature_list)[i] = NULL;
    }
}
void spillFeatureMatrix(
    int **in_featureptr,
    int *out_featurematrix,
    int in_numgroups,
    int in_numopcode
    )
{
    int i,j;
    for( i=0; i<in_numgroups; i++)
    {
        for( j=0; j<in_numopcode; j++)
        {
            if( in_featureptr[i] )
                out_featurematrix[ i*in_numopcode+j ] = in_featureptr[i][j];
            else
                out_featurematrix[ i*in_numopcode+j ] = 0;
        }
    }
    }

void showFiles( 
        s_files * p_files 
        )
{
    s_fileProp *temp = p_files->list;
    s_opcodenode *opcptr = NULL;
    int count = p_files->numFiles;
    while ( temp != NULL)
    {
        printf("%d %s %d\n", count--, temp->name, temp->numopcode);
        opcptr = temp->opcodes;
        int i=0;
        while( i<temp->numopcode)
        {
            printf( " %d=%d\t", opcptr[i].id, opcptr[i].freq);
            i++;
        }
        temp = temp->next;
    }
}

void showGroupWiseStats( 
        s_group * in_groups , 
        int in_num_groups
        )
{
    int i,j,c;
    for( i=0; i< in_num_groups; i++)
    {
        printf(" Group %d, has %d files, max opcode count = %d, min opcode count = %d.\n", \
                i+1, in_groups[i].count, in_groups[i].max, in_groups[i].min);
        s_filelistnode *temp;
        for( c=0 ; c<2; c++) // TODO make this genric NUM_CLASSES
        {
            temp = in_groups[i].list[c];
            for ( j=0; j<in_groups[i].count; j++)
            {
                printf(" %d ",temp->prop->numopcode); 
                temp = temp->next;
            }
            printf("\n");
        }
    }
}

void showGroupWiseProcessedValues( 
        float *out_data_matrix, 
        int in_num_groups, 
        int in_num_opcodes
        )
{
    int mean =0, var =1;
    int i,j;
    FILE *fp;
    char *fname = "/tmp/file";
    fp = fopen(fname, "w");

    printf(" Writing data to file %s\n", fname);
    for ( i=0; i<in_num_groups*4; i+=4)
    {
        for ( j=0; j<in_num_opcodes; j++)
        {
            fprintf(fp," %f", out_data_matrix[((i+0+mean)*in_num_opcodes)+j]);
        }
        fprintf(fp,"\n");
        for ( j=0; j<in_num_opcodes; j++)
        {
            fprintf(fp," %f", out_data_matrix[((i+0+var)*in_num_opcodes)+j]);
        } 
        fprintf(fp,"\n");
        for ( j=0; j<in_num_opcodes; j++)
        {
            fprintf(fp," %f", out_data_matrix[((i+2+mean)*in_num_opcodes)+j]);
        }
        fprintf(fp,"\n");
        for ( j=0; j<in_num_opcodes; j++)
        {
            fprintf(fp," %f", out_data_matrix[((i+2+var)*in_num_opcodes)+j]);
        } 
        fprintf(fp,"\n");
    }

    fclose(fp);
}

void spillMatrixToFile( float *in_mat, int in_numrows, int in_numcolumns, char *filename)
{
    FILE *fp ;
    fp = fopen(filename, "w");

    int i,j;
    for ( i=0; i<in_numrows; i++)
    {
        for ( j=0; j<in_numcolumns; j++)
        {
            fprintf(fp,"%0.5f ",in_mat[ i*in_numcolumns + j ] );
            }
            fprintf(fp,"\n");
    }
    fclose( fp );
}
