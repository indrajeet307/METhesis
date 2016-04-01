/*! \file opcodeFile.h */
#include "trie.h"
#ifndef __OPCHEADER_H_
#define __OPCHEADER_H_
struct opcodenode{
    int id;
    int freq;
};
typedef struct opcodenode s_opcodenode;

struct diffnode{
    int id;
    float diff;
};
typedef struct diffnode s_diffnode;

struct fileProp{
    char *name;
    int numopcode;
    int size;
    int data_type;
    int min_opcodefreq;
    int max_opcodefreq;
    int classId;
    float *normalized_opcodes;
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
    s_filelistnode *list[2];  // TODO make this NUM_CLASSES
    int *features;
    int count;
    int max;
    int min; 
};			
typedef struct group s_group;


int readCSVFile(char* in_filename, int in_numopcode, s_files** out_filelist, int* out_groupcount);
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
int adjustCountInEachGroup(int* out_groupcount, int num_groups);
void doGrouping( s_files* in_files, int* in_groupcount, s_group ** out_groups);
void addToGroup( s_group ** out_groups, int in_gropup_index, s_fileProp *in_fileprop);
void showGroupWiseStats( s_group * in_groups , int in_num_groups);
void initGroups( s_group ** out_groups, 
        int count);
void normalizeOpcodeFrequency( s_files** out_filelist );

int fillGroupWiseData(
        s_group   *in_groups,
        float     *out_trainArray,
        int        in_num_groups,
        int        in_num_opcodes,
        float     *out_testArray,
        int       *out_class_vect,
        int       *out_group_vect
        );

void showGroupWiseProcessedValues( 
        float *out_data_matrix, 
        int in_num_groups, 
        int in_num_opcodes 
        );

void selectFeaturesForEachGroup(
        s_group ** out_group,
        int in_num_groups,
        int in_num_opcodes,
        int in_num_features
        );

void setFeatureVector( 
        float **in_features, 
        s_group * out_group , 
        int in_num_list, 
        int in_num_columns, 
        int in_num_features 
        );

void assignFeatureListForEachGroup( 
        int ***out_feature_list, 
        s_group *in_groups, 
        int in_num_groups
        );

void createFeatureListForEachGroup( 
        int ***out_feature_list, 
        int in_num_groups
        );
void deleteGrouplist( s_group ** in_groups, int in_numgroups);
#endif//__OPCHEADER_H_
