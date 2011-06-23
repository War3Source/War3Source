#ifndef _Semaphore_
#define _Semaphore_

#include <errno.h>

#ifdef WIN32
  #include "Win32/Semaphore.h"
#else
  #include "Posix/Semaphore.h"
#endif

#endif // !_Semaphore_
