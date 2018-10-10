unit items;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Procedure InitItem();
Procedure ClearItemList();

Const
  ITEM_NOTE=0;
  ITEM_TASK=1;
  PRIORITY_LOW=0;
  PRIORITY_MEDIUM=1;
  PRIORITY_HIGH=2;

type
  PItem = ^TItem;
  TItem = Record
    id : longint;
    itemType : integer; //0=Note 1=Task
    project : string;
    priority : integer; //0=low 1=medium 3=high
    progress : integer; //0..100%
    endDate : TDateTime;
    delEndDate : boolean; //Used to initialize the 'endDate' field during the edit process
    text : string;
    creationDate : TDateTime;
    modifDate : TDateTime;
  end;



var
  current : TItem;
  itemList : TList;

implementation


procedure InitItem();
begin
  with current do
  begin
    itemType:=ITEM_NOTE;
    project:='';
    priority:=PRIORITY_LOW;
    progress:=0;
    endDate:=0.0;
    text:='';
    creationDate:=0.0;
    modifDate:=0.0;
    delEndDate:=false;
  end;
end;

Procedure ClearItemList();
Var i:Integer;
Begin
  For i:=itemList.count-1 Downto 0 Do
  Begin
    //-- Free the item
    If itemList.Items[i]<>Nil Then Dispose(PItem(ItemList.Items[i]));
    //-- Delete the item
    itemList.Delete(i);
  End;
End;



end.

