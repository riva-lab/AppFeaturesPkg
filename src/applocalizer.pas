
{ AppLocalizer.pas                                 |  (c) 2024 Riva   |  v1.0  |
  ------------------------------------------------------------------------------
  Class for smoothly localization for your application.
  See hints for class methods below.
  Instance of `TAppLocalizer` with name `appLocalizerEx` is already created.
  ------------------------------------------------------------------------------
  Lazarus 3.0  FPC 3.2.2
  ------------------------------------------------------------------------------
  (c) Riva, 2024.03.23
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
  -----------------------------------------------------------------------------}
unit AppLocalizer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, LazFileUtils, Math, IniPropStorage, StdCtrls,
  LCLTranslator, Translations;

type

  { TAppLocalizedComponent
    ----------------------
    Internal class. Do not use it.
  }
  TAppLocalizedComponent = class
  private
    FBackup: record
      Index: Integer;
      end;

  public
    Component: TComponent;
    Strings:   TStringArray;

    constructor Create;
    destructor Destroy; override;

    procedure BeginLocalize;
    procedure EndLocalize;
  end;


  { TAppLocalizer
    -------------
    Class for smoothly localization for your application.
  }
  TAppLocalizer = class
  private
    FLangCodes: TStringArray;
    FLanguages: TStringArray;
    FLang:      Integer;
    FIniFile:   String;
    FLangFile:  String;
    FLangDef:   String;
    FlangSys:   String;
    FLocComps:  array of TAppLocalizedComponent;

    procedure SetCurrentLanguage(AValue: Integer);
    procedure GetLanguagesFromIni;
    function FindComponent(AComponent: TComponent): Integer;
    function GetCurrentLangCode: String;

  public
    { Event occured on language changed.
      Use it to manually translate some specific components.
      You can use Localize() method to do this.
    }
    OnLanguageChange: TNotifyEvent;

    constructor Create;
    destructor Destroy; override;

    { Load list of languages from INI-file `IniFile`.
      INI file must contain list of languages.
      If this file doesn't exist it will be created with 1 default entry.
      `LangDefaultTitle` sets default entry for this purpose.
      `LangFileName` is a basic localization file name:
      'example' for localization files 'example.xx.po' or 'example.xx_yy.po'
    }
    procedure Load(IniFile, LangFileName: String; LangDefaultTitle: String = '');

    { Update component with provided strings from array
      Supported: TComboBox, TListBox.
      Use inside event handler `OnLanguageChange`.
    }
    procedure Localize(AComponent: TComponent; const AStrings: TStringArray);

    { List (array) of available languages
    }
    property Languages: TStringArray read FLanguages;

    { Index of current language.
      Writing new value will start localization
    }
    property CurrentLanguage: Integer read FLang write SetCurrentLanguage;

    { Code of current language
    }
    property CurrentLangCode: String read GetCurrentLangCode;
  end;

var
  appLocalizerEx: TAppLocalizer;


implementation


function GetLangCaption(ALangStr: String; ADelimiter: Char): String;
  begin
    Result := ALangStr.Remove(0, ALangStr.IndexOf(ADelimiter) + 1);
    Result := Result.Remove(0, Result.IndexOf(' ') + 1).Trim;
  end;

function GetLangCode(ALangStr: String; ADelimiter: Char): String;
  begin
    Result := ALangStr.Remove(ALangStr.IndexOf(ADelimiter)).ToLower;
    Result := Result.Remove(Result.IndexOf(' ')).ToLower;
  end;


{ TAppLocalizedComponent }

constructor TAppLocalizedComponent.Create;
  begin
    Component := nil;
    Strings   := nil;
  end;

destructor TAppLocalizedComponent.Destroy;
  begin
    inherited Destroy;
  end;

procedure TAppLocalizedComponent.BeginLocalize;
  begin
    if Component = nil then Exit;

    case Component.ClassName of
      'TComboBox': FBackup.Index := TComboBox(Component).ItemIndex;
      'TListBox': FBackup.Index  := TListBox(Component).ItemIndex;
      end;
  end;

procedure TAppLocalizedComponent.EndLocalize;
  var
    i, w: Integer;
  begin
    if Component = nil then Exit;

    case Component.ClassName of
      'TComboBox':
        with TComboBox(Component) do
          if Length(Strings) > 0 then
            begin
            Items.Clear;
            Items.AddStrings(Strings);
            ItemIndex := FBackup.Index;
            end;

      'TListBox':
        with TListBox(Component) do
          if Length(Strings) > 0 then
            begin
            Items.Clear;
            Items.AddStrings(Strings);
            ItemIndex := FBackup.Index;
            end;
      end;
  end;


{ TAppLocalizer }

procedure TAppLocalizer.SetCurrentLanguage(AValue: Integer);
  var
    i: Integer;
  begin
    if AValue = FLang then Exit;
    FLang := AValue;

    if Length(FLocComps) > 0 then
      for i := 0 to High(FLocComps) do
        FLocComps[i].BeginLocalize;

    SetDefaultLang(CurrentLangCode, '', FLangFile);

    // event on lang change
    if Assigned(OnLanguageChange) then OnLanguageChange(Self);

    if Length(FLocComps) > 0 then
      for i := 0 to High(FLocComps) do
        FLocComps[i].EndLocalize;
  end;

procedure TAppLocalizer.GetLanguagesFromIni;

  procedure AddLang(ACode, ATitle: String);
    begin
      SetLength(FLangCodes, Length(FLangCodes) + 1);
      SetLength(FLanguages, Length(FLanguages) + 1);

      FLangCodes[High(FLangCodes)] := ACode;
      FLanguages[High(FLanguages)] := ATitle;
    end;
  var
    i, cnt: Integer;
    code:   String;
  begin
    with TIniPropStorage.Create(nil) do
      begin
      IniFileName := ExtractFileDir(ParamStrUTF8(0)) + FIniFile;
      Active      := True;
      IniSection  := 'Languages List';

      // create localization ini-file if it doesn't exist
      if not FileExistsUTF8(IniFileName) then
        begin
        WriteInteger('Count', 1);
        WriteString('L-1', FLangDef);
        end;

      // read list of localizations
      cnt := ReadInteger('Count', 1);

      SetLength(FLanguages, 0);
      SetLength(FLangCodes, 0);

      AddLang('', Format('System or native (%s, %s)',
        [GetLanguageID.LanguageCode, GetLanguageID.LanguageID]));

      if cnt > 0 then
        for i := 1 to cnt do
          begin
          code := GetLangCode(ReadString('L-' + i.ToString, ''), ',');
          if FileExistsUTF8(
            ExtractFilePath(ParamStrUTF8(0)) + Format('%s.%s.po', [FLangFile, code])) then
            AddLang(code, GetLangCaption(ReadString('L-' + i.ToString, ''), ','));
          end;

      Free;
      end;
  end;

function TAppLocalizer.FindComponent(AComponent: TComponent): Integer;
  var
    i: Integer;
  begin
    Result := -1;
    if Length(FLocComps) > 0 then
      for i := 0 to High(FLocComps) do
        if FLocComps[i].Component.Name = AComponent.Name then
          Exit(i);
  end;

function TAppLocalizer.GetCurrentLangCode: String;
  begin
    Result   := FLangCodes[FLang];
    if Result = '' then
      Result := GetLanguageID.LanguageCode;
  end;

constructor TAppLocalizer.Create;
  begin
    FLang     := -1;
    FIniFile  := 'languages.ini';
    FLangFile := ExtractFileNameOnly(ExtractFileNameWithoutExt(ParamStrUTF8(0)));
    FLangDef  := '';
    FlangSys  := GetLanguageID.LanguageID;

    OnLanguageChange := nil;
  end;

destructor TAppLocalizer.Destroy;
  var
    i: Integer;
  begin
    if Length(FLocComps) > 0 then
      for i := 0 to High(FLocComps) do
        FLocComps[i].Free;

    SetLength(FLocComps, 0);
    SetLength(FLangCodes, 0);
    SetLength(FLanguages, 0);

    inherited Destroy;
  end;

procedure TAppLocalizer.Load(IniFile, LangFileName: String; LangDefaultTitle: String);
  begin
    FIniFile  := IniFile;
    FLangFile := LangFileName;
    FLangDef  := LangDefaultTitle;

    if FLangDef = '' then FLangDef := 'EN, English';
    GetLanguagesFromIni;
  end;

procedure TAppLocalizer.Localize(AComponent: TComponent; const AStrings: TStringArray);
  var
    index: Integer;
  begin
    index := FindComponent(AComponent);

    if index < 0 then
      begin
      index            := Length(FLocComps);
      SetLength(FLocComps, index + 1);
      FLocComps[index] := TAppLocalizedComponent.Create;
      end;

    with FLocComps[index] do
      begin
      Component := AComponent;
      Strings   := AStrings;
      end;
  end;


initialization
  appLocalizerEx := TAppLocalizer.Create;

end.
