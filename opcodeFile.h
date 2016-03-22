#include "trie.h"
#ifndef __OPCHEADER_H_
#define __OPCHEADER_H_
struct opcodenode{
    int id;
    int freq;
};
typedef struct opcodenode s_opcodenode;
    
struct fileProp{
    char *name;
    int numopcode;
    int size;
    int data_type;
    int classId;
    s_opcodenode *opcodes;
    struct fileProp * next;
};
typedef struct fileProp s_fileProp;

struct garbage{
    void *ptr;
    struct garbage* next;
};
typedef struct garbage s_garbage;

struct files{
    s_fileProp *list;
    int numFiles;
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
void deleteFiles(s_files**);
void fillTheMatrix( s_files ** , int * , int * , int , int );
void initFiles(s_files**);
void initFileList(s_filelist**);
void initGroups( s_group*);
void showFiles(s_files*);
void addToList( s_filelist **, s_fileProp *);
void fillTheMatrixFromList( s_filelist ** p_files, int * p_mat, int * p_cvect, int rows, int columns);



#endif//__OPCHEADER_H_
