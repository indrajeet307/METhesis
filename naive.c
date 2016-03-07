#include "helper.h"
#include "naiveOperations.h"
#include "trie.h"
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int readFromTestFile(char *fname, s_docs **docptr, s_trie **classptr, s_trie **wordptr)
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
        {
            printf(" Found an Outlier Class %s\n", class);
            continue;
            }
        s_doc *temp = addDocTolist(docptr,  cid);

        char *word;
        while( (word = strtok(NULL," \n\r")) != NULL)
        {
            numWords++;
            int wid = findWord(wordptr, word, strlen(word));
            if( wid < 0)
            {
                printf(" New Word %s, cannot accomodate\n", word);
                continue;
            }
            addWordDoc(&temp,docptr,wid);
        }
    }
    printf("Number of words %d\n",numWords);
    fclose(fp);
    return 0;
}
int readFromTrainFile(char *fname, s_docs **docptr, s_trie **classptr, s_trie **wordptr)
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
int *createVector(int columns)
{
    int *temp = (int*) calloc( sizeof(int), columns);
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
        printf("Usage: ./naive.out <training_file> <test_file>\n");
        return 1;
    }
    char * trainfname = argv[1];
    char * testfname = argv[2];

    s_trie *classlist = initTrie();
    s_trie *wordlist = initTrie();
    s_docs *doclist = initDL();
    s_docs *testdoclist = initDL();


    readFromTrainFile(trainfname, &doclist, &classlist, &wordlist);
    int numdocs = getNumDocs(doclist);
    int numclasses = getNumwords(classlist);
    printf(" Read %d Docs\n", numdocs);
    printf(" Containing %d total unique words\n", getNumwords(wordlist));
    int numwords = getNumwords(wordlist);

    int i=0;
    int count=0;
    int * mat = createMatrix( numwords, numdocs); // extra column for the classID
    assert( mat != NULL );
    int * cvect = createVector( numdocs);    // stores the class info for the doc
    assert( cvect != NULL );
        s_doc *docptr = doclist->list;

    count = filldata(doclist, mat, cvect ,numdocs, numwords);
    //printIntMatrix(mat, numdocs, numwords);
    float *fmat = createFloatMatrix( numdocs, numwords);
    normalize(mat ,fmat, numdocs, numwords);
    //print(fmat, numdocs, numwords);
    float * cprob = (float*) calloc( sizeof(float) , numclasses);
    assert( cprob != NULL );
    float * probmat=createFloatMatrix( numwords, numclasses); // extra column for probablity of the class
    createProbablityMatrix( mat, probmat, cvect, cprob, numdocs, numwords, numclasses, numwords);
    free(mat);
    print(probmat, numclasses, numwords);

    readFromTestFile( testfname, &testdoclist, &classlist, &wordlist);
    numdocs = getNumDocs(testdoclist);
    printf(" Read %d Training Docs\n", numdocs);
    printf(" Containing %d total unique words\n", getNumwords(wordlist));
    int *smat = createMatrix( numwords, numdocs); 
    filldata(testdoclist, smat, cvect, numdocs, numwords);
    int * pmat = createVector( numdocs); // for predicted classID
    
    assignClass( smat, probmat, cprob, pmat, numdocs, numclasses, numwords); 
    printIntMatrix( pmat, 1, numdocs);
    printIntMatrix( cvect, 1, numdocs);
    showWords(classlist);
    free(cvect);
    free(pmat);
    //free(smat);
    return 0;
}

