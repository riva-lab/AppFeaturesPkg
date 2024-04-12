unit fm_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, StdCtrls,
  Spin, ExtCtrls, ComCtrls, LazUTF8,
  AppSettings, config_record;

type

  { TfmMain }

  TfmMain = class(TForm)
    btnRestore:   TButton;
    btnSave:      TButton;
    cbCheckbox:   TCheckBox;
    cbCombobox:   TComboBox;
    cbSync:       TCheckBox;
    cgCheckGroup: TCheckGroup;
    edEdit:       TEdit;
    fseFloatSE:   TFloatSpinEdit;
    Label1:       TLabel;
    Label10:      TLabel;
    Label14:      TLabel;
    Label2:       TLabel;
    Label3:       TLabel;
    Label4:       TLabel;
    Label5:       TLabel;
    Label9:       TLabel;
    Panel1:       TPanel;
    Panel2:       TPanel;
    rgRadioGroup: TRadioGroup;
    seSpinEdit:   TSpinEdit;
    tbTrackBar:   TTrackBar;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);

  public
    procedure InitConfigComponents;

  end;

var
  fmMain: TfmMain;

implementation

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormCreate(Sender: TObject);
  begin
    Settings.IniFile := ExtractFilePath(ParamStrUTF8(0)) + 'settings.ini';
  end;

procedure TfmMain.FormShow(Sender: TObject);
  begin
    InitConfigComponents;
    InitConfigVariables;
  end;

procedure TfmMain.btnSaveClick(Sender: TObject);
  begin
    if cbSync.Checked then
      Settings.SyncValues;

    cfg.top  := Top;
    cfg.left := Left;

    Settings.Save;
  end;

procedure TfmMain.btnRestoreClick(Sender: TObject);
  begin
    Settings.Load;

    if cbSync.Checked then
      Settings.SyncComponents;

    Top  := cfg.top;
    Left := cfg.left;
  end;

procedure TfmMain.InitConfigComponents;
  begin
    Settings.Add(edEdit, @cfg.str1);
    Settings.Add(cgCheckGroup, @cfg.str2);
    Settings.Add(cbCheckbox, @cfg.bool1);
    Settings.Add(cbCombobox, @cfg.int1);
    Settings.Add(seSpinEdit, @cfg.int2);
    Settings.Add(rgRadioGroup, @cfg.int3);
    Settings.Add(tbTrackBar, @cfg.int4);
    Settings.Add(fseFloatSE, @cfg.num1);
  end;

end.
