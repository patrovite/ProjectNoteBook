unit dlgConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ButtonPanel,
  Calendar, ValEdit, StdCtrls, keys, windows, inifiles,utils,configuration;

type

  { TfrmConfig }

  TfrmConfig = class(TForm)
    ButtonPanel: TButtonPanel;
    cbLanguage: TComboBox;
    cbDateFormat: TComboBox;
    chkMinimizeOnStart: TCheckBox;
    chkHideOnMinimize: TCheckBox;
    chkHideOnClose: TCheckBox;
    chkShift: TCheckBox;
    chkConfirmDelItem: TCheckBox;
    chkConfirmDelProject: TCheckBox;
    chkCtrl: TCheckBox;
    chkAlt: TCheckBox;
    chkWin: TCheckBox;
    edKey: TEdit;
    edCharWeek: TEdit;
    grpbGlobalShortcut: TGroupBox;
    grpbMix: TGroupBox;
    grpbConfirmation: TGroupBox;
    grpbAppState: TGroupBox;
    grpbLanguage: TGroupBox;
    lbWeekChar: TLabel;
    lbDateFormat: TLabel;
    lbMinimizeOnStart: TLabel;
    lbHideOnMinimize: TLabel;
    lbHideOnClose: TLabel;
    lbPlus: TLabel;
    lbConfirmDelItem: TLabel;
    lbConfirmDelProject: TLabel;
    procedure edKeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    shortkey : word;
    config : TConfig;
    Function Translate:boolean;
  public
    procedure setLanguage(lang : string);
    function getLanguage():string;
    procedure setKeys(modkey,key:word);
    procedure getKeys(var modkey,key:word);
    procedure setConfig(configuration : TConfig);
  end;

var
  frmConfig: TfrmConfig;

implementation

{$R *.lfm}

procedure TfrmConfig.setConfig(configuration : TConfig);
begin
  config:=configuration;
end;

procedure TfrmConfig.edKeyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var s:string;
begin
  s:=VirtualKeyToString(key);
  if s<>'' then shortkey:=key;
  //--
  edKey.Text:=s;
  //--
  key:=0; //Don't tramsit the key to the dialog
end;

procedure TfrmConfig.FormShow(Sender: TObject);
begin
  Translate();
end;

//------------------------------------------------------------------------------
procedure TfrmConfig.setLanguage(lang : string);
begin
  if lang='en' then cbLanguage.ItemIndex:=0
  else if lang='fr' then cbLanguage.ItemIndex:=1
  else cbLanguage.ItemIndex:=0;
end;


//------------------------------------------------------------------------------
function TfrmConfig.getLanguage():string;
begin
  Case cbLanguage.ItemIndex of
    0 : result := 'en';
    1 : result := 'fr';
  end;
end;

procedure TfrmConfig.setKeys(modkey,key:word);
begin
  chkAlt.Checked:=(modkey AND MOD_ALT)<>0;
  chkCtrl.Checked:=(modkey AND MOD_CONTROL)<>0;
  chkShift.Checked:=(modkey AND MOD_SHIFT)<>0;
  chkWin.Checked:=(modkey AND MOD_WIN)<>0;

  shortkey:=key;
  edKey.Text:=VirtualKeyToString(key);
end;

procedure TfrmConfig.getKeys(var modkey,key:word);
begin
  modkey:=0;
  //--
  if chkAlt.Checked then modkey:=modKey+MOD_ALT;
  if chkCtrl.Checked then modkey:=modKey+MOD_CONTROL;
  if chkShift.Checked then modkey:=modKey+MOD_SHIFT;
  if chkWin.Checked then modkey:=modKey+MOD_WIN;
  //--
  key:=shortkey;
end;


Function TfrmConfig.Translate:boolean;
Var f:TIniFile;
    s:string;
    i:integer;
Begin
  result:=false;
  if not FileExists('.\lng\pnb.'+config.Lang+'.lng') then exit;

  f:= TIniFile.Create('.\lng\pnb.'+config.Lang+'.lng');

  frmConfig.Caption:=ReadLng(f,'SETTINGS','TITLE');
  grpbLanguage.Caption:=ReadLng(f,'SETTINGS','GRPBLANGUAGE');
  grpbConfirmation.Caption:=ReadLng(f,'SETTINGS','GRPBCONFIRMATION');
  lbConfirmDelItem.Caption:=ReadLng(f,'SETTINGS','LBCONFIRMDELITEM');
  lbConfirmDelProject.Caption:=ReadLng(f,'SETTINGS','LBCONFIRMDELGROUP');

  grpbGlobalShortcut.Caption:=ReadLng(f,'SETTINGS','GRPBGLOBALSHORTCUT');

  lbHideOnMinimize.Caption:=ReadLng(f,'SETTINGS','LBHIDEONMINIMIZE');
  lbHideOnClose.Caption:=ReadLng(f,'SETTINGS','LBHIDEONCLOSE');
  lbMinimizeOnStart.Caption:=ReadLng(f,'SETTINGS','LBHIDEONSTART');
  lbWeekChar.Caption:=ReadLng(f,'SETTINGS','LBWEEKCHAR');
  lbDateFormat.Caption:=ReadLng(f,'SETTINGS','LBDATEFORMAT');

  f.Free;
  result:=true;
end;

end.

