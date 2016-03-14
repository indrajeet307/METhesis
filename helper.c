#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "helper.h"

struct s_docs* initDL( )
{
    s_docs *temp=NULL;
    temp=(s_docs*)calloc(sizeof(s_docs),1);
    temp->list = NULL;
    temp->grb = NULL;
    return temp;
}

s_garbage *addCleanUpPointer(void *ptr)
{
    s_garbage *temp = (s_garbage*) malloc(sizeof(s_garbage));
    temp->ptr = ptr;
    temp->next = NULL;
    return temp;
}

void addToCleanUp( s_docs **dlist, void * ptr)
{

    if ( (*dlist)->grb == NULL)
    {
        (*dlist)->grb = addCleanUpPointer(ptr);
        return;
    }

    s_garbage *temp=addCleanUpPointer(ptr); 
    temp->next = (*dlist)->grb;
    (*dlist)->grb = temp;
    return;


}

void cleanUP(s_docs **dlist)
{
    if( (*dlist)->grb == NULL) return;
    s_garbage *temp = (*dlist)->grb;
    s_garbage *prev = (*dlist)->grb;
    while( temp != NULL)
    {
        prev= temp;
        temp= temp->next;
        free(prev->ptr);
        free(prev);
    }
    (*dlist)->grb == NULL;
}

s_doc* createDoc(s_docs **dlist,  int classid)
{
    s_doc *temp = (s_doc*) malloc (sizeof(s_doc));
    addToCleanUp(dlist, (void*)temp);
    temp->id = getDocIndex(dlist);
    temp->classid = classid;
    
    temp->wcount = 0;
    temp->wlist = NULL;
    temp->next = NULL;
    return temp;
}

struct s_doc* addDocTolist( s_docs **dlist, int classid)
{
    if ( (*dlist)->list == NULL )
    {
        (*dlist)->list  = createDoc(dlist,  classid);
        return (*dlist)->list;
    }
    // check for the doc in the list
    // append if not  found
    s_doc *temp;
    temp = createDoc(dlist, classid);
    temp->next = (*dlist)->list;
    (*dlist)->list = temp;
    return temp;
}

s_wordnode * createWord(s_docs **dlist, int id, int count)
{
    s_wordnode * temp = (s_wordnode*) malloc(sizeof(s_wordnode));
    addToCleanUp( dlist, (void*)temp);
    temp->id = id;
    temp->freq = count;
    temp->next = NULL;
    return temp;
}

int addWordDoc( s_doc **docptr, s_docs **dlist, int id)
{
    if( (*docptr)->wlist == NULL )
    {
        (*docptr)->wlist = createWord(dlist, id, 1);
        (*docptr)->wcount+=1;
        return id;
    }
    s_wordnode *temp = (*docptr)->wlist;
    while( temp->next != NULL)
    {
        if( temp->id == id)
        {
            temp->freq += 1;
            return id;
        }            
        temp=temp->next;
    }
    if( temp->id != id)
    {
        s_wordnode *nword = createWord(dlist, id, 1);
        (*docptr)->wcount+=1;
        temp->next =  nword;
        return id;
    }
    temp->freq += 1;
    return temp->id;

}

int showWordsDoc(s_doc *docptr)
{
    s_wordnode *temp = docptr->wlist;
        printf(" Id, Freq\n");
    while( temp!=NULL)
    {
        printf(" %d, %d\n", temp->id, temp->freq);
        temp=temp->next;
    }
    return docptr->wcount;
}

int showDocs(s_docs *docptr)
{
    s_doc *temp;
    temp = docptr->list;
    int count=0;
    while( temp!=NULL)
    {
        printf(" %d,%d", temp->classid, temp->wcount);
        temp= temp->next;
        count++;
    }
    return count;
}

int getDocIndex(s_docs **dlist)
{
    (*dlist)->numdocs += 1;
    return (*dlist)->numdocs;
}

int getNumDocs(s_docs *dlist)
{
    return dlist->numdocs;
}

int filldata(s_docs *docs, int*mat ,int *cvect, int rows, int columns)
{
    int i,j;
    int count=0;
    int numdocs = docs->numdocs;
    s_doc * pdoc;
    pdoc = docs->list;
    for ( i=0; i<numdocs; i++)
    {
        s_wordnode *pwordnode = pdoc->wlist;
        while( pwordnode!=NULL)
        {
#define INDEX(i,j) ( (i*columns)+j )
                mat[ INDEX(i,pwordnode->id) ] = pwordnode->freq;
                count += pwordnode->freq;
                pwordnode=pwordnode->next;
            }
        cvect[ i ] = pdoc->classid;
#undef INDEX
            pdoc = pdoc->next;
    }
    return count;
}
