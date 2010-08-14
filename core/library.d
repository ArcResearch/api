/*
 * library.d
 *
 * This file implements the Library class, which allows access to external
 * dynamic libraries at runtime.
 *
 * Author: Dave Wilkinson
 * Originated: May 29, 2009
 *
 */

module core.library;

import core.string;
import core.definitions;

import platform.vars.library;

import scaffold.system;

// Description: This class will allow runtime linking to dynamic libraries.
class Library {
private:

	// Description: This function can only be called within an instance of the class. It will give the function pointer to the procedure specified by proc and null when the procedure cannot be found.
	// proc: The name of the procedure to call upon.
	// Returns: Will return null if the procedure cannot be found, otherwise it will return the address to this function.
	final void* getProc(string proc) {
		if (proc in _funcs) {
			return _funcs[proc];
		}

		// acquire the signature (or null)
		void* signature = SystemLoadLibraryProc(_pfvars, proc);

		// set in hash
		_funcs[proc] = signature;
		return signature;
	}

	final void*[string] _funcs;

	LibraryPlatformVars _pfvars;

public:
	// Description: This constructor will dynamically load the library found at the given framework path.
	// path: The path to the library in question.
	this(string path) {
		SystemLoadLibrary(_pfvars, path);
	}

	~this() {
		SystemFreeLibrary(_pfvars);
	}
}
