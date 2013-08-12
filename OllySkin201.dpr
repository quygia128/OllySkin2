Library OllySkin201;

(*
- Plugin Name:
  .OllySkin v1.10 by maluc power by MASM32
  .OllySkin v2.01 by quygia128 power by Delphi
- Email: quygia128@gmail.com
- Date: 07.29.2013
- Credits to KSDev's develop & maluc & TQN & phpbb3 & BOB
- In OD2 - hexedittext not appear in register menu when apply skin , Sh!t
- This for fun only (and as an example of plugins for OD2) - not for use
*)

Uses
  Windows, Messages, skinvar, plugin2;
  
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$R Resource.res}
  
Type
  TOpenFileName = packed record
  lStructSize          : DWORD;
  hWndOwner            : HWND;
  hInstance            : HINST;
  lpstrFilter          : PAnsiChar;
  lpstrCustomFilter    : PAnsiChar;
  nMaxCustFilter       : DWORD;
  nFilterIndex         : DWORD;
  lpstrFile            : PAnsiChar;
  nMaxFile             : DWORD;
  lpstrFileTitle       : PAnsiChar;
  nMaxFileTitle        : DWORD;
  lpstrInitialDir      : PAnsiChar;
  lpstrTitle           : PAnsiChar;
  Flags                : DWORD;
  nFileOffset          : Word;
  nFileExtension       : Word;
  lpstrDefExt          : PAnsiChar;
  lCustData            : LPARAM;
  lpfnHook             : function(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): UINT stdcall;
  lpTemplateName       : PAnsiChar;
  end;

Var
  SaveDLLProc: TDLLProc;
  OD2hModule: HMODULE;
  filter: PChar;
  Title: PChar;
  FileName: array[0..4095] of Char;
  skinpath:array[0..MAXPATH] of WChar;
  skinpath1:array[0..MAXPATH] of Char;
  oddir: PChar;
  EnableSkinFlag: LongInt;
  Inst, Handle: Integer;
  OpenFileName: TOpenFileName;

  procedure InitSkinEngine; stdcall; external 'skinengine.dll';
  procedure LoadSkinFromFile; stdcall; external 'skinengine.dll';
  procedure ApplySkinEngine; stdcall; external 'skinengine.dll';
  procedure DisableSkinEngine; stdcall; external 'skinengine.dll';
  procedure AboutSkinEngine; stdcall; external 'skinengine.dll';

  function GetOpenFileNameA(var OpenFile: TOpenFileName): Bool; stdcall; external 'comdlg32.dll' name 'GetOpenFileNameA';
  function MP_Mainmenu(table:P_table;text:PWChar;index:ULong;mode:LongInt): LongInt; cdecl; forward;

Const
  PLUGIN_NAME: PWChar = 'OllySkin';
  PLUGIN_VERS: PWChar = 'v201.01';
  PLUGIN_AUTH: PWChar = 'quygia128';
  PLUGIN_EMAI: PWChar = 'quygia128@gmail.com';
  PLUGIN_DATE: PWChar = '07.29.2013';

  IDD_DIALOG          = 100;
  IDT_EDIT1           = 1001;
  IDC_BROWS           = 1002;
  IDC_APPLY           = 1003;
  IDC_CLOSE           = 1004;
  IDC_DISABLE         = 1005;
  {------------------------------}
  OFN_LONGNAMES       = $00200000;
  OFN_EXPLORER        = $00080000;
  OFN_FILEMUSTEXIST   = $00001000;
  OFN_PATHMUSTEXIST   = $00000800;
  OFN_HIDEREADONLY    = $00000004;
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Plugin Menu ///////////////////////////////
MainMenu:array[0..2] of t_menu=(
  (Name:'Skin Option';help: 'Open Option';shortcutid: 0;menufunc: MP_Mainmenu;submenu: nil;union: (index: 1)),
  (Name:'|About';help: 'About Plugin';shortcutid: 0;menufunc: MP_Mainmenu;submenu: nil;union: (index: 2)),
  ()
  );
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Plugin Menu ///////////////////////////////

function LoadSkin(hwnd: HWND): Boolean;
begin
  FillChar(OpenFileName, SizeOf(TOpenFileName),0);
  Filter:= Pchar('msstyles Files'+#0+'*.msstyles'+#0+'Skin Files'+#0+'*.skin'+#0+'All Files'+#0+'*.*');
  Title:= PChar('Load Skin');
  with OpenFileName do begin  // or you can use function Browsefilename
    lStructSize  := SizeOf(TOpenFileName);
    hInstance    := Inst;
    hWndOwner    := Handle;
    lpstrFilter  := Filter;
    nFilterIndex := 1;
    nMaxFile     := SizeOf(FileName);
    lpstrFile    := FileName;
    lpstrTitle   := Title;
    Flags        := OFN_LONGNAMES or OFN_EXPLORER or OFN_FILEMUSTEXIST or
                        OFN_PATHMUSTEXIST or OFN_HIDEREADONLY;

    if GetOpenFileNameA(OpenFileName) = True then begin
      WriteUnicode(OpenFileName.lpstrFile,skinpath,MAXPATH);
      Writetoini(nil,'OllySkin2','skinPath','%s',skinpath);
      SetDlgItemText(hwnd,IDT_EDIT1,OpenFileName.lpstrFile);
      Result:= True;
    end else Result:= False;
  end;
end;

procedure SetSkin;
var
  i: WORD;
begin
  if FileName[1] = #0 then begin
    oddir:= GetCommandLine;
    oddir:= Pchar(Mid(oddir,2,strlen(oddir)-1));
    for i:= strlen(oddir) downto 1 do begin
      if oddir[i] <> '.' then oddir[i]:= #0
      else Break;
    end;
    GetPrivateProfileString('OllySkin2','Skinpath',nil,skinpath1,MAXPATH,lstrcat(oddir,PChar('ini')));
    for i:= 0 to strlen(skinpath1) do FileName[i]:= skinpath1[i];
  end;
  asm
    call  InitSkinEngine
  push  offset FileName
	call  LoadSkinFromFile
	call  ApplySkinEngine
  end;
  Writetoini(nil,'OllySkin2','Enable','%i',1);
end;

procedure DisSkin;
begin
  DisableSkinEngine;
  Writetoini(nil,'OllySkin2','Enable','%i',0);
end;

function SkinFunc(hWnd: HWND; uMsg: Cardinal; wParam,lParam: Integer): Integer; stdcall;
var
  i: WORD;
begin
  case uMsg of
    WM_INITDIALOG:
    begin
      oddir:= GetCommandLine;
      oddir:= Pchar(Mid(oddir,2,lstrlen(oddir)-1));
      for i:= lstrlen(oddir) downto 1 do begin
        if oddir[i] <> '.' then oddir[i]:= #0
        else Break;
      end;
      GetPrivateProfileString('OllySkin2','Skinpath',nil,skinpath1,MAXPATH,lstrcat(oddir,PChar('ini')));
      SetDlgItemText(hWnd,IDT_EDIT1,skinpath1);
    end;
    WM_LBUTTONDOWN:
    begin
      SendMessage(hWnd,WM_NCLBUTTONDOWN,HTCAPTION,0);
    end;
    WM_CLOSE:
    begin
      EndDialog(hWnd,0);
    end;
    WM_COMMAND:
    begin
      if (hiword(wParam)= BN_CLICKED) and (loword(wParam) = IDC_CLOSE)   then SendMessage(hWnd,WM_CLOSE,0,0);
      if (hiword(wParam)= BN_CLICKED) and (loword(wParam) = IDC_BROWS)   then LoadSkin(hWnd);
	  if (hiword(wParam)= BN_CLICKED) and (loword(wParam) = IDC_APPLY)   then SetSkin;
      if (hiword(wParam)= BN_CLICKED) and (loword(wParam) = IDC_DISABLE) then DisSkin;
    end;
  end;
  Result:= 0;
end;

function MP_Mainmenu(table:P_table;text:PWChar;index:ULong;mode:LongInt): LongInt;
var
  info:array[0..TEXTLEN-1] of WCHAR;
  n: LongInt;
begin

  case mode of
    MENU_VERIFY: begin
      Result:= MENU_NORMAL;
    end;
    MENU_EXECUTE: begin
      Suspendallthreads;
      Result:= MENU_NOREDRAW;
      case index of
        1: begin
          DialogBoxParam(HInstance,MAKEINTRESOURCE(IDD_DIALOG),oddata.hwollymain^,@SkinFunc,0);
        end;
        2: begin
          FillChar(info,SizeOf(info),#0);
          Swprintf(info,'%s %s'#10#10, PLUGIN_NAME, PLUGIN_VERS);
          n:= StrlenW(info,TEXTLEN);
          Swprintf(info+n,'skinengine.dll - Copyright (c) by KSDev'#10#10);
          n:= StrlenW(info,TEXTLEN);
          Swprintf(info+n,'OllySkin v1.10 by maluc'#10#10);
          n:= StrlenW(info,TEXTLEN);
          Swprintf(info+n,'OllySkin v2.01 by %s'#10'Email: %s'#10#10,PLUGIN_AUTH, PLUGIN_EMAI);
          n:= StrlenW(info,TEXTLEN);
          Swprintf(info+n,'Credits to KSDev''s develop & maluc'#10#10);
          n:= StrlenW(info,TEXTLEN);
          Swprintf(info+n,'Special thanks to TQN ~ phpbb3 ~ BOB'#10);
          AboutSkinEngine; { -Not disable this line please- }
          MessageBoxW(oddata.hwollymain^,info,'About OllySkin',MB_OK);
        end;
      end;
      Resumeallthreads;
    end;
  else
    Result:= 0;
  end;
end;

// ODBG_Pluginquery() is a "must" for valid OllyDbg plugin. First it must check
// whether given OllyDbg version is correctly supported, and return 0 if not.
// Then it should make one-time initializations and allocate resources. On
// error, it must clean up and return 0. On success, if should fill plugin name
// and plugin version (as UNICODE strings) and return version of expected
// plugin interface. If OllyDbg decides that this plugin is not compatible, it
// will call ODBG2_Plugindestroy() and unload plugin. Plugin name identifies it
// in the Plugins menu. This name is max. 31 alphanumerical UNICODE characters
// or spaces + terminating L'\0' long. To keep life easy for users, this name
// should be descriptive and correlate with the name of DLL. This function
// replaces ODBG_Plugindata() and ODBG_Plugininit() from the version 1.xx.
function  ODBG2_Pluginquery(ollydbgversion: LongInt;features: PULong;pluginname,pluginversion: PWChar): LongInt; cdecl;
Begin
  if (ollydbgversion < 201) then Result:= 0
  else begin
    wcscpy(pluginname,PLUGIN_NAME);
    wcscpy(pluginversion,PLUGIN_VERS);
    Result:= PLUGIN_VERSION;
  end;
End;

// Optional entry, called immediately after ODBG2_Plugininit(). Plugin should
// make one-time initializations and allocate resources. On error, it must
// clean up and return -1. On success, it must return 0.
function  ODBG2_Plugininit: LongInt; cdecl;
Begin
  OD2hModule:= GetModuleHandleA(nil);
  oddata:= Getoddata(OD2hModule);
  Getfromini(nil,'OllySkin2','Enable','%i',@enableskinflag);
  if enableskinflag = 1 then SetSkin;
  Addtolist(0,1,'- OllySkin v1.10 alpha by maluc');
  Addtolist(0,1,'- %s %s by %s. Compiled date: %s', PLUGIN_NAME, PLUGIN_VERS, PLUGIN_AUTH, PLUGIN_DATE);
  Addtolist(0,2,' - Email: %s',PLUGIN_EMAI);
  Addtolist(0,2,' - ');
  Result:= 0;
End;

////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// DUMP WINDOW HOOK ///////////////////////////////

// Dump windows display contents of memory or file as bytes, characters,
// integers, floats or disassembled commands. Plugins have the option to modify
// the contents of the dump windows. If ODBG2_Plugindump() is present and some
// dump window is being redrawn, this function is called first with column=
// DF_FILLCACHE, addr set to the address of the first visible element in the
// dump window and n to the estimated total size of the data displayed in the
// window (n may be significantly higher than real data size for disassembly).
// If plugin returns 0, there are no elements that will be modified by plugin
// and it will receive no other calls. If necessary, plugin may cache some data
// necessary later. OllyDbg guarantees that there are no calls to
// ODBG2_Plugindump() from other dump windows till the final call with
// DF_FREECACHE.
// When OllyDbg draws table, there is one call for each table cell (line/column
// pair). Parameters s (UNICODE), mask (DRAW_xxx) and select (extended DRAW_xxx
// set) contain description of the generated contents of length n. Plugin may
// modify it and return corrected length, or just return the original length.
// When table is completed, ODBG2_Plugindump() receives final call with
// column=DF_FREECACHE. This is the time to free resources allocated on
// DF_FILLCACHE. Returned value is ignored.
// Use this feature only if absolutely necessary, because it may strongly
// impair the responsiveness of the OllyDbg. Always make it switchable with
// default set to OFF!
function  ODBG2_Plugindump(pd: P_dump;s: PWChar;mask: PWChar;n: LongInt;select: PInteger;addr: ULong;column: LongInt): LongInt; cdecl;
begin

  if (column= DF_FILLCACHE)then begin

    Result:= 0;
  end
  else
  if (column=TSC_MOUSE) then
  begin

  end
  else
  if (column=DF_FREECACHE)then
  begin
    // We have allocated no resources, so we have nothing to do here.
  end;
end;

function  ODBG2_Pluginmenu(WdType: PWChar): P_Menu; cdecl;
begin
   Result:= nil;
   if (wcscmp(WdType,PWM_MAIN) = 0) then Result:= @MainMenu;
end;

// OllyDbg calls this optional function when user wants to terminate OllyDbg.
// All MDI windows created by plugins still exist. Function must return 0 if
// it is safe to terminate. Any non-zero return will stop closing sequence. Do
// not misuse this possibility! Always inform user about the reasons why
// termination is not good and ask for his decision! Attention, don't make any
// unrecoverable actions for the case that some other plugin will decide that
// OllyDbg should continue running.
function ODBG2_Pluginclose:LongInt cdecl;
begin
  // For automatical restoring of open windows, mark in .ini file whether
  // Bookmarks window is still open.
  Result:= 0;
end;

// OllyDbg calls this optional function once on exit. At this moment, all MDI
// windows created by plugin are already destroyed (and received WM_DESTROY
// messages). Function must free all internally allocated resources, like
// window classes, files, memory etc.

exports
  ODBG2_Pluginquery name '_ODBG2_Pluginquery',
  ODBG2_Plugininit  name '_ODBG2_Plugininit',
  ODBG2_Pluginmenu  name '_ODBG2_Pluginmenu',
  ODBG2_Plugindump  name '_ODBG2_Plugindump',
  ODBG2_Pluginclose name '_ODBG2_Pluginclose';

procedure DLLEntryPoint(dwReason: DWORD);
begin
  if (dwReason = DLL_PROCESS_DETACH) then
  begin
    // Uninitialize code here
    OutputDebugStringW('Plugin Unloaded By DLL_PROCESS_DETACH');
  end;
  // Call saved entry point procedure
  if Assigned(SaveDLLProc) then SaveDLLProc(dwReason);
end;

begin
  //Initialize code here
  SaveDLLProc:= @DLLProc;
  DLLProc:= @DLLEntryPoint;
end.

