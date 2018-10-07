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


  ERROR_NOTEXT_STR = 'Pas de texte';
  ERROR_ENDDATE_STR = 'Date non valide';
  ERROR_P_TOOMANYPARAMS_STR = 'P command, too many parameters. "P"';
  ERROR_H_TOOMANYPARAMS_STR = 'H command, too many parameters. "H"';
  ERROR_D_SYNTAXE_STR = 'D command, wrong number of parameters. "D num" or "D project"';
  ERROR_NO_ITEMS_STR = 'No item in the list.';
  ERROR_E_NONUM_OR_PROJECT_STR = 'E command, first parameter must be the item number or a project. "E num ... or E @project ...';
  ERROR_PRIORITY_STR = 'Priority must between 0 and 2';
  ERROR_PROGRESS_STR = 'Progress must between 0 and 100';
  ERROR_E_RENAME_STR = 'E command : Project rename syntaxe error. "E @old_project_name new_project_name"';
  ERROR_C_SYNTAXE_STR = 'C command : syntaxe error. "C num [@project]"';
  ERROR_X_SYNTAXE_STR = 'X command : syntaxe error. "X n/t"';
  ERROR_FMM_SYNTAXE_STR = 'F-- command : Syntaxe error. "F--"';
  ERROR_FPP_SYNTAXE_STR = 'F++ command : Syntaxe error. "F++"';
  ERROR_F_SYNTAXE_STR = 'F command : Syntaxe error. "F [-/+@project]"';

implementation

end.

