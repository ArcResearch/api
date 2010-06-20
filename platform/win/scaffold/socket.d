/*
 * socket.d
 *
 * This file implements the Scaffold for platform specific Socket
 * operations in Windows.
 *
 * Author: Dave Wilkinson
 *
 */

module scaffold.socket;

pragma(lib, "WS2_32.lib");

import binding.win32.ws2def;
import binding.win32.winsock2;
import binding.win32.windef;
import binding.win32.winnt;

import platform.vars.socket;

import core.string;
import core.main;
import core.definitions;
import core.unicode;

//XXX: WS2tcpip.h

struct ADDRINFOW {
    int                 ai_flags;       // AI_PASSIVE, AI_CANONNAME, AI_NUMERICHOST
    int                 ai_family;      // PF_xxx
    int                 ai_socktype;    // SOCK_xxx
    int                 ai_protocol;    // 0 or IPPROTO_xxx for IPv4 and IPv6
    size_t              ai_addrlen;     // Length of ai_addr
    PWSTR               ai_canonname;   // Canonical name for nodename
    sockaddr*   ai_addr;        // Binary address
    ADDRINFOW*  ai_next;        // Next structure in linked list
}

alias ADDRINFOW* PADDRINFOW;
extern(System)
INT GetAddrInfoW(
    PCWSTR              pNodeName,
    PCWSTR              pServiceName,
    ADDRINFOW *   pHints,
    PADDRINFOW *        ppResult
    );

// SOCKET

bool SocketOpen(ref SocketPlatformVars sockVars, ref string hostname, ref ushort port)
{
	WSADATA wsaData;
	int iResult;

	if (!sockVars.inited)
	{
		iResult = WSAStartup((2 | (2 << 8)), &wsaData);

		if (!iResult)
		{
			sockVars.inited = true;
		}
		else
		{
			//Console.putln("wsastartup, error");
			return false;
		}
	}

	ADDRINFOW *result = null;
	ADDRINFOW *ptr = null;
	ADDRINFOW hints = ADDRINFOW.init;
	ptr = &hints;

	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;

	//OutputDebugStringA("getaddr start\n");

	wstring portstr = Unicode.toUtf16(toStr(port));

	wstring hname = Unicode.toUtf16(hostname);
	hname ~= '\0';

	iResult = GetAddrInfoW(hname.ptr, portstr.ptr, &hints, &result);

	//OutputDebugStringA("getaddr done\n");

	if (iResult)
	{
		//file an error event
		//Console.putln("getaddrinfow, error");
		return false;
	}

	sockVars.m_skt = INVALID_SOCKET;

//	sockVars.m_skt = socket(result.ai_family, result.ai_socktype, result.ai_protocol);
	sockVars.m_skt = socket(result.ai_family, result.ai_socktype, result.ai_protocol);

	if (sockVars.m_skt == INVALID_SOCKET)
	{
		//file an error event
		if (sockVars.init_ref == 0)
			{ WSACleanup(); }

		//Console.putln("socket, error");
		return false;
	}

	iResult = connect(sockVars.m_skt, result.ai_addr, result.ai_addrlen);
	if (iResult == SOCKET_ERROR)
	{
		//file an error event
		closesocket(sockVars.m_skt);
		sockVars.m_skt = INVALID_SOCKET;
		if (sockVars.init_ref == 0)
		{
			WSACleanup();
		}
		//Console.putln("connect, error");

		return false;
	}

	sockVars.init_ref++;

	return true;
}

bool SocketBind(ref SocketPlatformVars sockVars, ref ushort port)
{
	WSADATA wsaData;
	int iResult;

	if (!sockVars.inited)
	{
		iResult = WSAStartup((2 | (2 << 8)), &wsaData);

		if (!iResult)
		{
			sockVars.inited = true;
		}
		else
		{
			return false;
		}
	}

	if (iResult)
	{
		//file an error event
		return false;
	}

	sockVars.m_bind_skt = INVALID_SOCKET;

	sockVars.m_bind_skt = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

	if (sockVars.m_bind_skt == INVALID_SOCKET)
	{
		//file an error event
		if (sockVars.init_ref == 0){ WSACleanup(); }

		return false;
	}

	sockaddr_in service;
	service.sin_family = AF_INET;
	service.sin_addr.s_addr = inet_addr(cast(char *)("127.0.0.1".ptr));
	service.sin_port = htons(27015);

	iResult = bind(sockVars.m_bind_skt, cast(sockaddr*)&service, service.sizeof);
	if (iResult == SOCKET_ERROR)
	{
		//file an error event
		closesocket(sockVars.m_bind_skt);
		sockVars.m_bind_skt = INVALID_SOCKET;
		if (sockVars.init_ref == 0)
		{
			WSACleanup();
		}

		return false;
	}

	sockVars.init_ref++;

	return true;
}

bool SocketListen(ref SocketPlatformVars sockVars)
{
	if (listen(sockVars.m_bind_skt, 16) == SOCKET_ERROR)
	{
		return false;
	}

	return true;
}

bool SocketAccept(ref SocketPlatformVars sockVars)
{
	if ((sockVars.m_skt = accept(sockVars.m_bind_skt, null, null)) == SOCKET_ERROR)
	{
		return false;
	}

	return true;
}

void SocketClose(ref SocketPlatformVars sockVars)
{
	closesocket(sockVars.m_skt);

	if (sockVars.init_ref <= 1 && sockVars.inited)
	{
		sockVars.init_ref = 0;
		WSACleanup();

		sockVars.inited = false;
	}
	else
	{
		sockVars.init_ref--;
	}
}

bool SocketRead(ref SocketPlatformVars sockVars, ubyte* buffer, ulong len)
{
	ulong progress = 0;
	ulong ret = 0;
	ulong amt = len;

	int cur_amt;

	ubyte* cur = buffer;

	while (progress < len)
	{
		cur_amt = cast(int)(amt & 0x7FFFFFFF);
		ret = recv(sockVars.m_skt, cur, cur_amt, 0);

		if (ret == SOCKET_ERROR) { return false; }

		progress += ret;
		amt -= ret;
		cur += ret;

		if (ret <= 0) { return false; }
	}

	return true;
}

ulong SocketReadAvailable(ref SocketPlatformVars sockVars, ubyte* buffer, ulong len)
{
	//ulong total = recv(sockVars.m_skt, null, 0, MSG_PEEK);

	//if (total == 0) { return 0; }

	int cur_amt = cast(int)(len & 0x7FFFFFFF);
	long ret = recv(sockVars.m_skt, buffer, cur_amt, 0);

	if (ret < 0)
	{
		// error
		return 0;
	}

	return cast(ulong)ret;
}

bool SocketWrite(ref SocketPlatformVars sockVars, ubyte* buffer, ulong len)
{
	ulong progress = 0;
	ulong ret = 0;
	ulong amt = len;

	int cur_amt;

	ubyte* cur = buffer;

	while (progress < len)
	{
		cur_amt = cast(int)(amt & 0x7FFFFFFF);

		ret = send(sockVars.m_skt, cur, cur_amt, 0);
		progress += ret;
		amt -= ret;
		cur += ret;

		if (ret == 0) { return false; }
	}

	return true;
}

