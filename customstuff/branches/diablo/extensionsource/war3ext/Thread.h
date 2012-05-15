#ifndef _Thread_
#define _Thread_

#include <errno.h>

#ifdef WIN32
  #include "Win32/Thread.h"
#else
  #include "Posix/Thread.h"
#endif

#endif // !_Thread_
