/*
 * file.d
 *
 * This module has the structure that is kept with a File class for Windows.
 *
 * Author: Dave Wilkinson
 * Originated: July 22th, 2009
 *
 */

module platform.vars.file;

import binding.win32.winnt;

struct FilePlatformVars {
    HANDLE f;
}