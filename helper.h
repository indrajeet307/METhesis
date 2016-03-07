#ifndef __HELPER_H_
#define __HELPER_H_

struct s_wordnode{
    int id;
    int freq;
    struct s_wordnode *next;
};
typedef struct s_wordnode s_wordnode;

struct s_doc{
    int id;
    int classid;
    int wcount;
    s_wordnode *wlist;
    struct s_doc *next;
};
typedef struct s_doc s_doc;

struct s_garbage{
    void *ptr;
    struct s_garbage *next;
};
typedef struct s_garbage s_garbage;

struct s_docs{
    struct s_doc *list;
    struct s_garbage *grb;
    int numdocs;
};
typedef struct s_docs s_docs;
int addWordDoc( s_doc** , s_docs** , int );
int filldata( s_docs*,int*,int* , int, int);
int getDocIndex(s_docs** );
int getNumDocs(s_docs* );
int showDocs(s_docs *);
int showWordsDoc(s_doc *);
struct s_doc* addDocTolist( s_docs** , int );
struct s_docs* initDL( );
void cleanUP(s_docs **);
#endif // __HELPER_H_
