#if EXTVARS
#include "stdlib.h"
#include "string.h"
#include "pstw_vars.h"

pstw__tab_t **pstw__hashtab; // hash table
pstw__tab_t *pstw__tab;      // string table

size_t hashmemsize = 0;
size_t strmemsize = 0;

void pstw_resettables()
{
    if (!strmemsize)
    {
        strmemsize = pstw__tabM * sizeof(pstw__tab_t);
        pstw__tab = malloc(strmemsize);
    }

    if (!hashmemsize)
    {
        hashmemsize = pstw__hashtabM * sizeof(pstw__tab_t);
        pstw__hashtab = malloc(hashmemsize);
    }

    memset(pstw__hashtab, 0, hashmemsize);
}

#endif
