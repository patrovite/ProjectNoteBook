unit configuration;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, inifiles;

const
  DISPLAY_PROJECTS = 0;
  DISPLAY_TIMELINE = 1;

type
  TConfig = Class(TObject)
      constructor Create;
    Private
    Public
      Lang : string;
      ConfirmDeleteItem : boolean;
      ConfirmDeleteProject : boolean;
      HideOnMinimize : boolean;
      HideOnClose : boolean;
      MinimizeOnStart : boolean;
      DisplayMode : integer;
      DateOrder : integer;
      WeekChar : string;
      modkey : word;
      key : word;
      LastDir : string;
      Procedure SaveConfig();
      Procedure LoadConfig();
  end;

implementation
uses utils_date;

constructor TConfig.Create;
begin
  Lang:='fr';
  DisplayMode:=DISPLAY_PROJECTS;
  ConfirmDeleteItem:=true;
  ConfirmDeleteProject:=true;
  MinimizeOnStart:=false;
  HideOnClose:=false;
  HideOnMinimize:=false;
  WeekChar:='S';
  DateOrder:=DATE_DMY;
  LastDir:='';
end;


//------------------------------------------------------------------------------
// Save the configuration
//
procedure TConfig.SaveConfig();
var
  f: TIniFile;
begin
  f := TIniFile.Create('.\config.ini');

  f.WriteInteger('Main', 'DisplayMode', DisplayMode);
  f.WriteInteger('Main', 'DateOrder', DateOrder);
  f.WriteInteger('Main', 'Modkey', modkey);
  f.WriteInteger('Main', 'Key', key);

  f.WriteBool('Main','ConfirmDeleteItem',ConfirmDeleteItem);
  f.WriteBool('Main','ConfirmDeleteProject',ConfirmDeleteProject);
  f.WriteBool('Main','HideOnMinimize',HideOnMinimize);
  f.WriteBool('Main','HideOnClose',HideOnClose);
  f.WriteBool('Main','MinimizeOnStart',MinimizeOnStart);
  f.WriteString('Main','Lang',Lang);
  f.WriteString('Main','WeekChar',WeekChar);
  f.WriteString('Main','LastDir',LastDir);

  f.Free;
end;


//------------------------------------------------------------------------------
// Load the configuration
//
procedure TConfig.LoadConfig();
var
  f: TIniFile;
begin
  f := TIniFile.Create('.\config.ini');

  DisplayMode := f.ReadInteger('Main', 'DisplayMode', DISPLAY_PROJECTS);
  DateOrder:= f.ReadInteger('Main', 'DateOrder', DATE_DMY);
  Modkey:= word(f.ReadInteger('Main', 'Modkey', 0));
  key:= word(f.ReadInteger('Main', 'Key', 0));

  ConfirmDeleteItem:=f.ReadBool('Main', 'ConfirmDeleteItem', true);
  ConfirmDeleteProject:=f.ReadBool('Main', 'ConfirmDeleteProject', true);
  HideOnMinimize:=f.ReadBool('Main', 'HideOnMinimize', false);
  HideOnClose:=f.ReadBool('Main', 'HideOnClose', false);
  MinimizeOnStart:=f.ReadBool('Main', 'MinimizeOnStart', false);
  Lang:=f.ReadString('Main', 'Lang','en');
  WeekChar:=f.ReadString('Main', 'WeekChar','W');
  LastDir:=f.ReadString('Main', 'LastDir','');

  f.Free;
end;


end.

