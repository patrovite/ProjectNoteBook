unit history;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

THistory = Class(TObject)
    constructor Create();
    Destructor Destroy();
  Private
    list : TStringList;
    pos : integer;
  Public
    procedure Add(s : string);
    function getPrev():string;
    function getNext():string;
end;


implementation


constructor THistory.Create();
begin
  list := TStringList.Create();
  pos:=0;
end;


destructor THistory.Destroy();
Begin
  list.free();
End;

procedure THistory.Add(s : string);
begin
  list.Add(s);
  pos:=0;
end;

function THistory.getPrev():string;
var i:integer;
begin
  result:='';
  if list.Count<=0 then exit;

  if pos<list.Count then begin
    inc(pos);
    result:=list.Strings[list.Count-pos];
  end
  else if (list.Count-1-pos)=0 then begin
    result:=list.Strings[0];
  end;
end;

function THistory.getNext():string;
var i:integer;
begin
  result:='';
  if list.Count<=0 then exit;

  if pos>1 then begin
    dec(pos);
    result:=list.Strings[list.Count-pos];
  end
  else if pos=0 then
    result:=list.Strings[list.Count-1];
end;


end.

