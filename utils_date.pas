unit utils_date; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils;

Const
  DATE_DMY = 0;
  DATE_MDY = 1;
  DATE_YMD = 2;

  C_PARSE_NO_ADD      = 0;
  C_PARSE_NO_ADD_HOUR = 1;
  C_PARSE_ADD         = 2;

  Function ToFormatDate(code : integer):string;
  Function FirstDayOfWeek(Year:Integer; WeekNumber:integer; FirstDay:Integer; var td:TDateTime):Boolean;
  Function LastDayOfWeek(Year:Integer; WeekNumber:integer; LastDay:Integer; var td:TDateTime):Boolean;
  Function ParseDate(DateStr:String; DateFmt,HourPerDay, DayPerWeek,FirstDay,LastDay:integer; WeekChar:Char; Var dt:TDateTime; calc:Integer; Relative:Boolean):Boolean;

implementation

uses utils;

//------------------------------------------------------------------------------
// Convert date format code to date format string
//
// code : date format code
//
Function ToFormatDate(code : integer):string;
begin
  case code of
    DATE_DMY : Result:='DD/MM/YYYY';
    DATE_MDY : Result:='MM/DD/YYYY';
    DATE_YMD : Result:='YYYY/MM/DD';
  end;
end;


//-- FirstDayOfWeek ------------------------------------------------------------
//- Retourne le premier jour travaillé de la semaine
//Year = Année
//Weeknumber = numéro de la semaine
//FirstDay = Premier jour travaillé
//vd = Date du premier jour travaillé
//Retour : Vrai si calcul possible sinon faux
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


//-- LastDayOfWeek ------------------------------------------------------------
//- Retourne le dernier jour travaillé de la semaine
//Year = Année
//Weeknumber = numéro de la semaine
//LastDay = Premier jour travaillé
//vd = Date du premier jour travaillé
//Retour : Vrai si calcul possible sinon faux
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
//+3h = Ajoute 3 heures à dt (Pas codé!!)
//+3d = Ajoute 3 jours à dt
//+3w = Ajoute 3 semaines à dt
//+3m = Ajoute 3 mois à dt
Function ParseDate(DateStr:String; DateFmt,HourPerDay, DayPerWeek,FirstDay,LastDay:integer; WeekChar:Char; Var dt:TDateTime; calc:integer; Relative:Boolean):Boolean;
Var i,step,v,status,dd,dm,dy,ww,wy,nbs:Integer;
  a:integer;  //a: 0 pas de calcul / -1 pour sub / +1 pour add
  u:integer;  //u: 0 pas d'unité (pb) / 1=heure / 2=jour / 3=semaine / 4=mois
  str,s,s1,s2,s3,sy,sw:string;
  ok,ok1:Boolean;
Begin
  step:=0;
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
    case step of
      0 : Begin

        if (s[i] in ['0'..'9']) then begin
          status:=1;
          step:=10
        end
        else if (upCase(s[i])=WeekChar)  then begin
          status:=2;
          step:=20;
          inc(i);
        end
        else if (s[i]='<')  then begin
          status:=3;
          step:=1;
          inc(i);
        end
        else if ((calc=C_PARSE_NO_ADD_HOUR) or (calc=C_PARSE_ADD)) and (s[i]='+') then begin
          status:=4;
          a:=1;
          inc(i);
          step:=30;
        end
        else if ((calc=C_PARSE_NO_ADD_HOUR) or (calc=C_PARSE_ADD)) and (s[i]='-') then begin
          status:=4;
          a:=-1;
          inc(i);
          step:=30;
        end
        else ok:=false;
      end; //Case 0


      //---------------------------------
      1 : begin //décodage '<'
        if (upCase(s[i])=WeekChar)  then begin
          step:=20;
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
        else step:=11;
      end; // Case 10

      11 : begin // décodage de "/"
        if s[i]='/' then begin
          inc(i);
          step:=12;
        end
        else ok:=false;
      end; // Case 11

      12 : begin // décodage nombre
        if (s[i] in ['0'..'9']) then begin
          s2:=s2+s[i];
          inc(i);
          nbs:=2;
        end
        else step:=13;
      end; // Case 12

      13 : begin // décodage de "/"
        if s[i]='/' then begin
          inc(i);
          step:=14;
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
          step:=21
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
        else step:=31;
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
        else if upCase(s[i])='M' then begin
          u:=4;
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
                          else if (v>=1900) and (v<=2099) then begin
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
                          else if (v>=1900) and (v<=2099) then begin
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
                          else if (v>=1900) and (v<=2099) then begin
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
                  else if (v>=1900) and (v<=2099) then begin
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

      4: begin //Calcul sur date
          if Str2IntEx(str,v) then begin
            if (dt=0.0) or (not relative) then dt:=now;  //Rien alors date du jour
            case u of
              0 : ok:=false;
              2 : begin //jour
                    if (Calc=C_PARSE_NO_ADD_HOUR) or (calc=C_PARSE_ADD)
                      then dt:=IncDay(dt,a*v)
                      else ok:=false;
                  end;
              3 : begin //semaine
                    if (Calc=C_PARSE_NO_ADD_HOUR) or (calc=C_PARSE_ADD)
                      then dt:=IncWeek(dt,a*v)
                      else ok:=false;
                  end;
              4 : begin //semaine
                    if (Calc=C_PARSE_NO_ADD_HOUR) or (calc=C_PARSE_ADD)
                      then dt:=IncMonth(dt,a*v)
                      else ok:=false;
                  end;
            end; //Case
          end; //Case -1, 1
      end; //Case 4
    end; //case
  end;
  result:=ok;
end;


end.

