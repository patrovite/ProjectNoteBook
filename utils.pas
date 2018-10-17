unit utils;

{$mode objfpc} {$H+}

interface

uses
  Classes, SysUtils, DateUtils, inifiles;

const

  cVERSION = '1.00';

  DATE_DMY = 0;
  DATE_MDY = 1;
  DATE_YMD = 2;
  FORMAT_DATETIME = 'yyyymmddhhnnss';
  FORMAT_DATE = 'yyyymmdd';

  Function Int2Str(v,nb:Integer):String;
  Function Str2Int(s:string;default:integer):integer;
  Function Str2IntEx(s:string;var v:integer):boolean;

  Function StrDate2Datetime(s:string):TDatetime;
  Function StrDatetime2Datetime(s:string):TDatetime;
  Function FormatDateTimeEx(sFormat:String;dt:TDateTime):String;

  Function LR_Trim(s:String):String;
  Function RemoveSpecialChar(s:String):String;
  function UpCaseFirstChar(const S: string): string;

  Function DecodeEffort(s:String; HourPerDay, DayPerWeek:integer; Var effs:string; Var effi:Integer; calc:Boolean):Boolean;

  Function ReadLng(f:TIniFile; sSection,sElement:string):AnsiString;
  Procedure SplitCSVLine(Line,sep:string; list: TStringList);
  function GetDateFmt(v: integer;short:boolean): String;
  function VerifyFormIsOpen(formClass: String): Boolean;

Var
  DateOrder : Integer;

implementation
Uses Windows, ShellAPI, LMessages;

function GetDateFmt(v: integer;short:boolean): String;
begin
  if short then begin
    if v=DATE_MDY then result:='MM/DD/YYYY'
    else if v=DATE_YMD then result:='YYYY/MM/DD'
    else result:='DD/MM/YYYY';
  end
  else begin
    if v=DATE_MDY then result:='MMM DD YYYY'
    else if v=DATE_YMD then result:='YYYY MMM DD'
    else result:='DD MMM YYYY';
  end;
end;

//------------------------------------------------------------------------------
function UpCaseFirstChar(const S: string): string;
begin
 Result := S;

 if Length(Result) > 0 then
 Result[1] := UpCase(Result[1]);
end;


//-- Integer to string conversion with '0' before the the number --
Function Int2Str(v,nb:Integer):String;
Var s:String;
    I:Integer;
Begin
  s:=IntToStr(v);
  For I:=1 to nb-length(s) Do
    S:='0'+s;
  Int2Str:=s;
End;


Function Str2Int(s:string;default:integer):integer;
Var v,err:integer;
Begin
  Val(s,v,err);
  if err=0
    then Result:=v
    else Result:=default;
End;


Function Str2IntEx(s:string;var v:integer):boolean;
Var v1,err:integer;
Begin
  Result:=true;
  Val(s,v1,err);
  if err=0
    then v:=v1
    else Result:=false;
End;

//-- Remove char<32 from a string --
Function RemoveSpecialChar(s:String):String;
Var
  s1:string;
  i:integer;
Begin
  s1:='';
  For i:=1 to Length(s) do begin
    if ord(s[i])>=32 then s1:=s1+s[i];
    if s[i]=#10 then s1:=s1+' ';
  end;
  RemoveSpecialChar:=s1;
end;


Function StrDate2Datetime(s:string):TDatetime;
Var d:TDateTime;
Begin
  d:=0.0;
  If Length(s)=8 then begin
    d:=EncodeDateTime(Str2Int(Copy(s,1,4),0),Str2Int(Copy(s,5,2),0),Str2Int(Copy(s,7,2),0),0,0,0,0);
  end;
  result:=d;
end;


//Example:  20181002211054 => 2018/10/02 21h10min54s
Function StrDatetime2Datetime(s:string):TDatetime;
Var d:TDateTime;
Begin
  d:=0.0;
  If Length(s)=14 then begin
    d:=EncodeDateTime(Str2Int(Copy(s,1,4),0),Str2Int(Copy(s,5,2),0),Str2Int(Copy(s,7,2),0), Str2Int(Copy(s,9,2),0), Str2Int(Copy(s,11,2),0), Str2Int(Copy(s,13,2),0),0);
  end;
  result:=d;
end;



Function FormatDateTimeEx(sFormat:String;dt:TDateTime):String;
Begin
  if dt=0
    then result:=''
    else result:=FormatDateTime(sFormat,dt);
end;

//-- Remove starting and ending space from a string --
Function LR_Trim(s:String):String;
Var
  d,f:integer;
Begin
  For d:=1 to Length(s) do
    if (s[d]<>' ') then break;
  For f:=Length(s) downto 1 do
    if (s[f]<>' ') then break;
  result:=Copy(s,d,f-d+1);
end;


Function FirstDayOfWeek(Year:Integer; WeekNumber:integer; FirstDay:Integer; var td:TDateTime):Boolean;
var
  i:integer;
begin
  result:=false;
  if TryEncodeDateWeek(Year,WeekNumber,td,1) then begin
    Case FirstDay of
      DayMonday : i:=0;
      DayTuesday : i:=1;
      DayWednesday : i:=2;
      DayThursday : i:=3;
      DayFriday : i:=4;
      DaySaturday : i:=5;
      DaySunday : i:=-1;
    end;
    td:=IncDay(td,i);
    result:=true;
  end;
end;


Function LastDayOfWeek(Year:Integer; WeekNumber:integer; LastDay:Integer; var td:TDateTime):Boolean;
var
  i:integer;
begin
  result:=false;
  if TryEncodeDateWeek(Year,WeekNumber,td,1) then begin
    Case LastDay of
      DayMonday : i:=0;
      DayTuesday : i:=1;
      DayWednesday : i:=2;
      DayThursday : i:=3;
      DayFriday : i:=4;
      DaySaturday : i:=5;
      DaySunday : i:=6;
    end;
    td:=IncDay(td,i);
    result:=true;
  end;
end;


//3h = 3 heures
//3d = 3 jours
//3w = 3 semaines
//+3h = Ajoute 3h à dt
//+3d = Ajoute 3d à dt
//+3w = Ajoute 3w à dt
//Params:
// s : In : Chaine à analyser
// dt : In/Out : Contient la date et l'heure
// calc : True = Autorise le calcul sur dt sinon défaut
// Retour : True = Ok / False = Problème
Function DecodeEffort(s:String; HourPerDay, DayPerWeek:integer; Var effs:string; Var effi:Integer; calc:Boolean):Boolean;
Var i,c,v,err:Integer;
  a:integer;  //a: 0 pas de calcul / -1 pour sub / +1 pour add
  u:integer;  //u: 0 pas d'unité (pb) / 1=heure / 2=jour / 3=semaine
  str,s1:string;
  ok:Boolean;
Begin
  c:=0;
  a:=0;
  u:=0;
  str:='';
  Ok:=true;
  s1:=LR_Trim(s);
  if s1='' then begin
    effs:='';
    effi:=0;
    exit;
  end;
  i:=1;
  While (i<=length(s1)) and (ok) do begin
    case c of
      0 : Begin //'+' ou '-'
        if calc and (s1[i]='+') then begin
          a:=1;
          inc(i);
        end
        else if calc and (s1[i]='-') then begin
          a:=-1;
          inc(i);
        end;
        c:=1;
      end; //Case 0

      1 : begin //Analyse chiffres
        if s1[i] in ['0'..'9'] then begin
          str:=str+s1[i];
          inc(i);
        end
        else c:=2;
      end; // Case 1

      2 : begin //Analyse unité
        if upCase(s1[i])='H' then begin
          u:=1;
          inc(i);
        end
        else if upCase(s1[i])='D' then begin
          u:=2;
          inc(i);
        end
        else if upCase(s1[i])='W' then begin
          u:=3;
          inc(i);
        end
        else ok:=false;
      end; // Case 2
    end; //Case
  end; //While

  //Analyse resultat et calcul
  val(str,v,err);
  if err=0 then begin
    case a of
      0 : begin
        case u of
          0 : ok:=false;
          1 : begin //Heure
            effi:=v;
            if effi<0 then begin
              effi:=0;
              effs:='';
            end
            else effs:=IntToStr(effi)+'H';
          end;
          2 : begin //jour
            effi:=v*HourPerDay;
            if effi<0 then begin
              effi:=0;
              effs:='';
            end
            else effs:=IntToStr(effi)+'H';
          end;
          3 : begin //semaine
            effi:=v*DayPerWeek;
            if effi<0 then begin
              effi:=0;
              effs:='';
            end
            else effs:=IntToStr(effi)+'H';
          end;
        end; //Case
      end; //Case 0

      -1, 1 : begin
        case u of
          0 : ok:=false;
          1 : begin //Heure
            effi:=effi+(a*v);
            if effi<0 then begin
              effi:=0;
              effs:='';
            end
            else effs:=IntToStr(effi)+'H';
          end;
          2 : begin //jour
            effi:=effi+(a*v*HourPerDay);
            if effi<0 then begin
              effi:=0;
              effs:='';
            end
            else effs:=IntToStr(effi)+'H';
          end;
          3 : begin //semaine
            effi:=effi+(a*v*DayPerWeek);
            if effi<0 then begin
              effi:=0;
              effs:='';
            end
            else effs:=IntToStr(effi)+'H';
          end;
        end; //Case
      end; //Case -1, 1

    end; //case
  end
  else ok:=false;

  result:=ok;
end;


//12 : 12 du mois courant de l'année courante
//12/02 : 12/02 de l'année courante
//12/02/11 : 12/02/2011
//12/02/2011
//W12 : Début de semaine 12 (premier jour travail de la semaine de l'année courante)
//<W12 : Fin de semaine 12 (dernier jour travaillé de la semaine de l'année courante)
//W12/11 : Début de semaine 12 (premier jour travail de la semaine de l'année courante)
//<W12/11 : Fin de semaine 12 (dernier jour travaillé de la semaine de l'année courante)
//W12/2011 : Début de semaine 12 (premier jour travail de la semaine de l'année courante)
//<W12/2011 : Fin de semaine 12 (dernier jour travaillé de la semaine de l'année courante)
//+3h = Ajoute 3h à dt
//+3d = Ajoute 3d à dt
//+3w = Ajoute 3w à dt
Function ParseDate(DateStr:String; DateFmt,HourPerDay, DayPerWeek,FirstDay,LastDay:integer; WeekChar:Char; Var dt:TDateTime; calc:Boolean):Boolean;
Var i,c,v,status,dd,dm,dy,ww,wy,nbs:Integer;
  a:integer;  //a: 0 pas de calcul / -1 pour sub / +1 pour add
  u:integer;  //u: 0 pas d'unité (pb) / 1=heure / 2=jour / 3=semaine
  str,s,s1,s2,s3,sy,sw:string;
  ok,ok1:Boolean;
Begin
  c:=0;
  a:=0;
  u:=0;
  str:='';

  s1:='';
  s2:='';
  s3:='';
  sy:='';
  sw:='';

  dd:=0;
  dm:=0;
  dy:=0;
  ww:=0;
  wy:=0;
  nbs:=0;

  status:=0;
  Ok:=true;
  s:=LR_Trim(DateStr);
  if s='' then begin
    dt:=0.0;
    result:=true;
    exit;
  end;
  i:=1;
  While (i<=length(s)) and (ok) do begin
    case c of
      0 : Begin

        if (s[i] in ['0'..'9']) then begin
          status:=1;
          c:=10
        end
        else if (upCase(s[i])=WeekChar)  then begin
          status:=2;
          c:=20;
          inc(i);
        end
        else if (s[i]='<')  then begin
          status:=3;
          c:=1;
          inc(i);
        end
        else if calc and (s[i]='+') then begin
          status:=4;
          a:=1;
          inc(i);
          c:=30;
        end
        else if calc and (s[i]='-') then begin
          status:=4;
          a:=-1;
          inc(i);
          c:=30;
        end
        else ok:=false;
      end; //Case 0


      //---------------------------------
      1 : begin //décodage '<'
        if (upCase(s[i])=WeekChar)  then begin
          c:=20;
          inc(i);
        end
        else ok:=false;
      end; // Case 1


      //-- Decodage date ---------------------
      10 : begin //décodage nombre
        if (s[i] in ['0'..'9']) then begin
          s1:=s1+s[i];
          inc(i);
          nbs:=1;
        end
        else c:=11;
      end; // Case 10

      11 : begin // décodage de "/"
        if s[i]='/' then begin
          inc(i);
          c:=12;
        end
        else ok:=false;
      end; // Case 11

      12 : begin // décodage nombre
        if (s[i] in ['0'..'9']) then begin
          s2:=s2+s[i];
          inc(i);
          nbs:=2;
        end
        else c:=13;
      end; // Case 12

      13 : begin // décodage de "/"
        if s[i]='/' then begin
          inc(i);
          c:=14;
        end
        else ok:=false;
      end; // Case 13

      14 : begin // décodage nombre
        if (s[i] in ['0'..'9']) then begin
          s3:=s3+s[i];
          inc(i);
          nbs:=3;
        end
        else ok:=false;
      end; // Case 14


      //---------------------------------
      20 : begin // décodage de la semaine
        if (s[i] in ['0'..'9']) then begin
          sw:=sw+s[i];
          inc(i);
        end
        else if s[i]='/' then begin
          inc(i);
          c:=21
        end
        else ok:=false;
      end; // Case 20

      21 : begin // décodage de l'année
        if (s[i] in ['0'..'9']) then begin
          sy:=sy+s[i];
          inc(i);
        end
        else ok:=false;
      end; // Case 20


      //---------------------------------
      30 : begin // décodage du chiffre
        if (s[i] in ['0'..'9']) then begin
          str:=str+s[i];
          inc(i);
        end
        else c:=31;
      end; // Case 30

      31 : begin //Analyse unité
        if upCase(s[i])='D' then begin
          u:=2;
          inc(i);
        end
        else if upCase(s[i])='W' then begin
          u:=3;
          inc(i);
        end
        else ok:=false;
      end; // Case 31

    end; //Case
  end; //While

  //Analyse resultat et calcul
  if ok and (status>0) then begin
    case status of
      1: begin //Date
        ok1:=false;

        case nbs of
          1: begin
            if Str2IntEx(s1,dd) then begin
              if dd in [1..31] then begin
                dm:=MonthOf(now);
                dy:=YearOf(now);
                ok1:=true;
              end;
            end;
          end;

          2: begin
            case DateFmt of
              DATE_DMY: Begin  // DD/MM
                if Str2IntEx(s1,dd) then
                  if dd in [1..31] then
                    if Str2IntEx(s2,dm) then
                      if dm in [1..12] then begin
                        dy:=YearOf(now);
                        ok1:=true;
                      end;
              end;
              DATE_MDY: Begin  // MM/DD
                if Str2IntEx(s2,dd) then
                  if dd in [1..31] then
                    if Str2IntEx(s1,dm) then
                      if dm in [1..12] then begin
                        dy:=YearOf(now);
                        ok1:=true;
                      end;
              end;
              DATE_YMD: Begin  // MM/DD
                if Str2IntEx(s2,dd) then
                  if dd in [1..31] then
                    if Str2IntEx(s1,dm) then
                      if dm in [1..12] then begin
                        dy:=YearOf(now);
                        ok1:=true;
                      end;
              end;
            end; //Case
          end;

          3: begin
            case DateFmt of
              DATE_DMY: Begin  // DD/MM/YY
                if Str2IntEx(s1,dd) then
                  if dd in [1..31] then
                    if Str2IntEx(s2,dm) then
                      if dm in [1..12] then
                        if Str2IntEx(s3,v) then
                          if (v>=0) and (v<=99) then begin
                            dy:=v+2000;
                            ok1:=true;
                          end
                          else if (v>=2000) and (v<=2099) then begin
                            dy:=v;
                            ok1:=true;
                          end;
              end;
              DATE_MDY: Begin  // MM/DD/YY
                if Str2IntEx(s2,dd) then
                  if dd in [1..31] then
                    if Str2IntEx(s1,dm) then
                      if dm in [1..12] then
                        if Str2IntEx(s3,v) then
                          if (v>=0) and (v<=99) then begin
                            dy:=v+2000;
                            ok1:=true;
                          end
                          else if (v>=2000) and (v<=2099) then begin
                            dy:=v;
                            ok1:=true;
                          end;
              end;
              DATE_YMD: Begin  // YY/MM/DD
                if Str2IntEx(s3,dd) then
                  if dd in [1..31] then
                    if Str2IntEx(s2,dm) then
                      if dm in [1..12] then
                        if Str2IntEx(s1,v) then
                          if (v>=0) and (v<=99) then begin
                            dy:=v+2000;
                            ok1:=true;
                          end
                          else if (v>=2000) and (v<=2099) then begin
                            dy:=v;
                            ok1:=true;
                          end;
              end;
            end; //Case
          end;
        end; //case
        ok:=ok1;

        if ok then begin
          if not TryEncodeDateTime(dy,dm,dd,0,0,0,0,dt) then ok:=false;
        end;
      end; //case 1

      2,3: begin //Début et fin de semaine
        ok1:=false;
        if (sw<>'') then begin
          if Str2IntEx(sw,ww) then begin
            if ww in [1..53] then begin
              if (sy<>'') then begin
                if Str2IntEx(sy,v) then begin
                  if (v>=0) and (v<=99) then begin
                    wy:=v+2000;
                    ok1:=true;
                  end
                  else if (v>=2000) and (v<=2099) then begin
                    wy:=v;
                    ok1:=true;
                  end;
                end;
              end
              else begin
                wy:=YearOf(now);
                ok1:=true;
              end;
            end;
          end;
        end;
        ok:=ok1;
        if ok and (status=2) then begin
          if not FirstDayOfWeek(wy,ww,FirstDay,dt) then ok:=false;
        end
        else if ok and (status=3) then begin
          if not LastDayOfWeek(wy,ww,LastDay,dt) then ok:=false;
        end

      end; //case 2 et 3

      4: begin
          if Str2IntEx(str,v) then begin
            if dt=0.0 then dt:=now;  //Rien alors date du jour
            case u of
              0 : ok:=false;
              2 : begin //jour
                dt:=IncDay(dt,a*v);
              end;
              3 : begin //semaine
                dt:=IncWeek(dt,a*v);
              end;
            end; //Case
          end; //Case -1, 1
      end; //Case 4
    end; //case
  end;
  result:=ok;
end;


Procedure Translate(f:TIniFile;var str:string; sSection,sElement:string);
Var s:AnsiString;
Begin
  s:=f.ReadString(sSection, sElement,'');
  s:=StringReplace(s,'\n',#13,[rfReplaceAll]);
  if s<>'' then str:=AnsiToUtf8(s);
End;


Function ReadLng(f:TIniFile; sSection,sElement:string):AnsiString;
Var s:AnsiString;
Begin
  s:=f.ReadString(sSection, sElement,'?');
  s:=AnsiToUtf8(StringReplace(s,'\n',#13,[rfReplaceAll]));
  Result:=s;
End;

Procedure SplitCSVLine(Line,sep:string; list: TStringList);
Var i:integer;
    s:string;
Begin
  list.Clear;
  s:='';
  For i:=1 to length(Line) do begin
    if Line[i]<>sep
      then s:=s+Line[i]
      else begin
        list.Add(s);
        s:='';
      end;
  end;
end;


function VerifyFormIsOpen(formClass: String): Boolean;
var
  windowHndl, windowOld: HWND;
  processId: Cardinal;
begin
  windowOld := 0;
  windowHndl := 0;
  Result := False;
  repeat
    windowHndl :=  Windows.FindWindowEx(0, windowOld, PAnsiChar(formClass), nil);
    if (windowHndl > 0) then
    begin
      Windows.GetWindowThreadProcessId(windowHndl, processId);
      if processId = Windows.GetCurrentProcessId() then
      begin
        Windows.SendMessage(windowHndl, WM_ACTIVATEAPP, 0, 0);
        Result := True;
        break;
      end;
    end;
    windowOld := windowHndl;
  until windowHndl = 0;
end;


end.

