#ifdef WINDOWS
#include <tchar.h>
#include "unistd.h"
#endif

#ifdef __GNUC__
#define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))
#endif

#ifdef RAD
#define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))
#pragma comment (lib, "zlib")
#endif

#ifdef _MSC_VER
#define PACK( __Declaration__ ) __pragma( pack(push, 1) ) __Declaration__ __pragma( pack(pop))
#endif

