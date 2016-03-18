/*
 * Trie Implementation
 * https://en.wikipedia.org/wiki/Trie
 * TODO: ADD . as the part of the word, add clean up
 *
 * */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "trie.h"
#define MAX_WORDS 2048 // no more required
#define MAX_ALPHA 48 // allowed characters in a word
enum {DOT=26, ORB, CRB, ONE, THREE, TWO, SIX, FOUR, FIVE, COMMA,
    E8, S7, Z0, DASH, UNDERSCORE, NINE}; //ORB : Open Rounded Bracket, CRB = Close Rounded Bracket
inline int getNumberFromAlpha(int x)
{
    if( x == ',')
        return COMMA;
    if( x == '.')
        return DOT;
    if( x == '(')
        return ORB;
    if( x == ')')
        return CRB;
    if( x == '1')
        return ONE;
    if( x == '2')
        return TWO;
    if( x == '3')
        return THREE;
    if( x == '4')
        return FOUR;
    if( x == '5')
        return FIVE;
    if( x == '6')
        return SIX;
    if( x == '7')
        return S7;
    if( x == '8')
        return E8;
    if( x == '0')
        return Z0;
    if( x == '-')
        return DASH;
    if( x == '_')
        return UNDERSCORE;
    if( x == '9')
        return NINE;
    if( x >= 'A' && x <= 'Z')
        return (x - 'A');
    else if (x >= 'a' && x <= 'z')
        return (x - 'a');
    else return -1;
}


/*
 *	@DESC   : attaches pointer to the list of items to be garbage collected later
 *	@PRAM   : garbage list, pointer to be attched
 *	@RETURN : What does it return?
 *	
 */
void addToPickup(s_garbage_coll **garbage_ptr, void *ptr)
{
    struct garbage_coll *temp = (s_garbage_coll*) malloc (sizeof(s_garbage_coll));
    temp->ptr = ptr;
    temp->next = NULL;
    if((*garbage_ptr) ==NULL)
    {
        (*garbage_ptr) = temp;
        return;
    }
    temp->next = (*garbage_ptr);

    (*garbage_ptr) = temp;
}

/*
 *	@DESC   : Free all the pointers
 *	@PRAM   : Garbage list
 *	@RETURN : 
 *	
 */
void clean(s_garbage_coll **garbage_ptr)
{
    s_garbage_coll *temp, *prev;
    temp = (*garbage_ptr);
    if(temp == NULL)
        return;
    while(temp!=NULL)
    {
        prev = temp;
        temp = temp->next;
        free(prev->ptr);
        free(prev);
    }
    temp = prev = NULL;
    (*garbage_ptr) = NULL;
}

/*
 *	@DESC   : Initialize the trie level
 *	@PRAM   : Trie node ptr
 *	@RETURN :  
 *	
 */
inline void initTrieLevel(s_trie_node * node)
{
    int i = 0;
    for( i = 0 ; i<MAX_ALPHA; i++)
    {
        node[i].next = NULL;
        node[i].Id = 0;
    }
}

/*
 *	@DESC   : Initialize the trie, and return the pointer to the data structure 
 *	@PRAM   :  
 *	@RETURN : returns the pointer to the trie
 *	
 */
s_trie *initTrie()
{
    s_trie *temp = (s_trie*) malloc( sizeof(s_trie) );
    temp->trie_ptr = (s_trie_node*) malloc(sizeof(s_trie_node)*MAX_ALPHA);
    temp->word_list = NULL;
    temp->garbage_ptr = NULL;
    addToPickup(&(temp->garbage_ptr), (void*)temp->trie_ptr);
    initTrieLevel(temp->trie_ptr);
    temp->num_words = 0;
    return temp;
}

/*
 *	@DESC   : Clean up the trie
 *	@PRAM   : pointer to the trie
 *	@RETURN :  
 *	
 */
void deleteTrie(s_trie ** trie)
{
    clean( &((*trie)->garbage_ptr) );
    free(*trie);
    *trie = NULL;
}
/*
 *	@DESC   : Tells number of words in the trie
 *	@PRAM   : Pointer to the trie
 *	@RETURN : Number of words
 *	
 */
int getNumwords(s_trie *trie)
{
    return trie->num_words;
}

/*
 *	@DESC   : Increments number of words
 *	@PRAM   : Pointer to the trie
 *	@RETURN : Count before incrementing
 *	
 */
int incNumwords(s_trie **trie)
{
    int x = (*trie)->num_words;
    (*trie)->num_words +=1;  
    return x;
}

/*
 *	@DESC   : Add a blank new trie level
 *	@PRAM   : pointer to the trie
 *	@RETURN : pointer to the trie node
 *	
 */
s_trie_node* addTrieLevel(s_trie **trie)
{
    s_trie_node *temp;
    temp = (s_trie_node*) malloc(sizeof(s_trie_node) *MAX_ALPHA);
    addToPickup(&((*trie)->garbage_ptr), (void*)temp);
    initTrieLevel(temp);
    return temp;
}

/*
 *	@DESC   : add word to a list
 *	@PRAM   : index in the list, word , size of word
 *	@return : 
 *	
 */
void addToWordList(s_trie **trie, int val,char * word,int wsize)
{
    char * tempword =  (char*) malloc(sizeof(char)*wsize+1);
    addToPickup(&((*trie)->garbage_ptr), (void*)tempword);
    strncpy(tempword,word,wsize);
    tempword[wsize] =  '\0';

    s_word_node * node = ( s_word_node*) malloc(sizeof(s_word_node));
    addToPickup(&((*trie)->garbage_ptr), (void*)node);
    node->word = tempword;
    node->Id = val;
    node->next = NULL;

    s_word_node * prev;
    s_word_node * temp = (*trie)->word_list;
    prev = temp;
    if(temp == NULL)
    {
        (*trie)->word_list = node; 
        return ;
    }
    while(temp->next != NULL && strcmp(node->word, temp->next->word) > 0 )
    {   
        prev = temp;
        temp = temp->next;
    }
    if(temp->next == NULL)
    {
        if( strcmp(node->word, temp->word) < 0)
        { 
            if( prev == (*trie)->word_list )
            {
                (*trie)->word_list = node;
                node->next = temp;
            }
            else
            {
                node->next = prev->next;
                prev->next = node;
            }
        } else
            temp->next = node;
    }
    else
    {
        node->next = temp->next;
        temp->next = node;
    }
}

/*
 *	@DESC   : adds a word to the trie
 *	@PRAM   : the to be added and its size
 *	@return : index of the word else retrurn -1 on error
 *	
 */
int addWord(s_trie **trie, char *word,int wsize)
{
    s_trie_node *temp = (*trie)->trie_ptr;
    int val,i,in;
    for(  i=0;i < wsize;i++)
    {
        in = getNumberFromAlpha(word[i]);
        if( in == -1){
            printf("Cannot Add word,%s :( \n",word);
            return -1;
        }
        if(i != (wsize-1))
        {
            if(temp[in].next == NULL)
            {
                temp[in].next = addTrieLevel(trie);
                temp = temp[in].next;
            }
            else //if(temp[in].next) 
                temp = temp[in].next;
        }
        else // i== wsize-1
        {
            temp[in].Id = incNumwords(trie);
            val = temp[in].Id;
            addToWordList(trie, val, word, wsize); 
            return val;
        }
    }
    return -1;
}

/*
 *	@DESC   : Finds a word in the trie
 *	@PRAM   : the word to be addded and its size
 *	@return : index fo the word if found else RETURNs -1
 *	
 */
int findWord(s_trie **trie, char *word,int wsize)
{
    int i,in;
    if((*trie)->num_words == 0)
        return -1;
    s_trie_node *temp = (*trie)->trie_ptr;
    for( i=0;i < wsize;i++)
    {
        in = getNumberFromAlpha(word[i]);
        if( in == -1){
            printf("Cannot find word,%s :( \n",word);
            return -1;
        }
        if(i != (wsize-1))
        {
            if(temp[in].next == NULL){
                return -1;
            }
            if (temp[in].next ){
                temp = temp[in].next;
            }
        }
        else // i== wsize-1
        {
            return temp[in].Id ;
        }
    }
    return -1;
}

/*
 *	@DESC   : Shows the words in the dicitionary
 *	@PRAM   :
 *	@return :
 */
int showWords(s_trie *trie)
{
    int i=0; 
    int num_words = trie->num_words;
    if( num_words == 0)
        return 1;
    struct word_node *temp = trie->word_list;
    for ( i=0; i< num_words; i++,temp=temp->next)
    {
        printf("[%d] == %s. \n",temp->Id,temp->word);
    }
return 0;
}

/*
 *	@DESC   : Write contents of the trie to a file
 *	@PRAM   : Pointer to the trie and Filename
 *	@RETURN :  
 *	
 */
void putWordsToFile(s_trie *trie, char *filename)
{
    FILE *fp;
    int num_words = trie->num_words;
    if( num_words == 0)
        return ;
    errno = 0;
    fp = fopen(filename,"w+");
    int i;
    if(errno != 0)
    {
        printf("Error: %s",strerror(errno));
        return;
    }
    struct word_node *temp = trie->word_list;
    for ( i=0; i< num_words; i++,temp=temp->next)
    {
        fprintf(fp,"%d %s\n",temp->Id,temp->word);
    }
    fclose(fp);
}
