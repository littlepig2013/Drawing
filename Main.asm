TITLE DrawingTool Application

.386 
.model flat,stdcall 
option casemap:none

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD

INCLUDE windows.inc
INCLUDE user32.inc
INCLUDE kernel32.inc
INCLUDE gdi32.inc

INCLUDELIB user32.lib
INCLUDELIB kernel32.lib
INCLUDELIB gdi32.lib

;======================== DATA ========================
.data

; ���ֱ��
IDM_OPT1  dw 301
IDM_OPT2  dw 302
IDM_OPT3  dw 303
IDM_OPT4  dw 304

IDM_DRAW  dw 401
IDM_ERASE dw 402

IDB_ONE   dw 3301
IDB_TWO   dw 3302
IDB_THREE dw 3303

; �˵��ַ���
fileMenuStr db "�ļ�", 0
newMenuStr db "�½�", 0
loadMenuStr db "����", 0
saveMenuStr db "����", 0
saveAsMenuStr db "���Ϊ", 0

fileMenuStr1 db "��ͼ", 0
drawMenuStr db "��ͼ", 0
eraseMenuStr db "����", 0

; ��ť�ַ���
lineButtonStr db "ֱ��", 0

; �����Լ�������
className db "DrawingWinClass", 0
appName db "��ͼ", 0

; ����ȱ���
hInstance HINSTANCE ?
hMenu HMENU ?
commandLine LPSTR ?

; ����
buttonStr db "Button", 0
beginX dd 0
beginY dd 0
endX dd 0
endY dd 0

curX dd 0
curY dd 0

pointX dd 0
pointY dd 0
drawingFlag db 0
erasingFlag db 0
; ��ͼ/����ģʽ
mode db 0

; ��������
workRegion RECT <0, 0, 800, 600>

; �ṹ�嶨��
PAINTDATA STRUCT
	ptBeginX dd ?
	ptBeginY dd ?
	ptEndX   dd ?
	ptEndY   dd ?
	penStyle dd ?
PAINTDATA ENDS

;======================== CODE ========================
.code

start:
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	INVOKE GetCommandLine
	mov commandLine, eax
	INVOKE WinMain, hInstance, NULL, commandLine, SW_SHOWDEFAULT
	INVOKE ExitProcess, eax

; �����˵�
createMenu PROC
	LOCAL popFile: HMENU
	LOCAL popFile1: HMENU

	INVOKE CreateMenu
	.IF eax == 0
		ret
	.ENDIF
	mov hMenu, eax

	INVOKE CreatePopupMenu
	mov popFile, eax

	INVOKE CreatePopupMenu
	mov popFile1, eax
	
	INVOKE AppendMenu, hMenu, MF_POPUP, popFile, ADDR fileMenuStr

	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT1, ADDR newMenuStr
	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT2, ADDR loadMenuStr
	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT3, ADDR saveMenuStr
	INVOKE AppendMenu, popFile, MF_STRING, IDM_OPT4, ADDR saveAsMenuStr

	INVOKE AppendMenu, hMenu, MF_POPUP, popFile1, ADDR fileMenuStr1
	
	INVOKE AppendMenu, popFile1, MF_STRING, IDM_DRAW, ADDR drawMenuStr
	INVOKE AppendMenu, popFile1, MF_STRING, IDM_ERASE, ADDR eraseMenuStr

	ret

createMenu ENDP

; ������ť
createButtons PROC,
	hWnd: HWND
	
	;INVOKE CreateWindowEx, NULL, ADDR buttonStr, ADDR lineButtonStr, WS_VISIBLE or WS_CHILD or BS_PUSHBUTTON, 35, 10, 80, 30, hWnd, IDB_ONE, hInstance, NULL

	ret

createButtons ENDP

WinMain PROC,
	hInst: HINSTANCE, hPrevInst: HINSTANCE, CmdLine: LPSTR, CmdShow: DWORD
	LOCAL wc: WNDCLASSEX
	LOCAL msg: MSG
	LOCAL hwnd: HWND

	INVOKE createMenu
	mov wc.cbSize, SIZEOF WNDCLASSEX
	mov wc.style, CS_HREDRAW or CS_VREDRAW
	mov wc.lpfnWndProc, OFFSET WndProc
	mov wc.cbClsExtra, NULL
	mov wc.cbWndExtra, NULL
	push hInst
	pop wc.hInstance
	mov wc.hbrBackground, COLOR_WINDOW+1
	mov wc.lpszMenuName, NULL
	mov wc.lpszClassName, OFFSET className
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov wc.hIcon, eax
	mov wc.hIconSm, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor, eax
	INVOKE RegisterClassEx, ADDR wc
	INVOKE CreateWindowEx, NULL, ADDR className, ADDR appName, \
		WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, \
		CW_USEDEFAULT, 800, 600, NULL, hMenu, \
		hInst, NULL
	mov hwnd, eax
	INVOKE ShowWindow, hwnd, SW_SHOWNORMAL
	INVOKE UpdateWindow, hwnd
	.WHILE TRUE
		INVOKE GetMessage, ADDR msg, NULL, 0, 0
		.BREAK .IF (!eax)
			INVOKE TranslateMessage, ADDR msg
		INVOKE DispatchMessage, ADDR msg
	.ENDW
	mov eax, msg.wParam
	ret
WinMain ENDP

WndProc PROC USES ebx ecx edx,
	hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM
	LOCAL hdc: HDC
	LOCAL ps: PAINTSTRUCT
	LOCAL rect: RECT
	LOCAL lowordWParam: WORD
	LOCAL p: POINT

	.IF uMsg == WM_DESTROY
		INVOKE PostQuitMessage, NULL
	.ELSEIF uMsg == WM_CREATE
		INVOKE createButtons, hWnd
	.ELSEIF uMsg == WM_COMMAND	; ��Ӧ�¼�
		mov ebx, wParam
		.IF bx == IDB_ONE
			;INVOKE ShowWindow, hWnd, SW_HIDE
		.ELSEIF bx == IDM_DRAW  ; ��ͼģʽ
			mov mode,0
		.ELSEIF bx == IDM_ERASE ; ����ģʽ
			mov mode,1
		.ENDIF
	.ELSEIF uMsg == WM_MOUSEMOVE
		mov ebx, lParam
		mov edx, 0
		mov dx, bx
		sar ebx, 16

		mov curX, edx
		mov curY, ebx
		.IF mode == 0    ;drawing mode
			.IF drawingFlag == 1
				.IF endX == 0
					mov beginX, edx
				.ELSE
					mov eax, endX
					mov beginX, eax
				.ENDIF

				.IF endY == 0
					mov beginY, ebx
				.ELSE
					mov eax, endY
					mov beginY, eax
				.ENDIF

				mov endX, edx
				mov endY, ebx
				INVOKE InvalidateRect, hWnd, ADDR workRegion, 0
			.ENDIF
		.ENDIF

		.IF mode == 1 ; Erasing mode
			INVOKE InvalidateRect, hWnd, ADDR workRegion, 0

		.ENDIF
		
	.ELSEIF uMsg == WM_LBUTTONDOWN
		mov drawingFlag, 1
		mov erasingFlag, 1
	.ELSEIF uMsg == WM_LBUTTONUP
		mov drawingFlag, 0
		mov erasingFlag, 0
		mov beginX, 0
		mov beginY, 0
		mov endX, 0
		mov endY, 0
	.ELSEIF uMsg == WM_PAINT
		INVOKE BeginPaint, hWnd, ADDR ps
		.IF mode == 0
			; ebx = pen
			;INVOKE CreatePen, PS_SOLID, 1, 0
			;mov ebx, eax
			INVOKE MoveToEx, ps.hdc, beginX, beginY, NULL
			INVOKE LineTo, ps.hdc, endX, endY
			;INVOKE DeleteObject, ebx
		.ENDIF
		.IF mode == 1
			.IF erasingFlag == 1
				;INVOKE RGB,0,0,0
				;INVOKE SetDCBrushColor, ps.hdc, 0
				INVOKE GetStockObject, NULL_PEN
				INVOKE SelectObject, ps.hdc, eax
				sub curX, 10
				sub curY, 10
				mov ebx, curX
				mov edx, curY
				add ebx, 20
				add edx, 20
				
				INVOKE Rectangle, ps.hdc, curX, curY, ebx, edx
			.ENDIF
		.ENDIF

		INVOKE EndPaint, hWnd, ADDR ps
	.ELSE
		INVOKE DefWindowProc, hWnd, uMsg, wParam, lParam
		ret
	.ENDIF

	xor eax, eax
	ret
WndProc ENDP

end start
