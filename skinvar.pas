unit skinvar;

interface

uses
 Windows;

  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CAST OFF}

  function Mid(Str: string; From, Size: Word): string;
  function StrLen(Str: string): DWORD; assembler;//This code from BOB in WinMax2
  function Min(const A, B: DWORD): DWORD;
  function AllocMem(const Size: DWORD): Pointer;
  function AsAnsi(const Src: PWChar) : PAnsiChar;
  function WideToStr(const Src: PWChar): string;//This code from BOB in WinMax2
  function WriteUnicode(Const Src: PChar; Const Dst: PWChar; Const MaxLen: DWORD): DWORD;

implementation

function StrLen(Str: string): DWORD; assembler;
Asm
  Or      EAX, EAX
  Je      @Exit
  Push    EDI
  Push    ECX
  XChg    EDI, EAX
  Xor     EAX, EAX
  Xor     ECX, ECX
  Dec     ECX
  RepNE   ScasB
  Dec     EAX
  Dec     EAX
  Sub     EAX, ECX
  Pop     ECX
  Pop     EDI
  @Exit:
End;

function IntToStr(Value: DWord): string;
begin
  Str(Value, Result);
end;

function StrToInt(S: string): Integer;
var
  E: Integer;
begin
  Val(S, Result, E);
end;

function Mid(Str: string; From, Size: Word): string;
var
  i: Word;
  label Ex;
Begin
  Result:= '';
  if Size < 1 then goto Ex;
  if from = 0 then inc(from);
  for i:= from to (from + size-1) do
    Result:= Result + Str[i];
  Ex:
End;

//==============================================================================
// Return minimum value of two params ..
function Min(const A, B: DWORD): DWORD;   //This code from BOB in WinMax2
Begin
  If (A <= B) Then Result := A Else Result := B;
End;
//==============================================================================
// Return pointer of mem allocate...
function AllocMem(const Size: DWORD): Pointer;
Begin
  GetMem(Result, Size);
  if (Result <> nil) then FillChar(Result^, Size, 0);
End;

//==============================================================================
// Return allocated ansi string converted from widechar ..
function AsAnsi(const Src: PWChar) : PAnsiChar; //This code from BOB in WinMax2
var
  WL: DWORD;
  Len: DWORD;
Begin
  Result:= nil;
  if IsBadReadPtr(Src, Max_Path) then Exit;
  // Get length of Wide string ..
  WL:= 0;
  while (Src[WL] <> #0) do Inc(WL);
  // Get Length of buffer needed ..
  Len:= WideCharToMultiByte(GetACP, 0, Src, WL, Result, 0, nil, nil);
  Result:= AllocMem(Len);
  // Convert string and return ..
  WideCharToMultiByte(GetACP, 0, Src, WL, Result, Len, nil, nil);
End;
//==============================================================================
// Return string from widechar ..
function  WideToStr(const Src: PWChar): string;  //This code from BOB in WinMax2
var
  A: PAnsiChar;
  L: DWORD;
Begin
  Result:= '';
  A:= AsAnsi(Src);
  if (not IsBadReadPtr(A, MAX_PATH)) then
  try
    L:= lstrlen(A);
    SetLength(Result, L);
    Move(A^, Result[1], L);
  finally
    FreeMem(A);
  end;
End;

//==============================================================================
// Write MaxLen chars from ansi string as unicode to buffer ..  Returns length ..
function  WriteUnicode(Const Src: PChar; Const Dst: PWChar; Const MaxLen: DWORD): DWORD;
var  //This code from BOB in WinMax2
  Len: DWORD;
Begin
  Result := 0;
  If IsBadWritePtr(Dst, Max_Path) Then Exit;
  FillMemory(Dst, MaxLen Shl 1, 0);
  If IsBadReadPtr(Src, Max_Path) Then Exit;
  Result:= lstrlenA(Src);
  If (Result = 0) Then Exit;
  Len := Min(Result, MaxLen);

  // Get Length of buffer needed ..
  Result:= MultiByteToWideChar(GetACP, 0, Src, Len, Dst, 0);
  // Convert string and return length ..
  Result:= MultiByteToWideChar(GetACP, 0, Src, Len, Dst, Result);
End;

end.
