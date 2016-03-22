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
int getClassId( char * class)
{
    if ( strcmp( class, "MALWARE") == 0 ) return MALWARE;
    if ( strcmp( class, "BENIGN") == 0 ) return BENIGN;
    return -1;
}

s_fileProp* createFileNode( char *filename, int filesize, char *data_type, char *class, int numopcode, int totalopcodes)
{
    s_fileProp* temp = (s_fileProp*) malloc( sizeof(s_fileProp) );
    if( temp == NULL )
    {
        printf(" Malloc Failed \n");
        return NULL;
    }
    temp->name = (char*) malloc( sizeof(char) * (strlen(filename)+1) );
    strcpy( temp->name ,filename);
    temp->numopcode = numopcode;
    temp->size = filesize;
    temp->classId   = getClassId(class);
    temp->opcodes = (int*) calloc ( sizeof(int) , totalopcodes);
    temp->normalized_opcodes = (float*) calloc ( sizeof(float) , totalopcodes);
    return temp;
}

int readOpcodeFile( char* fname, s_trie** opcodelist)
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
    char  *opcode=NULL;
    int    numWords=0;
    size_t count=0;
    size_t readlen=0;
    while( !feof( fp ) )
    {
        readlen = getline( &buff, &count, fp);
        if( readlen == -1 ) break ;
        opcode = strtok( buff, "\n" );
        numopcodes++;
    }
    fclose( fp );
    return numopcodes;
}

void addToFiles(s_files ** p_files, s_fileProp ** p_fileprop)
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

int readCSVFile( char* in_filename, int in_numopcode, s_files ** out_fillist, int *out_groupcount)
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
    char  *filename=NULL;
    char  *freq     ;//= (char*) malloc (sizeof(char)*16);
    char  *class    ;//= (char*) malloc (sizeof(char)*16);
    char  *data_set ;//= (char*) malloc (sizeof(char)*16);
    char  *filesize ;//= (char*) malloc (sizeof(char)*8);
    char  *numopc   ;//= (char*) malloc (sizeof(char)*8);
    int    numopcodes=0;
    short int fcount=0;

    while( !feof( fp ) )
    {
        char  *buff=NULL;
        size_t count=0;
        size_t readlen=0;
        numopcodes = 0;
        readlen = getline( &buff, &count, fp);
        if( readlen == -1 ) break ;
        filename = strtok( buff, "," );
        filesize = strtok( NULL, "," );
        data_set = strtok( NULL, "," );
        class    = strtok( NULL, "," );
        numopc   = strtok( NULL, "," );
        int numopcode = atoi( numopc );
        int size = atoi( filesize );
        int index = size/5;
        int max = INT_MIN;
        int min = INT_MAX;


        if( numopcode > 10 && size < 500 )
        {
            out_groupcount[ index*2 + getClassId(class) ] += 1; // TODO replace 2 with NUM_CLASSES

            s_fileProp *tempfile = createFileNode( filename, size, data_set, class, numopcode, in_numopcode);
            while( (freq = strtok(NULL,",\n")) != NULL )
            {
                int currcount = atoi(freq);
                if ( currcount > max ) max = currcount;
                if ( currcount < min ) min = currcount;
                tempfile->opcodes[numopcodes++] = currcount;
            }
            tempfile->min_opcodefreq = min;
            tempfile->max_opcodefreq = max;
            tempfile->next = NULL;
            addToFiles( out_fillist, &tempfile);
            free(buff);
            numfiles++;
        }
    }
    fclose( fp );
    return numfiles;
}

void initFiles( s_files ** p_files)
{
    *p_files = (s_files*) malloc ( sizeof(s_files) );
    (*p_files)->list = NULL;
    (*p_files)->garb = NULL;
}

void initFileList( s_filelist ** p_list)
{
    (*p_list) = (s_filelist*) malloc ( sizeof( s_filelist) ) ;
    (*p_list)->count = 0;
    (*p_list)->list = NULL;
}

void cleanUp( s_garbage * p_garbage)
{
}

void deleteFiles( s_files ** p_files)
{
    cleanUp( (*p_files)->garb );
    free( *p_files );
    (*p_files) = NULL;
}

void showFiles( s_files * p_files)
{
    s_fileProp * temp = p_files->list;
    int count = p_files->numFiles;
    while ( temp != NULL)
    {
        printf("%d %s %d\n", count--, temp->name, temp->numopcode);
        temp = temp->next;
    }
}

void fillTheMatrix( s_files ** p_files, int * p_mat, int * p_cvect, int rows, int columns)
{
    s_fileProp * list = (*p_files)->list;
    int i=0,j=0;
    while( list!= NULL)
    {
        for( j=0; j<columns; j++)
        {
            p_mat[ (i*columns)+j ] = list->opcodes[j];
        }
        p_cvect[i] = list->classId;
        list= list->next;
        i++;
    }
}

void fillTheMatrixFromList( s_filelist ** p_files, int * p_mat, int * p_cvect, int rows, int columns)
{
    s_filelistnode * list = (*p_files)->list;
    int i=0,j=0;
    while( list!= NULL && i<rows)
    {
        for( j=0; j<columns; j++)
        {
            p_mat[ (i*columns)+j ] = list->prop->opcodes[j];
        }
        p_cvect[i] = list->prop->classId;
        list= list->next;
        i++;
    }
}

void addToList( s_filelist ** p_list, s_fileProp * p_prop)
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

void adjustCount(int* out_groupcount, int num_groups)
{
    int i;
    int count;
    for(  i=0; i<num_groups*2; i+=2)
    {
        if( out_groupcount[ i+0 ] > out_groupcount[ i+1 ])
            out_groupcount[ i+0 ] = out_groupcount[ i+1 ];
        else
            out_groupcount[ i+1 ] = out_groupcount[ i+0 ];
    }
}
/*
 *	@DESC   : Does grouping for only 2 classes
 *          : TODO make it genric for n classes
 *	@PRAM   : What are the parameters?
 *	@RETURN : What does it return?
 *	
 */
void doGrouping( s_files* in_files, int* in_groupcount, s_group ** out_groups)
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

void addToGroup( s_group ** out_groups, int in_gropup_index, s_fileProp *in_fileprop)
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

void showGroupWiseStats( s_group * in_groups , int in_num_groups)
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

void initGroups( s_group ** out_groups, int in_count)
{
    (*out_groups) = (s_group*) calloc(sizeof(s_group), in_count);
    int i;
    for ( i=0; i<in_count; i++)
    {
        (*out_groups)[i].list[0]=NULL;
        (*out_groups)[i].list[1]=NULL;
    }     
}

void normalizeFilelist( s_files ** out_filelist)
{
    s_fileProp * temp;
    temp = (*out_filelist)->list;
    int count = (*out_filelist)->numFiles;
    int i=0, j=0;
    int min=0, max=0;
    for ( i=0; i<count; i++)
    {
        min = temp->min_opcodefreq;
        max = temp->max_opcodefreq;
        int *opc = temp->opcodes;
        float *nopc = temp->normalized_opcodes;
        for ( j=0; j<temp->numopcode; j++)
        {
            nopc[j] = (float)(opc[j] - min)/(float)(max - min);
            assert( nopc[j] >= 0.0f ); // TODO can decide a threshold, right now checks only for +ve values
        }
        temp=temp->next;
    }
}

void fillGroupWiseData( s_group *in_groups, float *out_data_matrix, int in_num_groups, int in_num_opcodes)
{
    int mean =0, var =1;
    int i,j,k;
    float x;
    for ( i=0; i<in_num_groups*2; i+=2)
    {
        for ( j=0; j<2; j++) // TODO make this generic NUM_CLASSES
        {
            s_filelistnode *temp = in_groups[i/2].list[j];
            int num = in_groups[i/2].count;
            if( num > 0)
            {
                for ( k=0; k<in_num_opcodes; k++)
                {
                    x = temp->prop->normalized_opcodes[k];
                    float m = x/num;
                    float v = (m-x)*(m-x)/num;
                    //assert( m >= 0.0f && v >= 0.0f);
                    out_data_matrix[((i+mean)*in_num_opcodes)+k]+= m;
                    out_data_matrix[((i+var)*in_num_opcodes)+k]+= v;
                }
            }
        }
    }
}

void showGroupWiseProcessedValues( float *out_data_matrix, int in_num_groups, int in_num_opcodes)
{
    int mean =0, var =1;
    int i,j,k;
    FILE *fp;
    char *fname = "/tmp/file";
    fp = fopen(fname, "w");

    printf(" Writing data to file %s\n", fname);
    for ( i=0; i<in_num_groups*2; i+=2)
    {
        for ( j=0; j<in_num_opcodes; j++)
        {
            fprintf(fp," %f", out_data_matrix[((i+mean)*in_num_opcodes)+j]);
        }
        fprintf(fp,"\n");
        for ( j=0; j<in_num_opcodes; j++)
        {
            fprintf(fp," %f", out_data_matrix[((i+var)*in_num_opcodes)+j]);
        } 
        fprintf(fp,"\n");
    }

    fclose(fp);
}
