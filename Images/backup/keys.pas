unit keys;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,windows ;

function VirtualKeyToString(Key: Word): String;


implementation


function VirtualKeyToString(Key: Word): String;
begin
  // See define.inc
  case Key of
    VK_BACK: result:='VK_BACK';
    VK_TAB: result:='VK_TAB';
    VK_CLEAR: result:='VK_CLEAR';
    VK_RETURN: result:='VK_RETURN';
    VK_CAPITAL: result:='VK_CAPITAL';
    VK_ESCAPE: result:='VK_ESCAPE';
    VK_SPACE: result:='VK_SPACE';
    VK_PRIOR: result:='VK_PRIOR';
    VK_NEXT: result:='VK_NEXT';
    VK_END: result:='VK_END';
    VK_HOME: result:='VK_HOME';
    VK_LEFT: result:='VK_LEFT';
    VK_UP: result:='VK_UP';
    VK_RIGHT: result:='VK_RIGHT';
    VK_DOWN: result:='VK_DOWN';
    VK_SELECT: result:='VK_SELECT';
    VK_PRINT: result:='VK_PRINT';
    VK_EXECUTE: result:='VK_EXECUTE';
    VK_INSERT: result:='VK_INSERT';
    VK_DELETE: result:='VK_DELETE';
    VK_HELP: result:='VK_HELP';
    VK_0: result:='VK_0';
    VK_1: result:='VK_1';
    VK_2: result:='VK_2';
    VK_3: result:='VK_3';
    VK_4: result:='VK_4';
    VK_5: result:='VK_5';
    VK_6: result:='VK_6';
    VK_7: result:='VK_7';
    VK_8: result:='VK_8';
    VK_9: result:='VK_9';
    VK_A: result:='VK_A';
    VK_B: result:='VK_B';
    VK_C: result:='VK_C';
    VK_D: result:='VK_D';
    VK_E: result:='VK_E';
    VK_F: result:='VK_F';
    VK_G: result:='VK_G';
    VK_H: result:='VK_H';
    VK_I: result:='VK_I';
    VK_J: result:='VK_J';
    VK_K: result:='VK_K';
    VK_L: result:='VK_L';
    VK_M: result:='VK_M';
    VK_N: result:='VK_N';
    VK_O: result:='VK_O';
    VK_P: result:='VK_P';
    VK_Q: result:='VK_Q';
    VK_R: result:='VK_R';
    VK_S: result:='VK_S';
    VK_T: result:='VK_T';
    VK_U: result:='VK_U';
    VK_V: result:='VK_V';
    VK_W: result:='VK_W';
    VK_X: result:='VK_X';
    VK_Y: result:='VK_Y';
    VK_Z: result:='VK_Z';
    VK_NUMPAD0: result:='VK_NUMPAD0';
    VK_NUMPAD1: result:='VK_NUMPAD1';
    VK_NUMPAD2: result:='VK_NUMPAD2';
    VK_NUMPAD3: result:='VK_NUMPAD3';
    VK_NUMPAD4: result:='VK_NUMPAD4';
    VK_NUMPAD5: result:='VK_NUMPAD5';
    VK_NUMPAD6: result:='VK_NUMPAD6';
    VK_NUMPAD7: result:='VK_NUMPAD7';
    VK_NUMPAD8: result:='VK_NUMPAD8';
    VK_NUMPAD9: result:='VK_NUMPAD9';
    VK_MULTIPLY: result:='VK_MULTIPLY';
    VK_ADD: result:='VK_ADD';
    VK_SEPARATOR: result:='VK_SEPARATOR';
    VK_SUBTRACT: result:='VK_SUBTRACT';
    VK_DECIMAL: result:='VK_DECIMAL';
    VK_DIVIDE: result:='VK_DIVIDE';
    VK_F1: result:='VK_F1';
    VK_F2: result:='VK_F2';
    VK_F3: result:='VK_F3';
    VK_F4: result:='VK_F4';
    VK_F5: result:='VK_F5';
    VK_F6: result:='VK_F6';
    VK_F7: result:='VK_F7';
    VK_F8: result:='VK_F8';
    VK_F9: result:='VK_F9';
    VK_F10: result:='VK_F10';
    VK_F11: result:='VK_F11';
    VK_F12: result:='VK_F12';
    VK_F13: result:='VK_F13';
    VK_F14: result:='VK_F14';
    VK_F15: result:='VK_F15';
    VK_F16: result:='VK_F16';
    VK_F17: result:='VK_F17';
    VK_F18: result:='VK_F18';
    VK_F19: result:='VK_F19';
    VK_F20: result:='VK_F20';
    VK_F21: result:='VK_F21';
    VK_F22: result:='VK_F22';
    VK_F23: result:='VK_F23';
    VK_F24: result:='VK_F24';
    VK_NUMLOCK: result:='VK_NUMLOCK';
    VK_SCROLL: result:='VK_SCROLL';
  else
    Result := '';
  end;
end;



end.

