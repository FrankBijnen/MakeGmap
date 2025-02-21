unit MakeGmapUtils;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses Winapi.Windows, System.SysUtils, System.Classes,
     Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, VCL.ValEdit, Vcl.Graphics, Vcl.Menus, Vcl.DBGrids,
     System.SyncObjs, Data.DB, shfolder, ShellApi,
     Datasnap.DBClient;

const ExtDelimiter = '.';
const ExtSeparator = ';';
const CurDirString = '.';
const UpDirString  = '..';

type
  TCreateXmlTable = procedure of object;

  TBrowseRecord = record
    Selection: PChar;
    Caption: PChar;
  end;

  TBrowseForFolder = class(Tobject)
    public
      function BrowseForFolder(const Acaption, BrowseTitle: String;
                               var AFolder: String;
                               MayCreateNewFolder: boolean = true;
                               UseNewStyle: boolean = true): boolean;
  end;

  TEnumEnumerator<T> = class
    class procedure EnumToList(const Values: TStrings);
  end;

// path
function DirFromExe: string;
function GetCFGPath: string;
function GetShellFolder(const csidl: integer = CSIDL_MYPICTURES): string;
function GetKnownFolder(const Known: TGUID): string;
function GetSystemMemory: TMemoryStatusEx;

function TempPath: string;
function CreateTempPath: string;
function RemovePath(const ADir: string; const AFlags: FILEOP_FLAGS = FOF_NO_UI): boolean;
function TempFilename(const Prefix: string): string;
function XmpFilename(const ARawFile: string): string;
function TempFileHandle(const Prefix: string): THandle;
function FileHandle(const FileName: string): THandle;
function MemoryStreamFromHandle(const AHandle: THandle): TMemoryStream;
function ExtractFileDirUpFws(const SParent: string): string;
function ExtractFileNameFws(const SParent: string): string;
function GetFileDate(const FileName: string): TDateTime;
function SetFileDates(const FileName: string;
                      const DateTime: TDateTime;
                      const IncludeModified: boolean = false): boolean;
function CopyFileDates(const InFile: string;
                       const OutFile: string): boolean;
function CopyFileWithDates(const InFile, OutFile:string): boolean;
function GetTemplate: string;
function CreateNewFolder(const APath:string): string;
function SelectDirectory(const ACaption, ATitle: string; var APath: string): boolean;
function ValidDirectory(const Fs: TSearchRec): boolean;
function ValidFile(const Fs: TSearchRec): boolean;

//DB
function CreateTable(const ATable: TClientDataset;
                     const ACreateXml: string;
                     const ACreateXmlTable: TCreateXmlTable): boolean;
function DBGridColumnByName(const Columns: TDBGridColumns; const FieldName: string): TColumn;

// Debug
procedure BreakPoint;
procedure DebugMsg(const Msg: array of variant);

// Not in RTL?
function TzSpecificLocalTimeToSystemTime(lpTimeZoneInformation: PTimeZoneInformation;
  var lpLocalTime, lpUniversalTime: TSystemTime): BOOL; stdcall;
// Reset timer, dont care if it's disabled
procedure ResetTimer(const ATimer:TTimer);


implementation

uses System.IOUtils, System.StrUtils, System.DateUtils, System.Variants, System.Generics.Collections,
     UnitRedirect, System.TypInfo,
     System.Win.Registry, System.Masks, Vcl.Dialogs, WinApi.ShlObj,Winapi.ActiveX, Vcl.Themes;

var FormatSettings: TFormatSettings;

procedure BreakPoint;
  asm int 3
end;

procedure DebugMsg(const Msg: array of variant);
var I: integer;
    FMsg: string;
begin
  Fmsg := Format('%s %s %s', ['MakeGmap', Paramstr(0), IntToStr(GetCurrentThreadId)]);
  for I := 0 to high(Msg) do
    FMsg := Format('%s,%s', [FMsg, VarToStr(Msg[I])]);
  OutputDebugString(PChar(FMsg));
end;

function TzSpecificLocalTimeToSystemTime; external kernel32 name 'TzSpecificLocalTimeToSystemTime';

procedure ResetTimer(const ATimer:TTimer);
begin
  ATimer.Enabled := false;
  ATimer.Enabled := true;
end;


function ShiftPressed: boolean;
begin
  result := (GetKeyState(VK_SHIFT) and $8000) = $8000;
end;

function ColorsAreClose(const Col1, Col2: TColor): Boolean;
var CCol1, CCol2:TColor;
begin
  result := false;
  CCol1 := Col1 and $00ffffff;
  CCol2 := Col2 and $00ffffff;
  if (Abs(GetRValue(CCol1) - GetRValue(CCol2)) < $20) and
     (Abs(GetGValue(CCol1) - GetGValue(CCol2)) < $20) and
     (Abs(GetBValue(CCol1) - GetBValue(CCol2)) < $20) then
    result := true;
end;

function GetFileDate(const FileName: string): TDateTime;
var Handle: THandle;
    CreateTime, AccessTime,ModifiedTime: TFileTime;
    SystemTime, LocalTime: TSystemTime;
begin
  result := now;
  Handle := INVALID_HANDLE_VALUE;
  try
    Handle := CreateFile(PChar(FileName),
                         GENERIC_READ,
                         FILE_SHARE_READ,
                         nil,
                         OPEN_EXISTING,
                         FILE_ATTRIBUTE_NORMAL,
                         0);
    if Handle = INVALID_HANDLE_VALUE then
      exit;
    if not GetFileTime(Handle, @CreateTime, @AccessTime, @ModifiedTime) then
      exit;
    FileTimeToSystemTime(CreateTime, SystemTime);
    SystemTimeToTzSpecificLocalTime(nil, SystemTime, LocalTime);
    result := SystemTimeToDateTime(LocalTime);
  finally
    if (Handle <> INVALID_HANDLE_VALUE) then
      CloseHandle(Handle);
  end;
end;

function SetFileDates(const FileName: string;
                      const DateTime: TDateTime;
                      const IncludeModified: boolean = false): boolean;
var Handle: THandle;
    SystemTime, LocalTime: TSystemTime;
    FileTime: TFileTime;
begin
  result := false;
  Handle := INVALID_HANDLE_VALUE;
  try
    Handle := CreateFile(PChar(FileName),
                         FILE_WRITE_ATTRIBUTES,
                         FILE_SHARE_READ or FILE_SHARE_WRITE,
                         nil,
                         OPEN_EXISTING,
                         FILE_ATTRIBUTE_NORMAL,
                         0);
    if Handle = INVALID_HANDLE_VALUE then
      exit;

    DateTimeToSystemTime(DateTime, LocalTime);
    TzSpecificLocalTimeToSystemTime(nil, LocalTime, SystemTime);
    if not SystemTimeToFileTime(SystemTime, FileTime) then
      exit;
    if (IncludeModified) then
      result := SetFileTime(Handle, @FileTime, @FileTime, @FileTime)
    else
      result := SetFileTime(Handle, @FileTime, @FileTime, nil);
  finally
    if (Handle <> INVALID_HANDLE_VALUE) then
      CloseHandle(Handle);
  end;
end;

function CopyFileDates(const InFile: string;
                       const OutFile: string): boolean;
var InHandle, OutHandle: THandle;
    CreateTime, AccessTime,ModifiedTime: TFileTime;
begin
  result := false;
  InHandle := INVALID_HANDLE_VALUE;
  OutHandle := INVALID_HANDLE_VALUE;
  try
    InHandle := CreateFile(PChar(InFile),
                           GENERIC_READ,
                           FILE_SHARE_READ,
                           nil,
                           OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL,
                           0);
    if InHandle = INVALID_HANDLE_VALUE then
      exit;
    OutHandle := CreateFile(PChar(OutFile),
                            FILE_WRITE_ATTRIBUTES,
                            FILE_SHARE_READ or FILE_SHARE_WRITE,
                            nil,
                            OPEN_EXISTING,
                            FILE_ATTRIBUTE_NORMAL,
                            0);
    if OutHandle = INVALID_HANDLE_VALUE then
      exit;

    if not GetFileTime(InHandle, @CreateTime, @AccessTime, @ModifiedTime) then
      exit;
    result := SetFileTime(OutHandle, @CreateTime, @AccessTime, @ModifiedTime );
  finally
    if (InHandle <> INVALID_HANDLE_VALUE) then
      CloseHandle(InHandle);
    if (OutHandle <> INVALID_HANDLE_VALUE) then
      CloseHandle(OutHandle);
  end;
end;

function CopyFileWithDates(const InFile, OutFile:string): boolean;
begin
  result := CopyFile(PChar(InFile), PChar(OutFile), false);
  if (result) then
    result := CopyFileDates(InFile, OutFile);
end;

function GetCFGPath: string;
var NameBuffer: array [0 .. 255] of char;
begin
  if SUCCEEDED(SHGetFolderPath(Application.Handle, CSIDL_PERSONAL, 0, 0, NameBuffer)) then
    result := IncludeTrailingPathDelimiter(StrPas(NameBuffer)) +
              IncludeTrailingPathDelimiter(TPath.GetFileNameWithoutExtension(Application.ExeName));
  if not DirectoryExists(result) then
    CreateDir(result);
end;

function GetShellFolder(const csidl: integer = CSIDL_MYPICTURES): string;
var NameBuffer: array [0 .. 255] of char;
begin
  if SUCCEEDED(SHGetFolderPath(Application.Handle, csidl, 0, 0, NameBuffer)) then
    result := StrPas(NameBuffer);
end;

function GetKnownFolder(const Known: TGUID): string;
var NameBuffer: PChar;
begin
  if SUCCEEDED(SHGetKnownFolderPath(Known, 0, 0, NameBuffer)) then
    result := StrPas(NameBuffer);
  CoTaskMemFree(NameBuffer);
end;

function GetSystemMemory: TMemoryStatusEx;
begin
  FillChar(result, SizeOf(result), 0);
  result.dwLength := SizeOf(result);
  if not GlobalMemoryStatusEx(result) then
    raise Exception.Create('GlobalMemoryStatusEx failed');
end;

function TempPath: string;
var ADir: array [0 .. 255] of char;
begin
  GetTempPath(255, ADir);
  result := StrPas(ADir);
end;

function TempFilename(const Prefix: string): string;
var AName, ADir: array [0 .. 255] of char;
begin
  GetTempPath(255, ADir);
  GetTempFilename(ADir, PChar(Prefix), 0, AName);
  result := StrPas(AName);
end;

function XmpFilename(const ARawFile: string): string;
begin
  result := ChangeFileExt(ARawFile, '.xmp');
end;

function DoCreateFile(const AFile: Pchar; const Flags: DWord): THandle;
begin
  result := Winapi.Windows.CreateFile(AFile,
                                      GENERIC_READ or GENERIC_WRITE,
                                      FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
                                      nil,
                                      CREATE_ALWAYS,
                                      Flags,
                                      0);
  if (result = INVALID_HANDLE_VALUE) then
    raise exception.Create(Format('%s %s', [AFile, SysErrorMessage(GetLastError)] ));
end;

function TempFileHandle(const Prefix: string): THandle;
var TmpFile: string;
begin
  TmpFile := TempFilename(Prefix);
  // Windows will delete the file upon closing
  result := DoCreateFile(PChar(TmpFile), FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE);
end;

function FileHandle(const FileName: string): THandle;
begin
  result := DoCreateFile(PChar(FileName), FILE_ATTRIBUTE_NORMAL);
end;

function MemoryStreamFromHandle(const AHandle: THandle): TMemoryStream;
var HandleStream: THandleStream;
begin
  HandleStream := THandleStream.Create(AHandle);
  try
    result := TMemoryStream.Create;
    HandleStream.Position := 0;
    result.CopyFrom(HandleStream, HandleStream.Size);
    result.Position := 0;
  finally
    HandleStream.Free;
  end;
end;

function CreateTempPath: string;
begin
  result := TempFilename('MTP');
  if FileExists(result) then
    DeleteFile(result);
  MkDir(result);
end;

function RemovePath(const ADir: string; const AFlags: FILEOP_FLAGS = FOF_NO_UI): boolean;
var ShOp: TSHFileOpStruct;
    ShResult: Integer;
begin
  result := false;
  if not(DirectoryExists(ADir)) then
    exit;

  ShOp.Wnd := Application.Handle;
  ShOp.wFunc := FO_DELETE;
  ShOp.pFrom := PChar(ADir + #0);
  ShOp.pTo := nil;
  ShOp.fFlags := AFlags;

  ShResult := SHFileOperation(ShOp);
  if (ShResult <> 0) and
     (ShOp.fAnyOperationsAborted = false) then
    raise Exception.Create(Format('Remove directory failed code %u', [ShResult]));
  result := (ShResult = 0);
end;

function ExtractFileDirUpFws(const SParent: string): string;
begin
  result := StringReplace(ExtractFileDir(ExcludeTrailingBackslash(StringReplace(SParent, '/', '\',[rfReplaceAll]))),
                          '\', '/', [rfReplaceAll]);
end;

function ExtractFileNameFws(const SParent: string): string;
begin
  result := StringReplace(ExtractFileName(ExcludeTrailingBackslash(StringReplace(SParent, '/', '\',[rfReplaceAll]))),
                          '\', '/', [rfReplaceAll]);
end;

function DirFromExe: string;
begin
  result := ExtractFilePath(Application.ExeName);
end;

function NextField(var AString: string; const ADelimiter: string): string;
var Indx: integer;
begin
  Indx := Pos(ADelimiter, AString);
  if Indx < 1 then
  begin
    result := AString;
    AString := '';
  end
  else
  begin
    result := Copy(AString, 1, Indx - 1);
    Delete(AString, 1, Indx);
  end;
end;


function GetRegistryValue(const ARootKey: HKEY; const KeyName, Name: string): string;
var Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := ARootKey;
    // False because we do not want to create it if it doesn't exist
    Registry.OpenKey(KeyName, False);
    Result := Registry.ReadString(Name);
  finally
    Registry.Free;
  end;
end;

function GetTemplate: string;
const NewFolder = 'New Folder';
begin
  result := GetRegistryValue(HKEY_CURRENT_USER,
                             'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\NamingTemplates',
                             'RenameNameTemplate');
  if (result = '') then
    result := NewFolder;
end;

function CreateNewFolder(const APath:string): string;
var I: integer;
    Template: string;
begin
  Template := GetTemplate;
  result := Template;
  I := 0;
  while (DirectoryExists(APath + result)) do
  begin
    inc(I);
    result := Format('%s (%u)', [Template, i]);
  end;
  MkDir(APath + result);
end;

function BrowseForFolderCallBack(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
var PszSelDir: array[0..MAX_PATH] of char;
    ABrowseRecord: TBrowseRecord;
begin
  result := 0;
  case uMsg of
    BFFM_VALIDATEFAILED:
      result := -1;
    BFFM_SELCHANGED:
      begin
        if (SHGetPathFromIDList(PItemIDList(LParam), PszSelDir)) then
            SendMessage(Wnd, BFFM_SETSTATUSTEXT, 0, integer(@PszSelDir[0]));
      end;
    BFFM_INITIALIZED:
      begin
        ABrowseRecord := TBrowseRecord(pointer(lpData)^);
        SendMessage(Wnd, BFFM_SETSELECTION, 1, integer(ABrowseRecord.Selection));
        SendMessage(Wnd, BFFM_SETEXPANDED, 1, integer(ABrowseRecord.Selection));
        SetWindowText(Wnd, ABrowseRecord.Caption);
      end;
  end;
end;

function TBrowseForFolder.BrowseForFolder(const Acaption, BrowseTitle: String;
                                          var AFolder: String;
                                          MayCreateNewFolder: boolean = true;
                                          UseNewStyle: boolean = true): boolean;
var
  Browse_info: TBrowseInfo;
  Folder: array[0..MAX_PATH] of char;
  Find_context: PItemIDList;
  BrowseRecord: TBrowseRecord;
begin
  result := false;

  //--------------------------
  // Initialise the structure.
  //--------------------------
  FillChar(Browse_info, SizeOf(Browse_info), #0);
  FillChar(Folder, SizeOf(Folder), #0);
  Browse_info.pszDisplayName := @Folder[0];
  Browse_info.lpszTitle := PChar(BrowseTitle);
  Browse_info.ulFlags :=  BIF_RETURNONLYFSDIRS or
                          BIF_UAHINT or
                          BIF_BROWSEINCLUDEFILES or
                          BIF_VALIDATE or
                          BIF_STATUSTEXT;
  if (UseNewStyle) then
     Browse_info.ulFlags := Browse_info.ulFlags or BIF_USENEWUI;
  if not MayCreateNewFolder then
    Browse_info.ulFlags := Browse_info.ulFlags or BIF_NONEWFOLDERBUTTON;

  Browse_info.hwndOwner := Application.Handle;
  Browse_info.lpfn := BrowseForFolderCallBack;

  FillChar(BrowseRecord, SizeOf(BrowseRecord), #0);
  if (AFolder <> '') then
    BrowseRecord.Selection := @AFolder[1];
  if (ACaption <> '') then
    BrowseRecord.Caption := @ACaption[1];
  Browse_info.lParam := integer(@BrowseRecord);

  Find_context := SHBrowseForFolder(Browse_info);
  if Assigned(Find_context) then
  begin
    if SHGetPathFromIDList(Find_context, Folder) then
    begin
      AFolder := Folder;
      if not DirectoryExists(AFolder) then
        AFolder := ExtractFilePath(AFolder);
      result := true;
    end;
    GlobalFreePtr(Find_context);
  end;
end;

function SelectDirectory(const ACaption, ATitle: string; var APath: string): boolean;
begin
  with TBrowseForFolder.Create do
  begin
    try
      result := BrowseForFolder(ACaption, ATitle, APath);
    finally
      Free;
    end;
  end;
end;

function ValidDirectory(const Fs: TSearchRec): boolean;
begin
  result := (Fs.Attr and faDirectory <> 0) and
             (Fs.Name <> CurDirString) and
             (Fs.Name <> UpDirString);
end;

function ValidFile(const Fs: TSearchRec): boolean;
begin
  result := ((Fs.attr and faDirectory) = 0);
end;

function CreateTable(const ATable: TClientDataset;
                     const ACreateXml: string;
                     const ACreateXmlTable: TCreateXmlTable): boolean;

  function CreateTableInner: boolean;
  begin
    result := true;
    ATable.Close;
    ATable.DisableControls;
    try
      ACreateXmlTable;
      ATable.CreateDataSet;
      ATable.SaveToFile(ATable.FileName);
    finally
      ATable.Open;
      ATable.EnableControls;
    end;
  end;

begin
  result := false;
  ATable.FileName := GetCFGPath + ACreateXml;
  if FileExists(ATable.FileName) then
  begin
    try
      ATable.Open;
    except
      on E:Exception do
      begin
        ShowMessage('Table ' + ACreateXml + ' wil be recreated.' + #10 +
                     e.Message);
        result := CreateTableInner;
      end;
    end;
  end
  else
    result := CreateTableInner;
  ATable.LogChanges := false;
end;

function DBGridColumnByName(const Columns: TDBGridColumns; const FieldName: string): TColumn;
var Item: TCollectionItem;
begin
  result := nil;
  for Item in Columns do
  begin
    if (SameText(TColumn(Item).FieldName, FieldName)) then
    begin
      result := TColumn(Item);
      exit;
    end;
  end;
end;

// Enum
class procedure TEnumEnumerator<T>.EnumToList(const Values: TStrings);
var EnumName: String;
    Indx: integer;
    CheckVal: integer;
    TypeData: PTypeData;
begin
  Values.BeginUpdate;
  Values.Clear;
  try
    TypeData := GetTypeData(GetTypeData(TypeInfo(T))^.BaseType^);
    for Indx := TypeData^.MinValue to TypeData^.MaxValue do
    begin
      EnumName := GetEnumName(TypeInfo(T), Indx);
      CheckVal := GetEnumValue(TypeInfo(T), EnumName);
      if CheckVal <> -1 then
        Values.Add(EnumName);
    end;
  finally
    Values.EndUpdate;
  end;
end;

function GetLocaleSetting: TFormatSettings;
begin
  // Get Windows settings, and modify decimal separator and negcurr
  result := TFormatSettings.Create(GetThreadLocale);
  result.DecimalSeparator := '.'; // The decimal separator is a . PERIOD!
  result.NegCurrFormat := 11;
end;

initialization
begin
  FormatSettings := GetLocaleSetting;
end;

finalization
begin
{}
end;

end.
