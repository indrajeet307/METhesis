#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include "opcodeFile.h"
#include "trie.h"

int getClassId( char * class)
{
    if ( strcmp( class, "MALWARE") == 0 ) return 1;
    if ( strcmp( class, "BENIGN") == 0 ) return 0;
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
    //temp->data_type = data_type;
    temp->classId   = getClassId(class);
    temp->opcodes = (int*) calloc ( sizeof(int) , totalopcodes);
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
        //printf(" %s", buff);
        opcode = strtok( buff, "\n" );
        //printf("%s", opcode);
        numopcodes++;
    }
    fclose( fp );
    return numopcodes;
}

void addToFiles(s_files ** p_files, s_fileProp ** p_fileprop)
{
    (*p_files)->numFiles ++;
    //addToGarbage( (*p_files)->garb, (void*) (*p_files));
    if( (*p_files)->list== NULL )
    {
        (*p_files)->list = (*p_fileprop);
        return;
    }
    (*p_fileprop)->next = (*p_files)->list;
    (*p_files)->list = (*p_fileprop);
    return;
}

int readCSVFile( char* fname, int columns, s_files ** p_files, int *groupCount, s_filelist **trainlist, s_filelist **testlist)
{
    FILE *fp;
    int err;
    int numfiles=0;
    err = errno = 0;
    fp = fopen( fname, "r");
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
        //printf(" Files read %d\n", numfiles);
        readlen = getline( &buff, &count, fp);
        if( readlen == -1 ) break ;
        //printf(" %s", buff);
        filename = strtok( buff, "," );
        filesize = strtok( NULL, "," );
        data_set = strtok( NULL, "," );
        class    = strtok( NULL, "," );
        numopc   = strtok( NULL, "," );
        int numopcode = atoi( numopc );
        int size = atoi( filesize );
        int index = size/5;
            if( numopcode > 10 && size < 500 )
            {
                //printf(" %d\n", index);
                if ( getClassId( class ) == 0 )
                groupCount[ index ]++;
                else
                    groupCount[ index ] --;
                    if( groupCount[ index ] >= 0){
                s_fileProp *tempfile = createFileNode( filename, size, data_set, class, numopcode, columns);
                while( (freq = strtok(NULL,",\n")) != NULL )
                {
                    tempfile->opcodes[numopcodes++] = atoi(freq) ;
                }
                tempfile->next = NULL;
                if( fcount < 2)
                {
                    addToList( trainlist, tempfile );
                }
                else
                {
                    fcount=-1;
                    addToList( testlist, tempfile );
                }
                fcount++;
                addToFiles( p_files, &tempfile);
                free(buff);
                numfiles++;
                    }
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
