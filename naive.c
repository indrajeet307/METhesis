#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "helper.h"
#include "trie.h"
#include <assert.h>
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
    showWords(classlist);
    //printf(" %d classes\n", );
    //printf(" %d words\n", );
    int numdocs = getNumDocs(doclist);
    printf(" %d Docs\n", numdocs);
    printf(" %d total unique words\n", getNumwords(wordlist));
    int numwords = getNumwords(wordlist)+1;

    int i=0;
    int count=0;
    int * mat = createMatrix( numwords, numdocs);
    assert( mat != NULL );
        s_doc *docptr = doclist->list;
    for ( i=0; i<numdocs; i++)
    {
        count+=filldata( mat+(i*numwords), docptr);
         mat[(i*numwords)+numwords-1]=docptr->classid;
        docptr = docptr->next;
    }
    printf(" %d total words\n", count);
    
    //int j;
    //for( i=0;i<numdocs;i++)
    //{
    //    for ( j=0;j<numwords;j++)
    //    {
    //        printf(" %d",mat[(i*numwords)+j]);

    //    }
    //    printf("\n");
    //}
    
    //showWords(wordlist);
    //clean(&wordlist);
    //clean(&classlist);
    //cleanUP(&doclist);
    return 0;
}

