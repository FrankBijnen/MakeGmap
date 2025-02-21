#ifdef EXTVARS

#ifndef _PSTW_VARS_
#define _PSTW_VARS_

typedef struct pstw__tab_struct {
  int index;  // index of this string table element;
  int len;  // length of the string contents
  char* mem0;  // pointer to the string's header in string memory area,
    // i.e., the byte 0x0a and the string's length in Varint format;
  char* mem;  // pointer to the string contents in string memory area
  int frequency;  // number of occurrences of this string
  int hash;
    // hash value of this element, used as a backlink to the hash table;
  struct pstw__tab_struct* next;
    // for chaining of string table rows which match
    // the same hash value; the last element will point to NULL;
  } pstw__tab_t;

// The malloc version allows us to increase these numbers
//  #define pstw__hashtabM 50000017  // (preferably a prime number)
  #define pstw__hashtabM 25000009  // (preferably a prime number)
  // --> 150001, 1500007, 5000011, 10000019, 15000017,
  // 20000003, 25000009, 30000049, 40000003, 50000017

//#define pstw__tabM (1500000)
#define pstw__tabM (64 * 1024 * 1024)

#endif

#endif
