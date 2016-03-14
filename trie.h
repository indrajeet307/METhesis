#ifndef __TRIE_H_
#define __TRIE_H_

struct trie_node{
    struct trie_node *next;
    unsigned int Id;
};
typedef struct trie_node s_trie_node;

struct word_node{
    char *word;
    int  Id;
    struct word_node *next;
};
typedef struct word_node s_word_node;

struct garbage_coll{
    void * ptr;
    struct garbage_coll * next;
};
typedef struct garbage_coll s_garbage_coll;

struct trie{
    s_trie_node *trie_ptr;
    s_word_node *word_list;
    s_garbage_coll *garbage_ptr;
    unsigned int num_words;
};
typedef struct trie s_trie;

int addWord(s_trie**, char *, int);
int findWord(s_trie**, char *, int);
int getNumwords(s_trie*);
int showWords(s_trie*);
s_trie * initTrie();
void deleteTrie(s_trie**);
void putWordsToFile(s_trie*, char*);
#endif // __TRIE_H_
