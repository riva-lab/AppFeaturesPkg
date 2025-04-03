unit fm_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ComCtrls, Menus, ExtCtrls, ActnList,
  AppTuner,
  fm_second;

type

  { TfmMain }

  TfmMain = class(TForm)
    Action1:      TAction;
    ActionList1:  TActionList;
    btnClose:     TButton;
    btnSecond:    TButton;
    cbBolderless: TCheckBox;
    cbFormDrag:   TCheckBox;
    cbMenuIcons:  TCheckBox;
    cbMenuShow:   TCheckBox;
    cbMenuTune:   TCheckBox;
    cbOnTop:      TCheckBox;
    cbSnap:       TCheckBox;
    cbTheme:      TComboBox;
    ComboBox1:    TComboBox;
    ImageList1:   TImageList;
    ImageList2:   TImageList;
    Label1:       TLabel;
    Label2:       TLabel;
    Label3:       TLabel;
    Label4:       TLabel;
    Label5:       TLabel;
    Label6:       TLabel;
    Label7:       TLabel;
    MainMenu1:    TMainMenu;
    MenuItem1:    TMenuItem;
    MenuItem10:   TMenuItem;
    MenuItem11:   TMenuItem;
    MenuItem12:   TMenuItem;
    MenuItem13:   TMenuItem;
    MenuItem14:   TMenuItem;
    MenuItem15:   TMenuItem;
    MenuItem16:   TMenuItem;
    MenuItem17:   TMenuItem;
    MenuItem18:   TMenuItem;
    MenuItem19:   TMenuItem;
    MenuItem2:    TMenuItem;
    MenuItem20:   TMenuItem;
    MenuItem21:   TMenuItem;
    MenuItem22:   TMenuItem;
    MenuItem23:   TMenuItem;
    MenuItem24:   TMenuItem;
    MenuItem25:   TMenuItem;
    MenuItem26:   TMenuItem;
    MenuItem27:   TMenuItem;
    MenuItem28:   TMenuItem;
    MenuItem29:   TMenuItem;
    MenuItem3:    TMenuItem;
    MenuItem30:   TMenuItem;
    MenuItem31:   TMenuItem;
    MenuItem32:   TMenuItem;
    MenuItem33:   TMenuItem;
    MenuItem34:   TMenuItem;
    MenuItem35:   TMenuItem;
    MenuItem36:   TMenuItem;
    MenuItem37:   TMenuItem;
    MenuItem38:   TMenuItem;
    MenuItem39:   TMenuItem;
    MenuItem4:    TMenuItem;
    MenuItem5:    TMenuItem;
    MenuItem6:    TMenuItem;
    MenuItem7:    TMenuItem;
    MenuItem8:    TMenuItem;
    MenuItem9:    TMenuItem;
    Panel1:       TPanel;
    Panel2:       TPanel;
    Panel3:       TPanel;
    Panel4:       TPanel;
    PopupMenu1:   TPopupMenu;
    seFontScale:  TSpinEdit;
    Separator1:   TMenuItem;
    Separator2:   TMenuItem;
    Separator3:   TMenuItem;
    Separator4:   TMenuItem;
    SpinEdit1:    TSpinEdit;
    StatusBar1:   TStatusBar;
    ToolBar1:     TToolBar;
    ToolButton1:  TToolButton;
    ToolButton2:  TToolButton;
    ToolButton3:  TToolButton;


    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure actionExecute(Sender: TObject);

  private
  public
  end;

var
  fmMain: TfmMain;

implementation

{$R *.lfm}

{ TfmMain }

procedure TfmMain.FormCreate(Sender: TObject);
  begin
  end;

procedure TfmMain.FormShow(Sender: TObject);
  begin
    // call this method only once
    OnShow := nil;

    // init tuner
    appTunerEx.AddAllForms(True);
    appTunerEx.LoadProperties;
    appTunerEx.TuneComboboxes := True;

    // adjust menu item additional height increase
    appTunerEx.Form[Self].MenuAddHeight := 4;

    // load property values to controls
    seFontScale.Value    := appTunerEx.Form[Self].Scale;
    cbFormDrag.Checked   := appTunerEx.Form[Self].AllowDrag;
    cbOnTop.Checked      := appTunerEx.Form[Self].StayOnTop;
    cbBolderless.Checked := appTunerEx.Form[Self].Borderless;
    cbMenuShow.Checked   := appTunerEx.Form[Self].MenuShow;
    cbMenuTune.Checked   := appTunerEx.Form[Self].MenuTune;
    cbMenuIcons.Checked  := True;

    // use this for autosize and autoset constraints
    appTunerEx.AutoConstraints := True;

    // theme selector
    cbTheme.Items.AddStrings(CAppTheme);
    cbTheme.ItemIndex := Integer(appTunerEx.Theme);
    cbTheme.Enabled   := appTunerEx.IsDarkThemeAvailable;

    // theme detector
    if appTunerEx.IsDarkTheme then
      Label4.Caption := 'Dark: +' else
      Label4.Caption := 'Dark: -';
  end;

procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
  begin
    appTunerEx.SaveProperties;
  end;



procedure TfmMain.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
    appTunerEx.Form[Self].ProcessMouseDown(X, Y);
  end;

procedure TfmMain.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  begin
    if (Shift = [ssLeft]) and (WindowState = wsNormal) then
      appTunerEx.Form[Self].ProcessMouseMove(X, Y);
  end;

procedure TfmMain.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  begin
    appTunerEx.Form[Self].ProcessMouseUp(X, Y);
  end;



procedure TfmMain.actionExecute(Sender: TObject);
  begin
    case TComponent(Sender).Name of

      'btnSecond':
        fmSecond.Show;

      'btnClose':
        Close;

      'seFontScale':
        begin
        appTunerEx.ToolbuttonSize := Round(seFontScale.Value / 100 * 32 * 1.4);
        appTunerEx.Scale          := seFontScale.Value;
        Label3.Caption            := Format('Font H=%d', [Font.Height]);
        end;

      'cbSnap':
        begin
        // standard form option, not a feature of AppTuner
        SnapBuffer                := 24;
        SnapOptions.SnapToMonitor := cbSnap.Checked;
        end;

      'cbBolderless':
        appTunerEx.Form[Self].Borderless := cbBolderless.Checked;

      'cbFormDrag':
        appTunerEx.Form[Self].AllowDrag := cbFormDrag.Checked;

      'cbOnTop':
        appTunerEx.Form[Self].StayOnTop := cbOnTop.Checked;

      'cbMenuShow':
        appTunerEx.Form[Self].MenuShow := cbMenuShow.Checked;

      'cbMenuTune':
        appTunerEx.Form[Self].MenuTune := cbMenuTune.Checked;

      'cbMenuIcons':
        begin
        MainMenu1.Images  := nil;
        PopupMenu1.Images := nil;

        if cbMenuIcons.Checked then
          MainMenu1.Images := ImageList1;

        if cbMenuIcons.Checked then
          PopupMenu1.Images := ImageList2;
        end;

      'cbTheme':
        begin
        appTunerEx.Theme := TAppTheme(cbTheme.ItemIndex);
        //ShowMessage('Restart app to change theme.');
        end;
      end;
  end;



end.
