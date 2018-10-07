unit projects;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Procedure ClearProjectList();

Type
  PProject = ^TProject;
  TProject = Record
    id : longint;
    name : string;
    selected : boolean;
  end;

var
  projectList : TList;

implementation



Procedure ClearProjectList();
Var i:Integer;
Begin
  For i:=projectList.count-1 Downto 0 Do
  Begin
    //-- Free the item
    If projectList.Items[i]<>Nil Then Dispose(PProject(projectList.Items[i]));
    //-- Delete the item
    projectList.Delete(i);
  End;
End;

end.

