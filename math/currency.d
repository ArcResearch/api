/*
 * currency.d
 *
 * This module implements a data type for storing an amount of currency.
 *
 * Author: Dave Wilkinson
 * Originated: September 20th, 2009
 *
 */

module math.currency;

import math.fixed;

import djehuty;

class Currency : Fixed {
	this(long whole, long scale) {
		super(whole, scale);
	}

	this(double value) {
		super(value);
	}

	// This function will provide a string for the currency value rounded to 2 decimal points
	override string toString() {
		return Locale.formatCurrency(_whole, _scale);
	}
}
