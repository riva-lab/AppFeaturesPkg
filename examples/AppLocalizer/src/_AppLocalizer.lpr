program _AppLocalizer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, fm_main, AppLocalizer, i18n, fm_second
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'AppLocalizer';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TfmSecond, fmSecond);
  Application.Run;
end.

