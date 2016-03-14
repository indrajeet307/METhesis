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
    s_fileProp *list;
    int numFiles;
    s_garbage *garb;
};
typedef struct files s_files;

int readCSVFile(char*, int, s_files**, int*);
int readOpcodeFile(char*, s_trie**);
s_fileProp* createFileNode( char* , int , char *, char *, int, int);
void addToGarbage(void *);
void deleteFiles(s_files**);
void fillTheMatrix( s_files ** , int * , int * , int , int );
void initFiles(s_files**);
void showFiles(s_files*);

#endif//__OPCHEADER_H_

