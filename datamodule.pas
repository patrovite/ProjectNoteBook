unit datamodule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, db, FileUtil;

type

  { TdmDB }

  TdmDB = class(TDataModule)
    Connection: TSQLite3Connection;
    DataSource: TDataSource;
    SQLQuery: TSQLQuery;
    Transaction: TSQLTransaction;
  private

  public

  end;

var
  dmDB: TdmDB;

implementation

{$R *.lfm}

end.

