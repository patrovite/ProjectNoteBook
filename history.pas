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
  list.add(s);
  pos:=0;
end;

function THistory.getPrev():string;
begin
  if (list.Count-pos-1)>0 then begin
    dec(pos);
    result:=list.Strings[list.Count-pos-1];
  end;
end;

function THistory.getNext():string;
begin
  if pos<0 then begin
    inc(pos);
    result:=list.Strings[list.Count-pos-1];
  end;
end;


end.

