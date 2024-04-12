unit fm_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls,
  fm_second,
  AppLocalizer, i18n;

type

  { TForm1 }

  TForm1 = class(TForm)
    PageControl1: TPageControl;
    tsTab1:       TTabSheet;
    tsTab2:       TTabSheet;
    Panel1:       TPanel;
    cbLang:       TComboBox;
    Label1:       TLabel;
    cbTest:       TComboBox;
    Label2:       TLabel;
    lbTest:       TListBox;
    Label3:       TLabel;
    cbAuto:       TComboBox;
    Label4:       TLabel;
    btnSecond:    TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbLangChange(Sender: TObject);
    procedure btnSecondClick(Sender: TObject);

  private
    procedure OnLangChange(Sender: TObject);

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
  begin
    appLocalizerEx.OnLanguageChange := @OnLangChange;
    appLocalizerEx.Load(
      Format('%0:slang%0:slanguages.ini', [DirectorySeparator]),
      Format('%0:slang%0:sAppLocalizer', [DirectorySeparator]));
    //Caption         := appLocalizerEx.IniFile;
  end;

procedure TForm1.FormShow(Sender: TObject);
  begin
    cbAuto.Items.Add('auto 1');
    cbAuto.Items.Add('auto 2');
    cbAuto.Items.Add('auto 3');

    cbLang.Items.SetStrings(appLocalizerEx.Languages);
    cbLang.ItemIndex := 0;
    cbLangChange(Sender);
  end;

procedure TForm1.cbLangChange(Sender: TObject);
  begin
    BeginFormUpdate;
    appLocalizerEx.CurrentLanguage := cbLang.ItemIndex;
    EndFormUpdate;
  end;

procedure TForm1.btnSecondClick(Sender: TObject);
  begin
    fmSecond.Show;
  end;

procedure TForm1.OnLangChange(Sender: TObject);
  begin
    appLocalizerEx.Localize(cbTest, i18nCB1);
    appLocalizerEx.Localize(lbTest, i18nLB1);
  end;

end.
