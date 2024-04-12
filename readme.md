# AppFeaturesPkg

A **FreePascal** package for **Lazarus IDE** that provides several modules for customizing GUI applications and implementing standard application functionality.

Package gets together several completely mutually independent units:

- **AppTuner**. Class `TAppTuner` is used to tune some GUI application options for better appearance.

- **AppSettings**. Class `TAppSettings` for easy work with application settings.

- **AppLocalizer**. Class `TAppLocalizer` for smoothly localization for the application.

Notes:

1. > Package was tested on **Lazarus 3.0 FPC 3.2.2**.
2. > Package was tested only on **Windows 10**.

## Features of units

### Unit *AppTuner*

Unit implements class `TAppTuner`. Unit also provides pre-created instance `appTunerEx`. `TAppTuner` is used to tune some GUI application options for better appearance.

Features:

- easy **scaling**;

- `TCombobox` & `TToolbar` enhancing;

- set window as **borderless**;

- set window as **stayed on top**;

- **save/restore** each form properties (from this class) to INI file;

- correct restoring form size/pos and window state;

- **custom menu** drawing (mainly for scaling availability);

- allow **form dragging** by any control using `FormMouseDown/Up/Move` events;

- allow **theme** select (`MetaDarkStyle` package required, see chapter *Dependencies*).

>   Note. For correct theme applying you must set `IniFile` property in the very beginning of application running, before `Application.Initialize` method call.

How to use **AppTuner** see example [_AppTuner.lpi](examples/AppTuner/src/_AppTuner.lpi) in this [directory](examples/AppTuner/src/).

### Unit *AppSettings*

Unit implements class `TAppSettings` for easy work with settings. It allows exchange between class property and variable by pointer. Support of non-class values by string ID. Save to and load from INI file. Supports following classes and properties:

| Class          | Sync property | Associated var type   |
| -------------- | ------------- | --------------------- |
| TSpinEdit      | Value         | Integer               |
| TFloatSpinEdit | Value         | Double                |
| TComboBox      | ItemIndex     | Integer               |
| TListBox       | ItemIndex     | Integer               |
| TRadioGroup    | ItemIndex     | Integer               |
| TNotebook      | PageIndex     | Integer               |
| TPageControl   | PageIndex     | Integer               |
| TPairSplitter  | Position      | Integer (in promille) |
| TTrackBar      | Position      | Integer               |
| TCheckBox      | Checked       | Boolean               |
| TRadioButton   | Checked       | Boolean               |
| TAction        | Checked       | Boolean               |
| TToggleBox     | Checked       | Boolean               |
| TColorButton   | ButtonColor   | TColor                |
| TEdit          | Text          | String                |
| TLabeledEdit   | Text          | String                |
| TMaskEdit      | Text          | String                |
| TEditButton    | Text          | String                |
| TFileNameEdit  | Text          | String                |
| TDirectoryEdit | Text          | String                |
| TDateEdit      | Text          | String                |
| TTimeEdit      | Text          | String                |
| TCheckGroup    | Checked[]     | String                |
| TCheckListBox  | Checked[]     | String                |

How to use **AppSettings** see example [_AppSettings.lpi](examples/AppSettings/src/_AppSettings.lpi) in this [directory](examples/AppSettings/src/).

### Unit *AppLocalizer*

Unit implements class `TAppLocalizer` for smoothly localization for your application. See hints for class methods in unit's code. Instance of `TAppLocalizer` with name `appLocalizerEx` is already created.

**AppLocalizer** utilizes Lazarus regular i18n functionality, enable it in your project parameters.

How to use **AppLocalizer** see example [_AppLocalizer.lpi](examples/AppLocalizer/src/_AppLocalizer.lpi) in this [directory](examples/AppLocalizer/src/).

## Dependencies

The package depends on:

- [metadarkstyle](https://github.com/zamtmn/metadarkstyle) — package that adds dark theme to your program under windows 10. Copyright (c) 2023 zamtmn.

## How to use

1. In **Lazarus IDE** click `Package > Open package file (.lpk)`.
2. Select and open **AppFeaturesPkg.lpk**.
3. In package window click `Use > Add to Project`.
4. In your code in `uses` section add one or more of package units.
5. See usage example in [examples](examples) directory.

## License

Package releases under [MIT License](license.txt). Copyright (c) 2024 Riva.
