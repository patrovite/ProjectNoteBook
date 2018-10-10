unit Constantes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  ACT_OK = 0;
  ACT_NO_ERASE = 1;

  NOERROR = 0;
  ERROR_NOTEXT = -1;
  ERROR_ENDDATE = -2;
  ERROR_P_TOOMANYPARAMS = -3;
  ERROR_H_TOOMANYPARAMS = -4;
  ERROR_D_SYNTAXE = -5;
  ERROR_NO_ITEMS = -6;
  ERROR_E_NONUM_OR_PROJECT = -7;
  ERROR_PRIORITY = -8;
  ERROR_PROGRESS = -9;
  ERROR_E_RENAME = -10;
  ERROR_C_SYNTAXE = -11;
  ERROR_X_SYNTAXE = -12;
  ERROR_FMM_SYNTAXE = -13;
  ERROR_FPP_SYNTAXE = -14;
  ERROR_F_SYNTAXE = -15;
  NB_ERROR = 15; //Number of error message

implementation

end.

