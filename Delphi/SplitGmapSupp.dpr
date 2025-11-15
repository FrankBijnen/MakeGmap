program SplitGmapSupp;

{$WARN SYMBOL_PLATFORM OFF}
//{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  UnitStringUtils;

const SeqLen = 2;
      DescLen = 50;

var MkgMapOptions: string;
    TmpTilesDir: string;
    FinalTilesDir: string;
    MapId: string;
    MapDesc: string;
    MaxDescLen: integer;
    ImgDesc: string;
    CountryHyphen: integer;
    CurSize: int64;
    MaxSize: int64;
    SuppSeq: integer;
    Fs: TSearchRec;
    F: TextFile;
    Rc: integer;
    Img: integer;
    Opened: boolean;
    OptionStringList: TStringList;
    DescriptionList: TStringList;
    CountryList: TStringList;
    ToDoList: TStringList;
    MustSelect: boolean;
    Country: string;
    SelImg: string;
    ImgList: string;
    ImgToDoList: TStringList;

    procedure EpiLog;
    var ACountry, AImgDesc: string;
    begin
      AImgDesc := '';
      if (SelImg <> '*') then
        AImgDesc := SelImg
      else
      begin
        for ACountry in CountryList do
        begin
          if (AImgDesc <> '') then
            AImgDesc := AImgDesc + ',';
          if ((Length(AImgDesc) + Length(ACountry) +1) > MaxDescLen) then
            break;
          AImgDesc := AImgDesc + ACountry;
        end;
      end;
      AImgDesc := MapDesc + Intd(SuppSeq, SeqLen) + ' ' + AImgDesc;
      Writeln(F, 'description: ' + AImgDesc);
      Writeln(F, '#CountryList: ' + StringReplace(CountryList.Text, #13#10, ',', [rfReplaceAll]));
      CloseFile(F);
    end;

    function TilesDesc: TStringList;
    const TemplateArgs = 'Template.args';
          MapName = 'mapname: ';
          Description = 'description: ';
    var F: TextFile;
        Fn, ALine, AKey, AValue: string;
    begin
      result := TStringList.Create;
      Fn := IncludeTrailingPathDelimiter(TmpTilesDir) + TemplateArgs;
      if not FileExists(Fn) then
        exit;
      AssignFile(F, Fn);
      Reset(F);
      while not Eof(F) do
      begin
        Readln(F, ALine);
        if (Pos(MapName, ALine) = 1) then
        begin
          AKey := Copy(Aline, Length(MapName) + 1, Length(Aline));
          Continue;
        end;
        if (Pos(Description, ALine) = 1) then
        begin
          AValue := Copy(Aline, Length(Description) + 1, Length(Description));
          result.Values[AKey] := AValue;
          Continue;
        end;
      end;
      CloseFile(F);
    end;

    procedure CloseImg;
    begin
      if (Opened) then
        EpiLog;
      CountryList.Clear;
      Opened := false;
      CurSize := 0;
      Inc(SuppSeq);
      if (SuppSeq > 99) then
      begin
        Writeln(ParamStr(0), ' More than 99 Images. Increase Split Mb');
        halt(3);
      end;
    end;

{$R *.res}

begin
  ExitCode := 1;
  if (ParamCount<5) then
  begin
    Writeln(ParamStr(0), ' Not enough parameters.');
    exit;
  end;

  MkgMapOptions := ParamStr(1);
  ToDoList := TStringList.Create;
  ToDoList.Sorted := true;
  ImgToDoList := TStringList.Create;
  OptionStringList := TStringList.Create;
  CountryList := TStringList.Create;
  CountryList.Sorted := true;
  CountryList.Duplicates := dupIgnore;
  DescriptionList := nil;
  try
    try
      OptionStringList.LoadFromFile(MkgMapOptions);
    except
      Writeln(ParamStr(0), ' Cant read MkgMapOptions.');
      halt(2);
    end;

    TmpTilesDir := ParamStr(2);
    FinalTilesDir := ParamStr(3);
    MapId := ParamStr(4);
    MaxSize := StrToInt(ParamStr(5));
    // Countries in image
    ImgList := '*;';
    if (ParamCount > 5) then
      ImgList := ParamStr(6);

    MapDesc := ExtractFileName(FinalTilesDir);
    MaxDescLen := DescLen - Length(MapDesc) - SeqLen - 2;
    DescriptionList := TilesDesc;

    SuppSeq := 0;
    CurSize := 0;
    Opened := false;

    ChDir(FinalTilesDir);
    Rc := FindFirst(MapId + '*.img', faReadOnly + faArchive + faNormal, Fs);
    try
      while (Rc = 0) do
      begin
        ToDoList.AddObject(Fs.Name, Pointer(Fs.Size));
        Rc := FindNext(Fs);
      end;
    finally
      FindClose(Fs);
    end;

    SelImg := NextField(ImgList, ';');
    while (SelImg <> '') do
    begin
      ImgToDoList.Assign(ToDoList);

      for Img := ImgToDoList.Count -1 downto 0 do
      begin
        if not Opened then
        begin
          AssignFile(F, TmpTilesDir + '\mkgmap_gmapsupp' + Intd(SuppSeq, SeqLen) + '.args');
          Rewrite(F);
          Write(F, OptionStringList.Text);
          Opened := true;
        end;
        Country := '';
        ImgDesc := DescriptionList.Values[ChangeFileExt(ImgToDoList[Img], '')];
        if (ImgDesc <> '') then
        begin
          CountryHyphen := Pos('-', ImgDesc);
          if (CountryHyphen > 1) then
            Country := Copy(ImgDesc, 1, CountryHyphen -1);
        end;
        MustSelect := (SelImg = '*') or
                      (Pos(Country, SelImg) > 0);
        if MustSelect then
        begin
          CountryList.Add(Country);
          Writeln(F, 'input-file: ' + FinalTilesDir + '\' + ImgToDoList[Img]);

          CurSize := CurSize + int64(ImgToDoList.Objects[Img]); // Bytes
          if ((CurSize div 1024 div 1024) >= MaxSize) then // We count MB!
            CloseImg;

          ToDoList.Delete(Img);
        end;
      end;
      CloseImg;
      SelImg := NextField(ImgList, ';');
    end;
  finally
    CountryList.Free;
    ToDoList.Free;
    ImgToDoList.Free;
    OptionStringList.Free;
    if Assigned(DescriptionList) then
      DescriptionList.Free;
  end;

  ExitCode := 0;

end.
