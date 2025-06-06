unit UfrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Data.DB, Vcl.Grids, Vcl.DBGrids, Tdbgrids, Vcl.ExtCtrls,
  Vcl.DBCtrls, Vcl.Mask, Datasnap.DBClient,
  UnitDSFields, Vcl.Menus, OleRich, hotspot, Winapi.ActiveX, Vcl.Buttons;

const CM_ProgressMessage = WM_User + 50;

type
  TAppState = (taNormal, taDownloading, taExecuting);

  TFrmMain = class(TForm)
    ProgressBar1: TProgressBar;
    PctMain: TPageControl;
    TabConfiguration: TTabSheet;
    TabProjects: TTabSheet;
    PnlMainTop: TPanel;
    BtnCheckConfig: TButton;
    PnlProjectsTop: TPanel;
    BtnDownload: TButton;
    BtnCancel: TButton;
    BtnExecute: TButton;
    Splitter1: TSplitter;
    PnlMainNav: TPanel;
    DBNavGeneral: TDBNavigator;
    PnlProjects: TPanel;
    Splitter2: TSplitter;
    PnlProjectsUrl: TPanel;
    DBNavProjectsUrl: TDBNavigator;
    DBProjectsUrl: TDBWGrid;
    PnlLog: TPanel;
    MemoLog: TOleRichEdit;
    BtnLoadLog: TButton;
    PnlProjectsGrid: TPanel;
    DBNavProjects: TDBNavigator;
    DBWPrrojects: TDBWGrid;
    CmbLogType: TComboBox;
    PnlGeneralFields: TPanel;
    MainMenu: TMainMenu;
    Help: TMenuItem;
    General1: TMenuItem;
    Gettingstarted1: TMenuItem;
    TabPreview: TTabSheet;
    HotStylePreview: THotLabel;
    OpenDialogGpx: TOpenDialog;
    BtnPreviewPoly: TButton;
    BtnImportPoly: TButton;
    PctProjects: TPageControl;
    TsBasic: TTabSheet;
    PnlBasicProjectsFields: TPanel;
    TsAdvanced: TTabSheet;
    PnlAdvancedProjectsFields: TPanel;
    TabInstallmaps: TTabSheet;
    PnlInstallProjects: TPanel;
    DbgrdInstallProjects: TDBGrid;
    PnlTopInstallProjects: TPanel;
    PnlInstalled: TPanel;
    LbInstalled: TListBox;
    PnlTopInstalled: TPanel;
    BtnInstallMap: TButton;
    BtnUninstallMap: TButton;
    Splitter3: TSplitter;
    StatusBarInstalled: TStatusBar;
    StatusBarProjects: TStatusBar;
    CmbEcho: TComboBox;
    BrnClearTileCache: TButton;
    ScPreview: TScrollBox;
    ImgStyle: TImage;
    procedure WndProc(var Msg: TMessage); override;
    procedure BtnDownloadClick(Sender: TObject);
    procedure BtnCheckConfigClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnExecuteClick(Sender: TObject);
    procedure BtnLoadLogClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CmbLogTypeChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure General1Click(Sender: TObject);
    procedure Gettingstarted1Click(Sender: TObject);
    procedure BtnImportPolyClick(Sender: TObject);
    procedure BtnPreviewPolyClick(Sender: TObject);
    procedure BtnInstallMapClick(Sender: TObject);
    procedure LbInstalledClick(Sender: TObject);
    procedure BtnUninstallMapClick(Sender: TObject);
    procedure BrnClearTileCacheClick(Sender: TObject);
    procedure PctMainChange(Sender: TObject);
    procedure Resized(Sender: TObject);
  private
    { Private declarations }
    Aborted: boolean;
    Pi: TProcessInformation;
    AppState: TAppState;
    GeneralDSFields: TDSFields;
    ProjectBasicDSFields: TDSFields;
    ProjectAdvancedDSFields: TDSFields;
    InstalledMaps: TStringList;

    function GetProjectDir: string;
    function GetMapDir: string;
    procedure RefreshMapInfo;
    procedure FreeInstalledMaps;
    procedure ScanMaps;
    procedure ShowWarning;

    procedure LoadHelpFile(HelpItem: string);
    procedure HelpField(Sender: TField);
    procedure AddGeneralFields;
    procedure AddProjectsFields;
    function DownloadList(var DownList: string): integer;
    function CheckConfig: boolean;
    procedure UpdateDesign(NewState: TAppState);
    procedure SetPlainText(ARichEdit: TRichEdit; PlainText: boolean);
    procedure ScrollToBottom(ARichEdit: TRichEdit);
    procedure InitLogfiles(CmdLine: string);
    procedure Readlog;
    procedure NavigatePoly(APoly: string);
    procedure OnProjectChanged(Sender: TObject; Field: TField);
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

uses UDmSettings, MakeGmapUtils, UnitStringUtils, UnitRedirect, DownloadTask, UnitGpxObjects, UnitMapUtils,
     System.StrUtils,
     Winapi.RichEdit, Winapi.ShellAPI, vcl.Imaging.jpeg;

{$R *.dfm}

const ProgressLog     = 'makegmap_progress.log';
      DetailLog       = 'makegmap_detail.log';
      CommandLog      = 'makegmap_commands.log';
      CancelCode      = 4096;
      LoadLogCode     = 4097;
      HelpDir         = 'help\';
      GettingStarted  = 'getting started.rtf';
      General         = 'general.rtf';


function TFrmMain.CheckConfig: boolean;
var Output, Error: string;
    ExitCode: DWord;
begin
  result := false;
  try
    MemoLog.Lines.Clear;
    result := Sto_RedirectedExecute('java -showversion -jar "' +
                                    DirFromExe + '\CheckJava\CheckJava.jar"',
                                    Output, Error, ExitCode, '');
    if not result then
    begin
      MemoLog.Lines.Add('Executing Java failed. Install Java, and add to PATH.');
      exit;
    end;

    if ExitCode <> 0 then
    begin
      result := false;
      MemoLog.Lines.Add('Executing CheckJava.jar failed. Correct the error.');
      exit;
    end;

    MemoLog.Lines.Add('Java executed. Exitcode: '+ IntToStr(ExitCode));
    MemoLog.Lines.Add('Please also check for a 64 bit version.');
    MemoLog.Lines.Add('');
    MemoLog.Lines.Add(Output);
    MemoLog.Lines.Add(Error);

    result := DmSettings.CheckPaths;
    if not result then
    begin
      MemoLog.Lines.Add('Not all Directories specified exist, or point to a hard drive, or have enough free space (15 Gb min.)');
      MemoLog.Lines.Add('');
      MemoLog.Lines.Add('');
    end;

  finally

{$IFDEF DEBUG}
    result := true;
{$ENDIF}

    DmSettings.SetInitialised(result);
  end;
end;

procedure TFrmMain.CmbLogTypeChange(Sender: TObject);
begin
  Readlog;
end;

procedure TFrmMain.BtnCheckConfigClick(Sender: TObject);
begin
  CheckConfig;
  UpdateDesign(TAppState.taNormal);
  PctMainChange(Sender);
end;

procedure TFrmMain.BtnDownloadClick(Sender: TObject);
var DownloadList: TStringList;
    Url: string;
    Extension: string;
    MaxThreads: integer;
begin
  Aborted := False;
  UpdateDesign(TAppState.taDownloading);
  DownloadList := TStringList.Create;
  try
    with DmSettings do
    begin
      // Get Urls to download. User could change active record while downloading.
      TabProjectsUrls.First;
      while not TabProjectsUrls.Eof do
      begin
        DownloadList.Add(TabProjectsUrlsUrl.AsString);
        TabProjectsUrls.Next;
      end;
      TabProjectsUrls.First;

      // Now Download
      for Url in DownloadList do
      begin
        MemoLog.Lines.Clear;
        MemoLog.Lines.Add(Url);
        Extension := ExtractFileExt(Url);
        MaxThreads := TabGeneralMaxDownloadThreads.AsInteger;
        if (ContainsText(Extension, '.zip')) then
          MaxThreads := 1;
        TDownloadTask.DownLoad(Self.Handle,
                               TDownloadInfo.Create(Url,
                                                    TabGeneralDownloadsDir.AsString,
                                                    DirFromExe,
                                                    TabGeneralDownloadChunkSize.AsInteger * 1024 * 1024,
                                                    MaxThreads));
        if (Aborted) then
          break;
      end;
    end;
  finally
    DownloadList.Free;
    UpdateDesign(TAppState.taNormal);
  end;
end;

procedure TFrmMain.BrnClearTileCacheClick(Sender: TObject);
begin
  ClearTileCache;
  ShowWarning;
end;

procedure TFrmMain.BtnCancelClick(Sender: TObject);
begin
  Aborted := true;
  if (Pi.hProcess <> 0) then // Also checked in TerminateRunningProcess
    TerminateRunningProcess(Pi, CancelCode, false);
  UpdateDesign(TAppState.taNormal);
end;

function TFrmMain.DownloadList(var DownList: string): integer;
var MyBook: TBookmark;
    Url, Ext: string;
begin
  DownList := '';
  result := 0;
  with DmSettings do
  begin
    MyBook := TabProjectsUrls.GetBookmark;
    try
      TabProjectsUrls.First;
      while not TabProjectsUrls.Eof do
      begin
        Url := TabProjectsUrlsUrl.AsString;
        Ext := ExtractFileExt(Url);
        if SameText(Ext, '.pbf') then
        begin
          Url := Url + '.o5m';
          if (DownList <> '') then
            DownList := DownList + ' ';
          DownList := DownList +
                     Copy(Url, System.SysUtils.LastDelimiter('/', Url) + 1, Length(Url));
          inc(Result)
        end;
        TabProjectsUrls.Next;
      end;
    finally
      TabProjectsUrls.GotoBookmark(MyBook);
      TabProjectsUrls.FreeBookmark(MyBook);
    end;
  end;
end;

procedure TFrmMain.AddGeneralFields;
begin
  GeneralDSFields := TDSFields.Create(PnlGeneralFields, DmSettings.DsGeneral);
  GeneralDSFields.HelpNotify := HelpField;
end;

procedure TFrmMain.AddProjectsFields;
begin
  ProjectBasicDSFields := TDSFields.Create(PnlBasicProjectsFields, DmSettings.DsProjects, 1);
  ProjectBasicDSFields.HelpNotify := HelpField;
  ProjectAdvancedDSFields := TDSFields.Create(PnlAdvancedProjectsFields, DmSettings.DsProjects, 10);
  ProjectAdvancedDSFields.HelpNotify := HelpField;
end;

procedure TFrmMain.LoadHelpFile(HelpItem: string);
var HelpFile: string;
begin
  HelpFile := DirFromExe + HelpDir + HelpItem + '.rtf';
  if not FileExists(HelpFile) then
  begin
    SetPlainText(MemoLog, false);
    MemoLog.Lines.Text := 'No help available.' + #10 + HelpFile;
    exit;
  end;
  MemoLog.Lines.LoadFromFile(HelpFile);
end;

procedure TFrmMain.HelpField(Sender: TField);
begin
  LoadHelpFile(Sender.DataSet.Name + '_' + Sender.FieldName);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  UpdateDesign(TAppState.taNormal);
  AddGeneralFields;
  AddProjectsFields;
  DmSettings.OnProjectChanged := OnProjectChanged;
  DmSettings.TabProjects.First;

  ScanMaps;
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  FreeInstalledMaps;

  GeneralDSFields.Free;
  ProjectBasicDSFields.Free;
  ProjectAdvancedDSFields.Free;
end;

procedure TFrmMain.Resized(Sender: TObject);
begin
  PnlInstallProjects.Width := (ClientWidth - PnlLog.Width) div 2;
end;

procedure TFrmMain.UpdateDesign(NewState: TAppState);
begin
  TabProjects.TabVisible :=  DmSettings.TabGeneralInitialized.AsBoolean;
  TabPreview.TabVisible :=  TabProjects.TabVisible;
  if (TabProjects.TabVisible = false) then
    PctMain.ActivePage := TabConfiguration;
  PctProjects.ActivePage := TsBasic;

  AppState := NewState;
  case AppState of
    TAppState.taNormal:
      begin
        BtnDownload.Enabled := true;
        BtnExecute.Enabled := true;
        BtnCancel.Enabled := false;
        CmbEcho.Enabled := true;

        RefreshMapInfo;

      end;
    TAppState.taDownloading:
      begin
        BtnDownload.Enabled := false;
        BtnExecute.Enabled := false;
        BtnCancel.Enabled := true;
        CmbEcho.Enabled := true;
      end;
    TAppState.taExecuting:
      begin
        BtnDownload.Enabled := false;
        BtnExecute.Enabled := false;
        BtnCancel.Enabled := true;
        CmbEcho.Enabled := false;
      end;
  end;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  if not CheckConfig then
    MemoLog.Lines.LoadFromFile(DirFromExe + HelpDir + GettingStarted)
  else
    PctMain.ActivePage := TabProjects;
  UpdateDesign(TAppState.taNormal);
  PctMainChange(Sender);
end;

procedure TFrmMain.General1Click(Sender: TObject);
begin
  SetPlainText(MemoLog, false);
  MemoLog.Lines.LoadFromFile(DirFromExe + HelpDir + General);
end;

procedure TFrmMain.Gettingstarted1Click(Sender: TObject);
begin
  SetPlainText(MemoLog, false);
  MemoLog.Lines.LoadFromFile(DirFromExe + HelpDir + GettingStarted);
end;

// Make sure all logfiles are cleared
procedure TFrmMain.InitLogfiles(CmdLine: string);
begin
  MemoLog.Lines.BeginUpdate;
  MemoLog.Lines.Clear;
  SetPlainText(MemoLog, true);
  MemoLog.Lines.SaveToFile(DmSettings.TabGeneralTempDir.AsString + '\' + DetailLog);
  MemoLog.Lines.SaveToFile(DmSettings.TabGeneralTempDir.AsString + '\' + ProgressLog);
  MemoLog.Lines.Text := 'REM Executing ' + CmdLine + #10;
  MemoLog.Lines.SaveToFile(DmSettings.TabGeneralTempDir.AsString + '\' + CommandLog);
  MemoLog.Lines.Clear;
  MemoLog.Lines.EndUpdate;
end;

procedure TFrmMain.LbInstalledClick(Sender: TObject);
begin
  StatusBarInstalled.SimpleText := GetMapDir;
end;

procedure TFrmMain.BtnExecuteClick(Sender: TObject);
var ExitCode: dword;
    CmdLine: string;
    Gmapi: string;
    GmapSupp: string;
    SplitGmapSupp: string;
    MaxJavaThreads: integer;
    CodePage: string;
    Transparent: string;
    DownList: string;
    Echo: string;
    DownListCount: integer;
    NewEnvironment: AnsiString;

    function BuildEnvironment: AnsiString;
    var CurrentEnvironment: TStringList;
    begin
      result := '';
      with DmSettings do
      begin
        Echo := 'Off';
        if (CmbEcho.ItemIndex = 1) then
          Echo := 'On';
        MaxJavaThreads := TabGeneralMaxJavaThreads.AsInteger;
        if (MaxJavaThreads = -1) then
          MaxJavaThreads := CPUCount;
        CodePage := 'latin1';
        if (TabProjectsUnicode.AsBoolean) then
          CodePage := 'unicode';
        Gmapi := '';
        if TabProjectsGMapi.AsBoolean then
          Gmapi := '--gmapi';
        GmapSupp := '';
        if TabProjectsGMapSupp.AsBoolean then
          GmapSupp := '--gmapsupp';
        Transparent := '# No Transparency';
        if TabProjectsTransparent.AsBoolean then
          Transparent := 'transparent';

        SplitGmapSupp := IntToStr(TabProjectsSplitGmapSupp.AsInteger);
        DownListCount := DownLoadList(DownList);

        CurrentEnvironment := GetCurrentEnvironment;
        try
          Add2Environment(CurrentEnvironment, 'MKGM_echo',            Echo);
          Add2Environment(CurrentEnvironment, 'MKGM_progdir',         ExcludeTrailingPathDelimiter(DirFromExe));
          Add2Environment(CurrentEnvironment, 'MKGM_tempdir',         ExcludeTrailingPathDelimiter(TabGeneralTempDir.AsString));
          Add2Environment(CurrentEnvironment, 'MKGM_tempdrive',       ExtractFileDrive(TabGeneralTempDir.AsString));
          Add2Environment(CurrentEnvironment, 'MKGM_downdir',         ExcludeTrailingPathDelimiter(TabGeneralDownloadsDir.AsString));
          Add2Environment(CurrentEnvironment, 'MKGM_downdrive',       ExtractFileDrive(TabGeneralDownloadsDir.AsString));
          Add2Environment(CurrentEnvironment, 'MKGM_finaldir',        ExcludeTrailingPathDelimiter(TabGeneralFinalDir.AsString));
          Add2Environment(CurrentEnvironment, 'MKGM_finaldrive',      ExtractFileDrive(TabGeneralFinalDir.AsString));
          Add2Environment(CurrentEnvironment, 'MKGM_poly',            TabProjectsPoly.AsString);
          Add2Environment(CurrentEnvironment, 'MKGM_mapname',         TabProjectsMapName.AsString);
          Add2Environment(CurrentEnvironment, 'MKGM_mapcode',         TabProjectsMapCode.AsString);
          Add2Environment(CurrentEnvironment, 'MKGM_mapid',           Intd(TabProjectsMapId.AsInteger, 4));
          Add2Environment(CurrentEnvironment, 'MKGM_style',           TabProjectsStyle.AsString);
          Add2Environment(CurrentEnvironment, 'MKGM_gmapi',           Gmapi);
          Add2Environment(CurrentEnvironment, 'MKGM_gmapsupp',        GmapSupp);
          Add2Environment(CurrentEnvironment, 'MKGM_splitgmapsupp',   SplitGmapSupp);
          Add2Environment(CurrentEnvironment, 'MKGM_minjavamem',      TabGeneralMinJavaMem.AsString);
          Add2Environment(CurrentEnvironment, 'MKGM_maxjavamem',      TabGeneralMaxJavaMem.AsString);
          Add2Environment(CurrentEnvironment, 'MKGM_maxjavathreads',  IntToStr(MaxJavaThreads));
          Add2Environment(CurrentEnvironment, 'MKGM_hwnd',            IntToStr(Self.Handle));
          Add2Environment(CurrentEnvironment, 'MKGM_progressmessage', IntToStr(CM_ProgressMessage));
          Add2Environment(CurrentEnvironment, 'MKGM_codepage',        CodePage);
          Add2Environment(CurrentEnvironment, 'MKGM_mapfilescount',   IntToStr(DownListCount));
          Add2Environment(CurrentEnvironment, 'MKGM_mapfiles',        DownList);
          Add2Environment(CurrentEnvironment, 'MKGM_maxnodes',        IntToStr(TabProjectsMaxNodes.AsInteger));
          Add2Environment(CurrentEnvironment, 'MKGM_maxareas',        IntToStr(TabProjectsMaxAreas.AsInteger));
          Add2Environment(CurrentEnvironment, 'MKGM_drawprio',        IntToStr(TabProjectsDrawPrio.AsInteger));
          Add2Environment(CurrentEnvironment, 'MKGM_transparent',     Transparent);
          Add2Environment(CurrentEnvironment, 'MKGM_countrylist',     TabProjectsCountryList.AsString);
          result := GetEnvironment(CurrentEnvironment);
        finally
          CurrentEnvironment.Free;
        end;
      end;
    end;

begin
  with DmSettings do
  begin
    CmdLine := '"'  + DirFromExe + 'MakeGmap.cmd"';
    InitLogfiles(CmdLine);
    CmdLine := CmdLine + ' >>"' + IncludeTrailingPathDelimiter(TabGeneralTempDir.AsString) + CommandLog + '"';
    NewEnvironment := BuildEnvironment;

    UpdateDesign(TAppState.taExecuting);
    FillChar(Pi, SizeOf(Pi), 0);
    try
      Pi := CreateProcessWait(CmdLine, false, PAnsiChar(NewEnvironment));
      ExitCode := WaitOnProcess(Pi, 250);

      MemoLog.Lines.Add('');
      case (ExitCode) of
        CancelCode:
          MemoLog.Lines.Add('Execution cancelled');
        0:
          MemoLog.Lines.Add('Execution ended');
        else
        begin
          MemoLog.Lines.Add('Execution ended unexpectedly. Exitcode:' + IntToStr(ExitCode));
          if (CmbEcho.ItemIndex = 1) then
            Readlog
          else
            MemoLog.Lines.Add('Set Echo on, retry and see commands log.');
        end;
      end;
    finally
      FillChar(Pi, SizeOf(Pi), 0);
      UpdateDesign(TAppState.taNormal);
    end;
  end;
end;

procedure TFrmMain.NavigatePoly(APoly: string);
var WB: string;
    CrNormal, CrWait: HCURSOR;
begin
  CrWait := LoadCursor(0, IDC_WAIT);
  CrNormal := SetCursor(CrWait);
  try
    WB := ChangeFileExt(APoly, '.html');
    if FileExists(WB) then
      ShellExecute(0, 'open', PChar(WB), '', '', SW_SHOWNORMAL);
  finally
    SetCursor(CrNormal);
  end;
end;

procedure TFrmMain.BtnImportPolyClick(Sender: TObject);
var
  NewPolyDir, NewPoly: string;
begin
  if not OpenDialogGpx.Execute then
    exit;
  NewPolyDir := IncludeTrailingPathDelimiter(DirFromExe + 'Poly');
  NewPoly := NewPolyDir + ExtractFileName(OpenDialogGpx.FileName);
  if not SameText(OpenDialogGpx.FileName, NewPoly) then // GPX needs to be copied first.
  begin
    if not CopyFileWithDates(OpenDialogGpx.FileName, NewPoly) then
      raise Exception.Create('Could not copy GPX to: ' + NewPoly);
  end;
  TGPXFile.PerformFunctions([TGPXFunc.CreatePoly, TGPXFunc.CreateOSM], NewPoly, nil, nil, NewPolyDir);
  DmSettings.CreatePolys;
  NavigatePoly(NewPoly);
end;

procedure TFrmMain.SetPlainText(ARichEdit: TRichEdit; PlainText: boolean);
begin
  if (ARichEdit.PlainText <> PlainText) then
    ARichEdit.Lines.Clear;

  ARichEdit.PlainText := PlainText;
end;

procedure TFrmMain.ScrollToBottom(ARichEdit: TRichEdit);
begin
  ARichEdit.SetFocus;
  ARichEdit.SelStart := ARichEdit.GetTextLen;
  ARichEdit.Perform(EM_SCROLLCARET, 0, 0);
end;

procedure TFrmMain.Readlog;
var LogTemp: string;
    LogFile: string;
begin
  MemoLog.Lines.BeginUpdate;
  SetPlainText(MemoLog, false);
  LogFile := DmSettings.TabGeneralTempDir.AsString + '\';
  case (CmbLogType.ItemIndex) of
    0:   LogFile := LogFile + ProgressLog;
    1:   LogFile := LogFile + DetailLog;
    2:   LogFile := LogFile + CommandLog;
  end;

  LogTemp := TempFilename('OSM');
  try
    if not CopyFile(PChar(LogFile), PChar(LogTemp), false) then
    begin
      MemoLog.Lines.Add('No log available');
      exit;
    end;
    MemoLog.Lines.LoadFromFile(LogTemp);
    ScrollToBottom(MemoLog);
  finally
    MemoLog.Lines.EndUpdate;
    DeleteFile(LogTemp);
  end;
end;

procedure TFrmMain.BtnLoadLogClick(Sender: TObject);
begin
  ReadLog;
end;

procedure TFrmMain.OnProjectChanged(Sender: TObject; Field: TField);
var PreviewStyle: string;
begin
  if Assigned(Field) and
     (Field.FieldName = 'Style') then
    PreviewStyle := Field.Value
  else
    PreviewStyle := DmSettings.TabProjectsStyle.AsString;
  HotStylePreview.Caption := PreviewStyle;

  PreviewStyle := DirFromExe + 'styles\' + PreviewStyle + '\preview.jpg';
  if (FileExists(PreviewStyle)) then
    ImgStyle.Picture.LoadFromFile(PreviewStyle)
  else
    ImgStyle.Picture := nil;

  StatusBarProjects.SimpleText := GetProjectDir;
end;

procedure TFrmMain.PctMainChange(Sender: TObject);
begin
  if AppState = TAppState.taNormal then
  begin
    RefreshMapInfo;
    if PctMain.ActivePage = TabConfiguration then
      CheckConfig
    else
      LoadHelpFile(PctMain.ActivePage.Name);
  end;
end;

procedure TFrmMain.BtnPreviewPolyClick(Sender: TObject);
var PreviewPoly: string;
begin
  if (DmSettings.TabProjects.State in [dsEdit, dsInsert]) then
    DmSettings.TabProjects.Post;
  PreviewPoly := DmSettings.TabProjectsPoly.AsString;
  NavigatePoly(DirFromExe + 'poly\' + PreviewPoly);
end;

function TFrmMain.GetProjectDir: string;
begin
  result := '';
  with DmSettings do
  begin
    result := IncludeTrailingPathDelimiter(TabGeneralFinalDir.AsString);
    result := result + IncludeTrailingPathDelimiter(TabProjectsMapName.AsString);
    result := result + IncludeTrailingPathDelimiter(TabProjectsMapName.AsString + '-' + TabProjectsMapId.AsString + '.gmap');
    if (not DirectoryExists(result)) then
      result := '';
  end;
end;

function TFrmMain.GetMapDir: string;
var MapSegments: TStringList;
    MapDir: string;
begin
  result := '';
  if (LbInstalled.ItemIndex > -1) and
     (LbInstalled.ItemIndex < LbInstalled.Items.Count) then
  begin
    MapSegments := TStringList(TStringList(LbInstalled.Items).Objects[LbInstalled.ItemIndex]);
    if (MapSegments.Count > 0) then
    begin
      MapDir := MapSegments[MapSegments.Count-1];
      if (ResolveLink(MapDir) <> '') then
        result := Mapdir;
    end;
  end;
end;

procedure TFrmMain.RefreshMapInfo;
begin
  StatusBarProjects.SimpleText := GetProjectDir;
  StatusBarInstalled.SimpleText := GetMapDir;
end;

procedure TFrmMain.BtnUninstallMapClick(Sender: TObject);
var MapDir: string;
begin
  MapDir := GetMapDir;
  if (MapDir <> '') then
  begin
    if not DeleteLink(MapDir) then
      raise Exception.Create('Can not delete:' + MapDir );
    ScanMaps;
    ClearTileCache;
    ShowWarning;
  end;
end;

procedure TFrmMain.FreeInstalledMaps;
var Indx: integer;
begin
  if (InstalledMaps = nil) then
    exit;
  for Indx := 0 to InstalledMaps.Count -1 do
    TStringList(InstalledMaps.Objects[Indx]).Free;
  FreeAndNil(InstalledMaps);
end;

procedure TFrmMain.ScanMaps;
begin
  FreeInstalledMaps;
  InstalledMaps := TStringList.Create;

  ListMapsAppData(GetMapFolder, InstalledMaps, true);
  LbInstalled.Items.Assign(InstalledMaps);
end;

procedure TFrmMain.ShowWarning;
begin
  ShowMessage('Tilecache cleared. Restart Basecamp/Mapsource.');
end;

procedure TFrmMain.BtnInstallMapClick(Sender: TObject);
var ProjectDir, MapFolder, MapLink: string;
begin
  ProjectDir :=  GetProjectDir;
  if (ProjectDir = '') then
    exit;

  MapFolder := GetMapFolder;
  if (not DirectoryExists(MapFolder)) then
    if not ForceDirectories(MapFolder) then
      raise Exception.Create('Can not create directory: ' + MapFolder);

  MapLink := IncludeTrailingPathDelimiter(MapFolder) + DmSettings.TabProjectsMapName.AsString + '.lnk';
  if (ResolveLink(MapLink) <> '') then
    raise exception.Create('Map already installed');
  if not CreateLink(ProjectDir, MapLink, DmSettings.TabProjectsMapName.AsString, '') then
      raise Exception.Create('Can not create link: ' + MapLink);
  ScanMaps;
  ClearTileCache;
  ShowWarning;
end;

procedure TFrmMain.WndProc(var Msg: TMessage);

  procedure Prolog(ALine: string = '');
  begin
    Msg.Result := 0;
    if Aborted then
      Msg.Result := -1;
    if (ALine <> '') then
    begin
      SetPlainText(MemoLog, true);
      MemoLog.Lines.Add(ALine);
      ScrollToBottom(MemoLog);
    end;
  end;

  procedure Epilog;
  begin
    ProgressBar1.Position := ProgressBar1.Max;
    TDownloadInfo(Msg.LParam).Free;
  end;

begin
  case Msg.Msg of
    CM_StartDownload:
      begin
        Prolog('Start Download');
        ProgressBar1.Position := 0;
      end;
    CM_SizesComputed:
      begin
        Prolog('Sizes computed.' +
               ' ChunkSize:' + IntToStr(TDownloadInfo(Msg.LParam).FChunkSize div 1024 div 1024) + ' Mb' +
               ' Chunks: ' + IntToStr(TDownloadInfo(Msg.LParam).FChunkCnt)
              );
        ProgressBar1.Max := TDownloadInfo(Msg.LParam).FChunkCnt +2; // Add 2 for joining and converting to O5M!
      end;
    CM_StartChunk:
      begin
        Prolog;
      end;
    CM_DoneChunk:
      begin
        Prolog;
        ProgressBar1.Position := ProgressBar1.Position + 1;
      end;
    CM_FailedChunk:
      begin
        Aborted := true;
        Prolog('Failed Chunk: ' + IntToStr(Msg.WParam) + #10 +
               TDownloadInfo(Msg.LParam).FErrorMsg);
      end;
    CM_JoiningDownloads:
      begin
        Prolog('Start Joining');
      end;
    CM_ConvertingDownloads:
      begin
        Prolog('Converting to O5M');
      end;
    CM_DoneDownLoad:
      begin
        Prolog('Downloading completed');
        Epilog;
      end;
    CM_FailedDownLoad:
      begin
        Aborted := true;
        Prolog('Failed DowLoad: ' + TDownloadInfo(Msg.LParam).FUrl + #10 +
               TDownloadInfo(Msg.LParam).FErrorMsg);
        Epilog;
      end;
    CM_ProgressMessage:
      begin
        ReadLog;
        if (Msg.LParam < 0) then
        begin
// Msg.Wparam contains the exitcode. Nut used here. Reported by .cmd file.
          ProgressBar1.Max := 0;
          ProgressBar1.Position := 0;
        end
        else
        begin
          ProgressBar1.Max := Msg.LParam;
          ProgressBar1.Position := Msg.WParam;
        end;
        msg.Result := -1;
      end;

    else
      inherited WndProc(Msg)
  end;
end;

end.

