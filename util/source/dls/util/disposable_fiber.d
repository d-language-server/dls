/*
 *Copyright (C) 2018 Laurent Tréguier
 *
 *This file is part of DLS.
 *
 *DLS is free software: you can redistribute it and/or modify
 *it under the terms of the GNU General Public License as published by
 *the Free Software Foundation, either version 3 of the License, or
 *(at your option) any later version.
 *
 *DLS is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *GNU General Public License for more details.
 *
 *You should have received a copy of the GNU General Public License
 *along with DLS.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

module dls.util.disposable_fiber;

import core.thread : Fiber;

class FiberDisposedException : Exception
{
    this()
    {
        super("Fiber disposed");
    }
}

class DisposableFiber : Fiber
{
    static bool safeMode;
    private bool _disposed;

    static DisposableFiber getThis()
    {
        const thisFiber = Fiber.getThis();
        assert(typeid(thisFiber) == typeid(DisposableFiber));
        return cast(DisposableFiber) thisFiber;
    }

    static void yield()
    {
        if (safeMode)
        {
            return;
        }

        Fiber.yield();

        if (getThis()._disposed)
        {
            throw new FiberDisposedException();
        }
    }

    this(void delegate() dg)
    {
        size_t pageSize;

        version (Windows)
        {
            import core.sys.windows.winbase : GetSystemInfo, SYSTEM_INFO;

            SYSTEM_INFO info;
            GetSystemInfo(&info);
            pageSize = cast(size_t) info.dwPageSize;
        }
        else version (Posix)
        {
            import core.sys.posix.unistd : _SC_PAGESIZE, sysconf;

            pageSize = cast(size_t) sysconf(_SC_PAGESIZE);
        }
        else
        {
            pageSize = 4096;
        }

        super(dg, pageSize * 32);
    }

    void dispose()
    {
        _disposed = true;
    }
}
