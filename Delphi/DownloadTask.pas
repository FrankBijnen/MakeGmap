unit DownloadTask;
// Download Sea and bounds
// http://develop.freizeitkarte-osm.de/boundaries/
interface

uses
  Winapi.Windows, Winapi.Messages, System.Threading, System.SyncObjs, System.Classes,
  IdHTTP, IdIOHandler, IdIOHandlerStream, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdGlobal;

const CM_StartDownload        = WM_User + 1;
      CM_SizesComputed        = WM_User + 2;
      CM_StartChunk           = WM_User + 3;
      CM_DoneChunk            = WM_User + 4;
      CM_FailedChunk          = WM_User + 5;
      CM_JoiningDownloads     = WM_User + 6;
      CM_ConvertingDownloads  = WM_User + 7;
      CM_DoneDownLoad         = WM_User + 8;
      CM_FailedDownLoad       = WM_User + 9;
type
  TDownloadInfo = class
    FUrl: string;
    FPath: string;
    FProgPath: string;
    FlocalFile: string;
    FErrorMsg: string;
    FFileSize: int64;
    FChunkSize: int64;
    FChunkCnt: int64;
    FMaxTasks: integer;
    procedure ComputeChunks(AFileSize: int64);
  public
    constructor Create(const AUrl, APath, AProgPath: string;
                       const AChunkSize: int64;
                       const AMaxTasks: integer = -1);
    procedure Init;
  end;

  TDownloadTask = class(TTask, ITask)
  private
    FChunk: int64;
    FStart: int64;
    FEnd: int64;
    FDownLoadInfo: TDownloadInfo;
    FHandle: THandle;
    procedure DoDownload;
    procedure DoExecute;
    class function GetIO: TIdSSLIOHandlerSocketOpenSSL;
    class function GetIdHttp(IOHandler: TIdSSLIOHandlerSocketOpenSSL): TIdHttp;
    class function GetSize(Url:string):int64;
    class procedure GetChunk(Url, OFile: string; Chunk, RStart, REnd: int64);
  public
    constructor Create(const ADownTask: TDownloadInfo;
                       const AChunk: int64;
                       const AHandle: THandle); reintroduce;

    destructor Destroy; override;
    class procedure DownLoad(const AHandle: THandle;
                             const ADownLoadInfo: TDownloadInfo);
    class procedure CancelAllTasks;

    function Start: ITask; reintroduce;
    procedure Cancel; reintroduce;
  end;

threadvar
  Tasks: array of ITask;

implementation

uses System.SysUtils, System.StrUtils, MsgLoop, UnitRedirect;

const CancelReq = 'Cancel Requested';

var MyThreadPool: TThreadPool;

//
constructor TDownloadInfo.Create(const AUrl, APath, AProgPath: string;
                                 const AChunkSize: int64;
                                 const AMaxTasks: integer = -1);
begin
  inherited Create;
  FUrl := AUrl;
  FPath := APath;
  FProgPath := AProgPath;
  FFileSize := -1;
  FChunkSize := AChunkSize;
  FChunkCnt := -1;
  FMaxTasks := AMaxTasks;
end;

procedure TDownloadInfo.ComputeChunks(AFileSize: int64);
begin
  FFileSize := AFileSize;
  FChunkCnt := (FFileSize div FChunkSize);
  if (FFileSize mod FChunkSize) <> 0 then
    Inc(FChunkCnt);
end;

procedure TDownloadInfo.Init;
begin
  FLocalFile := IncludeTrailingPathDelimiter(FPath) +
                Copy(FUrl, System.SysUtils.LastDelimiter('/', FUrl) + 1, Length(FUrl));
  ComputeChunks(TDownloadTask.GetSize(FUrl));
end;

// Task helpers
procedure ResetPool(const Threads: integer = -1);
var
  MinThreads, MaxThreads: integer;
begin
  if (Assigned(MyThreadPool)) then
    FreeAndNil(MyThreadPool);
  MyThreadPool := TThreadPool.Create;

  MinThreads := (Threads + 1) div 2;
  MaxThreads := Threads;
  if (Threads = -1) then
  begin
    MinThreads := (CPUCount + 1) div 2;
    MaxThreads := CPUCount;
  end;

  MyThreadPool.SetMinWorkerThreads(MinThreads);
  MyThreadPool.SetMaxWorkerThreads(MaxThreads);
end;

procedure StartAndWaitForAllTasks(const TaskCnt: integer; const DoMsgLoop: boolean = true);
var
  Indx: integer;
begin
  if (TaskCnt > 0) then
  begin
    try
      SetLength(Tasks, TaskCnt);
      for Indx := 0 to TaskCnt - 1 do
        TDownloadTask(Tasks[Indx]).Start;
      while not TTask.WaitForAll(Tasks, 50) do
      begin
        if (DoMsgLoop) then
          ProcessMessages;
        Sleep(100);
      end;
    except
      on E:Exception do
      begin
        AllocConsole;
        Writeln('WaitforAll failed ', E.Message);
      end;
    end;
  end;
  SetLength(Tasks, 0);
  ProcessMessages;
end;

class procedure TDownloadTask.CancelAllTasks;
var
  Indx: integer;
begin
  for Indx := 0 to High(Tasks) do
    TDownloadTask(Tasks[Indx]).Cancel;
end;

// End Task helpers

// Indy helpers
class function TDownloadTask.GetIO: TIdSSLIOHandlerSocketOpenSSL;
begin
  result := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  result.SSLOptions.Method := sslvSSLv23;
  result.SSLOptions.SSLVersions := [sslvSSLv2, sslvSSLv3, sslvTLSv1, sslvTLSv1_1, sslvTLSv1_2];
end;

class function TDownloadTask.GetIdHttp(IOHandler: TIdSSLIOHandlerSocketOpenSSL): TIdHttp;
begin
  result := TIdHTTP.Create(nil);
  result.ConnectTimeout := 5 * 60 * 1000;
  result.ReadTimeout := 1 * 60 * 1000;
  result.HandleRedirects := true;
  result.IOHandler :=  IOHandler;
end;

class function TDownloadTask.GetSize(Url: string):int64;
var
  IOHandler: TIdSSLIOHandlerSocketOpenSSL;
  IdHTTP: TIdHTTP;
begin
  IOHandler := GetIO;
  IdHTTP := GetIdHttp(IOHandler);
  try
    IdHTTP.Request.Ranges.Clear;
    IdHTTP.Head(Url);
    result := IdHTTP.Response.ContentLength;
  finally
    IOHandler.Free;
    IdHTTP.Free;
  end;
end;

class procedure TDownloadTask.GetChunk(Url, Ofile: string; Chunk, RStart, REnd: int64);
var
  IOHandler: TIdSSLIOHandlerSocketOpenSSL;
  IdHTTP: TIdHTTP;
  AFileStream: TFileStream;
begin
  AFileStream := TFileStream.Create(OFile + IntToStr(Chunk), fmCreate);
  IOHandler := GetIO;
  IdHTTP := GetIdHttp(IOHandler);
  try
    IdHTTP.Request.Ranges.Clear;
    with IdHTTP.Request.Ranges.Add do
    begin
      StartPos := RStart;
      EndPos := REnd;
    end;
    IdHTTP.Get(URL, AFileStream);
  finally
    IOHandler.Free;
    IdHTTP.Free;
    AFileStream.Free;
  end;
end;
// End Indy Helpers

destructor TDownloadTask.Destroy;
begin
  inherited;
end;

constructor TDownloadTask.Create(const ADownTask: TDownloadInfo;
                                 const AChunk: int64;
                                 const AHandle: THandle);
begin
  FDownLoadInfo := ADownTask;
  FChunk := AChunk;
  FHandle := AHandle;

  FStart := FDownLoadInfo.FChunkSize * FChunk;
  FEnd := FStart + (FDownLoadInfo.FChunkSize -1);
  if (FEnd > FDownLoadInfo.FFileSize) then
    FEnd := FDownLoadInfo.FFileSize;

  inherited Create(nil,
                   TNotifyEvent(nil),
                   DoExecute,
                   MyThreadPool,
                   nil,
                   []);
end;

procedure TDownloadTask.DoExecute;
begin
  DoDownload;
end;

procedure TDownloadTask.DoDownload;
var
  Rc: LRESULT;
begin
  Rc := SendMessage(FHandle, CM_StartChunk, FChunk, LPARAM(FDownLoadInfo));
  try
    if (Rc <> 0) then
      raise Exception.Create(CancelReq);
    try
      TDownloadTask.GetChunk(FDownLoadInfo.FUrl,
                             FDownLoadInfo.FLocalFile,
                             FChunk,
                             FStart,
                             FEnd);
    finally
      Rc := SendMessage(FHandle, CM_DoneChunk, FChunk, LPARAM(FDownLoadInfo));
      if (Rc <> 0) then
        raise Exception.Create(CancelReq);
    end;

  except
    on E:Exception do
    begin
      FDownLoadInfo.FErrorMsg := E.Message;
      PostMessage(FHandle, CM_FailedChunk, FChunk, LPARAM(FDownLoadInfo));
    end;
  end;
end;

function TDownloadTask.Start: ITask;
begin
  result := inherited;
end;

procedure TDownloadTask.Cancel;
begin
 inherited;
end;

class procedure TDownloadTask.DownLoad(const AHandle: THandle;
                                       const ADownLoadInfo: TDownloadInfo);

var
  InStream, OutStream: TFileStream;
  Chunk: int64;
  Rc: LRESULT;
  Output, Error: string;
  ExitCode: DWord;
begin
  PostMessage(AHandle, CM_StartDownload, 0, LPARAM(ADownLoadInfo));
  try
    ADownLoadInfo.Init;
    PostMessage(AHandle, CM_SizesComputed, 0, LPARAM(ADownLoadInfo));
    ProcessMessages;

    ResetPool(ADownLoadInfo.FMaxTasks);
    SetLength(Tasks, ADownLoadInfo.FChunkCnt);

    for Chunk := 0 to ADownLoadInfo.FChunkCnt -1 do
    begin
      Tasks[Chunk] := TDownloadTask.Create(ADownLoadInfo,
                                           Chunk,
                                           AHandle);

    end;

    StartAndWaitForAllTasks(ADownLoadInfo.FChunkCnt);

    Rc := SendMessage(AHandle, CM_JoiningDownloads, 0, LPARAM(ADownLoadInfo));
    ProcessMessages;
    if (Rc <> 0) then
      raise Exception.Create(CancelReq);

    // Join Chunks to PBF file
    OutStream := TFileStream.Create(ADownLoadInfo.FLocalFile, fmCreate);
    try
      for Chunk := 0 to ADownLoadInfo.FChunkCnt -1 do
      begin
        InStream := TFileStream.Create(ADownLoadInfo.FLocalFile + IntToStr(Chunk), fmOpenRead);
        try
          OutStream.CopyFrom(InStream, InStream.Size);
        finally
          InStream.Free;
          DeleteFile(ADownLoadInfo.FLocalFile + IntToStr(Chunk));
        end;
      end;
    finally
      OutStream.Free;
    end;

    if ContainsText(ExtractFileExt(ADownLoadInfo.FLocalFile), '.pbf') then
    begin
      Rc := SendMessage(AHandle, CM_ConvertingDownloads, 0, LPARAM(ADownLoadInfo));
      if (Rc <> 0) then
        raise Exception.Create(CancelReq);
      ProcessMessages;
      // Convert PBF to O5M
      Sto_RedirectedExecute(ADownLoadInfo.FProgPath + '\osmconvert.exe' +
                            ' --drop-version' +
                            ' "' + ADownLoadInfo.FLocalFile + '"' +
                            ' -o="' + ADownLoadInfo.FLocalFile + '.o5m"',
                            '',
                            Output, Error, ExitCode);
      if (ExitCode <> 0) then
        raise Exception.Create(Error);
      // Delete PBF
      DeleteFile(ADownLoadInfo.FLocalFile);
    end;
    PostMessage(AHandle, CM_DoneDownLoad , 0, LPARAM(ADownLoadInfo));

  except
    on E:Exception do
    begin
      ADownLoadInfo.FErrorMsg := E.Message;
      PostMessage(AHandle, CM_FailedDownLoad, 0, LPARAM(ADownLoadInfo));
    end;
  end;
end;

initialization

begin
  MyThreadPool := TThreadPool.Create;
end;

finalization

begin
  MyThreadPool.Free;
end;

end.
