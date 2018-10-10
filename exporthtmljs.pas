unit exportHtmlJS;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, items, configuration, utils, utils_date;


procedure Export_HtmlJS(fname:string; list : TList; config : TConfig; stGlobal : String);


implementation

procedure Export_HtmlJS(fname:string; list : TList; config : TConfig; stGlobal : String);
var
  f: TextFile;
  lastProject, sd, sp, sproj, sl : string;
  lastDate : TDateTime;
  i,sc : integer;
  item: PItem;
  first:boolean;
begin
  lastDate:=-1; //unused value
  lastProject:='%µ£';  //unused value
  first:=true;
  sc:=0; //section counter

  AssignFile(f,fname);

  try
    Rewrite(f);
    writeln(f, '<!doctype html>');
    writeln(f, '<html lang="fr">');
    writeln(f, '    <head>');
    writeln(f, '        <meta charset="utf-8">');

    writeln(f, '        <title>Titre de la page</title>');

    writeln(f, '        <style>');
    writeln(f, '          .plus {');
    writeln(f, '              background-color: white;');
    writeln(f, '             color: black;');
    writeln(f, '             cursor: pointer;');
    writeln(f, '          }');
    writeln(f, '          .title {');
    writeln(f, '             font-family: "Verdana","Arial";');
    writeln(f, '             font-weight: bold;');
    writeln(f, '          }');
    writeln(f, '          .p0 {');
    writeln(f, '             font-family: "Verdana","Arial";');
    writeln(f, '             color:black;');
    writeln(f, '          }');
    writeln(f, '          .p1 {');
    writeln(f, '             font-family: "Verdana","Arial";');
    writeln(f, '             color:coral;');
    writeln(f, '          }');
    writeln(f, '          .p2 {');
    writeln(f, '             font-family: "Verdana","Arial";');
    writeln(f, '             color:red;');
    writeln(f, '          }');
    writeln(f, '          .ended{');
    writeln(f, '              font-family: "Verdana","Arial";');
    writeln(f, '              color: yellowgreen;');
    writeln(f, '          }');
    writeln(f, '          .project{');
    writeln(f, '              font-family: "Verdana","Arial";');
    writeln(f, '              background-color: dimgray;');
    writeln(f, '              color: white;');
    writeln(f, '          }');
    writeln(f, '          li {');
    writeln(f, '             display: block;');
    writeln(f, '             font-family: "Verdana","Arial";');
    writeln(f, '          }');
    writeln(f, '        </style>');

    writeln(f, '    </head>');
    writeln(f, '    <body>');

    writeln(f, '      <ul>');

    for i := 0 to itemList.Count - 1 do
    begin
      item := PItem(itemList.Items[i]);

      if Config.DisplayMode=DISPLAY_PROJECTS then begin
        if lastProject<>item^.project then begin
          if item^.project='' then
            sd:= stGlobal
          else
            sd:=item^.project;
          inc(sc);
          if first=false then begin
            writeln(f, '          </ul>');
            writeln(f, '        </li>');
          end;
          writeln(f, '        <li><span id="section'+intToStr(sc)+'" class="plus">&#10752</span> <span class="title">'+sd+'</span>');
          writeln(f, '          <ul id="ulsection'+intToStr(sc)+'">');
          lastProject:=item^.project;
          first:=false;
        end;
      end
      else if Config.DisplayMode=DISPLAY_TIMELINE then begin
        if lastDate<>item^.endDate then begin
          if item^.endDate=0 then
            sd:='Sans date de fin'
          else
            sd:=FormatDateTime('dddd dd mmmm yyyy',item^.endDate);
          //--
          inc(sc);
          if first=false then begin
            writeln(f, '          </ul>');
            writeln(f, '        </li>');
          end;
          writeln(f, '        <li><span id="section'+intToStr(sc)+'" class="plus">&#10752</span> <span class="title">'+sd+'</span>');
          writeln(f, '          <ul id="ulsection'+intToStr(sc)+'">');
          lastDate:=item^.endDate;
          first:=false;
        end;
      end;

      if item^.progress<>100 then
        sp:='p'+IntToStr(item^.priority)
      else
        sp:='ended';

      //-- Notes
      if item^.itemType = ITEM_NOTE then
      begin
        if item^.project<>'' then
          sproj:=' ['+item^.project+']'
        else
          sproj:='';
        writeln(f, '            <li class="'+sp+'">&#11208 '+ item^.Text + sproj+ '</li>');
      end //Notes

      //-- Tasks
      else if item^.itemType = ITEM_TASK then
      begin
        if (item^.project<>'') and (config.DisplayMode=DISPLAY_TIMELINE) then
          sproj:=' <span class="project">&nbsp'+item^.project+'&nbsp</span>'
        else
          sproj:='';

        if item^.progress<>100 then
          sl:='&#9744'
        else
          sl:='&#9745';

        if (item^.endDate<>0) and (config.DisplayMode=DISPLAY_PROJECTS) then
          sd:=' <span>&#9719</span>'+FormatDateTimeEx(ToFormatDate(config.DateOrder), item^.endDate)
        else
          sd:='';

        writeln(f, '            <li class="'+sp+'">'+sl+' '+intToStr(item^.progress)+'%'+sd+'&#11208 '+ item^.Text + sproj+ '</li>');
      end; //Tasks
    end; //for

    if first=false then begin
      writeln(f, '          </ul>');
      writeln(f, '        </li>');
    end;

    writeln(f, '       </ul>');

    writeln(f, '        <script>');
    writeln(f, '          function HideShow(el,item) {');
    writeln(f, '            if (el.textContent=="\u2A00") {');
    writeln(f, '                el.textContent="\u2A01";');
    writeln(f, '              document.getElementById(item).style.display="none";');
    writeln(f, '            }');
    writeln(f, '            else {');
    writeln(f, '              el.textContent="\u2A00";');
    writeln(f, '              document.getElementById(item).style.display="block";');
    writeln(f, '            }');
    writeln(f, '          }');

    for i:=1 to sc do begin
      writeln(f, '');
      writeln(f, '          document.getElementById("section'+intToStr(i)+'").addEventListener("click",');
      writeln(f, '            function() {HideShow(this,"ulsection'+intToStr(i)+'");}');
      writeln(f, '              , false);');
    end;

    writeln(f, '        </script>');
    writeln(f, '    </body>');
    writeln(f, '</html>');

    CloseFile(f);
  except
    on E: EInOutError do
     writeln('Error while exporting the list as HTML+JS. Details: ', E.Message);
  end;
end;






end.

