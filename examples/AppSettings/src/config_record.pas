unit config_record;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, AppSettings;

type

  { Project settings.
    Saved and restored from INI file by TAppSettings class.
  }
  TAppConfig = record
    str1:  String;
    str2:  String;
    int1:  Integer;
    int2:  Integer;
    int3:  Integer;
    int4:  Integer;
    top:   Integer;
    left:  Integer;
    num1:  Double;
    bool1: Boolean;
  end;

// init user defined setting entries
procedure InitConfigVariables;

var
  Settings: TAppSettings; // class for work with settings
  cfg:      TAppConfig;   // configuration record with project settings

implementation

procedure InitConfigVariables;
  begin
    Settings.Add('main.top', stInt, @cfg.top);
    Settings.Add('main.left', stInt, @cfg.left);
  end;

initialization
  Settings := TAppSettings.Create;

end.
