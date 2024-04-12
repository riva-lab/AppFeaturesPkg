program _AppTuner;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, fm_main, fm_second,
  SysUtils, LazUTF8, AppTuner;

  {$R *.res}

begin
  { CRITICAL! Load INI file as soon as possible to support dark theme.
    INI file should be loaded before Application.Initialize method! }
  appTunerEx.IniFile := ExtractFilePath(ParamStrUTF8(0)) + 'settings.ini';

  RequireDerivedFormResource := True;
  Application.Title := 'AppTuner';
  Application.Scaled := True;

  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmSecond, fmSecond);
  Application.Run;
end.
