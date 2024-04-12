unit i18n;

{
  This is project localization file.
  It contains all strings which must be translated.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring
  {
    Put here your i18n string.
  }

  CB1_TEST_1 = 'item 1';
  CB1_TEST_2 = 'item 2';
  CB1_TEST_3 = 'item 3';
  CB1_TEST_4 = 'item 4';

  LB1_TEST_1 = 'line 1';
  LB1_TEST_2 = 'line 2';
  LB1_TEST_3 = 'line 3';
  LB1_TEST_4 = 'line 4';

const
  {
    Put here arrays of i18n strings.
    Note that you must provide specific length of array: array[0..3] of String
    You can also set range using enumerations:           array[TEnumType] of String
    Do not use dynamic arrays! They does not work appropriatelly.
  }

  i18nCB1: array[0..3] of String = (CB1_TEST_1, CB1_TEST_2, CB1_TEST_3, CB1_TEST_4);
  i18nLB1: array[0..3] of String = (LB1_TEST_1, LB1_TEST_2, LB1_TEST_3, LB1_TEST_4);

implementation

end.
