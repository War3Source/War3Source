using System;
using System.Collections.Generic;
using System.Text;

namespace GoogleRequester
{
    public class Singleton
    {
        private static Singleton instance = null;
        private static object lockObject = new object();

        private Singleton()
        {
        }

        public static Singleton GetInstance()
        {
            lock (lockObject)
            {
                 if (instance == null)
                     instance = new Singleton();

                return instance;
            }
        }

    }
}