#ifndef _Mutex_
#define _Mutex_

#include <errno.h>

#ifdef WIN32
  #include "Win32/Mutex.h"
#else
  #include "Posix/Mutex.h"
#endif

#endif // !_Mutex_
