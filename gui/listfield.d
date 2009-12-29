/*
 * listfield.d
 *
 * This module implements a GUI drop-down list widget.
 *
 * Author: Dave Wilkinson
 *
 */

module gui.listfield;

import core.color;
import core.definitions;
import core.string;
import core.list;

import graphics.graphics;

import gui.widget;
import gui.window;
import gui.button;
import gui.listbox;

template ControlPrintCSTRList() {
	const char[] ControlPrintCSTRList = `
	this(int x, int y, int width, int height, Iterable!(String) list = null) {
		super(x,y,width,height,list);
	}
	`;
}

class ListFieldWindow : Window {
	this(uint width) {
		super("ListFieldPopup", WindowStyle.Popup, SystemColor.Window, 0,0,width,width / 2);
	}

	override void onLostFocus() {
		remove();
	}
}

// Section: Controls

// Description: This control provides a standard dropdown list selection box.
class ListField : Widget, Iterable!(String) {

	enum Signal : uint {
		Selected,
		Unselected
	}

	this(int x, int y, int width, int height, Iterable!(String) list = null) {
		super(x,y,width,height);

		_list = new List!(String)();
		if (list !is null) {
			foreach(item; list) {
				_list.add(item);
			}
		}
	}

	// handle events
	override void onAdd() {
		if (control_button is null) {
			control_button = new Button(this.right - this.height,this.top, this.height, this.height, "V");
			control_listbox = new ListBox(0,0, this.width,this.width / 2);
			control_window = new ListFieldWindow(this.width);

			if (_list !is null) {
				foreach(item; _list) {
					control_listbox.add(item);
				}
			}
			_list = null;
		}

		Graphics grp = _view.lockDisplay();
		_font = new Font(FontSans, 8, 400, false, false, false);
		grp.font = _font;
		grp.measureText(" ", 1, m_entryHeight);
		_view.unlockDisplay();

		m_clroutline = Color.fromRGB(0x80, 0x80, 0x80);
		m_clrhighlight = Color.fromRGB(0xdd,0xdd,0xdd);
		m_clrhighlighttext = Color.fromRGB(0xff,0xff,0xff);
		m_clrnormal = Color.fromRGB(0,0,0);
		m_clrbackground = Color.fromRGB(0xff,0xff,0xff);

		m_first_visible = 0;
		m_total_visible = 0;

		//normal state
		m_hoverstate = 0;

		//control_scroll.Bound(17, this.height);
		//control_scroll.Move(this.left+(this.width-17), this.top);

		m_total_visible = ((this.height+2) / m_entryHeight.y) + 1;

		// Add the Child Button, which will spawn the window and the list
		_window.push(control_button);

		control_button.enabled = false;
	}

	override void onRemove() {
		//control_button.remove();
	}

	override void onDraw(ref Graphics g) {
	//draw all entries

		ulong i;

		Rect rt;

		Brush brsh = new Brush(m_clrbackground);
		Pen pen = new Pen(m_clroutline);

		g.pen = pen;
		g.brush = brsh;

		g.drawRect(this.left, this.top, this.right, this.bottom);

		rt.left = this.left+1;
		rt.top = this.top+1;
		rt.right = this.right - control_button.width;
		rt.bottom = rt.top + m_entryHeight.y;
	}

	// List Methods

	void add(String data) {
		control_listbox.add(data);
	}

	void add(string data) {
		control_listbox.add(data);
	}

	void add(Iterable!(String) list) {
		control_listbox.add(list);
	}

	void add(String[] list) {
		control_listbox.add(list);
	}

	String remove() {
		return control_listbox.remove();
	}

	String removeAt(size_t idx){
		return control_listbox.removeAt(idx);
	}

	String peek() {
		return control_listbox.peek();
	}

	String peekAt(size_t idx) {
		return control_listbox.peekAt(idx);
	}

	void set(String c) {
		control_listbox.set(c);
	}

	void apply(String delegate(String) func) {
		control_listbox.apply(func);
	}

	bool contains(String c) {
		return control_listbox.contains(c);
	}

	bool empty() {
		return control_listbox.empty();
	}

	void clear() {
		control_listbox.clear();
	}

	String[] array() {
		return control_listbox.array();
	}

	List!(String) dup() {
		return control_listbox.dup();
	}

	List!(String) slice(size_t start, size_t end) {
		return control_listbox.slice(start, end);
	}

	List!(String) reverse() {
		return control_listbox.reverse();
	}

	size_t length() {
		return control_listbox.length();
	}

	String opIndex(size_t i1) {
		return control_listbox.opIndex(i1);
	}

	int opApply(int delegate(ref String) loopFunc) {
		return control_listbox.opApply(loopFunc);
	}

	int opApply(int delegate(ref size_t, ref String) loopFunc) {
		return control_listbox.opApply(loopFunc);
	}

	int opApplyReverse(int delegate(ref String) loopFunc) {
		return control_listbox.opApplyReverse(loopFunc);
	}

	int opApplyReverse(int delegate(ref size_t, ref String) loopFunc) {
		return control_listbox.opApplyReverse(loopFunc);
	}

	void opCatAssign(String[] list) {
		control_listbox.opCatAssign(list);
	}

	void opCatAssign(Iterable!(String) list) {
		control_listbox.opCatAssign(list);
	}

	void opCatAssign(String item) {
		control_listbox.opCatAssign(item);
	}

	Iterable!(String) opCat(String[] list) {
		return control_listbox.opCat(list);
	}

	Iterable!(String) opCat(Iterable!(String) list) {
		return control_listbox.opCat(list);
	}

	Iterable!(String) opCat(String item) {
		return control_listbox.opCat(item);
	}
protected:

	Font _font;

	Size m_entryHeight;

	ulong m_first_visible;
	ulong m_total_visible;
	ulong m_sel_start;

	Color m_clrnormal;
	Color m_clrhighlight;
	Color m_clrhighlighttext;
	Color m_clrbackground;
	Color m_clroutline;

	int m_hoverstate;

	Button control_button;
	ListBox control_listbox;
	Window control_window;

	List!(String) _list;
}
