unit UDmSettings;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Datasnap.DBClient;

const ProjectsXMLName           = 'Projects.xml';
const ProjectsUrlSXMLName       = 'ProjectsUrls.xml';
const StyleXMLName              = 'Styles.xml';
const PolyXMLName               = 'Polys.xml';
const GeneralXMLName            = 'General.xml';

type
  TDmSettings = class(TDataModule)
    TabProjects: TClientDataSet;
    DsProjects: TDataSource;
    DsGeneral: TDataSource;
    TabGeneral: TClientDataSet;
    TabProjectsMapName: TStringField;
    TabGeneralInitialized: TBooleanField;
    TabGeneralDownloadsDir: TStringField;
    TabGeneralTempDir: TStringField;
    TabGeneralFinalDir: TStringField;
    TabGeneralMinJavaMem: TIntegerField;
    TabGeneralMaxJavaMem: TIntegerField;
    TabGeneralMaxJavaThreads: TIntegerField;
    TabProjectsMapCode: TStringField;
    TabProjectsMapId: TIntegerField;
    TabProjectsStyleLookup: TStringField;
    TabProjectsGMapSupp: TBooleanField;
    DsProjectsUrls: TDataSource;
    TabProjectsUrls: TClientDataSet;
    TabProjectsUrlsMapCode: TStringField;
    TabProjectsUrlsUrl: TStringField;
    TabGeneralDownloadChunkSize: TIntegerField;
    TabProjectsPoly: TStringField;
    TabProjectsGMapi: TBooleanField;
    TabProjectsUnicode: TBooleanField;
    TabStyle: TClientDataSet;
    TabProjectsStyle: TStringField;
    TabPoly: TClientDataSet;
    TabPolyPoly: TStringField;
    TabProjectsPolyLookup: TStringField;
    TabStyleStyle: TStringField;
    TabGeneralMaxDownloadThreads: TIntegerField;
    TabProjectsSplitGmapSupp: TIntegerField;
    TabProjectsMaxNodes: TIntegerField;
    TabProjectsMaxAreas: TIntegerField;
    TabProjectsTransparent: TBooleanField;
    TabProjectsDrawPrio: TIntegerField;
    TabProjectsCountryList: TStringField;
    procedure DataModuleCreate(Sender: TObject);
    procedure TabProjectsMapCodeChange(Sender: TField);
    procedure TabProjectChanged(DataSet: TDataSet);
    procedure DsProjectsDataChange(Sender: TObject; Field: TField);
    procedure TabProjectsAfterInsert(DataSet: TDataSet);
    procedure TabProjectsBeforePost(DataSet: TDataSet);
  private
    { Private declarations }
    var ProjectsXML: string;
    var ProjectsUrlsXML: string;
    var StyleXML: string;
    var PolyXML: string;
    var GeneralXML: string;
    var FOnProjectChanged: TDataChangeEvent;
    procedure SetProjectDefaults;
    procedure DefineGeneral;
    procedure CreateGeneral;
    procedure DefineStyles;
    procedure DefinePolys;
    procedure DefineProjects;
    procedure DefineProjectsUrls;
  public
    { Public declarations }
    function CheckPaths: boolean;
    procedure SaveSettings;
    procedure SetInitialised(AValue: boolean);
    procedure CreateStyles;
    procedure CreatePolys;
    property OnProjectChanged: TDataChangeEvent read FOnProjectChanged write FOnProjectChanged;
  end;

var
  DmSettings: TDmSettings;

implementation

uses MakeGmapUtils, System.StrUtils, System.TypInfo, Vcl.Dialogs,
     System.Variants, Winapi.KnownFolders, Winapi.Windows;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure TDmSettings.SetProjectDefaults;
begin
  with TabProjects do
  begin
    if (FieldByName('GMapi').IsNull) then
      FieldByName('GMapi').AsBoolean := false;
    if (FieldByName('GMapSupp').IsNull) then
      FieldByName('GMapSupp').AsBoolean := false;
    if (FieldByName('UniCode').IsNull) then
      FieldByName('UniCode').AsBoolean := false;
    if (FieldByName('Poly').IsNull) then
      FieldByName('Poly').AsString := '';
    if (FieldByName('MaxNodes').IsNull) then
      FieldByName('MaxNodes').AsInteger := 1600000;
    if (FieldByName('MaxAreas').IsNull) then
      FieldByName('MaxAreas').AsInteger := 4096;
    if (FieldByName('DrawPrio').IsNull) then
      FieldByName('DrawPrio').AsInteger := 25;
    if (FieldByName('Transparent').IsNull) then
      FieldByName('Transparent').AsBoolean := false;
  end;
end;

procedure TDmSettings.DefineGeneral;
begin
  with TabGeneral do
  begin
    FieldDefs.Clear;
    FieldDefs.Add('Initialized',        ftBoolean,  0, false);
    FieldDefs.Add('DownloadsDir',       ftString, 260, false);
    FieldDefs.Add('TempDir',            ftString, 260, false);
    FieldDefs.Add('FinalDir',           ftString, 260, false);
    FieldDefs.Add('MinJavaMem',         ftInteger,  0, false);
    FieldDefs.Add('MaxJavaMem',         ftInteger,  0, false);
    FieldDefs.Add('MaxJavaThreads',     ftInteger,  0, false);
    FieldDefs.Add('DownloadChunkSize',  ftInteger,  0, false);
    FieldDefs.Add('MaxDownloadThreads', ftInteger,  0, false);
  end;
end;

procedure TDmSettings.CreateGeneral;
begin
  with TabGeneral do
  begin
    Append;
    FieldByName('DownloadsDir').AsString        := GetKnownFolder(FOLDERID_Downloads);
    FieldByName('TempDir').AsString             := TempPath;
    FieldByName('FinalDir').AsString            := GetKnownFolder(FOLDERID_ProgramData) + '\Garmin\Maps';
    FieldByName('MinJavaMem').AsInteger         := 2;   // Is it to much to ask?
    FieldByName('MaxJavaMem').AsInteger         := GetSystemMemory.ullAvailPhys div 1024 div 1024 div 1024; // GB
    FieldByName('MaxJavaThreads').AsInteger     := -1;  // CPUCount
    FieldByName('DownloadChunkSize').AsInteger  := 25;  // MB
    FieldByName('MaxDownloadThreads').AsInteger := -1;  // CPUCount
    Post;
    SetInitialised(False);
  end;
end;

procedure TDmSettings.DefineProjects;
begin
  with TabProjects do
  begin
    FieldDefs.Clear;
    FieldDefs.Add('MapName',        ftString, 255, True);
    FieldDefs.Add('MapCode',        ftString,  10, True);
    FieldDefs.Add('MapId',          ftInteger,  0, True);
    FieldDefs.Add('Style',          ftString, 128, True);
    FieldDefs.Add('GMapi',          ftBoolean,  0, False);
    FieldDefs.Add('GMapSupp',       ftBoolean,  0, False);
    FieldDefs.Add('SplitGmapSupp',  ftInteger,  0, False);
    FieldDefs.Add('Unicode',        ftBoolean,  0, False);
    FieldDefs.Add('Poly',           ftString, 128, False);
    FieldDefs.Add('MaxNodes',       ftInteger,  0, False);
    FieldDefs.Add('MaxAreas',       ftInteger,  0, False);
    FieldDefs.Add('DrawPrio',       ftInteger,  0, False);
    FieldDefs.Add('TransParent',    ftBoolean,  0, False);
    FieldDefs.Add('CountryList',    ftString, 255, False);
    IndexFieldNames := 'MapCode';
  end;
end;

procedure TDmSettings.DefineProjectsUrls;
begin
  with TabProjectsUrls do
  begin
    FieldDefs.Clear;
    FieldDefs.Add('MapCode', ftString,  10, True);
    FieldDefs.Add('Url',     ftString, 512, True);
    IndexFieldNames := 'MapCode;Url';
  end;
end;

procedure TDmSettings.DefineStyles;
begin
  with TabStyle do
  begin
    FieldDefs.Clear;
    FieldDefs.Add('Style',   ftString, 128, true);
  end;
end;

procedure TDmSettings.DsProjectsDataChange(Sender: TObject; Field: TField);
begin
  if Assigned(FOnProjectChanged) then
    FOnProjectChanged(Sender, Field);
end;

procedure TDmSettings.CreateStyles;
var Fs: TSearchRec;
    Rc: integer;
    SavedDir: string;
begin
  with TabStyle do
  begin
    EmptyDataSet;

    GetDir(0, SavedDir);
    ChDir(DirFromExe + '\Styles');
    Rc := System.SysUtils.FindFirst('*.*', faDirectory, Fs);
    try
      while (Rc = 0) do
      begin
        if (ValidDirectory(Fs)) then
        begin
          Append;
          FieldByName('Style').AsString := Fs.Name;
          Post;
        end;
        Rc := System.SysUtils.FindNext(Fs);
      end;
    finally
      ChDir(SavedDir);
      System.SysUtils.FindClose(Fs);
    end;
  end;
end;

procedure TDmSettings.DefinePolys;
begin
  with TabPoly do
  begin
    FieldDefs.Clear;
    FieldDefs.Add('Poly',    ftString,  128, false);
  end;
end;

procedure TDmSettings.CreatePolys;
var Fs: TSearchRec;
    Rc: integer;
    SavedDir: string;
begin
  with TabPoly do
  begin
    EmptyDataSet;
    Append;
    FieldByName('Poly').AsString := ''; // Not mandatory
    Post;

    GetDir(0, SavedDir);
    ChDir(DirFromExe + '\Poly');
    Rc := System.SysUtils.FindFirst('*.poly', faAnyFile, Fs);
    try
      while (Rc = 0) do
      begin
        Append;
        FieldByName('Poly').AsString := Fs.Name;
        Post;
        Rc := System.SysUtils.FindNext(Fs);
      end;
    finally
      ChDir(SavedDir);
      System.SysUtils.FindClose(Fs);
    end;
  end;
end;

procedure TDmSettings.SaveSettings;
begin
  TabProjects.SaveToFile(TabProjects.FileName);
  TabProjectsUrls.SaveToFile(TabProjectsUrls.FileName);
  TabStyle.SaveToFile(TabStyle.FileName);
  TabPoly.SaveToFile(TabPoly.FileName);
  TabGeneral.SaveToFile(TabGeneral.FileName);
end;

procedure TDmSettings.SetInitialised(AValue: boolean);
begin
  TabGeneral.Edit;
  TabGeneralInitialized.ReadOnly := false;
  TabGeneralInitialized.AsBoolean := AValue;
  TabGeneral.Post;
end;

procedure TDmSettings.TabProjectChanged(DataSet: TDataSet);
begin
  if Assigned(FOnProjectChanged) then
    FOnProjectChanged(DataSet, nil);
end;

procedure TDmSettings.TabProjectsAfterInsert(DataSet: TDataSet);
begin
  SetProjectDefaults;
end;

procedure TDmSettings.TabProjectsBeforePost(DataSet: TDataSet);
begin
  SetProjectDefaults;
end;

procedure TDmSettings.TabProjectsMapCodeChange(Sender: TField);
begin
  if (TabProjects.State <> dsInsert) then
  begin
    if (TabProjectsUrls.RecordCount > 0) then
    begin
      TabProjects.Cancel;
      raise Exception.Create('Can not change MapCode when URL''s specified');
    end;
  end;
end;

function TDmSettings.CheckPaths: boolean;

  function CheckPath(Apath: string): boolean;
  const MinFree = 15; // 15 Gb
  var Drive: string;
      DriveByte: byte;
  begin
    result := false;

    if not DirectoryExists(Apath) then
      exit;

    Drive := ExtractFileDrive(Apath);
    if (GetDriveType(PWideChar(Drive)) <> DRIVE_FIXED) then
      exit;

    DriveByte := Ord(UpperCase(Drive)[1]) - Ord('@');
    if ((DiskFree(DriveByte) div 1024 div 1024 div 1024) < MinFree) then
      exit;
    result := true;
  end;

begin
  result := false;
  if not CheckPath(TabGeneralDownloadsDir.AsString) then
    exit;
  if not CheckPath(TabGeneralTempDir.AsString) then
    exit;
  if not CheckPath(TabGeneralFinalDir.AsString) then
    exit;
  result := true;
end;

procedure TDmSettings.DataModuleCreate(Sender: TObject);
begin
  GeneralXML := GetCFGPath + GeneralXMLName;
  if CreateTable(TabGeneral, GeneralXMLName, DefineGeneral) then
    CreateGeneral;

  StyleXML := GetCFGPath + StyleXMLName;
  CreateTable(TabStyle, StyleXMLName, DefineStyles);
  CreateStyles;

  PolyXML := GetCFGPath + PolyXMLName;
  CreateTable(TabPoly, PolyXMLName, DefinePolys);
  CreatePolys;

  ProjectsXML := GetCFGPath + ProjectsXMLName;
  CreateTable(TabProjects, ProjectsXMLName, DefineProjects);

  ProjectsUrlsXML := GetCFGPath + ProjectsUrlsXMLName;
  CreateTable(TabProjectsUrls, ProjectsUrlsXMLName, DefineProjectsUrls);

end;

end.
