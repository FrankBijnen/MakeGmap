program MakeGmap;

uses
  MidasLib,
  Vcl.Forms,
  UfrmMain in 'UfrmMain.pas' {FrmMain},
  DownloadTask in 'DownloadTask.pas',
  MakeGmapUtils in 'MakeGmapUtils.pas',
  UDmSettings in 'UDmSettings.pas' {DmSettings: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDmSettings, DmSettings);
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
