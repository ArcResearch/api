/*
 * exception.d
 *
 * This module implements the Exception base class and the runtime functions.
 *
 */

module runtime.exception;

// Description: This class represents a recoverable failure.
class Exception : Object {
	char[] msg;

	// Description: Will construct an Exception with the given descriptive message.
	this(char[] msg) {
		this.msg = msg;
	}

	char[] toString() {
		return msg;
	}
}

extern(C):

void onFinalizeError(ClassInfo ci, Exception ex) {
}

void onOutOfMemoryError() {
	throw cast(OutOfMemoryException)cast(void*)OutOfMemoryException.classinfo.init;
}

void _d_throw_exception(Object e) {
}
