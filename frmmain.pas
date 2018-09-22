unit frmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs;

type

  { Tmain }

  Tmain = class(TForm)
    const
      MAX_TOKEN=255;
    procedure FormCreate(Sender: TObject);
  private
      token : array [1..MAX_TOKEN] of string;
  public
    Procedure InitToken();
    function Tokenize(s : string):integer;
    Procedure Analyse(n :integer);
    Procedure CreateTask(n : integer);
    Procedure CreateNote(n : integer);
    Procedure DeleteItem(n : integer);
    Procedure CopyItem(n : integer);
    Procedure MoveItem(n : integer);
    Procedure ConvertItem(n : integer);
    Procedure EditItem(n : integer);
    Procedure SetDisplayFilter(n : integer);
    Procedure AddDisplayFilter(n : integer);
    Procedure RemoveDisplayFilter(n : integer);
    Procedure ResetDisplayFilter(n : integer);
  end;

var
  Main: Tmain;

implementation

{$R *.lfm}

{ TMain }

procedure TMain.FormCreate(Sender: TObject);
var
  str : String;
  n : integer;
begin
  InitToken;
  str:='                     t @cats P1     >18/10   %100 texte d"essai';
  n:=Tokenize(str);
  if (n<>0) then
  begin
    Pass1(n);
  end;
end;


Procedure TMain.InitToken();
var i:integer;
begin
  for i:=1 to MAX_TOKEN do
    Token[i]:='';
end;

function TMain.Tokenize(s : string):integer;
var i,n,step:integer;
begin
  //-- Suppress beginning and ending spaces
  s:=Trim(s);

  n:=0;
  step:=0;

  for i:=1 to length(s) do
  begin
    if (s[i]<>#32) and (s[i]<>#9) then
    begin //A char differente than space and tab
      if (step=0) or (step=2) then begin
         inc(n);
         token[n]:='';
         step:=1;
      end;
      token[n]:=token[n]+s[i];
    end
    else
    begin
      step:=2;
    end;
  end;
  Tokenize:=n;
end;


Procedure TMain.Analyse(n :integer);
var i,j:integer;
  str : String;
begin
  if n=0 then exit;

  str := '';

  if Token[1]='t' then
  //-- Create a task : t [projects] [Px] [>x] [%x] [%e] Text
  begin
    CreateTask(n);
  end
  else if token[1]='n' then
  //-- Create a note : n [projects] [Px] Text
  begin
    CreateNote(n);
  end
  else if token[i]='d' then
  //-- Delete an item : d "num"
  //-- Delete a project : d [Project]
  begin
    DeleteItem(n);
  end
  else if token[i]='c' then
  //-- Copy item: c [projects] "num"
  begin
    CopyItem(n);
  end
  else if token[i]='m' then
  //-- Move item : m [projects] "num"
  begin
    MoveItem(n);
  end
  else if token[i]='x' then
  //-- Convert item task<>note :x [n/t] "num"
  begin
    ConvertItem(n);
  end
  else if token[i]='e' then
  //-- Edit an item : e [Px] [>x] [%x] [%e] "num" [text]
  //-- Edit a project name : e [projet] "text"
  begin
    EditItem(n);
  end
  else if token[i]='f' then
  //-- Set a display filter on some projets : f [projects]
  begin
    SetDisplayFilter(n);
  end
  else if token[i]='f+' then
  //-- Add projects to the current display filter : f+ [projects]
  begin
    AddDisplayFilter(n);
  end
  else if token[i]='f-' then
  //-- Remove projects from the current display filter : f- [projects]
  begin
    RemoveDisplayFilter(n);
  end
  else if token[i]='f--' then
  //-- Reset the display filter. All projects displayed : f--
  begin
    ResetDisplayFilter(n);
  end;
end;


//-- Create a task : t [projects] [Px] [>x] [%x] [%e] Text
Procedure TMain.CreateTask(n : integer);
begin

end;

//-- Create a note : n [projects] [Px] Text
Procedure TMain.CreateNote(n : integer);
begin

end;

//-- Delete an item : d "num"
//-- Delete a project : d [Project]
Procedure TMain.DeleteItem(n : integer);
begin

end;

//-- Copy item: c [projects] "num"
Procedure TMain.CopyItem(n : integer);
begin

end;

//-- Move item : m [projects] "num"
Procedure TMain.MoveItem(n : integer);
begin

end;

//-- Convert item task<>note :x [n/t] "num"
Procedure TMain.ConvertItem(n : integer);
begin

end;

//-- Edit an item : e [Px] [>x] [%x] [%e] "num" [text]
//-- Edit a project name : e [projet] text
Procedure TMain.EditItem(n : integer);
begin

end;

//-- Set a display filter on some projets : f [projects]
Procedure TMain.SetDisplayFilter(n : integer);
begin

end;

//-- Add projects to the current display filter : f+ [projects]
Procedure TMain.AddDisplayFilter(n : integer);
begin

end;

//-- Remove projects from the current display filter : f- [projects]
Procedure TMain.RemoveDisplayFilter(n : integer);
begin

end;

//-- Reset the display filter. All projects displayed : f--
Procedure TMain.ResetDisplayFilter(n : integer);
begin

end;


end.

