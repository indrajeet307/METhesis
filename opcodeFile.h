#include "trie.h"
#ifndef __OPCHEADER_H_
#define __OPCHEADER_H_
struct fileProp{
    char *name;
    int numopcode;
    int size;
    int data_type;
    int classId;
    int *opcodes;
    struct fileProp * next;
};
typedef struct fileProp s_fileProp;

struct garbage{
    void *ptr;
    struct garbage* next;
};
typedef struct garbage s_garbage;

struct files{
    int numFiles;
    s_fileProp *list;
    s_garbage *garb;
};
typedef struct files s_files;

struct filelistnode{
    s_fileProp *prop;
    struct filelistnode *next;
};
typedef struct filelistnode s_filelistnode;

struct filelist{
    int count;
    s_filelistnode *list;
};
typedef struct filelist s_filelist;


struct group {
    s_filelistnode *list;
    int count;
    int max;
    int min; 
};				/* ----------  end of struct group  ---------- */
typedef struct group s_group;


int readCSVFile(char*, int, s_files**, int*,s_filelist**,s_filelist**);
int readOpcodeFile(char*, s_trie**);
s_fileProp* createFileNode( char* , int , char *, char *, int, int);
void addToGarbage(void *);
void addToList( s_filelist **, s_fileProp *);
void deleteFiles(s_files**);
void fillTheMatrix( s_files ** , int * , int * , int , int );
void fillTheMatrixFromList( s_filelist ** p_files, int * p_mat, int * p_cvect, int rows, int columns);
void initFileList(s_filelist**);
void initFiles(s_files**);
void showFiles(s_files*);
void adjustCount(int* out_groupcount, int num_groups);
void doGrouping( s_files* in_files, int* in_groupcount, s_group ** out_groups);
void addToGroup( s_group ** out_groups, int in_gropup_index, s_fileProp *in_fileprop);
void showGroupWiseStats( s_group * in_groups , int in_num_groups);
void initGroups( s_group ** out_groups, int count);



#endif//__OPCHEADER_H_
