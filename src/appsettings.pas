
{ AppSettings.pas                                  |  (c) 2024 Riva   |  v1.1  |
  ------------------------------------------------------------------------------
  Class `TAppSettings` for easy work with settings.
  It allows exchange between class property and variable by pointer.
  Support of non-class values by string ID.
  Save to and load from INI file.

  Supports following classes and properties:

  class            sync property     associated var type
  ------------------------------------------------------
  TSpinEdit        Value             Integer
  TFloatSpinEdit   Value             Double
  TComboBox        ItemIndex         Integer
  TListBox         ItemIndex         Integer
  TRadioGroup      ItemIndex         Integer
  TNotebook        PageIndex         Integer
  TPageControl     PageIndex         Integer
  TPairSplitter    Position          Integer (in promille)
  TTrackBar        Position          Integer
  TCheckBox        Checked           Boolean
  TRadioButton     Checked           Boolean
  TAction          Checked           Boolean
  TToggleBox       Checked           Boolean
  TColorButton     ButtonColor       TColor
  TEdit            Text              String
  TLabeledEdit     Text              String
  TMaskEdit        Text              String
  TEditButton      Text              String
  TFileNameEdit    Text              String
  TDirectoryEdit   Text              String
  TDateEdit        Text              String
  TTimeEdit        Text              String
  TCheckGroup      Checked[]         String
  TCheckListBox    Checked[]         String
  TMemo            Lines.CommaText   String

  Класс для обмена значениями между
  свойством компонента и переменной по указателю.
  Используется для упрощения работы с массивом настроек.
  Также сохраняет настройки в заданный ini-файл.
  ------------------------------------------------------------------------------
  (c) Riva, 2024.04.16
  https://riva-lab.gitlab.io        https://gitlab.com/riva-lab
  ==============================================================================

  MIT License
  ------------------------------------------------------------------------------
  Copyright (c) 2024 Riva

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
  v1.1    2024.04.16  Fix loading mechanism
                      Fix bug in `Find(TComponent)`
                      Add `TMemo` component support
                      Add `Clear` method for settings reset
  -----------------------------------------------------------------------------}
unit AppSettings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Spin, StdCtrls, ExtCtrls, Dialogs, Graphics, MaskEdit,
  ComCtrls, CheckLst, PairSplitter, EditBtn, ActnList, IniPropStorage, base64;

type

  TAppSettingsType = (stInt, stInt64, stWord, stQWord, stBool, stString, stDouble);


  { TAppSettingsItem }

  TAppSettingsItem = class
  private
    FValueDef:  String;
    FValueType: TAppSettingsType;
    FFS:        TFormatSettings;

    procedure SetValueDef(AValue: String);
    procedure SetValueType(AValue: TAppSettingsType);

  public
    ID:         String;
    Component:  TComponent;
    ValuePtr:   Pointer;
    Multiplier: Integer;

    constructor Create;
    destructor Destroy; override;

    procedure SyncComponent;
    procedure SyncValue;

    procedure Write(AStorage: TIniPropStorage);
    procedure Read(AStorage: TIniPropStorage);

    property ValueDef: String read FValueDef write SetValueDef;
    property ValueType: TAppSettingsType read FValueType write SetValueType;
  end;


  { TAppSettings }

  TAppSettings = class
  private
    FIniStorage: TIniPropStorage;
    FItems:      array of TAppSettingsItem;
    FIniFile:    String;
    FClear:      Boolean;

    procedure Reset;
    function Find(AComponent: TComponent): Integer;
    function Find(UID: String): Integer;

    procedure Add(AComponent: TComponent; AValuePtr: Pointer; AMultiplier: Integer;
      UID: String; AType: TAppSettingsType; ADefaultValue: String);

    procedure SetIniFile(AValue: String);

  public
    OnLoad:           TNotifyEvent;
    OnSave:           TNotifyEvent;
    OnSyncComponents: TNotifyEvent;
    OnSyncValues:     TNotifyEvent;

    constructor Create;
    constructor Create(AIniFileName: String);
    destructor Destroy; override;

    procedure Add(UID: String; AType: TAppSettingsType; AValuePtr: Pointer; ADefaultValue: String = '');
    procedure Add(AComponent: TComponent; AValuePtr: Pointer = nil);
    procedure Add(AComponent: TComponent; AValuePtr: Pointer; AMultiplier: Integer);

    procedure Save;
    procedure Load;
    procedure Clear;

    procedure SyncComponents;
    procedure SyncValues;

    property IniFile: String read FIniFile write SetIniFile;
  end;


implementation

{ TAppSettingsItem }

procedure TAppSettingsItem.SetValueDef(AValue: String);
  begin
    FValueDef := AValue;

    if FValueDef = '' then
      case FValueType of

        stInt, stInt64, stWord, stQWord, stDouble:
          FValueDef := '0';

        stBool:
          FValueDef := False.ToString;
        end;
  end;

procedure TAppSettingsItem.SetValueType(AValue: TAppSettingsType);
  begin
    FValueType := AValue;
    SetValueDef(FValueDef);
  end;

constructor TAppSettingsItem.Create;
  begin
    Component  := nil;
    ValuePtr   := nil;
    Multiplier := 1;
    FValueDef  := '';
    FValueType := stString;

    FFS := DefaultFormatSettings;
    FFS.DecimalSeparator := '.';
  end;

destructor TAppSettingsItem.Destroy;
  begin
    inherited Destroy;
  end;

procedure TAppSettingsItem.SyncComponent;
  var
    _p: Pointer;
    _c: TComponent;
    i:  Integer;
  begin
    if not Assigned(Component) then Exit;
    if not Assigned(ValuePtr) then Exit;

    _p := ValuePtr;
    _c := Component;

      try
      case _c.ClassName of
        'TSpinEdit': TSpinEdit(_c).Value             := (PInteger(_p))^ div Multiplier;
        'TFloatSpinEdit': TFloatSpinEdit(_c).Value   := (PDouble(_p))^ / Multiplier;
        'TComboBox': TComboBox(_c).ItemIndex         := (PInteger(_p))^;
        'TListBox': TListBox(_c).ItemIndex           := (PInteger(_p))^;
        'TRadioGroup': TRadioGroup(_c).ItemIndex     := (PInteger(_p))^;
        'TNotebook': TNotebook(_c).PageIndex         := (PInteger(_p))^;
        'TPageControl': TPageControl(_c).PageIndex   := (PInteger(_p))^;
        'TTrackBar': TTrackBar(_c).Position          := (PInteger(_p))^;
        'TColorButton': TColorButton(_c).ButtonColor := (PColor(_p))^;
        'TCheckBox': TCheckBox(_c).Checked           := (PBoolean(_p))^;
        'TRadioButton': TRadioButton(_c).Checked     := (PBoolean(_p))^;
        'TAction': TAction(_c).Checked               := (PBoolean(_p))^;
        'TToggleBox': TToggleBox(_c).Checked         := (PBoolean(_p))^;

        'TEdit': TEdit(_c).Text         := (PString(_p))^;
        'TMaskEdit': TMaskEdit(_c).Text := (PString(_p))^;
        'TDateEdit': TDateEdit(_c).Text := (PString(_p))^;
        'TTimeEdit': TTimeEdit(_c).Text := (PString(_p))^;

        'TLabeledEdit': TLabeledEdit(_c).Text     := (PString(_p))^;
        'TEditButton': TEditButton(_c).Text       := (PString(_p))^;
        'TFileNameEdit': TFileNameEdit(_c).Text   := (PString(_p))^;
        'TDirectoryEdit': TDirectoryEdit(_c).Text := (PString(_p))^;
        'TMemo': TMemo(_c).Lines.CommaText        := (PString(_p))^;

        'TCheckGroup':
          if TCheckGroup(_c).Items.Count > 0 then
            for i := 0 to TCheckGroup(_c).Items.Count - 1 do
              TCheckGroup(_c).Checked[i] := (PString(_p))^[i + 1] = '+';

        'TCheckListBox':
          if TCheckListBox(_c).Items.Count > 0 then
            for i := 0 to TCheckListBox(_c).Items.Count - 1 do
              TCheckListBox(_c).Checked[i] := (PString(_p))^[i + 1] = '+';

        'TPairSplitter':
          TPairSplitter(_c).Position := (PInteger(_p))^ * TPairSplitter(_c).Width div 1000;
        end;
      except
      end;
  end;

procedure TAppSettingsItem.SyncValue;
  var
    _p: Pointer;
    _c: TComponent;
    i:  Integer;
  begin
    if not Assigned(Component) then Exit;
    if not Assigned(ValuePtr) then Exit;

    _p := ValuePtr;
    _c := Component;

      try
      case _c.ClassName of
        'TSpinEdit': (PInteger(_p))^     := TSpinEdit(_c).Value * Multiplier;
        'TFloatSpinEdit': (PDouble(_p))^ := TFloatSpinEdit(_c).Value * Multiplier;
        'TComboBox': (PInteger(_p))^     := TComboBox(_c).ItemIndex;
        'TListBox': (PInteger(_p))^      := TListBox(_c).ItemIndex;
        'TRadioGroup': (PInteger(_p))^   := TRadioGroup(_c).ItemIndex;
        'TNotebook': (PInteger(_p))^     := TNotebook(_c).PageIndex;
        'TPageControl': (PInteger(_p))^  := TPageControl(_c).PageIndex;
        'TTrackBar': (PInteger(_p))^     := TTrackBar(_c).Position;
        'TColorButton': (PColor(_p))^    := TColorButton(_c).ButtonColor;
        'TCheckBox': (PBoolean(_p))^     := TCheckBox(_c).Checked;
        'TRadioButton': (PBoolean(_p))^  := TRadioButton(_c).Checked;
        'TAction': (PBoolean(_p))^       := TAction(_c).Checked;
        'TToggleBox': (PBoolean(_p))^    := TToggleBox(_c).Checked;
        'TEdit': (PString(_p))^          := TEdit(_c).Text;
        'TMaskEdit': (PString(_p))^      := TMaskEdit(_c).Text;
        'TDateEdit': (PString(_p))^      := TDateEdit(_c).Text;
        'TTimeEdit': (PString(_p))^      := TTimeEdit(_c).Text;
        'TLabeledEdit': (PString(_p))^   := TLabeledEdit(_c).Text;
        'TEditButton': (PString(_p))^    := TEditButton(_c).Text;
        'TFileNameEdit': (PString(_p))^  := TFileNameEdit(_c).Text;
        'TDirectoryEdit': (PString(_p))^ := TDirectoryEdit(_c).Text;
        'TMemo': (PString(_p))^          := TMemo(_c).Lines.CommaText;

        'TCheckGroup':
          begin
          (PString(_p))^ := '';
          if TCheckGroup(_c).Items.Count > 0 then
            for i := 0 to TCheckGroup(_c).Items.Count - 1 do
              (PString(_p))^ += BoolToStr(TCheckGroup(_c).Checked[i], '+', '-');
          end;

        'TCheckListBox':
          begin
          (PString(_p))^ := '';
          if TCheckListBox(_c).Items.Count > 0 then
            for i := 0 to TCheckListBox(_c).Items.Count - 1 do
              (PString(_p))^ += BoolToStr(TCheckListBox(_c).Checked[i], '+', '-');
          end;

        'TPairSplitter':
          (PInteger(_p))^ := 1000 * TPairSplitter(_c).Position div TPairSplitter(_c).Width;
        end;
      except
      end;
  end;

procedure TAppSettingsItem.Write(AStorage: TIniPropStorage);
  var
    _p: Pointer;
    _n: String;
  begin
    if not Assigned(AStorage) then Exit;
    if not Assigned(ValuePtr) then Exit;

    _p := ValuePtr;

    with AStorage do
      if Assigned(Component) then
        begin
        _n := Component.Name;

        case Component.ClassName of

          'TSpinEdit', 'TComboBox', 'TListBox', 'TRadioGroup', 'TNotebook',
          'TPageControl', 'TPairSplitter', 'TTrackBar':
            WriteInteger(_n, (PInteger(_p))^);

          'TCheckBox', 'TRadioButton', 'TAction', 'TToggleBox':
            WriteBoolean(_n, (PBoolean(_p))^);

          'TEdit', 'TLabeledEdit', 'TMaskEdit', 'TCheckGroup', 'TCheckListBox',
          'TEditButton', 'TFileNameEdit', 'TDirectoryEdit', 'TDateEdit',
          'TTimeEdit':
            WriteString(_n, (PString(_p))^);

          'TMemo':
            WriteString(_n, EncodeStringBase64((PString(_p))^));

          'TFloatSpinEdit': WriteString(_n, (PDouble(_p))^.ToString(FFS));
          'TColorButton': WriteInteger(_n, (PColor(_p))^);
          end;
        end
      else
      if ID <> '' then
        case FValueType of
          stInt: WriteInteger(ID, (PInteger(_p))^);
          stInt64: WriteInteger(ID, (PInt64(_p))^);
          stWord: WriteString(ID, (PWord(_p))^.ToString);
          stQWord: WriteString(ID, (PQWord(_p))^.ToString);
          stBool: WriteBoolean(ID, (PBoolean(_p))^);
          stString: WriteString(ID, (PString(_p))^);
          stDouble: WriteString(ID, ((PDouble(_p))^).ToString(FFS));
          end;
  end;

procedure TAppSettingsItem.Read(AStorage: TIniPropStorage);
  var
    _p: Pointer;
    _n: String;
  begin
    if not Assigned(AStorage) then Exit;
    if not Assigned(ValuePtr) then Exit;

    _p := ValuePtr;

    with AStorage do
      if Assigned(Component) then
        begin
        _n := Component.Name;
        if ReadString(_n, '{320B3B72-B768-4CCC-AA7C-10FF74F339F3}')
          = '{320B3B72-B768-4CCC-AA7C-10FF74F339F3}' then Exit;

        case Component.ClassName of

          'TSpinEdit', 'TComboBox', 'TListBox', 'TRadioGroup', 'TNotebook',
          'TPageControl', 'TPairSplitter', 'TTrackBar':
            (PInteger(_p))^ := ReadInteger(_n, 0);

          'TCheckBox', 'TRadioButton', 'TAction', 'TToggleBox':
            (PBoolean(_p))^ := ReadBoolean(_n, False);

          'TEdit', 'TLabeledEdit', 'TMaskEdit', 'TCheckGroup', 'TCheckListBox',
          'TEditButton', 'TFileNameEdit', 'TDirectoryEdit', 'TDateEdit',
          'TTimeEdit':
            (PString(_p))^ := ReadString(_n, '');

          'TMemo':
            (PString(_p))^ := DecodeStringBase64(ReadString(_n, ''));

          'TFloatSpinEdit': (PDouble(_p))^ := StrToFloat(ReadString(_n, '0'), FFS);
          'TColorButton': (PColor(_p))^    := TColor(ReadInteger(_n, 0));
          end;
        end
      else
      if ID <> '' then
        case FValueType of
          stInt: (PInteger(_p))^     := ReadInteger(ID, FValueDef.ToInteger);
          stInt64: (PInt64(_p))^     := ReadString(ID, FValueDef).ToInt64;
          stWord: (PWord(_p))^       := StrToQWord(ReadString(ID, FValueDef));
          stQWord: (PQWord(_p))^     := StrToQWord(ReadString(ID, FValueDef));
          stBool: (PBoolean(_p))^    := ReadBoolean(ID, FValueDef.ToBoolean);
          stString: (PString(_p))^   := ReadString(ID, FValueDef);
          stDouble: ((PDouble(_p))^) := StrToFloat(ReadString(ID, FValueDef), FFS);
          end;
  end;


{ TAppSettings }

procedure TAppSettings.Reset;
  var
    i: Integer;
  begin
    if Length(FItems) > 0 then
      for i := 0 to High(FItems) do
        FItems[i].Free;

    SetLength(FItems, 0);
  end;

function TAppSettings.Find(AComponent: TComponent): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    if not Assigned(AComponent) then Exit;
    if Length(FItems) = 0 then Exit;
    for i := 0 to High(FItems) do
      if FItems[i].Component = AComponent then Exit(i);
  end;

function TAppSettings.Find(UID: String): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    if UID = '' then Exit;
    if Length(FItems) = 0 then Exit;
    for i := 0 to High(FItems) do
      if FItems[i].ID = UID then Exit(i);
  end;

procedure TAppSettings.Add(AComponent: TComponent; AValuePtr: Pointer;
  AMultiplier: Integer; UID: String; AType: TAppSettingsType;
  ADefaultValue: String);
  var
    lastIndex: Integer;
  begin
    if Assigned(AComponent) then
      lastIndex := Find(AComponent)
    else
    if UID = '' then Exit
    else
      lastIndex := Find(UID);

    if lastIndex < 0 then
      begin
      SetLength(FItems, Length(FItems) + 1);
      FItems[High(FItems)] := TAppSettingsItem.Create;

      with FItems[High(FItems)] do
        begin
        ID         := UID;
        ValueType  := AType;
        Component  := AComponent;
        ValuePtr   := AValuePtr;
        ValueDef   := ADefaultValue;
        Multiplier := AMultiplier;
        end;
      end;
  end;

procedure TAppSettings.SetIniFile(AValue: String);
  begin
    FIniFile                := AValue;
    FIniStorage.IniFileName := FIniFile;
  end;

constructor TAppSettings.Create;
  begin
    Reset;

    FIniStorage.Free;
    FIniStorage := TIniPropStorage.Create(nil);
    FIniFile    := '';
    FClear      := False;

    OnLoad           := nil;
    OnSave           := nil;
    OnSyncComponents := nil;
    OnSyncValues     := nil;
  end;

constructor TAppSettings.Create(AIniFileName: String);
  begin
    Create;
    IniFile := AIniFileName;
  end;

destructor TAppSettings.Destroy;
  begin
    Create;

    inherited Destroy;
  end;

procedure TAppSettings.Add(UID: String; AType: TAppSettingsType; AValuePtr: Pointer; ADefaultValue: String);
  begin
    Add(nil, AValuePtr, 1, UID, AType, ADefaultValue);
  end;

procedure TAppSettings.Add(AComponent: TComponent; AValuePtr: Pointer);
  begin
    Add(AComponent, AValuePtr, 1);
  end;

procedure TAppSettings.Add(AComponent: TComponent; AValuePtr: Pointer; AMultiplier: Integer);
  begin
    Add(AComponent, AValuePtr, AMultiplier, '', stInt, '');
  end;

procedure TAppSettings.Save;
  var
    i: Integer;
  begin
    if FIniFile = '' then Exit;

    with FIniStorage do
      begin
      Active     := True;
      IniSection := 'TAppSettingsRecord';
      EraseSections;

      if not FClear and (Length(FItems) > 0) then
        for i := 0 to High(FItems) do
          FItems[i].Write(FIniStorage);

      IniSection := '';
      end;

    if Assigned(OnSave) then OnSave(Self);
  end;

procedure TAppSettings.Load;
  var
    i: Integer;
  begin
    if FIniFile = '' then Exit;

    with FIniStorage do
      begin
      Active     := True;
      IniSection := 'TAppSettingsRecord';

      if Length(FItems) > 0 then
        for i := 0 to High(FItems) do
          FItems[i].Read(FIniStorage);

      IniSection := '';
      end;

    if Assigned(OnLoad) then OnLoad(Self);
  end;

procedure TAppSettings.Clear;
  begin
    FClear := True;
  end;

procedure TAppSettings.SyncComponents;
  var
    i: Integer;
  begin
    if Length(FItems) = 0 then Exit;

    for i := 0 to High(FItems) do
      FItems[i].SyncComponent;

    if Assigned(OnSyncComponents) then OnSyncComponents(Self);
  end;

procedure TAppSettings.SyncValues;
  var
    i: Integer;
  begin
    if Length(FItems) = 0 then Exit;

    for i := 0 to High(FItems) do
      FItems[i].SyncValue;

    if Assigned(OnSyncValues) then OnSyncValues(Self);
  end;



end.
