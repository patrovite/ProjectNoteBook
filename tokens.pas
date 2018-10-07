unit Tokens;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Procedure InitToken();
function Tokenize(s : string):integer;

const
     MAX_TOKEN=255;

var
  token : array [1..MAX_TOKEN] of string;
  tokenpos : array [1..MAX_TOKEN] of integer;
  analyzeStr : String;

//------------------------------------------------------------------------------
implementation

Procedure InitToken();
var i:integer;
begin
  for i:=1 to MAX_TOKEN do
    Token[i]:='';
end;


function Tokenize(s : string):integer;
var i,n,step:integer;
begin
  //-- Suppress beginning and ending spaces
  s:=Trim(s);
  analyzeStr:=s;
  n:=0;
  step:=0;

  for i:=1 to length(s) do
  begin
    if (s[i]<>#32) and (s[i]<>#9) then
    begin //A char differente than space and tab
      if (step=0) or (step=2) then begin
         inc(n);
         token[n]:='';
         tokenpos[n]:=i;
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


end.

