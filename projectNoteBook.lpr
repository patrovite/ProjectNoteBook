program projectNoteBook;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, FrameViewer09, frmMain, utils, utils_date, datamodule, configuration,
  dlgConfig, keys, errors, exportHtmlJS;

{$R *.res}

begin
  Application.Scaled:=True;
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TdmDB, dmDB);
  Application.CreateForm(Tmain, main);
  Application.CreateForm(TfrmConfig, frmConfig);
  Application.Run;
end.

