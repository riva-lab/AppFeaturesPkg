
{ AppTuner.pas                                |  (c) 2024-2025 Riva   |  v1.6  |
  ------------------------------------------------------------------------------
  Class `TAppTuner`. Unit also provides pre-created instance `appTunerEx`.
  `TAppTuner` is used to tune some GUI app options for better appearance.

  Features:
  - easy scaling;
  - TCombobox & TToolbar enhancing;
  - set window as borderless;
  - set window as stayed on top;
  - save/restore each form properties (from this class) to ini file;
  - correct restoring form size/pos and window state;
  - custom menu drawing (mainly for scaling availability);
  - allow form dragging by any control using FormMouseDown/Up/Move events;
  - allow theme select (`MetaDarkStyle` package required, see below).

  Note. For correct theme applying you must set `IniFile` property
  in the very beginning of app, before `Application.Initialize` method call.
  ------------------------------------------------------------------------------
  (c) Riva, 2024-2025
  https://riva-lab.gitlab.io        https://gitlab.com/riva-lab
  ==============================================================================

  MIT License
  ------------------------------------------------------------------------------
  Copyright (c) 2024-2025 Riva

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
  ==============================================================================

  Versions:
  ------------------------------------------------------------------------------
  v1.0    2024.03.23
  v1.1    2024.04.16  Add `ClearProperties` method for resetting saved settings
  v1.2    2024.04.17  Fix dark theme multiple applying
  v1.3    2024.04.17  Fix menu drawing bug in nested proc DrawBar
                      Add custom drawn menu update on form `OnChangeBounds`
  v1.4    2024.04.18  Add property `SaveProps` for controlling save/load from ini
  v1.5    2024.04.18  Change menu disabled item text colors for light theme
  v1.5.1  2024.04.18  Change submenu right arrow
  v1.5.2  2025.04.01  Fix menu item width measuring
  v1.6    2025.04.05  Fix menu bar drawing
  -----------------------------------------------------------------------------}
unit AppTuner;

{$mode ObjFPC}{$H+}

{ Uncomment define statement for dark theme support.
  Note. Theme will be applied after app restart!
  MetaDarkStyle package required: https://github.com/zamtmn/metadarkstyle }
{$Define USE_METADARKSTYLE}

interface


uses
  Windows, Classes, SysUtils, LazFileUtils, LCLType, LCLProc, GraphType, Math,
  Forms, IniPropStorage, Controls, StdCtrls, ComCtrls, Graphics, Menus, ImgList
  {$IfDef USE_METADARKSTYLE}
  , uDarkStyleParams, uMetaDarkStyle, uDarkStyleSchemes
  {$EndIf}
  ;


resourcestring
  AT_THEME_ALLOWDARK = 'System';
  AT_THEME_LIGHT     = 'Light';
  AT_THEME_DARK      = 'Dark';


type

  TMenuItemColors = record
    Back, Select, Text, TextSel: TColor;
  end;

  TMenuColors = record
    Bar, Item, Mark, Disabled: TMenuItemColors;
  end;

  TAppTheme = (atAllowDark, atLight, atDark);

  { TFormTuned }

  TFormTuned = class
  private
    FForm:            TForm;
    FIniFile:         String;
    FScale:           Integer;
    FBorderless:      Boolean;
    FStayOnTop:       Boolean;
    FBounds:          TRect;    // coords and sizes of form
    FPosOffset:       TPoint;   // offset beetwen window coords and form coords
    FMouseDPos:       TPoint;   // mouse coords when left button clicks
    FMouseDown:       Boolean;  // flag to show mouse down state
    FLoaded:          Boolean;
    FBorderStyle:     TFormBorderStyle;
    FToolbuttonSize:  Integer;
    FAutoConstraints: Boolean;
    FStateBackup:     TWindowState;
    FStateToSave:     TWindowState;

    FMenuDark:      Boolean;
    FMenuTune:      Boolean;
    FMenuShow:      Boolean;
    FMenuItemH:     Integer;
    FMenuBarCoordL: Integer;
    FMenuBarCoordR: Integer;
    FMenuAddHeight: Integer;
    FMenuColors:    TMenuColors;
    FMainMenu:      TMainMenu;

    procedure SetScale(AValue: Integer);
    procedure SetBorderless(AValue: Boolean);
    procedure SetForm(AValue: TForm);
    procedure SetStayOnTop(AValue: Boolean);
    procedure SetIniFile(AValue: String);
    procedure SetToolbuttonSize(AValue: Integer);
    procedure SetAutoConstraints(AValue: Boolean);
    procedure SetMenuTune(AValue: Boolean);
    procedure SetMenuShow(AValue: Boolean);
    procedure SetMenuDark(AValue: Boolean);
    procedure SetMenuAddHeight(AValue: Integer);

    procedure FormOnChangeBounds(Sender: TObject);
    procedure AutoConstraintsBegin;
    procedure AutoConstraintsEnd;
    procedure ThemeApply;

    procedure MenuDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
    procedure MenuMeasItem(Sender: TObject; ACanvas: TCanvas; var AWidth, AHeight: Integer);

  public
    AllowDrag: Boolean;
    SaveProps: Boolean;

    constructor Create;
    destructor Destroy; override;

    procedure TuneComboboxes;
    procedure MenuAppearance(AColors: TMenuColors; AAddHeight: Integer = 0);

    procedure SavePropertiesToIni(AClear: Boolean = False);
    procedure LoadPropertiesFromIni;

    procedure ProcessMouseDown(X, Y: Integer);
    procedure ProcessMouseUp(X, Y: Integer);
    procedure ProcessMouseMove(X, Y: Integer);

    property Form: TForm read FForm write SetForm;
    property Scale: Integer read FScale write SetScale;
    property Borderless: Boolean read FBorderless write SetBorderless;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop;
    property IniFile: String read FIniFile write SetIniFile;
    property ToolbuttonSize: Integer read FToolbuttonSize write SetToolbuttonSize;
    property AutoConstraints: Boolean read FAutoConstraints write SetAutoConstraints;
    property MenuTune: Boolean read FMenuTune write SetMenuTune;
    property MenuDark: Boolean read FMenuDark write SetMenuDark;
    property MenuShow: Boolean read FMenuShow write SetMenuShow;
    property MenuAddHeight: Integer read FMenuAddHeight write SetMenuAddHeight;
  end;


  { TAppTuner }

  TAppTuner = class
  private
    FScale:                Integer;
    FForms:                array of TFormTuned;
    FIniFile:              String;
    FToolbuttonSize:       Integer;
    FAutoConstraints:      Boolean;
    FTuneComboboxes:       Boolean;
    FMenuTune:             Boolean;
    FMenuShow:             Boolean;
    FIsDarkTheme:          Boolean;
    FIsDarkThemeAvailable: Boolean;
    FClear:                Boolean;
    FTheme:                TAppTheme;

    procedure DoTuneComboboxes;

    function FindForm(AForm: TForm): Integer;
    function GetForms(Index: Integer): TFormTuned;
    function GetForms(AForm: TForm): TFormTuned;

    procedure SetScale(AValue: Integer);
    procedure SetIniFile(AValue: String);
    procedure SetToolbuttonSize(AValue: Integer);
    procedure SetAutoConstraints(AValue: Boolean);
    procedure SetTuneComboboxes(AValue: Boolean);
    procedure SetMenuTune(AValue: Boolean);
    procedure SetTheme(AValue: TAppTheme);
    procedure SetMenuShow(AValue: Boolean);

    procedure LoadDarkThemeSupport(AIniFile: String);
    procedure SaveDarkThemeSupport(AIniFile: String);

  public
    constructor Create;
    destructor Destroy; override;

    procedure AddForm(AForm: TForm; ASaveProps: Boolean = False);
    procedure AddAllForms(ASaveProps: Boolean = False);

    procedure SaveProperties;
    procedure LoadProperties;
    procedure ClearProperties;

    procedure MenuAppearance(AColors: TMenuColors; AAddHeight: Integer = 0);

    property IniFile: String read FIniFile write SetIniFile;
    property Scale: Integer read FScale write SetScale;
    property Forms[Index: Integer]: TFormTuned read GetForms;
    property Form[AForm: TForm]: TFormTuned read GetForms;
    property TuneComboboxes: Boolean read FTuneComboboxes write SetTuneComboboxes;
    property ToolbuttonSize: Integer read FToolbuttonSize write SetToolbuttonSize;
    property AutoConstraints: Boolean read FAutoConstraints write SetAutoConstraints;
    property MenuTune: Boolean read FMenuTune write SetMenuTune;
    property MenuShow: Boolean read FMenuShow write SetMenuShow;

    property Theme: TAppTheme read FTheme write SetTheme;
    property IsDarkThemeAvailable: Boolean read FIsDarkThemeAvailable;
    property IsDarkTheme: Boolean read FIsDarkTheme;
  end;


const
  CAppTheme: array[0..2] of String = (AT_THEME_ALLOWDARK, AT_THEME_LIGHT, AT_THEME_DARK);


var
  appTunerEx: TAppTuner;


implementation


var
  darkModeInitDone: Boolean = False;


function GetFormOffset(AForm: TForm): TPoint;
  var
    winRect: TRect;
  begin
    with AForm do
      begin
      GetWindowRect(Handle, winRect);
      if Assigned(Menu) then
        winRect.Height := winRect.Height - Menu.Height;

      Result.X := (winRect.Width - Width) div 2;
      Result.Y := (winRect.Height - Height) - Result.X;
      end;
  end;

{$IfDef DEBUG}
function TOwnerDrawStateDbg(Sender: TObject; AState: TOwnerDrawState): String;
  const
    s: array[TOwnerDrawStateType] of String = (
      'odSelected', 'odGrayed', 'odDisabled', 'odChecked', 'odFocused',
      'odDefault', 'odHotLight', 'odInactive', 'odNoAccel', 'odNoFocusRect',
      'odReserved1', 'odReserved2', 'odComboBoxEdit', 'odBackgroundPainted');
  var
    e: TOwnerDrawStateType;
  begin
    Result := '';
    for e in TOwnerDrawStateType do
      if e in AState then Result += Format('%s, ', [s[e]]);
  end; 
{$EndIf}


 { TFormTuned }

procedure TFormTuned.SetScale(AValue: Integer);
  begin
    if FScale = AValue then Exit;
    if Form = nil then Exit;

    AutoConstraintsBegin;

    Form.ScaleBy(AValue, FScale);
    FScale   := AValue;
    MenuTune := FMenuTune;

    AutoConstraintsEnd;
  end;

procedure TFormTuned.SetBorderless(AValue: Boolean);
  var
    _boundsBackup: TRect;
    _wsBackup:     TWindowState;
    _offsetSign:   Integer;
  begin
    if FBorderless = AValue then Exit;
    FBorderless := AValue;

    _wsBackup := Form.WindowState;

    case _wsBackup of

      wsNormal:
        begin
        _boundsBackup := Form.BoundsRect;

        if FBorderless then
          begin
          FBorderStyle     := Form.BorderStyle;
          Form.BorderStyle := bsNone;
          _offsetSign      := 1;
          end
        else
          begin
          Form.BorderStyle := FBorderStyle;
          _offsetSign      := -1;
          end;

        _boundsBackup.Offset(
          FPosOffset.X * _offsetSign,
          FPosOffset.Y * _offsetSign);
        Form.BoundsRect := _boundsBackup;
        end;

      wsMaximized:
        if FBorderless then
          begin
          FBorderStyle     := Form.BorderStyle;
          Form.BorderStyle := bsNone;
          end
        else
          begin
          Form.BoundsRect  := FBounds;
          Form.BorderStyle := FBorderStyle;
          end;
      end;

    Form.WindowState := _wsBackup;
    ThemeApply;
  end;

procedure TFormTuned.SetForm(AValue: TForm);
  begin
    if FForm = AValue then Exit;
    FForm := AValue;

    FPosOffset   := GetFormOffset(Form);
    FMenuShow    := Assigned(FForm.Menu);
    FStateBackup := Form.WindowState;
    FStateToSave := FStateBackup;
    Form.AddHandlerOnChangeBounds(@FormOnChangeBounds, True);
  end;

procedure TFormTuned.SetStayOnTop(AValue: Boolean);
  var
    wsBackup: TWindowState;
  begin
    if FStayOnTop = AValue then Exit;
    FStayOnTop := AValue;

    // form position backup
    wsBackup  := Form.WindowState;
    if wsBackup = wsNormal then
      FBounds := Form.BoundsRect;

    if FStayOnTop then
      Form.FormStyle := fsSystemStayOnTop else
      Form.FormStyle := fsNormal;

    // form position restore
    Form.WindowState := wsNormal;
    Form.BoundsRect  := FBounds;
    Form.WindowState := wsBackup;

    ThemeApply;
  end;

procedure TFormTuned.SetIniFile(AValue: String);
  begin
    if FIniFile = AValue then Exit;
    FIniFile := AValue;
  end;

procedure TFormTuned.SetToolbuttonSize(AValue: Integer);
  var
    i: Integer;
  begin
    if AValue = 0 then Exit;
    if FToolbuttonSize = AValue then Exit;
    FToolbuttonSize := AValue;

    AutoConstraintsBegin;

    for i := 0 to Form.ComponentCount - 1 do
      if Form.Components[i].ClassName = 'TToolBar' then
        with TToolBar(Form.Components[i]) do
          begin
          ButtonWidth  := FToolbuttonSize;
          ButtonHeight := ButtonWidth;
          end;

    AutoConstraintsEnd;
  end;

procedure TFormTuned.SetAutoConstraints(AValue: Boolean);
  begin
    if FAutoConstraints = AValue then Exit;
    FAutoConstraints := AValue;

    if FAutoConstraints then Form.AutoSize := False;
    AutoConstraintsBegin;
    AutoConstraintsEnd;
  end;

procedure TFormTuned.SetMenuTune(AValue: Boolean);
  var
    i:       Integer;
    tmpList: TCustomImageList;
  begin
    FMenuTune := AValue;

    for i := 0 to Form.ComponentCount - 1 do
      if Form.Components[i].ClassParent.ClassName = 'TMenu' then
        with TMenu(Form.Components[i]) do
          begin
          tmpList := Images;
          Images  := nil;
          if FMenuTune then
            begin
            OnDrawItem    := TMenuDrawItemEvent(@MenuDrawItem);
            OnMeasureItem := TMenuMeasureItemEvent(@MenuMeasItem);
            end
          else
            begin
            OnDrawItem    := nil;
            OnMeasureItem := nil;
            end;
          Images := tmpList;
          end;
  end;

procedure TFormTuned.SetMenuShow(AValue: Boolean);
  begin
    FMenuShow := AValue;

    if FMenuShow then
      begin
      if not Assigned(Form.Menu) then
        Form.Menu := FMainMenu;
      end
    else
    if Assigned(Form.Menu) then
      begin
      FMainMenu := Form.Menu;
      Form.Menu := nil;
      end;

    ThemeApply;
  end;

procedure TFormTuned.SetMenuDark(AValue: Boolean);
  begin
    FMenuDark := AValue;

    with FMenuColors do
      if FMenuDark then
        begin
        Bar.Back         := clWindow;
        Bar.Select       := clHotLight;
        Bar.Text         := clMenuText;
        Bar.TextSel      := clMenuText;
        Item.Back        := clMenu;
        Item.Select      := clHotLight;
        Item.Text        := clMenuText;
        Item.TextSel     := clMenuText;
        Mark.Back        := clMenuHighlight;
        Mark.Select      := clInactiveCaption;
        Mark.Text        := clMenuText;
        Mark.TextSel     := clMenuText;
        Disabled.Back    := clMenu;
        Disabled.Select  := cl3DLight;
        Disabled.Text    := clGrayText;
        Disabled.TextSel := clGrayText;
        end
      else
        begin
        Bar.Back         := clWindow;
        Bar.Select       := RGBToColor($e5, $f3, $ff);
        Bar.Text         := clMenuText;
        Bar.TextSel      := clMenuText;
        Item.Back        := clMenu;
        Item.Select      := RGBToColor($90, $c8, $f6); // cce8ff
        Item.Text        := clMenuText;
        Item.TextSel     := clMenuText;
        Mark.Back        := RGBToColor($90, $c8, $f6);
        Mark.Select      := RGBToColor($56, $b0, $fa);
        Mark.Text        := RGBToColor($00, $60, $80);
        Mark.TextSel     := clMenuText;
        Disabled.Back    := clMenu;
        Disabled.Select  := cl3DLight;
        Disabled.Text    := clBtnShadow;
        Disabled.TextSel := clBtnShadow;
        end;
  end;

procedure TFormTuned.SetMenuAddHeight(AValue: Integer);
  begin
    if FMenuAddHeight = AValue then Exit;
    FMenuAddHeight := AValue;
  end;

procedure TFormTuned.FormOnChangeBounds(Sender: TObject);
  var
    tmpTune: Boolean;
  begin
    case Form.WindowState of

      wsNormal:
        begin
        FStateToSave := wsNormal;
        FBounds      := Form.BoundsRect;
        if FStateBackup = wsMaximized then
          begin
          AutoConstraintsBegin;
          AutoConstraintsEnd;
          end;
        end;

      wsMaximized:
        begin
        FStateToSave := wsMaximized;
        end;
      end;

    tmpTune  := MenuTune;
    MenuTune := False;
    MenuTune := tmpTune;

    FStateBackup := Form.WindowState;
  end;

procedure TFormTuned.AutoConstraintsBegin;
  begin
    if Form.WindowState <> wsNormal then Exit;
    if FAutoConstraints = False then Exit;

    Form.AutoSize              := False;
    Form.Constraints.MinHeight := 0;
    Form.Constraints.MinWidth  := 0;
    Form.DisableAlign;
  end;

procedure TFormTuned.AutoConstraintsEnd;
  var
    _formPosition: TPosition;
  begin
    if Form.WindowState <> wsNormal then Exit;
    if FAutoConstraints = False then Exit;

    _formPosition   := Form.Position;
    if not FileExistsUTF8(FIniFile) or (FileSizeUtf8(FIniFile) = 0) then
      Form.Position := poDesigned;

    FAutoConstraints           := False;
    Form.AutoSize              := True;
    Form.EnableAlign;
    Form.Constraints.MinHeight := Form.Height;
    Form.Constraints.MinWidth  := Form.Width;
    Form.AutoSize              := False;

    Form.Position := _formPosition;
  end;

procedure TFormTuned.ThemeApply;
  begin
    {$IFDEF USE_METADARKSTYLE}
    if IsDarkModeEnabled then
      MetaDarkFormChanged(FForm);
    {$ENDIF}
  end;

procedure TFormTuned.MenuDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
  //const
  //  subMark   = '❯';
  //  checkMark = '✔';
  //  radioMark = '🔘';
  var
    rx, y, wi, ws: Integer;
    item:          TMenuItem;
    title:         String;
    subMark:       String = '❯';
    checkMark:     String = '✔';
    radioMark:     String = '🔘';
    imList:        TImageList;
    oldWin:        Boolean;

  procedure LoadMarks;
    begin
      if not oldWin then Exit;
      subMark   := '>';
      checkMark := 'v';
      radioMark := '●';
    end;

  function GetCaption: String;
    begin
      Result := String(item.Caption).
        Replace('&&', #0).Replace('&', #1).Replace(#0, '&');
    end;

  function GetCaptionWidth: Integer;
    begin
      Result := ACanvas.TextWidth(GetCaption.Replace(#1, ''));
    end;

  function GetImagesSize: TPoint;
    begin
      if not Assigned(imList) then
        Exit(Classes.Point(ARect.Height - 8, FMenuItemH - 8));

      Result.X := imList.Width;
      Result.Y := imList.Height;
    end;

  function StateIs(ACheck: TOwnerDrawState): Boolean;
    var
      _item: TOwnerDrawStateType;
    begin
      Result := True;
      for _item in ACheck do
        if not (_item in AState) then Exit(False);
    end;

  procedure Check(ACheck: Boolean; AColorBrush, AcolorFont: TColor);
    begin
      if not ACheck then Exit;
      ACanvas.Brush.Color := AColorBrush;
      ACanvas.Font.Color  := AcolorFont;
    end;

  procedure DrawBar;
    begin
      Check(item.IsInMenuBar, FMenuColors.Bar.Back, FMenuColors.Bar.Text);

      if item.RightJustify then
        FMenuBarCoordR := Min(FMenuBarCoordR, ARect.Left) else
        FMenuBarCoordL := Max(FMenuBarCoordL, ARect.Right);

      ACanvas.Pen.Color := ACanvas.Brush.Color;
      ACanvas.Rectangle(
        FMenuBarCoordL, ARect.Top,
        FMenuBarCoordR, ARect.Bottom);
    end;

  procedure DrawSelector;
    begin
      if title <> '-' then
        begin
        Check(StateIs([odHotLight]), FMenuColors.Bar.Select, FMenuColors.Bar.TextSel);
        Check(StateIs([odSelected]), FMenuColors.Item.Select, FMenuColors.Item.TextSel);
        Check(StateIs([odDisabled]), FMenuColors.Disabled.Back, FMenuColors.Disabled.Text);
        Check(StateIs([odSelected, odDisabled]), FMenuColors.Disabled.Select, FMenuColors.Disabled.TextSel);
        Check(StateIs([odDisabled]) and item.IsInMenuBar, FMenuColors.Bar.Back, FMenuColors.Disabled.Text);
        end;

      ACanvas.Pen.Color := ACanvas.Brush.Color;

      with ARect do ACanvas.Rectangle(Left, Top, Right, Bottom);
    end;

  procedure DrawDelimiter;
    begin
      with ARect do
        begin
        ACanvas.Pen.Style := psSolid;
        ACanvas.Pen.Color := FMenuColors.Disabled.TextSel;

        if not item.IsInMenuBar then
          ACanvas.Line(
            Left + wi - ws, CenterPoint.Y,
            Right, CenterPoint.Y);
        end;
    end;

  procedure DrawIcon;
    var
      x, y, r, a: Integer;
      s:          String;
      i:          Boolean;
    begin
      x := ARect.Left + ws;
      y := ARect.Top + FMenuAddHeight div 2;
      r := ARect.Height - FMenuAddHeight;
      i := Assigned(imList) and (item.ImageIndex >= 0);

      if StateIs([odChecked]) and item.Checked then
        begin
        if item.Enabled then
          if StateIs([odSelected]) then
            Check(True, FMenuColors.Mark.Select, FMenuColors.Mark.TextSel) else
            Check(True, FMenuColors.Mark.Back, FMenuColors.Mark.Text)
        else
          Check(True, FMenuColors.Disabled.Select, FMenuColors.Disabled.TextSel);
        a := Round(FMenuAddHeight / 2.6);

        ACanvas.Pen.Color := ACanvas.Brush.Color;
        ACanvas.Rectangle(x - a, y - a, x + r + a, y + r + a);

        if not i then
          begin
          if item.GroupIndex > 0 then
            s := radioMark else
            s := checkMark;

          if oldWin then
            ACanvas.Font.Height := Round(r / 1.2) else
            ACanvas.Font.Height := Round(r / 1.8);
          a := Round((r - ACanvas.TextHeight(s)) / 2);
          r := Round((r - ACanvas.TextWidth(s)) / 2);
          ACanvas.Brush.Style := bsClear;
          ACanvas.TextOut(x + r, y + a, s);
          end;
        end;

      if i then
        begin
        x += (r - imList.Width) div 2;
        y += (r - imList.Height) div 2;
        if item.Enabled then
          imList.Draw(ACanvas, x, y, item.ImageIndex) else
          imList.Draw(ACanvas, x, y, item.ImageIndex, gdeDisabled);
        end;
    end;

  procedure DrawCaption;
    var
      ts: TStringArray;
      x:  Integer;
      s:  String;
      i:  Integer = 0;
    procedure OutStr(Str: String; U: Boolean = False);
      begin
        ACanvas.Font.Underline := U;
        ACanvas.TextRect(ARect, x, y, Str);
        x += ACanvas.TextWidth(Str);
      end;
    begin
      x  := ARect.Left + wi;
      ts := title.Split([#1]);
      for i := 0 to High(ts) do
        begin
        s := ts[i];
        if i > 0 then
          begin
          OutStr(s[1], True);
          s := s.Remove(0, 1);
          end;
        OutStr(s);
        end;
    end;

  procedure DrawSubmenuArrow;
    begin
      rx := ARect.Right - ACanvas.TextWidth(subMark) - 8;
      if not item.IsInMenuBar and (item.Count > 0) then
        begin
        ACanvas.TextRect(ARect, rx, y, subMark);
        end;
    end;

  procedure DrawShortcuts;
    var
      s: String;
    begin
      if item.ShortCut <> 0 then
        begin
        s := ShortCutToText(item.ShortCut);
        if item.ShortCutKey2 <> 0 then s += ', ' + ShortCutToText(item.ShortCutKey2);
        ACanvas.TextRect(ARect, rx - ACanvas.TextWidth(s) - 12, y, s);
        end;
    end;
  begin
    item   := TMenuItem(Sender);
    title  := GetCaption;
    imList := item.GetImageList as TImageList;
    oldWin := Win32BuildNumber < 6000 {WinVista or lower};

    ACanvas.Font.Color := clYellow;

    if item.IsInMenuBar then
      ACanvas.Font.Height := 0 else
      ACanvas.Font.Height := FForm.Font.Height;

    ws := FMenuItemH div 8;

    if item.IsInMenuBar then
      wi := (ARect.Width - GetCaptionWidth) div 2 else
      wi := FMenuItemH - FMenuAddHeight + ws * 3;

    y := ARect.Top + (ARect.Height - ACanvas.TextHeight(title)) div 2;

    ACanvas.Brush.Color := FMenuColors.Item.Back;
    if item.IsInMenuBar then DrawBar;

    DrawSelector;

    if title = '-' then
      begin
      DrawDelimiter;
      Exit;
      end;

    ACanvas.Font.Bold := StateIs([odDefault]);
    Check(True, FMenuColors.Item.Back, FMenuColors.Item.Text);
    Check(StateIs([odChecked]), FMenuColors.Item.Select, FMenuColors.Item.TextSel);
    Check(StateIs([odDisabled]), FMenuColors.Disabled.Back, FMenuColors.Disabled.Text);
    Check(StateIs([odDisabled, odSelected]), FMenuColors.Disabled.Select, FMenuColors.Disabled.TextSel);

    LoadMarks;
    DrawCaption;
    DrawSubmenuArrow;
    DrawShortcuts;
    DrawIcon;

    with ARect do
      ExcludeClipRect(ACanvas.Handle, Left, Top, Right, Bottom);
  end;

procedure TFormTuned.MenuMeasItem(Sender: TObject; ACanvas: TCanvas; var AWidth, AHeight: Integer);
  var
    item: TMenuItem;
  begin
    item := TMenuItem(Sender);

    if Assigned(item.GetImageList) then
      AHeight := item.GetImageList.Height;

    ACanvas.Font.Assign(FForm.Font);

    AHeight    := Max(AHeight, Abs(ACanvas.TextHeight('A')) + 4) + FMenuAddHeight;
    FMenuItemH := AHeight;

    if (item.Caption = '-') or item.IsInMenuBar then
      AHeight := 8 - 1;

    if item.GetParentMenu.OnDrawItem = nil then Exit;

    if not item.IsInMenuBar then
      AWidth := Round(FScale / 100 * (AWidth + 4)) + 8
    else
    if (FMainMenu.Items.Count > 0) and (item.Handle = FMainMenu.Items[0].Handle) then
      begin
      // reset menu bar coordinates
      FMenuBarCoordL := 0;
      FMenuBarCoordR := MaxInt;
      end;
  end;

constructor TFormTuned.Create;
  begin
    Form             := nil;
    FIniFile         := '';
    AllowDrag        := False;
    SaveProps        := False;
    FStayOnTop       := False;
    FBorderless      := False;
    FLoaded          := False;
    FScale           := 100;
    FToolbuttonSize  := 24;
    FAutoConstraints := False;

    FMenuItemH     := 0;
    FMenuAddHeight := 0;
    MenuDark       := False;
    FMenuTune      := False;
    FMenuShow      := False;
    FMainMenu      := nil;
  end;

destructor TFormTuned.Destroy;
  begin
    inherited Destroy;
  end;

procedure TFormTuned.TuneComboboxes;
  var
    sw, i, w, j: Integer;
  begin
    if Form = nil then Exit;

    sw := Form.VertScrollBar.Size;

    for i := 0 to Form.ComponentCount - 1 do
      if Form.Components[i].ClassName = 'TComboBox' then
        with TComboBox(Form.Components[i]) do
          begin
          w := 0;

          for j := 0 to Items.Count - 1 do
            w := Max(w, Form.Canvas.GetTextWidth(Items.Strings[j] + '**'));

          ItemWidth := w + sw;
          end;
  end;

procedure TFormTuned.MenuAppearance(AColors: TMenuColors; AAddHeight: Integer);
  begin
    MenuAddHeight := AAddHeight;
    FMenuColors   := AColors;
  end;

procedure TFormTuned.SavePropertiesToIni(AClear: Boolean);
  begin
    if not SaveProps then Exit;
    if Form = nil then Exit;
    if FIniFile = '' then Exit;

    with TIniPropStorage.Create(Form) do
      try
      IniFileName := FIniFile;
      Active      := True;
      IniSection  := 'AppTuner.' + Form.Name;
      EraseSections;

      if not AClear then
        begin
        WriteInteger('Scale', Scale);
        WriteBoolean('Borderless', Borderless); Borderless := False;
        WriteInteger('Left', FBounds.Left);
        WriteInteger('Top', FBounds.Top);
        WriteInteger('Width', FBounds.Width);
        WriteInteger('Height', FBounds.Height);
        WriteInteger('State', Integer(FStateToSave));
        WriteBoolean('OnTop', StayOnTop);
        WriteBoolean('AllowDrag', AllowDrag);
        WriteBoolean('MenuShow', MenuShow);
        WriteBoolean('MenuTune', MenuTune);
        end;

      IniSection := '';
      finally
      Free;
      end;
  end;

procedure TFormTuned.LoadPropertiesFromIni;
  begin
    if not SaveProps then Exit;
    if FLoaded then Exit;
    if Form = nil then Exit;
    if FIniFile = '' then Exit;

    if FileExistsUTF8(FIniFile) then
      with TIniPropStorage.Create(Form) do
        try
        IniFileName      := FIniFile;
        Active           := True;
        IniSection       := 'AppTuner.' + Form.Name;
        Scale            := ReadInteger('Scale', 100);
        Borderless       := ReadBoolean('Borderless', False);
        FBounds.Left     := ReadInteger('Left', Form.Left);
        FBounds.Top      := ReadInteger('Top', Form.Top);
        FBounds.Width    := ReadInteger('Width', Form.Width);
        FBounds.Height   := ReadInteger('Height', Form.Height);
        Form.BoundsRect  := FBounds;
        Form.WindowState := TWindowState(ReadInteger('State', 0));
        StayOnTop        := ReadBoolean('OnTop', False);
        AllowDrag        := ReadBoolean('AllowDrag', False);
        MenuShow         := ReadBoolean('MenuShow', True);
        MenuTune         := ReadBoolean('MenuTune', False);

        // keep form visible if parameters are incorrect
        with Form do
          begin
          if Abs(Top) - 32 > Screen.Height - Height then Top := (Screen.Height - Height) div 2;
          if Abs(Left) - 32 > Screen.Width - Width then Left := (Screen.Width - Width) div 2;
          end;

        IniSection := '';
        finally
        Free;
        end;

    FLoaded := True;
  end;

procedure TFormTuned.ProcessMouseDown(X, Y: Integer);
  begin
    if Form = nil then Exit;
    if not AllowDrag then Exit;

    FMouseDown := True;

    FMouseDPos.Create(Form.Left - Mouse.CursorPos.X, Form.Top - Mouse.CursorPos.Y);
  end;

procedure TFormTuned.ProcessMouseUp(X, Y: Integer);
  begin
    if Form = nil then Exit;

    FMouseDown := False;
  end;

procedure TFormTuned.ProcessMouseMove(X, Y: Integer);
  begin
    if Form = nil then Exit;
    if not FMouseDown then Exit;

    Form.Left := FMouseDPos.X + Mouse.CursorPos.X;
    Form.Top  := FMouseDPos.Y + Mouse.CursorPos.Y;
  end;


{ TAppTuner }

function TAppTuner.FindForm(AForm: TForm): Integer;
  var
    i: Integer;
  begin
    Result := -1;

    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        if FForms[i].Form.Name = AForm.Name then
          Exit(i);
  end;

procedure TAppTuner.SetScale(AValue: Integer);
  var
    i: Integer;
  begin
    if FScale <> AValue then
      begin
      FScale := AValue;

      if Length(FForms) > 0 then
        for i := 0 to High(FForms) do
          FForms[i].Scale := FScale;
      end;

    DoTuneComboboxes;
  end;

function TAppTuner.GetForms(Index: Integer): TFormTuned;
  begin
    Result := nil;

    if Index in [0..High(FForms)] then
      Result := FForms[Index];
  end;

function TAppTuner.GetForms(AForm: TForm): TFormTuned;
  var
    i: Integer;
  begin
    Result := nil;
    i      := FindForm(AForm);

    if i >= 0 then
      Result := FForms[i];
  end;

procedure TAppTuner.SetIniFile(AValue: String);
  var
    i: Integer;
  begin
    if FIniFile = AValue then Exit;
    FIniFile := AValue;

    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].IniFile := FIniFile;

    LoadDarkThemeSupport(FIniFile);
  end;

procedure TAppTuner.SetToolbuttonSize(AValue: Integer);
  var
    i: Integer;
  begin
    if FToolbuttonSize = AValue then Exit;
    FToolbuttonSize := AValue;

    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].ToolbuttonSize := FToolbuttonSize;
  end;

procedure TAppTuner.SetAutoConstraints(AValue: Boolean);
  var
    i: Integer;
  begin
    if FAutoConstraints = AValue then Exit;
    FAutoConstraints := AValue;

    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].AutoConstraints := FAutoConstraints;
  end;

procedure TAppTuner.SetTuneComboboxes(AValue: Boolean);
  begin
    if FTuneComboboxes = AValue then Exit;
    FTuneComboboxes := AValue;
    DoTuneComboboxes;
  end;

procedure TAppTuner.SetMenuTune(AValue: Boolean);
  var
    i: Integer;
  begin
    FMenuTune := AValue;

    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].MenuTune := FMenuTune;
  end;

procedure TAppTuner.LoadDarkThemeSupport(AIniFile: String);
  {$IfDef USE_METADARKSTYLE}
  const
    CPreferredMode: array[TAppTheme] of TPreferredAppMode =
      (pamAllowDark, pamForceLight, pamForceDark);
    {$EndIf}
  begin
    if AIniFile = '' then Exit;
    if darkModeInitDone then Exit;
    {$IFDEF USE_METADARKSTYLE}

    // dark theme works only on windows 1809 (build 17763) and higher
    {$IFDEF WINDOWS}
    if Win32BuildNumber >= 17763 then
    {$ENDIF}

    // read theme value from app .ini settings file
    with TIniPropStorage.Create(nil) do
      begin
      IniFileName           := AIniFile;
      Active                := True;
      IniSection            := 'AppTuner.DarkTheme';
      FTheme                := TAppTheme(ReadInteger('AppTheme', 0));
      PreferredAppMode      := CPreferredMode[FTheme];
      uMetaDarkStyle.ApplyMetaDarkStyle(DefaultDark); // apply theme  
      FIsDarkTheme          := IsDarkModeEnabled;
      FIsDarkThemeAvailable := True;
      darkModeInitDone      := True;
      Free;
      end;

    {$ENDIF}
  end;

procedure TAppTuner.SaveDarkThemeSupport(AIniFile: String);
  begin
    if AIniFile = '' then Exit;
    {$IFDEF USE_METADARKSTYLE}

    // dark theme works only on windows 1809 (build 17763) and higher
    {$IFDEF WINDOWS}
    if Win32BuildNumber >= 17763 then
    {$ENDIF}

    // read theme value from app .ini settings file
    with TIniPropStorage.Create(nil) do
      begin
      IniFileName := AIniFile;
      Active      := True;
      IniSection  := 'AppTuner.DarkTheme';
      EraseSections;

      if not FClear then
        WriteInteger('AppTheme', Integer(FTheme));

      IniSection := '';
      Free;
      end;

    {$ENDIF}
  end;

procedure TAppTuner.SetTheme(AValue: TAppTheme);
  begin
    if FTheme = AValue then Exit;
    FTheme := AValue;
  end;

procedure TAppTuner.SetMenuShow(AValue: Boolean);
  var
    i: Integer;
  begin
    FMenuShow := AValue;

    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].MenuShow := FMenuShow;
  end;

constructor TAppTuner.Create;
  begin
    SetLength(FForms, 0);
    FScale                := 100;
    FIniFile              := '';
    FIsDarkThemeAvailable := False;
    FClear                := False;
  end;

destructor TAppTuner.Destroy;
  begin
    inherited Destroy;
  end;

procedure TAppTuner.AddForm(AForm: TForm; ASaveProps: Boolean);
  var
    i: Integer;
  begin
    if not Assigned(AForm) then Exit;
    i := FindForm(AForm);

    if i < 0 then
      begin
      i := Length(FForms);
      SetLength(FForms, i + 1);

      FForms[i] := TFormTuned.Create;
      end;

    FForms[i].Form            := AForm;
    FForms[i].SaveProps       := ASaveProps;
    FForms[i].IniFile         := FIniFile;
    FForms[i].Scale           := FScale;
    FForms[i].ToolbuttonSize  := FToolbuttonSize;
    FForms[i].AutoConstraints := FAutoConstraints;
    FForms[i].MenuTune        := FMenuTune;
    FForms[i].MenuDark        := FIsDarkTheme;
  end;

procedure TAppTuner.AddAllForms(ASaveProps: Boolean);
  var
    i: Integer;
  begin
    for i := 0 to Screen.FormCount - 1 do
      AddForm(Screen.Forms[i], ASaveProps);
  end;

procedure TAppTuner.SaveProperties;
  var
    i: Integer;
  begin
    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].SavePropertiesToIni(FClear);

    SaveDarkThemeSupport(FIniFile);
  end;

procedure TAppTuner.LoadProperties;
  var
    i: Integer;
  begin
    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].LoadPropertiesFromIni;

    SetScale(Scale);
  end;

procedure TAppTuner.ClearProperties;
  begin
    FClear := True;
  end;

procedure TAppTuner.MenuAppearance(AColors: TMenuColors; AAddHeight: Integer);
  var
    i: Integer;
  begin
    if Length(FForms) > 0 then
      for i := 0 to High(FForms) do
        FForms[i].MenuAppearance(AColors, AAddHeight);
  end;

procedure TAppTuner.DoTuneComboboxes;
  var
    i: Integer;
  begin
    if FTuneComboboxes then
      if Length(FForms) > 0 then
        for i := 0 to High(FForms) do
          FForms[i].TuneComboboxes;
  end;


initialization
  appTunerEx := TAppTuner.Create;

end.
