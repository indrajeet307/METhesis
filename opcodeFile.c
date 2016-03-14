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

s_fileProp* createFileNode( char* name, int size, char *data_type, char *class, int numopcode, int columns)
{
    s_fileProp* temp = (s_fileProp*) malloc( sizeof(s_fileProp) );
    if( temp == NULL )
    {
        printf(" Malloc Failed \n");
        return NULL;
        }
    temp->name = (char*) malloc( sizeof(char) * (strlen(name)+1) );
    strcpy( temp->name ,name);
    temp->numopcode = numopcode;
    temp->size = size;
    //temp->data_type = data_type;
    temp->classId   = getClassId(class);
    temp->opcodes = (int*) malloc ( sizeof(int) * columns);
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

int readCSVFile( char* fname, int columns, s_files ** p_files, int *groupCount)
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
    size_t readlen=0;

    while( !feof( fp ) )
    {
        char  *buff=NULL;
        size_t count=0;
        numopcodes = 0;
        printf(" Files read %d\n", numfiles);
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
        if( numopcode <= 20 && size > 500)
        {
            //printf(" Empty File \n");
            continue;
        }
        s_fileProp *tempfile = createFileNode( filename, size, data_set, class, numopcode, columns);
        while( (freq = strtok(NULL,",\n")) != NULL )
        {
            tempfile->opcodes[numopcodes++] = atoi(freq) ;
        }
        tempfile->next = NULL;
        //groupCount[ (size)/5 ]++;
        addToFiles( p_files, &tempfile);
        //printf("%s\n", filename);
        //printf("%s\n", data_set);
        //printf("%s\n", class);
        //printf("%d\n", atoi(numopc));
        //printf("%d\n", atoi(filesize));
        free(buff);
        numfiles++;
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
