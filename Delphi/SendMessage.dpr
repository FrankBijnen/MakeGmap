program SendMessage;

//{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils;

var Handle: Hwnd;
    Msg: Cardinal;
    WParm: WPARAM;
    LParm: LPARAM;
begin
  ExitCode := 1;

  if (ParamCount<3) then
    exit;

  Handle := StrToInt(ParamStr(1));
  Msg := StrToInt(ParamStr(2));
  WParm := StrToInt(ParamStr(3));
  LParm := 0;
  if (ParamCount > 3) then
    LParm := StrToInt(ParamStr(4));
  // If the Window Handle is invalid we still get Exitcode 0!
  ExitCode := Winapi.Windows.SendMessage(Handle, Msg, WParm, LParm);

end.
