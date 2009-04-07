module platform.win.scaffolds.graphics;

import core.view;

import bases.window;
import core.window;
import platform.win.main;
import core.string;
import core.file;
import core.graphics;
import core.color;
import graphics.region;

import core.main;

import core.definitions;

import core.string;

import platform.win.common;
import platform.win.definitions;
import platform.win.vars;



// Shapes

// Draw a line
void drawLine(ViewPlatformVars* viewVars, int x, int y, int x2, int y2)
{
	MoveToEx(viewVars.dc, x, y, null);

	LineTo(viewVars.dc, x2, y2);
}

// Draw a rectangle (filled with the current brush, outlined with current pen)
void drawRect(ViewPlatformVars* viewVars, int x, int y, int x2, int y2)
{
	Rectangle(viewVars.dc, x, y, x2, y2);
}

// Draw an ellipse (filled with current brush, outlined with current pen)
void drawOval(ViewPlatformVars* viewVars, int x, int y, int x2, int y2)
{
	Ellipse(viewVars.dc, x, y, x2, y2);
}





// Text
void drawText(ViewPlatformVars* viewVars, int x, int y, String str)
{
	TextOutW(viewVars.dc, x, y, str.ptr, str.length);
}

void drawText(ViewPlatformVars* viewVars, int x, int y, StringLiteral str)
{
	TextOutW(viewVars.dc, x, y, str.ptr, str.length);
}

void drawText(ViewPlatformVars* viewVars, int x, int y, String str, uint length)
{
	TextOutW(viewVars.dc, x, y, str.ptr, length);
}

void drawText(ViewPlatformVars* viewVars, int x, int y, StringLiteral str, uint length)
{
	TextOutW(viewVars.dc, x, y, str.ptr, length);
}

void drawTextPtr(ViewPlatformVars* viewVars, int x, int y, Char* str, uint length)
{
	TextOutW(viewVars.dc, x, y, str, length);
}

// Clipped Text
void drawClippedText(ViewPlatformVars* viewVars, int x, int y, Rect region, String str)
{
	ExtTextOutW(viewVars.dc, x,y, ETO_CLIPPED, cast(RECT*)&region, str.ptr, str.length, null);
}

void drawClippedText(ViewPlatformVars* viewVars, int x, int y, Rect region, StringLiteral str)
{
	ExtTextOutW(viewVars.dc, x,y, ETO_CLIPPED, cast(RECT*)&region, str.ptr, str.length, null);
}

void drawClippedText(ViewPlatformVars* viewVars, int x, int y, Rect region, String str, uint length)
{
	ExtTextOutW(viewVars.dc, x,y, ETO_CLIPPED, cast(RECT*)&region, str.ptr, length, null);
}

void drawClippedText(ViewPlatformVars* viewVars, int x, int y, Rect region, StringLiteral str, uint length)
{
	ExtTextOutW(viewVars.dc, x,y, ETO_CLIPPED, cast(RECT*)&region, str.ptr, length, null);
}

void drawClippedTextPtr(ViewPlatformVars* viewVars, int x, int y, Rect region, Char* str, uint length)
{
	ExtTextOutW(viewVars.dc, x,y, ETO_CLIPPED, cast(RECT*)&region, str, length, null);
}

// Text Measurement
void measureText(ViewPlatformVars* viewVars, String str, out Size sz)
{
	GetTextExtentPoint32W(viewVars.dc, str.ptr, str.length, cast(SIZE*)&sz);
}

void measureText(ViewPlatformVars* viewVars, String str, uint length, out Size sz)
{
	GetTextExtentPoint32W(viewVars.dc, str.ptr, length, cast(SIZE*)&sz);
}

void measureText(ViewPlatformVars* viewVars, StringLiteral str, out Size sz)
{
	GetTextExtentPoint32W(viewVars.dc, str.ptr, str.length, cast(SIZE*)&sz);
}

void measureText(ViewPlatformVars* viewVars, StringLiteral str, uint length, out Size sz)
{
	GetTextExtentPoint32W(viewVars.dc, str.ptr, length, cast(SIZE*)&sz);
}

void measureTextPtr(ViewPlatformVars* viewVars, Char* str, uint length, out Size sz)
{
	GetTextExtentPoint32W(viewVars.dc, str, length, cast(SIZE*)&sz);
}

// Text Colors
void setTextBackgroundColor(ViewPlatformVars* viewVars, ref Color textColor)
{
	SetBkColor(viewVars.dc, ColorGetValue(textColor));
}

void setTextColor(ViewPlatformVars* viewVars, ref Color textColor)
{
	platform.win.common.SetTextColor(viewVars.dc, ColorGetValue(textColor));
}

// Text States

void setTextModeTransparent(ViewPlatformVars* viewVars)
{
	SetBkMode(viewVars.dc, TRANSPARENT);
}

void setTextModeOpaque(ViewPlatformVars* viewVars)
{
	SetBkMode(viewVars.dc, OPAQUE);
}




// Fonts

void createFont(FontPlatformVars* font, StringLiteral fontname, int fontsize, int weight, bool italic, bool underline, bool strikethru)
{
	String s = new String(fontname ~ cast(Char)'\0');
	HDC dcz = GetDC(cast(HWND)0);
	font.fontHandle = CreateFontW(-MulDiv(fontsize, GetDeviceCaps(dcz, 90), 72),0,0,0, weight, italic, underline, strikethru, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, DEFAULT_PITCH, s.ptr);
	ReleaseDC(cast(HWND)0, dcz);
}

void createFont(FontPlatformVars* font, String fontname, int fontsize, int weight, bool italic, bool underline, bool strikethru)
{
	fontname = new String(fontname);
	fontname.appendChar('\0');
	HDC dcz = GetDC(cast(HWND)0);
	font.fontHandle = CreateFontW(-MulDiv(fontsize, GetDeviceCaps(dcz, 90), 72),0,0,0, weight, italic, underline, strikethru, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, PROOF_QUALITY, DEFAULT_PITCH, fontname.ptr);
	ReleaseDC(cast(HWND)0, dcz);
}

void setFont(ViewPlatformVars* viewVars, FontPlatformVars* font)
{
	SelectObject(viewVars.dc, font.fontHandle);
}

void destroyFont(FontPlatformVars* font)
{
	DeleteObject(font.fontHandle);
}


// Brushes

void createBrush(BrushPlatformVars* brush, ref Color clr)
{
	brush.brushHandle = CreateSolidBrush(ColorGetValue(clr) & 0xFFFFFF);
}

void setBrush(ViewPlatformVars* viewVars, BrushPlatformVars* brush)
{
	SelectObject(viewVars.dc, brush.brushHandle);
}
void destroyBrush(BrushPlatformVars* brush)
{
	DeleteObject(brush.brushHandle);
}

// Pens

void createPen(PenPlatformVars* pen, ref Color clr)
{
	pen.penHandle = platform.win.common.CreatePen(0,1,ColorGetValue(clr) & 0xFFFFFF);
}

void setPen(ViewPlatformVars* viewVars, PenPlatformVars* pen)
{
	SelectObject(viewVars.dc, pen.penHandle);
}

void destroyPen(PenPlatformVars* pen)
{
	DeleteObject(pen.penHandle);
}





// View Interfacing

void drawView(ref ViewPlatformVars* viewVars, ref View view, int x, int y, ref ViewPlatformVars* viewVarsSrc, ref View srcView)
{
	static const BLENDFUNCTION bf = { AC_SRC_OVER, 0, 0xFF, AC_SRC_ALPHA };

	if (srcView.getAlphaFlag())
	{
		uint viewWidth = srcView.getWidth();
		uint viewHeight = srcView.getHeight();
		if (x + viewWidth > view.getWidth())
		{
			viewWidth = view.getWidth() - x;
		}

		if (y + viewHeight > view.getHeight())
		{
			viewHeight = view.getHeight() - y;
		}
		AlphaBlend(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, 0,0, viewWidth, viewHeight, bf);
	}
	else
	{
		BitBlt(viewVars.dc, x, y, srcView.getWidth(), srcView.getHeight(), viewVarsSrc.dc, 0,0,SRCCOPY);
	}
}

void drawView(ref ViewPlatformVars* viewVars, ref View view, int x, int y, ref ViewPlatformVars* viewVarsSrc, ref View srcView, int viewX, int viewY)
{
	static const BLENDFUNCTION bf = { AC_SRC_OVER, 0, 0xFF, AC_SRC_ALPHA };

	if (srcView.getAlphaFlag())
	{
		uint viewWidth = srcView.getWidth();
		uint viewHeight = srcView.getHeight();
		if (x + viewWidth > view.getWidth())
		{
			viewWidth = view.getWidth() - x;
		}

		if (y + viewHeight > view.getHeight())
		{
			viewHeight = view.getHeight() - y;
		}

		if (viewX + viewWidth > srcView.getWidth())
		{
			viewWidth = srcView.getWidth() - viewX;
		}

		if (viewY + viewHeight > srcView.getHeight())
		{
			viewHeight = srcView.getHeight() - viewY;
		}
		AlphaBlend(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, viewX,viewY,viewWidth, viewHeight, bf);
	}
	else
	{
		BitBlt(viewVars.dc, x, y, srcView.getWidth(), srcView.getHeight(), viewVarsSrc.dc, viewX,viewY,SRCCOPY);
	}
}

void drawView(ref ViewPlatformVars* viewVars, ref View view, int x, int y, ref ViewPlatformVars* viewVarsSrc, ref View srcView, int viewX, int viewY, int viewWidth, int viewHeight)
{
	static const BLENDFUNCTION bf = { AC_SRC_OVER, 0, 0xFF, AC_SRC_ALPHA };

	if (srcView.getAlphaFlag())
	{
		if (viewWidth > srcView.getWidth())
		{
			viewWidth = srcView.getWidth();
		}

		if (viewHeight > srcView.getHeight())
		{
			viewHeight = srcView.getHeight();
		}

		if (x + viewWidth > view.getWidth())
		{
			viewWidth = view.getWidth() - x;
		}

		if (y + viewHeight > view.getHeight())
		{
			viewHeight = view.getHeight() - y;
		}

		if (viewX + viewWidth > srcView.getWidth())
		{
			viewWidth = srcView.getWidth() - viewX;
		}

		if (viewY + viewHeight > srcView.getHeight())
		{
			viewHeight = srcView.getHeight() - viewY;
		}
		AlphaBlend(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, viewX,viewY,viewWidth, viewHeight, bf);
	}
	else
	{
		BitBlt(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, viewX,viewY,SRCCOPY);
	}
}

void drawView(ref ViewPlatformVars* viewVars, ref View view, int x, int y, ref ViewPlatformVars* viewVarsSrc, ref View srcView, double opacity)
{
	static BLENDFUNCTION bf = { AC_SRC_OVER, 0, 0xFF, AC_SRC_ALPHA };

	bf.SourceConstantAlpha = cast(ubyte)(opacity * 255.0);


	uint viewWidth = srcView.getWidth();
	uint viewHeight = srcView.getHeight();
	if (x + viewWidth > view.getWidth())
	{
		viewWidth = view.getWidth() - x;
	}

	if (y + viewHeight > view.getHeight())
	{
		viewHeight = view.getHeight() - y;
	}
	AlphaBlend(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, 0,0,viewWidth, viewHeight, bf);
}

void drawView(ref ViewPlatformVars* viewVars, ref View view, int x, int y, ref ViewPlatformVars* viewVarsSrc, ref View srcView, int viewX, int viewY, double opacity)
{
	static BLENDFUNCTION bf = { AC_SRC_OVER, 0, 0xFF, AC_SRC_ALPHA };

	bf.SourceConstantAlpha = cast(ubyte)(opacity * 255.0);

	uint viewWidth = srcView.getWidth();
	uint viewHeight = srcView.getHeight();
	if (x + viewWidth > view.getWidth())
	{
		viewWidth = view.getWidth() - x;
	}

	if (y + viewHeight > view.getHeight())
	{
		viewHeight = view.getHeight() - y;
	}

	if (viewX + viewWidth > srcView.getWidth())
	{
		viewWidth = srcView.getWidth() - viewX;
	}

	if (viewY + viewHeight > srcView.getHeight())
	{
		viewHeight = srcView.getHeight() - viewY;
	}
	AlphaBlend(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, viewX,viewY,viewWidth, viewHeight, bf);
}

void drawView(ref ViewPlatformVars* viewVars, ref View view, int x, int y, ref ViewPlatformVars* viewVarsSrc, ref View srcView, int viewX, int viewY, int viewWidth, int viewHeight, double opacity)
{
	static BLENDFUNCTION bf = { AC_SRC_OVER, 0, 0xFF, AC_SRC_ALPHA };

	bf.SourceConstantAlpha = cast(ubyte)(opacity * 255.0);

	if (viewWidth > srcView.getWidth())
	{
		viewWidth = srcView.getWidth();
	}

	if (viewHeight > srcView.getHeight())
	{
		viewHeight = srcView.getHeight();
	}

	if (x + viewWidth > view.getWidth())
	{
		viewWidth = view.getWidth() - x;
	}

	if (y + viewHeight > view.getHeight())
	{
		viewHeight = view.getHeight() - y;
	}

	if (viewX + viewWidth > srcView.getWidth())
	{
		viewWidth = srcView.getWidth() - viewX;
	}

	if (viewY + viewHeight > srcView.getHeight())
	{
		viewHeight = srcView.getHeight() - viewY;
	}

	AlphaBlend(viewVars.dc, x, y, viewWidth, viewHeight, viewVarsSrc.dc, viewX,viewY,viewWidth, viewHeight, bf);
}

void clipSave(ViewPlatformVars* viewVars)
{
	if (viewVars.clipRegions.length == 0)
	{
		viewVars.clipRegions.addItem(null);
	}
	else
	{
		HRGN rgn = CreateRectRgn(0,0,0,0);

		GetClipRgn(viewVars.dc, rgn);

		viewVars.clipRegions.addItem(rgn);
	}
}

void clipRestore(ViewPlatformVars* viewVars)
{
	HRGN rgn;

	if (viewVars.clipRegions.remove(rgn))
	{
		SelectClipRgn(viewVars.dc, rgn);

		DeleteObject(rgn);
	}
}

void clipRect(ViewPlatformVars* viewVars, int x, int y, int x2, int y2)
{
	HRGN rgn = CreateRectRgn(x,y,x2,y2);

	ExtSelectClipRgn(viewVars.dc, rgn, RGN_AND);

	DeleteObject(rgn);
}

void clipRegion(ViewPlatformVars* viewVars, Region region)
{
}