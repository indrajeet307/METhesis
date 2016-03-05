#include "helper.h"
#include "naiveOperations.h"
#include "trie.h"
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int readFromFile(char *fname, s_docs **docptr, s_trie **classptr, s_trie **wordptr)
{
    FILE *fp;
    int err;
    errno = 0;
    fp = fopen(fname, "r");
    err = errno;
    if(fp == NULL)
    {
        printf("[ Error ] %s.\n",strerror(err));
        return err;
    } 
    char *buff=NULL;
    size_t count=0;
    size_t readlen;
    int numWords=0;
    while( !feof(fp))
    {
        readlen = getline( &buff, &count, fp);
        if( readlen == -1) break;
        char *class = strtok(buff,"\t");
        int cid = findWord(classptr, class, strlen(class));
        if( cid < 0)
            cid = addWord(classptr, class, strlen(class));
        s_doc *temp = addDocTolist(docptr,  cid);

        char *word;
        while( (word = strtok(NULL," \n\r")) != NULL)
        {
            numWords++;
            int wid = findWord(wordptr, word, strlen(word));
            if( wid < 0)
                wid = addWord(wordptr, word, strlen(word));
            addWordDoc(&temp,docptr,wid);
        }
    }
    printf("Number of words %d\n",numWords);
    fclose(fp);
    return 0;
}
int* createMatrix( int columns, int rows)
{
    int *temp = (int*) calloc( sizeof(int), columns*rows);
    return temp;
}
float* createFloatMatrix( int columns, int rows)
{
    float *temp = (float*) calloc( sizeof(float), columns*rows);
    return temp;
}
int main(int argc, char **argv)
{
    if( argc < 2)
    {
        printf("Usage: ./naive.out <training_file>\n");
        return 1;
    }
    char * fname = argv[1];
    s_trie *classlist;
    s_trie *wordlist;
    s_docs *doclist;

    classlist = initTrie();
    wordlist = initTrie();
    doclist = initDL();

    readFromFile(fname, &doclist, &classlist, &wordlist);
    int numdocs = getNumDocs(doclist);
    int numclasses = getNumwords(classlist);
    printf(" Read %d Docs\n", numdocs);
    printf(" Containing %d total unique words\n", getNumwords(wordlist));
    int numwords = getNumwords(wordlist);

    int i=0;
    int count=0;
    int * mat = createMatrix( numwords+1, numdocs); // extra column for the classID
    assert( mat != NULL );
        s_doc *docptr = doclist->list;

    count = filldata(doclist, mat, numdocs, numwords+1);
    float * probmat=createFloatMatrix( numwords, numclasses);
    createProbablityMatrix( mat, probmat, numdocs, numwords+1, numclasses, numwords);
    
    return 0;
}

