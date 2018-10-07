//------------------------------------------------------------------------------
// ProjectNotBook
// Copyright 2018 - Pierre Delore
// pierre@TechAndRun.com
//
// License GPL V3
//
//------------------------------------------------------------------------------
{ -- TODO list
* add an undo command. Store deleted data in an backup table?
* Display errors
* Translation
* global hotkey configuration
-------------------------------------------------------------------------------}

unit frmMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Menus, ExtCtrls, ComCtrls, CheckLst, LCLType,
  HtmlView, utils, items, projects, utils_date, DateUtils, constantes, tokens,
  datamodule, configuration, dlgconfig, windows;

const
  COLOR_LOW = $00FFFFFF;
  COLOR_MEDIUM = $0057CEF9;
  COLOR_HIGH = $000027FF;
  COLOR_PROJECT_BACK = $00485659;
  COLOR_PROJECT_FONT = clLtGray;
  COLOR_BACK = $003C3C3C;

  DBFILE = '.\pnb.db';
  PRE_FILE = '.\template_pre.html';
  POST_FILE = '.\template_post.html';
  VERSION = '1.00alpha';
  GLOBAL = 'global';

type
  TMWndProc = Windows.WNDPROC;

  { Tmain }
  Tmain = class(TForm)
    ApplicationProperties: TApplicationProperties;
    ChklstProject: TCheckListBox;
    CtrlbMain: TControlBar;
    fpnMain: TFlowPanel;
    HtmlView: THtmlViewer;
    edCommandLine: TLabeledEdit;
    ImageListMenu: TImageList;
    ImageListToolbar: TImageList;
    ImageListTbaCheck: TImageList;
    MainMenu: TMainMenu;
    mnuSettings: TMenuItem;
    MenuItem2: TMenuItem;
    mnuDisplayTimeline: TMenuItem;
    mnuDisplayProjects: TMenuItem;
    mnuDisplay: TMenuItem;
    mnuQuit: TMenuItem;
    mnuFileSeparator2: TMenuItem;
    mnuExport: TMenuItem;
    mnuImport: TMenuItem;
    mnuFile: TMenuItem;
    pnChecks: TPanel;
    pnBottom: TPanel;
    SplitterMain: TSplitter;
    stNote: TStaticText;
    stItems: TStaticText;
    stItemsVal: TStaticText;
    stNoteVal: TStaticText;
    stTaskActive: TStaticText;
    stTaskActiveVal: TStaticText;
    tbarCheck: TToolBar;
    tbAll: TToolButton;
    tbNone: TToolButton;
    ToolBarMain: TToolBar;
    tbDisplayProjects: TToolButton;
    tbDisplayTimeline: TToolButton;
    TrayIcon: TTrayIcon;

    procedure ApplicationPropertiesMinimize(Sender: TObject);
    procedure ChklstProjectClickCheck(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edCommandLineKeyDown(Sender: TObject; var Key: word;
      Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure mnuDisplayProjectsClick(Sender: TObject);
    procedure mnuDisplayTimelineClick(Sender: TObject);
    procedure mnuQuitClick(Sender: TObject);
    procedure mnuSettingsClick(Sender: TObject);
    procedure tbAllClick(Sender: TObject);
    procedure tbDisplayProjectsClick(Sender: TObject);
    procedure tbDisplayTimelineClick(Sender: TObject);
    procedure tbNoneClick(Sender: TObject);
    procedure TrayIconClick(Sender: TObject);
  private
    NbNote: integer;
    NbTask: integer;
    NbActiveTask: integer;
    DisplayMode: integer;
    StrListPre: TStringList;
    StrListPost: TStringList;
    config : TConfig;
    LastWindowState : TWindowState;
    memTop:integer;
    memLeft:integer;
    memWidth:integer;
    memHeight:integer;
    RequestToClose : boolean;
    //--
    procedure Hook;
    procedure Unhook;
    procedure ReduceToTray;
    procedure RestoreFromTray;
  public
    procedure CreateDB();
    procedure AddToItemsTable();
    procedure ReadItemsFromDB();
    procedure ReadProjectsFromDB();
    Procedure DeleteItemFromDB(id : integer);
    Procedure DeleteProjectFromDB(str : string);
    Procedure UpdateProjectTableFromItemTable();
    procedure UpdateItemsTable();
    Procedure RenameProjectInItemTable(old, New :string);
    //--
    Function AddToProjectTable(project: string):boolean;
    //--
    function Analyze(n: integer; var act: integer): boolean;
    function GetProject(var src: string; var FoundProject: string): string;
    function GenFilter():String;
    function ConvTestParam(ToConv:string; var value:integer; min, max, error : integer; var res:integer):boolean;
    //--
    function CreateTask(n: integer; var act: integer): integer;
    function CreateNote(n: integer; var act: integer): integer;
    function DeleteItem(n: integer; var act: integer): integer;
    function CopyItem(n: integer; var act: integer): integer;
    function ConvertItem(n: integer; var act: integer): integer;
    function EditItem(n: integer; var act: integer): integer;
    function SetDisplayFilter(n: integer; var act: integer): integer;
    function DisplayFilterNone(n: integer; var act: integer): integer;
    function DisplayFilterAll(n: integer; var act: integer): integer;
    Function SetDisplayModeTimeline(n: integer; var act: integer): integer;
    Function SetDisplayModeProjects(n: integer; var act: integer): integer;
    //--
    procedure Refresh();
    procedure Refresh_Display_Mode();
    procedure RefreshItemsList();
    procedure RefreshProjectsList();
    procedure RefreshStatusbar();
    Procedure RefreshTitle();
    procedure CalcStat();
    procedure SelectAllProjects();
    procedure UnselectAllProjects();
    procedure SelectProject(s:string);
    procedure UnselectProject(s:string);
    //--
    procedure ProcessHotKey(HK: LongInt);
  end;

var
  Main: Tmain;
  OldProc: TMWndProc;
  PrevWndProc: WNDPROC;

function MsgProc(Handle: HWnd; Msg: UInt; WParam: Windows.WParam;
                 LParam: Windows.LParam): LResult; stdcall;

implementation

{$R *.lfm}

{ TMain }

procedure TMain.FormCreate(Sender: TObject);
begin
  //-- Ensure we're using the local sqlite3.dll
  SQLiteLibraryName := 'sqlite3.dll';

  config := TConfig.create();

  itemList := TList.Create();
  projectList := TList.Create();

  StrListPre := TStringList.Create();
  try
    StrListPre.LoadFromFile(PRE_FILE);
  except
    ShowMessage('Unable to open "template_pre.html"');
  end;

  StrListPost := TStringList.Create();
  try
    StrListPost.LoadFromFile(POST_FILE);
  except
    ShowMessage('Unable to open "template_post.html"');
  end;

  RequestToClose:=false;

  //-- Load the configuration file
  Config.LoadConfig();

  //-- Set the path to the database
  dmDB.Connection.DatabaseName := DBFILE;

  //-- Create the database if necessary
  if not FileExists(DBFILE) then
    CreateDB();

  //-- Init variables
  Refresh_Display_Mode();

  //-- Refresh the display
  Refresh();
  RefreshTitle();

  //-- Register the global hotkey
  if config.key<>0 then begin
    RegisterHotKey(Handle, 0, config.modkey, config.key);
    Hook();
  end;

  //-- Minimize on start?
  if config.MinimizeOnStart then ReduceToTray();
end;


//------------------------------------------------------------------------------
procedure Tmain.FormShow(Sender: TObject);
begin
  //TODO
end;


//------------------------------------------------------------------------------
procedure Tmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Config.SaveConfig();
end;


//------------------------------------------------------------------------------
procedure Tmain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  Canclose:=True;
  if (Config.HideOnClose) and (not(RequestToClose)) Then begin
    ReduceToTray();
    CanClose:=False;
  end;
end;


//------------------------------------------------------------------------------
procedure Tmain.FormDestroy(Sender: TObject);
begin
  StrListPre.Free();
  StrListPost.Free();

  dmDB.SQLQuery.Free();
  dmDB.Transaction.Free();
  dmDB.Connection.Free();

  ClearItemList();
  ClearProjectList();
  itemList.Free();

  Unhook();
  UnregisterHotKey(Handle, 0);
end;


//------------------------------------------------------------------------------
procedure TMain.Hook;
begin
  OldProc:=Windows.WNDPROC(SetWindowLongPtr(Self.Handle,GWL_WNDPROC,PtrInt(@MsgProc)));
end;


//------------------------------------------------------------------------------
procedure TMain.Unhook;
begin
  if Assigned(OldProc) then
    Windows.SetWindowLong(Handle, GWL_WNDPROC, LongInt(OldProc));
  OldProc := nil;
end;


//------------------------------------------------------------------------------
procedure TMain.ProcessHotKey(HK: LongInt);
begin
  // HK is a virtual key code, process it here
  if Main.WindowState=wsMinimized then
     RestoreFromTray()
  else
    ReduceToTray();
end;


//------------------------------------------------------------------------------
procedure TMain.ReduceToTray;
Begin
  memTop:=Top;
  memLeft:=Left;
  memWidth:=Width;
  memHeight:=Height;

  if WindowState=wsMinimized then
    LastWindowState:=wsNormal
  else
    LastWindowState:=WindowState;

  TrayIcon.Visible:=True;
  WindowState:=wsMinimized;
  Hide;
end;


//------------------------------------------------------------------------------
procedure TMain.RestoreFromTray;
Begin
  TrayIcon.Visible:=false;
  Application.ShowMainForm:=true;
  ShowInTaskBar:=stDefault;
  Show();
  Top:=memTop;
  Left:=memLeft;
  Width:=memWidth;
  Height:=memHeight;
  WindowState:=LastWindowState;
end;


//------------------------------------------------------------------------------
procedure Tmain.TrayIconClick(Sender: TObject);
begin
  RestoreFromTray();
end;


//------------------------------------------------------------------------------
procedure Tmain.ChklstProjectClickCheck(Sender: TObject);
var
  n:integer;
  s:string;
begin
  n := ChklstProject.ItemIndex;
  if (n < projectList.Count) and (n >= 0) then
  begin
    try
      dmDB.Connection.Open;
      dmDB.Transaction.Active := True;
      //--
      s:='UPDATE projects SET selected=';
      //--
      if ChklstProject.Checked[n] then
        s:=s+'1'
      else
        s:=s+'0';
      //--
      s:=s+' WHERE id='+intToStr(PProject(projectList.Items[n])^.id);
      dmDB.Connection.ExecuteDirect(s);
      dmDB.Transaction.Commit;
      dmDB.Connection.Close;
    except
      ShowMessage('Unable to change the selection in the DB');
    end;
  end;

  //-- Update items
  Refresh();
end;


//------------------------------------------------------------------------------
procedure Tmain.ApplicationPropertiesMinimize(Sender: TObject);
begin
  if Config.HideOnMinimize Then ReduceToTray();
  //memTop:=Top;
  //memLeft:=Left;
  //memWidth:=Width;
  //memHeight:=Height;
end;


//------------------------------------------------------------------------------
// Calculate statistics
//
procedure TMain.CalcStat();
var
  i: integer;
begin
  NbNote := 0;
  NbTask := 0;
  NbActiveTask := 0;
  for i := 0 to itemList.Count - 1 do
  begin
    if PItem(itemList.Items[i])^.itemType = ITEM_NOTE then
      Inc(NbNote)
    else if PItem(itemList.Items[i])^.itemType = ITEM_TASK then
    begin
      Inc(NbTask);
      if PItem(itemList.Items[i])^.progress <> 100 then
        Inc(NbActiveTask);
    end;
  end;
end;


//------------------------------------------------------------------------------
Procedure TMain.RefreshTitle();
begin
  Caption:='ProjectNoteBook V'+VERSION+' - '+FormatDateTimeEx(GetDateFmt(Config.DateOrder,true),now)+' ('+Config.WeekChar+intToStr(WeekOf(now))+')';
end;


//------------------------------------------------------------------------------
// Refresh the status bar
//
procedure TMain.RefreshStatusbar();
begin
  CalcStat();
  stItemsVal.Caption := IntToStr(itemList.Count);
  stNoteVal.Caption := IntToStr(NbNote);
  stTaskActiveVal.Caption := IntToStr(NbActiveTask) + '/' + IntToStr(NbTask);
end;


//------------------------------------------------------------------------------
procedure TMain.RefreshProjectsList();
var
  i: integer;
begin
  ChklstProject.Items.Clear();

  for i := 0 to projectList.Count - 1 do
  begin
    ChklstProject.Items.Add(PProject(projectList.Items[i])^.name);
    ChklstProject.Checked[i]:= PProject(projectList.Items[i])^.selected;
  end;
end;


//------------------------------------------------------------------------------
procedure TMain.RefreshItemsList();
var
  item: PItem;
  i: integer;
  s,sd,sbr,sp,sl: string;
  sList: TStringList;
  mem: TMemoryStream;
  lastProject : string;
  lastDate : TDateTime;
begin
  sList := TStringList.Create();
  mem := TMemoryStream.Create();

  //-- Add the begin of the html page
  sList.AddStrings(StrListPre, False);

  lastDate:=-1; //unused value
  lastProject:='%µ£';  //unused value
  sbr:='';
  //-- Add the content
  for i := 0 to itemList.Count - 1 do
  begin
    item := PItem(itemList.Items[i]);

    if DisplayMode=DISPLAY_PROJECTS then begin
      if lastProject<>item^.project then begin
        if item^.project='' then
          sd:=GLOBAL
        else
          sd:=item^.project;
        sList.Add('<tr>');
        sList.Add(' <td colspan="4">'+sbr+'<span id="title">'+sd+'</span></td>');
        sList.Add('</tr>');
        lastProject:=item^.project;
        sbr:='<br/>';
      end;
    end
    else if DisplayMode=DISPLAY_TIMELINE then begin
      if lastDate<>item^.endDate then begin
        if item^.endDate=0 then
          sd:='Sans date de fin'
        else
          sd:=FormatDateTime('dddd dd mmmm yyyy',item^.endDate);
        //--
        sList.Add('<tr>');
        sList.Add(' <td colspan="4">'+sbr+'<span id="title">'+sd+'</span></td>');
        sList.Add('</tr>');
        lastDate:=item^.endDate;
        sbr:='<br/>';
      end;
    end;

    sp:=IntToStr(item^.priority);

    //-- Notes
    if item^.itemType = ITEM_NOTE then
    begin
      sList.Add('<tr>');
      sList.Add(' <td>&nbsp&nbsp</td>');
      sList.Add(' <td align="right" valign="top"><span id="num">' + IntToStr(i + 1) + '. </span></td>');
      if item^.project <> '' then
        sList.Add(' <td valign="top"><span id="logo0">&#33</span>&nbsp<span id="text' + sp + '">' + item^.Text +
          '</span>&nbsp<span id="project">&nbsp' +
          item^.project + '&nbsp</span></td>')
      else
        sList.Add(' <td><span id="logo0">&#33</span>&nbsp<span id="text'+sp+'">' + item^.Text + '</span></td>');
      sList.Add('</tr>');
    end
    //-- Tasks
    else if item^.itemType = ITEM_TASK then
    begin
      if item^.progress<>100 then
        sl:='<span id="logo0">&#163</span>&nbsp'
      else
        sl:='<span id="logo1">&#82</span>&nbsp';

      sList.Add('<tr>');
      sList.Add(' <td>&nbsp&nbsp</td>');
      sList.Add(' <td align="right" valign="top"><span id="num">' + IntToStr(i + 1) + '. </span></td>');
      if item^.project <> '' then
        sList.Add(' <td valign="top">'+sl+'<span id="text' + sp + '">' + item^.Text +
          '</span>&nbsp<span id="project">&nbsp' +
          item^.project + '&nbsp</span></td>')
      else
        sList.Add(' <td>'+sl+'<span id="text'+ sp +'">' + item^.Text + '</span></td>');
      sList.Add('</tr>');
      sList.Add('<tr>');
      sList.Add(' <td></td>');
      sList.Add(' <td></td>');

      s := FormatDateTimeEx(ToFormatDate(config.DateOrder), item^.endDate);
      if s <> '' then
        s := ' >' + s;
      sList.Add(' <td><span id="info">' + IntToStr(item^.progress) + '%' + s + '</span></td>');
      sList.Add('</tr>');
    end;
  end;

  //-- Add the end of the html page
  sList.AddStrings(StrListPost, False);

  //-- Transfer to the html viewer
  sList.SaveToStream(mem);
  HtmlView.LoadFromStream(mem);

  mem.Free();
  sList.Free();
end;


//------------------------------------------------------------------------------
procedure Tmain.edCommandLineKeyDown(Sender: TObject; var Key: word;
  Shift: TShiftState);
var
  n, err, act: integer;
begin
  if (key = VK_RETURN) and (Shift = []) then
  begin
    InitToken();
    n := Tokenize(edCommandLine.Text);
    if (n <> 0) then
    begin
      if Analyze(n, act) then begin
        if act=ACT_OK then
          edCommandLine.Text := '';
      end;
    end;
  end;
end;



//------------------------------------------------------------------------------
procedure Tmain.mnuDisplayProjectsClick(Sender: TObject);
begin
  DisplayMode := DISPLAY_PROJECTS;
  Refresh_Display_Mode();
  Refresh();
end;


//------------------------------------------------------------------------------
procedure Tmain.mnuDisplayTimelineClick(Sender: TObject);
begin
  DisplayMode := DISPLAY_TIMELINE;
  Refresh_Display_Mode();
  Refresh();
end;


//------------------------------------------------------------------------------
procedure Tmain.mnuQuitClick(Sender: TObject);
begin
  RequestToClose:=true;
  close();
end;


//------------------------------------------------------------------------------
procedure Tmain.mnuSettingsClick(Sender: TObject);
begin
  With frmConfig do begin;
    chkConfirmDelItem.Checked:=Config.ConfirmDeleteItem;
    chkConfirmDelProject.Checked:=Config.ConfirmDeleteProject;
    chkHideOnMinimize.Checked:=Config.HideOnMinimize;
    chkHideOnClose.Checked:=Config.HideOnClose;
    chkMinimizeOnStart.Checked:=config.MinimizeOnStart;
    edCharWeek.Text:=Config.WeekChar;
    cbDateFormat.ItemIndex:=Config.DateOrder;
    setLanguage(Config.Lang);
    setKeys(config.modkey, config.key);
    if ShowModal= mrOk then begin
      Config.ConfirmDeleteItem:=chkConfirmDelItem.Checked;
      Config.ConfirmDeleteProject:=chkConfirmDelProject.Checked;
      Config.HideOnMinimize:=chkHideOnMinimize.Checked;
      Config.HideOnClose:=chkHideOnClose.Checked;
      Config.MinimizeOnStart:=chkMinimizeOnStart.Checked;
      Config.Lang:=getLanguage();
      Config.WeekChar:=edCharWeek.Text;
      Config.DateOrder:=cbDateFormat.ItemIndex;
      getKeys(config.modkey, config.key);
      //-- Update
      Refresh();
      RefreshItemsList();
      RefreshTitle();
    end;
  end;
end;


//------------------------------------------------------------------------------
procedure Tmain.tbAllClick(Sender: TObject);
begin
  SelectAllProjects();
  Refresh();
end;


//------------------------------------------------------------------------------
procedure Tmain.tbDisplayProjectsClick(Sender: TObject);
begin
  DisplayMode := DISPLAY_PROJECTS;
  Refresh_Display_Mode();
  Refresh();
end;


//------------------------------------------------------------------------------
procedure Tmain.tbDisplayTimelineClick(Sender: TObject);
begin
  DisplayMode := DISPLAY_TIMELINE;
  Refresh_Display_Mode();
  Refresh();
end;

//------------------------------------------------------------------------------
procedure Tmain.tbNoneClick(Sender: TObject);
begin
  UnselectAllProjects();
  Refresh();
end;


//------------------------------------------------------------------------------
// Analyse the token list
//------------------------------------------------------------------------------
// n : Number of token in the token list
// update : Indicate if the data need to be updated
//
//- return : true if there is no analyse error
//
function TMain.Analyze(n: integer; var act: integer): boolean;
var
  err: integer;
  sToken: string;
begin
  if n = 0 then
    exit;

  //str := '';

  sToken := LowerCase(Token[1]);

  if sToken = 't' then
    //-- Create a task : t [projects] [Px] [>x] [%x] [%e] Text
  begin
    err := CreateTask(n, act);
    if err = 0 then
    begin
      Refresh();
    end;
  end
  else if sToken = 'n' then
    //-- Create a note : n [projects] [Px] Text
  begin
    err := CreateNote(n, act);
    if err = 0 then
    begin
      Refresh();
    end;
  end
  else if sToken = 'd' then
    //-- Delete an item : d "num"
    //-- Delete a project : d [Project]
  begin
    err := DeleteItem(n, act);
  end
  else if sToken = 'c' then
    //-- Copy item: c "num" [projects]
  begin
    err := CopyItem(n, act);
  end
  else if sToken = 'x' then
    //-- Convert item task<>note :x "num" [n/t]
  begin
    err := ConvertItem(n, act);
  end
  else if sToken = 'e' then
  // List item in command line : e "num"
  // Edit an item : e "num" [@Project] [Px] [>x] [%x] [%e] [text]
  // Edit a project name : e @project new_project_name
  begin
    err := EditItem(n, act);
  end
  else if sToken = 'f' then
    //-- Set a display filter on some projets : f [projects]
  begin
    err := SetDisplayFilter(n, act);
  end
  else if sToken = 'f--' then
    //-- hide all project : f--
  begin
    err := DisplayFilterNone(n, act);
  end
  else if sToken = 'f++' then
    //-- Show all projects : f--
  begin
    err := DisplayFilterAll(n, act);
  end
  else if sToken = 'h' then
    //-- Set display mode to timeline : h
  begin
    err := SetDisplayModeTimeline(n, act);
  end
  else if sToken = 'p' then
    //-- Set display mode to projects : p
  begin
    err := SetDisplayModeProjects(n, act);
  end;

  if err<>0 then begin
    //TODO
  end;

  Analyze := (err = 0);
end;


//------------------------------------------------------------------------------
// Create a task : t [projects] [Px] [>x] [%x] [%e] Text
//
function TMain.CreateTask(n: integer; var act: integer): integer;
var
  i, vi: integer;
  s, sProject: string;
  textFound: boolean;
  err: integer;
  dt: TDateTime;
begin
  result:=0;
  act:=ACT_OK;

  err := 0;
  current.itemType := ITEM_TASK;
  sProject := '';
  textFound := False;
  for i := 2 to n do
  begin
    //-- [@]
    if token[i][1] = '@' then
      sProject := sProject + token[i]
    //-- [Px]
    else if Lowercase(token[i][1]) = 'p' then
    begin
      s := copy(token[i], 2, length(token[i]) - 1);
      if not(ConvTestParam(s, current.priority, 0, 2, ERROR_PRIORITY, err)) then
      begin
        textFound := True;
        break; //Exit for
      end;
    end
    //-- >x
    else if token[i][1] = '>' then
    begin
      s := copy(token[i], 2, length(token[i]) - 1);

      if ParseDate(s, config.DateOrder, 8, 5, DayMonday, DayFriday, config.WeekChar[1],
        dt, C_PARSE_NO_ADD_HOUR, False) then
      begin
        current.endDate := dt;
      end
      else
        err := ERROR_ENDDATE;
    end
    //-- [%e]
    else if Lowercase(token[i]) = '%e' then
    begin
      current.progress := 100;
    end
    //-- [%x]
    else if token[i][1] = '%' then
    begin
      s := copy(token[i], 2, length(token[i]) - 1);

      if not(ConvTestParam(s, current.progress, 0, 100, ERROR_PROGRESS, err)) then
      begin
        textFound := True;
        break; //Exit for
      end;
    end
    else
    begin
      textFound := True;
      break; //Exit for
    end;

    //-- Exit for if error
    if err<>0 then break;
  end; //for

  if textFound then
  begin
    current.Text := copy(analyzeStr, tokenpos[i], length(analyzeStr) - tokenpos[i] + 1);
    if length(current.Text) = 0 then
      err := ERROR_NOTEXT;
  end;

  current.creationDate := now;
  current.modifDate := now;

  if err = 0 then
  begin //-- Add to database
    if sProject <> '' then
    begin //-- One or more project
      while GetProject(sProject, current.project) <> '' do
      begin
        current.project := LowerCase(current.project);
        AddToItemsTable();
        AddToProjectTable(current.project);
      end;
    end
    else //-- No project
      AddToItemsTable();
    Result := 0;
  end
  else
    Result := err;
end;


//------------------------------------------------------------------------------
// Convert and test a string
//
// ToConv : String to convert
// Value : Result value
// min : minimum value to test
// max : maximum value
// error : error code if the value is not in the tested range (min,max)
// res : result code. res=0 if no range error. res=error if range error
//
//- return : false=string conversion error. true=string conversion ok
//
function TMain.ConvTestParam(ToConv:string; var value:integer; min, max, error : integer; var res:integer):boolean;
begin
  result:=false;
  res:= error;

  if TryStrToInt(ToConv, value) then begin
    result:=true;
    if value in [min..max] then
      res:=0;
  end
end;


//------------------------------------------------------------------------------
// Get a project string froma source string containing more than one project
//
// src: Source string
// FoundProject: project found. no project=empty
//
//- return: project found. Empty if no project found
//
function TMain.GetProject(var src: string; var FoundProject: string): string;
var
  s: string;
  i: integer;
begin
  i := 2;
  s := '';
  while (i <= length(src)) and (src[i] <> '@') do
  begin
    s := s + src[i];
    Inc(i);
  end;

  Delete(src, 1, i - 1);

  FoundProject := s;
  Result := s;
end;


//------------------------------------------------------------------------------
// Create a note : n [projects] [Px] Text
//
function TMain.CreateNote(n: integer; var act: integer): integer;
var
  i, vi: integer;
  s, sProject: string;
  textFound: boolean;
  err: integer;
  dt: TDateTime;
begin
  result:=0;
  act:=ACT_OK;

  err := 0;
  current.itemType := ITEM_NOTE;
  sProject := '';
  textFound := False;
  for i := 2 to n do
  begin
    //-- [@]
    if token[i][1] = '@' then
      sProject := sProject + token[i]
    //-- [Px]
    else if Lowercase(token[i][1]) = 'p' then
    begin
      s := copy(token[i], 2, length(token[i]) - 1);
      if not(ConvTestParam(s, current.priority, 0, 2, ERROR_PRIORITY, err)) then
      begin
        textFound := True;
        break; //Exit for
      end;
    end
    else
    begin
      textFound := True;
      break; //Exit for
    end;

    //-- Exit for if error
    if err<>0 then break;
  end; //for

  if textFound then
  begin
    current.Text := copy(analyzeStr, tokenpos[i], length(analyzeStr) - tokenpos[i] + 1);
    if length(current.Text) = 0 then
      err := ERROR_NOTEXT;
  end;

  current.creationDate := now;
  current.modifDate := now;

  if err = 0 then
  begin //-- Add to database
    if sProject <> '' then
    begin //-- One or more project
      while GetProject(sProject, current.project) <> '' do
      begin
        current.project := LowerCase(current.project);
        AddToItemsTable();
        AddToProjectTable(current.project);
      end;
    end
    else //-- No project
      AddToItemsTable();
    Result := 0;
  end
  else
    Result := err;
end;


//------------------------------------------------------------------------------
// Delete an item : d "num"
// Delete a project : d [Project]
//
function TMain.DeleteItem(n: integer; var act: integer): integer;
var
  p : integer;
  str : string;
begin
  result:=0;
  act:=ACT_OK;

  if itemList.Count<=0 then begin
    result:=ERROR_NO_ITEMS;
    exit;
  end;

  if n=2 then
  begin
    //-- Delete a project
    if token[2][1]='@' then
    begin
      str :=copy(token[2], 2, length(token[2]) - 1);
      //-- It's not possible to delete the global project => exit
      if str=LowerCase(GLOBAL) then exit;

      if (config.ConfirmDeleteProject=false)
        OR (QuestionDlg('ProjectNoteBook', 'Do you want to delete the project "'+str+'" ?', mtConfirmation,[mrCancel,'Cancel',mrYes,'Ok'],0)=mrYes) then
      begin
        DeleteProjectFromDB(copy(token[2], 2, length(token[2]) - 1));
        UpdateProjectTableFromItemTable();
        Refresh();
      end;
      result:=0;
      exit;
    end
    //-- Delete an item
    else if Str2IntEx(token[2], p) then
    begin
      if (config.ConfirmDeleteItem=false)
        OR (QuestionDlg('ProjectNoteBook', 'Do you want to delete item '+ intToStr(p)+' ?', mtConfirmation,[mrCancel,'Cancel',mrYes,'Ok'],0)=mrYes) then
      begin
        dec(p);
        if p in [0..(itemList.Count-1)] then begin
          DeleteItemFromDB(PItem(itemList.Items[p])^.id);
          UpdateProjectTableFromItemTable();
          Refresh();
        end;
      end;
      result:=0;
      exit;
    end
    else
      result:=ERROR_D_SYNTAXE;
  end
  else begin
    result:=ERROR_D_SYNTAXE;
  end;
end;


//------------------------------------------------------------------------------
// Copy item: c "num" [@project]
//
function TMain.CopyItem(n: integer; var act: integer): integer;
var
  p : integer;
  item : PItem;
  s : string;
begin
  result:=0;
  act:=ACT_OK;

  if Str2IntEx(token[2], p) then
  begin
    dec(p);
    if p in [0..(itemList.Count-1)] then begin
      item:=PItem(itemList.Items[p]);

      if n=2 then //-- copy an item in the same project
      begin
        current.itemType:=item^.itemType;
        current.project:=item^.project;
        current.priority:=item^.priority;
        current.progress:=item^.progress;
        current.endDate:=item^.endDate;
        current.text:=item^.text;
        current.creationDate:=item^.creationDate;
        current.modifDate:=now;
        //--
        AddToItemsTable();
        Refresh();
      end
      else if n=3 then //-- copy an item in the another project
      begin
        current.itemType:=item^.itemType;
        current.project:=lowercase(copy(token[3], 2, length(token[3]) - 1));
        if current.project=global then
          current.project:='';
        current.priority:=item^.priority;
        current.progress:=item^.progress;
        current.endDate:=item^.endDate;
        current.text:=item^.text;
        current.creationDate:=item^.creationDate;
        current.modifDate:=now;
        //--
        AddToItemsTable();
        AddToProjectTable(current.project);
        UpdateProjectTableFromItemTable();
        Refresh();
      end
      else
        result:=ERROR_C_SYNTAXE;
    end;
  end
  else
    result:=ERROR_C_SYNTAXE;
end;



//------------------------------------------------------------------------------
// Convert item task<>note :x "num" [n/t]
//
function TMain.ConvertItem(n: integer; var act: integer): integer;
var
  item : PItem;
  p :integer;
begin
  result:=ERROR_X_SYNTAXE;
  act:=ACT_OK;

  if Str2IntEx(token[2], p) then
  begin
    dec(p);
    if p in [0..(itemList.Count-1)] then begin
      item:=PItem(itemList.Items[p]);
      //--
      if n=3 then begin
        current.id:=item^.id;
        current.project:=item^.project;
        current.priority:=item^.priority;
        current.progress:=item^.progress;
        current.endDate:=item^.endDate;
        current.text:=item^.text;
        current.creationDate:=item^.creationDate;
        current.modifDate:=now;

        if lowercase(token[3])='n' then begin
          current.itemType:=ITEM_NOTE;
          UpdateItemsTable();
          Refresh();
          result:=0;
        end
        else if lowercase(token[3])='t' then begin
          current.itemType:=ITEM_TASK;
          UpdateItemsTable();
          Refresh();
          result:=0;
        end
      end
    end
  end
end;


//------------------------------------------------------------------------------
// List item in command line : e "num"
// Edit an item : e "num" [@Project] [Px] [>x] [%x] [%e] [text]
// Edit a project name : e @project new_project_name
//
function TMain.EditItem(n: integer; var act: integer): integer;
var
  i, num, err : integer;
  item : PItem;
  s, sOld, sNew : string;
  textFound : boolean;
  dt: TDateTime;
begin
  act:=ACT_OK;
  result:=0;
  num := 0;
  err:=0;
  s:='';

  if Str2IntEx(token[2],num) then begin
    if num in [1..itemList.Count] then begin
      item:=PItem(itemList.Items[num-1]);

      //-- e "num" : 2 parameters, list the parameters in the commandline
      if n=2 then begin
        s:='e '+intToStr(num);

        if item^.project<>'' then
          s:=s+' @'+item^.project;


        s:= s + ' P'+intToStr(item^.priority);

        if item^.itemType=ITEM_TASK then begin
          s:=s+' %'+intToStr(item^.progress);

          if item^.endDate<>0 then
            s:=s + ' >' + FormatDateTimeEx(ToFormatDate(config.DateOrder), item^.endDate);
        end;

        s:=s +' '+item^.text;

        edCommandLine.Text:=s;
        act:=ACT_NO_ERASE;
        exit;
      end
      else begin
        //-- More than 2 parameters. Analyze the command line
        err := 0;
        textFound := False;

        with current do begin
          id :=item^.id;
          itemType :=item^.itemType;
          project :=item^.project;
          priority :=item^.priority;
          progress :=item^.progress;
          endDate :=item^.endDate;
          text :=item^.text;
          creationDate :=item^.creationDate;
          modifDate :=item^.modifDate;
        end; //with

        for i := 3 to n do
        begin
          //-- [@]
          if token[i][1] = '@' then begin
            current.project := copy(token[i], 2, length(token[i]) - 1);
            if LowerCase(current.project)=GLOBAL then
              current.project:='';
          end
          //-- [Px]
          else if Lowercase(token[i][1]) = 'p' then
          begin
            s := copy(token[i], 2, length(token[i]) - 1);
            if not(ConvTestParam(s, current.priority, 0, 2, ERROR_PRIORITY, err)) then
            begin
              textFound := True;
              break; //Exit for
            end;
          end
          //-- >x
          else if (token[i][1] = '>') AND (current.itemType=ITEM_TASK) then
          begin
            s := copy(token[i], 2, length(token[i]) - 1);

            if ParseDate(s, config.DateOrder, 8, 5, DayMonday, DayFriday, config.WeekChar[1],
              dt, C_PARSE_NO_ADD_HOUR, False) then
            begin
              current.endDate := dt;
            end
            else
              err := ERROR_ENDDATE;
          end
          //-- [%e]
          else if (Lowercase(token[i]) = '%e') AND (current.itemType=ITEM_TASK) then
          begin
            current.progress := 100;
          end
          //-- [%x]
          else if (token[i][1] = '%') AND (current.itemType=ITEM_TASK) then
          begin
            s := copy(token[i], 2, length(token[i]) - 1);

            if not(ConvTestParam(s, current.progress, 0, 100, ERROR_PROGRESS, err)) then
            begin
              textFound := True;
              break; //Exit for
            end;
          end
          else
          begin
            textFound := True;
            break; //Exit for
          end;

          //-- Exit for if error
          if err<>0 then break;
        end; //for

        if textFound then
        begin
          current.Text := copy(analyzeStr, tokenpos[i], length(analyzeStr) - tokenpos[i] + 1);
          if length(current.Text) = 0 then
            err := ERROR_NOTEXT;
        end;

        current.modifDate := now;

        if err = 0 then
        begin //-- Update item in database
          UpdateItemsTable();
          AddToProjectTable(current.project);
          UpdateProjectTableFromItemTable();
          Refresh();
          Result := 0;
        end
        else
          Result := err;
      end;
    end
  end
  else if token[2][1]='@' then begin
    //-- Edit a project name : e [projet] text
    if n=3 then begin
      sOld := copy(token[2], 2, length(token[2]) - 1);
      sNew := token[3];
      RenameProjectInItemTable(sOld,sNew);
      AddToProjectTable(sNew);
      UpdateProjectTableFromItemTable();
      Refresh();
      Result := 0;
    end
    else
      result:=ERROR_E_RENAME;
  end
  else
    result:=ERROR_E_NONUM_OR_PROJECT;
end;


//------------------------------------------------------------------------------
// Set a display filter on some projets : f +/-[projects]
//
function TMain.SetDisplayFilter(n: integer; var act: integer): integer;
var
  s,sl : string;
  i : integer;
begin
  result:=ERROR_F_SYNTAXE;
  act:=ACT_OK;

  for i:=2 to n do begin
    s:=lowercase(token[i]);
    if length(s)>1 then begin
      sl:=LeftStr(s,2);
      if sl[1]='@' then begin
        SelectProject(copy(token[i], 2, length(token[i]) - 1));
        result:=0;
      end
      else if sl='+@' then begin
        SelectProject(copy(token[i], 3, length(token[i]) - 2));
        result:=0;
      end
      else if sl='-@' then begin
        UnselectProject(copy(token[i], 3, length(token[i]) - 2));
        result:=0;
      end;
    end;
  end;
  Refresh();
end;


//------------------------------------------------------------------------------
// Unselect all project : f--
//
function TMain.DisplayFilterNone(n: integer; var act: integer): integer;
begin
  act:=ACT_OK;
  if n=1 then begin
    UnselectAllProjects();
    Refresh();
    result:=0;
  end
  else
    result:=ERROR_FMM_SYNTAXE;
end;

//------------------------------------------------------------------------------
// Select all project : f++
//
function TMain.DisplayFilterAll(n: integer; var act: integer): integer;
begin
  act:=ACT_OK;
  if n=1 then begin
    SelectAllProjects();
    Refresh();
    act:=ACT_OK;
    result:=0;
  end
  else
    result:=ERROR_FMM_SYNTAXE;
end;


//------------------------------------------------------------------------------
// Set display mode to Timeline : h
//
Function TMain.SetDisplayModeTimeline(n: integer; var act: integer): integer;
begin
  if n=1 then begin
    DisplayMode:=DISPLAY_TIMELINE;
    Refresh();
    Refresh_Display_Mode();
    result:=0;
  end
  else begin
    result:=ERROR_H_TOOMANYPARAMS;
  end;
end;


//------------------------------------------------------------------------------
// Set display mode to Timeline : p
//
Function TMain.SetDisplayModeProjects(n: integer; var act: integer): integer;
begin
  if n=1 then begin
    DisplayMode:=DISPLAY_PROJECTS;
    Refresh();
    Refresh_Display_Mode();
    result:=0;
  end
  else begin
    result:=ERROR_P_TOOMANYPARAMS;
  end;
end;

//------------------------------------------------------------------------------
// Create a new database file
//
procedure TMain.CreateDB();
begin
  try
    // Make the database and the tables
    try
      dmDB.Connection.Open;
      dmDB.Transaction.Active := True;

      // Here we're setting up a table named "ITEMS" in the new database
      dmDB.Connection.ExecuteDirect('CREATE TABLE IF NOT EXISTS "items" (' +
        ' "id"	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,' +
        ' "type"	INTEGER NOT NULL DEFAULT 0,' + ' "project"	TEXT NOT NULL,' +
        ' "priority"	INTEGER NOT NULL DEFAULT 0,' +
        ' "progress"	INTEGER NOT NULL DEFAULT 0,' +
        ' "enddate"	TEXT NOT NULL,' + ' "text"	TEXT NOT NULL,' +
        ' "creationDate"	TEXT NOT NULL,' + ' "modifDate"	TEXT NOT NULL)');

      dmDB.Connection.ExecuteDirect('CREATE TABLE IF NOT EXISTS "projects" (' +
        ' "id"	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,' +
        ' "name"	TEXT NOT NULL,' +
        ' "selected" INTEGER NOT NULL DEFAULT 1)');

      dmDB.Connection.ExecuteDirect('INSERT INTO projects (name,selected) VALUES ("'+GLOBAL+'",1)');

      dmDB.Transaction.Commit;

    except
      ShowMessage('Unable to Create new Database');
    end;
  except
    ShowMessage('Unable to check if database file exists');
  end;
end;


//------------------------------------------------------------------------------
// Rename project in "items" table
//
// old : Project name to reanme
// new : New project name
//
Procedure TMain.RenameProjectInItemTable(old, New :string);
var
  s:string;
begin
  if (old='') or (new='') then exit;

  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;

    s:='UPDATE items SET project="'+New+'" WHERE project="'+Old+'"';

    dmDB.SQLQuery.SQL.Text := s;
    dmDB.SQLQuery.ExecSQL;

    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to rename project in table "items".');
  end;
end;


//------------------------------------------------------------------------------
// Update an item in the 'items' table
//
procedure TMain.UpdateItemsTable();
var s,sd:string;
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;

    s:='UPDATE items SET '+
      ' type='+intToStr(current.itemType);

    //if current.project<>'' then
      s:=s+', project="'+current.project+'"';

    s:=s+', priority='+intToStr(current.priority)+
      ', progress='+intToStr(current.progress);

    sd:=FormatDateTimeEx(FORMAT_DATE, current.endDate);
    if sd<>'' then
      s:=s+', enddate='+sd;

    if current.text<>'' then
      s:=s+', text="'+current.text+'"';

    s:=s+', creationdate='+FormatDateTimeEx(FORMAT_DATETIME, current.creationDate)+
      ', modifdate='+FormatDateTimeEx(FORMAT_DATETIME, current.modifDate)+
      ' WHERE id='+intToStr(current.id);

    dmDB.SQLQuery.SQL.Text := s;
    dmDB.SQLQuery.ExecSQL;

    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable update an item in table "items".');
  end;
end;


//------------------------------------------------------------------------------
// Add the current item to the items table
//
procedure TMain.AddToItemsTable();
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;

    dmDB.SQLQuery.SQL.Text :=
      'INSERT INTO items (type,project,priority,progress,enddate,text,creationdate,modifdate) VALUES (:type,:project,:priority,:progress,:enddate,:text,:creationdate,:modifdate)';
    dmDB.SQLQuery.Params.ParamByName('type').AsInteger := current.itemType;
    dmDB.SQLQuery.Params.ParamByName('project').AsString := current.project;
    dmDB.SQLQuery.Params.ParamByName('priority').AsInteger := current.priority;
    dmDB.SQLQuery.Params.ParamByName('progress').AsInteger := current.progress;
    dmDB.SQLQuery.Params.ParamByName('enddate').AsString :=
      FormatDateTimeEx(FORMAT_DATE, current.endDate); //current.endDate;
    dmDB.SQLQuery.Params.ParamByName('text').AsString := current.Text;
    dmDB.SQLQuery.Params.ParamByName('creationdate').AsString :=
      FormatDateTimeEx(FORMAT_DATETIME, current.creationDate);
    dmDB.SQLQuery.Params.ParamByName('modifdate').AsString :=
      FormatDateTimeEx(FORMAT_DATETIME, current.modifDate);

    dmDB.SQLQuery.ExecSQL;

    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to add an item to table "items".');
  end;
end;


//------------------------------------------------------------------------------
// Add an item to the projects table
//
//- Return : true = new project / false = project already exist
//
Function TMain.AddToProjectTable(project: string):boolean;
begin
  result:=false;
  // Attempt to add txtUser_Name and txtInfo to the database
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;

    //-- Test if the project name is already in the table
    dmDB.SQLQuery.SQL.Text := 'SELECT * FROM projects WHERE name="'+project+'"';
    dmDB.SQLQuery.Open;

    if dmDB.SQLQuery.EOF then begin
      //-- Not in the table! Add it...
      dmDB.SQLQuery.SQL.Text := 'INSERT INTO projects (name,selected) VALUES (:name,1)';
      dmDB.SQLQuery.Params.ParamByName('name').AsString := project;

      dmDB.SQLQuery.ExecSQL;
      dmDB.Transaction.Commit;
      result:=true;
    end;

    dmDB.Connection.Close;
  except
    ShowMessage('Unable to a project name to table "projects".');
  end;
end;


//------------------------------------------------------------------------------
// Read items from the "items" table
//
procedure TMain.ReadItemsFromDB();
var
  s : string;
  item: PItem;
begin
  ClearItemList();
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;

    s:='SELECT * FROM items ';

    //-- Project filters
    s:=s + 'WHERE project IN (' + genFilter() + ') ';

    //-- Sort
    if DisplayMode=DISPLAY_PROJECTS then begin
      s:=s + 'ORDER BY project, enddate';
    end
    else if DisplayMode=DISPLAY_TIMELINE then begin
      s:= s + 'ORDER BY enddate,project';
    end;

    dmDB.SQLQuery.SQL.Text:=s;

    //-- Go
    dmDB.SQLQuery.Open;
    while not dmDB.SQLQuery.EOF do
    begin
      new(item);
      item^.id := dmDB.SQLQuery.FieldByName('id').AsLongint;
      item^.itemType := dmDB.SQLQuery.FieldByName('type').AsInteger;
      item^.project := dmDB.SQLQuery.FieldByName('project').AsString;
      item^.priority := dmDB.SQLQuery.FieldByName('priority').AsInteger;
      item^.progress := dmDB.SQLQuery.FieldByName('progress').AsInteger;
      item^.endDate := StrDate2Datetime(dmDB.SQLQuery.FieldByName('enddate').AsString);
      item^.Text := dmDB.SQLQuery.FieldByName('text').AsString;
      item^.creationDate := StrDatetime2Datetime(dmDB.SQLQuery.FieldByName('creationdate').AsString);
      item^.modifDate := StrDatetime2Datetime(dmDB.SQLQuery.FieldByName('modifdate').AsString);
      itemList.Add(item);
      dmDB.SQLQuery.Next;
    end;
    dmDB.SQLQuery.Close;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to read the database');
  end;
end;


//------------------------------------------------------------------------------
// Read projects from the "projects" table
//
procedure TMain.ReadProjectsFromDB();
var
  prj: PProject;
begin
  ClearProjectList();

  //-- Read from DB
  try
    dmDB.Connection.Open();
    dmDB.Transaction.Active := True;
    //--
    dmDB.SQLQuery.SQL.Text := 'SELECT * FROM projects WHERE name="'+GLOBAL+'" ORDER BY name ASC';
    dmDB.SQLQuery.Open();
    while not dmDB.SQLQuery.EOF do
    begin
      new(prj);
      prj^.id := dmDB.SQLQuery.FieldByName('id').AsLongint;
      prj^.name := dmDB.SQLQuery.FieldByName('name').AsString;
      prj^.selected := (dmDB.SQLQuery.FieldByName('selected').AsInteger=1);
      projectList.Add(prj);
      dmDB.SQLQuery.Next();
    end;
    dmDB.Transaction.Commit();
    //--
    dmDB.SQLQuery.SQL.Text := 'SELECT * FROM projects WHERE name<>"'+GLOBAL+'" ORDER BY name ASC';
    dmDB.SQLQuery.Open();
    while not dmDB.SQLQuery.EOF do
    begin
      new(prj);
      prj^.id := dmDB.SQLQuery.FieldByName('id').AsLongint;
      prj^.name := dmDB.SQLQuery.FieldByName('name').AsString;
      prj^.selected := (dmDB.SQLQuery.FieldByName('selected').AsInteger=1);
      projectList.Add(prj);
      dmDB.SQLQuery.Next();
    end;


    dmDB.SQLQuery.Close();
    dmDB.Connection.Close();
  except
    ShowMessage('Unable to read the database');
  end;
end;



//------------------------------------------------------------------------------
// Select all the projects in the project list and on the check list
//
procedure TMain.SelectAllProjects();
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;
    dmDB.Connection.ExecuteDirect('UPDATE projects SET selected=1');
    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to select projects');
  end;
end;


//------------------------------------------------------------------------------
// Unselect all the projects
//
procedure TMain.UnselectAllProjects();
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;
    dmDB.Connection.ExecuteDirect('UPDATE projects SET selected=0');
    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to select projects');
  end;
end;

//------------------------------------------------------------------------------
// Select one project
//
procedure TMain.SelectProject(s:string);
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;
    dmDB.Connection.ExecuteDirect('UPDATE projects SET selected=1 WHERE name="'+s+'"');
    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    //ShowMessage('Unable to select projects');
  end;
end;


//------------------------------------------------------------------------------
// Unselect one project
//
procedure TMain.UnselectProject(s:string);
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;
    dmDB.Connection.ExecuteDirect('UPDATE projects SET selected=0 WHERE name="'+s+'"');
    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    //ShowMessage('Unable to select projects');
  end;
end;


//------------------------------------------------------------------------------
// Delete an item from the database
//
// str : item to delete
//
Procedure TMain.DeleteItemFromDB(id : integer);
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;
    dmDB.Connection.ExecuteDirect('DELETE FROM items WHERE id='+IntToStr(id));
    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to delete an item');
  end;
end;


//------------------------------------------------------------------------------
// Delete a project from the database
//
// str : project to delete
//
Procedure TMain.DeleteProjectFromDB(str : string);
begin
  str:=LowerCase(str);
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;
    dmDB.Connection.ExecuteDirect('DELETE FROM items WHERE project="'+str+'"');
    dmDB.Transaction.Commit;
    dmDB.Connection.ExecuteDirect('DELETE FROM projects WHERE name="'+str+'"');
    dmDB.Transaction.Commit;
    dmDB.Connection.Close;
  except
    ShowMessage('Unable to delete a project');
  end;
end;


//------------------------------------------------------------------------------
Procedure TMain.UpdateProjectTableFromItemTable();
var
  s : string;
begin
  try
    dmDB.Connection.Open;
    dmDB.Transaction.Active := True;

    //--
    s:='';
    dmDB.SQLQuery.SQL.Text := 'SELECT DISTINCT project FROM items WHERE project<>"" ORDER BY project';
    dmDB.SQLQuery.Open();
    while not dmDB.SQLQuery.EOF do
    begin
      if s='' then
        s:= 'name<>"'+GLOBAL+'" AND name<>"'+dmDB.SQLQuery.FieldByName('project').AsString+'"'
      else
        s:= s + ' AND name<>"'+dmDB.SQLQuery.FieldByName('project').AsString+'"';
      dmDB.SQLQuery.Next();
    end;

    if s='' then
      s:= 'name<>"'+GLOBAL+'"';

    //--
    dmDB.Connection.ExecuteDirect('DELETE FROM projects WHERE ' + s);
    dmDB.Transaction.Commit;

    dmDB.Connection.Close;
  except
    ShowMessage('Unable to uptable projects table');
  end;
end;


//------------------------------------------------------------------------------
// Refresh the display mode in the menu
//
procedure TMain.Refresh_Display_Mode();
begin
  mnuDisplayProjects.Checked := (DisplayMode = DISPLAY_PROJECTS);
  mnuDisplayTimeline.Checked := (DisplayMode = DISPLAY_TIMELINE);

  tbDisplayProjects.Down :=  (DisplayMode = DISPLAY_PROJECTS);
  tbDisplayTimeline.Down :=  (DisplayMode = DISPLAY_TIMELINE);
end;


//------------------------------------------------------------------------------
// Generate the project filter to read the "projects" table
//
//- Return : String containing the formated filter
//
function TMain.GenFilter():String;
var
  s, sep:string;
  i:integer;
  p : PProject;
begin
  s:='';
  sep:='';
  for i:=0 to projectList.Count-1 do begin
    p:=PProject(projectList.Items[i]);
    if p^.selected then begin
      if p^.name=GLOBAL then begin
        s:=s+sep+'"" ';
        sep:=',';
      end
      else begin
        s:=s+sep+'"'+p^.name+'" ';
        sep:=',';
      end;
    end;
  end;
  result:=s;
end;


//------------------------------------------------------------------------------
// Update the display
//
Procedure TMain.Refresh();
begin
  //-- Read data from DB
  ReadProjectsFromDB();
  ReadItemsFromDB();
  //-- Update display
  RefreshItemsList();
  RefreshProjectsList();
  RefreshStatusbar();
end;


//------------------------------------------------------------------------------
function MsgProc(Handle: HWnd; Msg: UInt; WParam: Windows.WParam;
    LParam: Windows.LParam): LResult; stdcall;
begin
  with Main do
  begin
    if Msg = WM_HOTKEY then
      ProcessHotKey(HIWORD(LParam))
    else
      Result := Windows.CallWindowProc(OldProc, Handle, Msg, WParam, LParam);
  end;
end;


end.
