module gui.osbutton;

import gui.button;

import binding.win32.windef;
import binding.win32.winnt;
import binding.win32.winbase;
import binding.win32.wingdi;
import binding.win32.winuser;

import platform.win.widget;
import platform.win.main;

import platform.vars.view;

import core.string;
import core.definitions;

import gui.widget;
import gui.window;
import gui.apploop;

import io.console;

import graphics.view;
import graphics.graphics;

class OSButton : Button, WinWidget {

	this(int x, int y, int width, int height, string value) {
		super(x,y,width,height,value);
	}

	override void onAdd() {

		ViewPlatformVars* viewVars = _window._viewVars;

		HDC dc = GetDC(_hWnd);

		HDC dc2 = CreateCompatibleDC(dc);
		HBITMAP hbmp = CreateCompatibleBitmap(viewVars.dc, this.width, this.height);

		SelectObject(dc2, hbmp);

		DeleteObject(hbmp);
		ReleaseDC(_hWnd, dc);

		newx = -this.width + 1;
		newy = -this.height + 1;
		_hdc = dc2;

		_hWnd = CreateWindowExW(0,
			"BUTTON\0", cast(wchar*)_value.ptr, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_TEXT ,
			newx, newy, this.width, this.height,
			_window._pfvars.hWnd, null, cast(HINSTANCE)GetWindowLongW(_window._pfvars.hWnd,GWLP_HINSTANCE), null);

		SetWindowPos(_hWnd, cast(HWND)HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE);

		SendMessageW( _hWnd, WM_SETFONT, cast(WPARAM)GuiApplicationController.win_button_font, 1);

		SetWindowLongW(_hWnd, GWLP_USERDATA, cast(LONG)(cast(void*)(cast(WinWidget)this)));
		_oldproc = cast(WNDPROC)SetWindowLongW(_hWnd, GWLP_WNDPROC, cast(ULONG)&GuiApplicationController.CtrlProc);

		SendMessageW(_hWnd, WM_PRINTCLIENT, cast(DWORD)_hdc, PRF_CHILDREN | PRF_CLIENT | PRF_ERASEBKGND | PRF_NONCLIENT | PRF_OWNED);
	}

	override void onDraw(ref Graphics g) {
		// save current background for later

		// copy over current image
		ViewPlatformVars* viewVars = _window._viewVars;

		BitBlt(viewVars.dc, this.left, this.top, this.width, this.height, _hdc, 0,0,SRCCOPY);
	}

	override bool onPrimaryMouseDown(ref Mouse mouse) {
		hasCapture = true;

		SendMessageW(_hWnd, WM_LBUTTONDOWN, 0, 0);
		return true;
	}

	override bool onPrimaryMouseUp(ref Mouse mouse) {
		hasCapture = false;

		SendMessageW(_hWnd, WM_LBUTTONUP, 0, 0);
		requestRelease();
		return true;
	}

	override bool onMouseEnter() {
		return false;
	}

	override bool onMouseMove(ref Mouse mouse) {

		if (hasCapture) {
			return false;
		}

		POINT pt;
		GetCursorPos(&pt);

		RECT rect;
		RECT client;

		int ncx, ncy;

		GetWindowRect(_window._pfvars.hWnd, &rect);
		ncx = rect.left;
		ncy = rect.top;

		ncx = pt.x + (newx - this.left);
		ncy = pt.y + (newy - this.top);

		ncy &= 0xffff;
		ncx &= 0xffff;

		uint lparam = (ncy << 16) | (ncx);
		SendMessageW(_hWnd, WM_NCHITTEST, 0, lparam);

		lparam = ((mouse.y - this.top) << 16) | (mouse.x - this.left);

		SendMessageW(_hWnd, WM_MOUSEMOVE, 0, lparam);
		SendMessageW(_hWnd, WM_PAINT, 0, 0);
		//SendMessageW(_hWnd, WM_MOUSEHOVER, 0, lparam);
		return false;
	}

	override bool onMouseLeave() {
	//	Console.putln("mouseleave");
		SendMessageW(_hWnd, WM_MOUSELEAVE, 0, 0);
		return true;
	}

	override void onRemove() {
		DestroyWindow(_hWnd);
	}

protected:

	HDC _GetDC() {
		return _hdc;
	}

	LRESULT _AppLoopMessage(uint message, WPARAM wParam, LPARAM lParam) {
	//	Console.putln("message: ", new String("%x",message), " ml:", new String("%x", WM_MOUSELEAVE));
		if (message == WM_COMMAND) {
			raiseSignal(Button.Signal.Selected);
			return 0;
		}
		else if (message == WM_LBUTTONUP && hasCapture) {
			short x, y;
			x = cast(short)(lParam & 0xffff);
			y = cast(short)((lParam >> 16) & 0xffff);

			// convert coords to window coords, send window WM_MOUSEMOVE
			x += newx; //this.left;
			y += newy;
			uint windowlParam = (y << 16) | x;
			x = cast(short)(lParam & 0xffff);
			y = cast(short)((lParam >> 16) & 0xffff);
//			Console.putln("mouse up (captured) x:", x, "y:",y);
			SendMessageW(_window._pfvars.hWnd, message, 0, windowlParam);
		}
		else if (message == WM_MOUSELEAVE) {
			// ignore!
			if (_hovered) {
				//Console.putln("message ignored");
			return 0;
			}
			else {
				//Console.putln("message meh!");
			}
		}
		else if (message == WM_NCHITTEST || message == WM_MOUSEMOVE) {
			// change wParam to point to where it thinks it is

			short x, y;
			x = cast(short)(lParam & 0xffff);
			y = cast(short)((lParam >> 16) & 0xffff);

			if (message == WM_NCHITTEST) {
				//Console.put("HT ");
			}
			else {
				//Console.put("MM ");
			}
			//Console.putln("x: ", x, " y: ", y);

			if (hasCapture) {
				// convert coords to window coords, send window WM_MOUSEMOVE
				x += newx; //this.left;
				y += newy;
				uint windowlParam = (y << 16) | x;
				x = cast(short)(lParam & 0xffff);
				y = cast(short)((lParam >> 16) & 0xffff);
			//	Console.putln("mouse move (captured) x:", x, "y:",y);
				SendMessageW(_window._pfvars.hWnd,WM_MOUSEMOVE, 0, windowlParam);
			}
			else {
				//Console.putln("mouse move");
			}

			if (message == WM_MOUSEMOVE) {
				if (_hovered) {
				//	Console.putln("hovered");
					x += (newx - this.left);
					y += (newy - this.top);
					lParam = (y << 16) | x;
				}
				else {
					//Console.putln("not hovered");
				}
			}

//			Console.putln("x: ", x, " y: ", y, " msg: ", new String("%x",message));

		}
		else if (message == WM_ERASEBKGND) {
		}

		auto ret = CallWindowProcW(_oldproc, _hWnd, message, wParam, lParam);
		
		//Console.putln("return: ", ret);

		if (message == WM_PAINT) {
			_window.onDraw();
		}

		return ret;
	}

	View _ReturnView(out int x, out int y, out int w, out int h) {
		x = this.left;
		y = this.top;
		w = this.width;
		h = this.height;
		return _view;
	}

	HWND _hWnd;
	HDC _hdc;
	WNDPROC _oldproc;

	bool noDraw;

	bool hasCapture;

	int newy;
	int newx;
}
