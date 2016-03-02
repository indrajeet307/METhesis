#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
struct word{
    char word[32];
    int id;
    struct word *next;
};
struct masterwordlist
{
    struct word *list;
    int count;
};
typedef struct masterwordlist s_masterwordlist;
struct wordidlist{
    int id;
    struct wordidlist *next;
};

struct class
{
    char name[32];
    int id;
    int count;
    struct wordidlist *list;
};
typedef struct class s_class;

struct garbage{
    void *ptr;
    struct garbage *next;
};
typedef struct garbage s_garbage;

void init(s_class *cls, s_masterwordlist *mwl, s_garbage *grb)
{
    cls = NULL;
    mwl = NULL;
    grb = NULL;
}
int readFromFile(char *fname, s_class *p_class, s_masterwordlist *p_wordlist, s_garbage *p_garbage)
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
    char buff[1024];
    size_t count=1024;
    size_t readlen;
    while( !feof(fp))
    {
        readlen = read(fileno(fp), buff, count);
        if( readlen == 0) break;
        printf("[ buff ] %d \n", (int)readlen);
        if( readlen == count )
        {
        char *p = buff+(readlen-1);
        while( *p != ' ')
            p--;
            *p = '\0';
        }
        //printf(" %s", buff);
    }
    fclose(fp);
    return 0;
}
int main(int argc, char **argv)
{
    if( argc < 2)
    {
        printf("Usage: ./naive.out <training_file>\n");
        return 1;
    }
    char * fname = argv[1];
    s_class *p_class; 
    s_masterwordlist *p_wordlist;
    s_garbage *p_garbage;
    init(p_class, p_wordlist, p_garbage);
    readFromFile(fname, p_class, p_wordlist, p_garbage);

    return 0;
}

