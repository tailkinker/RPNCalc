{
  This file is part of RPNCalc, Copyright (c) 2026 Timothy Groves

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
}

unit fcalc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Types;

type

  { TfrmCalculator }

  TfrmCalculator = class(TForm)
    panKeyGrid: TPanel;
    txtEntry: TEdit;
    lstStack: TListBox;
    procedure btnEnterClick(Sender: TObject);
    procedure btnNumberClick(Sender: TObject);
    procedure btnOperatorClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure KeyPress(Sender: TObject; var Key: char);
    procedure lstStackDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
  private
    t_buttonWidth : integer;
    t_buttonHeight : integer;
    t_fontHeight : integer;
    angles : byte;
    t_stack : array of double;
    PrimedToExit : boolean;
    procedure Push (Value : double);
    function Pop: Double;
    procedure UpdateStackDisplay;
    procedure btnOperation (aTag : integer);
    procedure FocusEntry;
  public
    Buttons : array [0..7, 0..4] of tButton;
  end;

var
  frmCalculator: TfrmCalculator;

implementation

uses
  lcltype, math, inifiles;

const
  BUTTON_CAPS : array[0..4, 0..7] of string = (
    // Row 0
    ('sin', 'cos', 'tan', 'deg', 'Enter', '7', '8', '9'),
    // Row 1
    ('×', '+', '-', '÷', 'Clear', '4', '5', '6'),
    // Row 2
    ('x²', '√x', 'ln', 'log', 'y^x', '1', '2', '3'),
    // Row 3
    ('π', 'Dup', 'Swap', 'Drop', '1/x', '0', '.', '±'),
    // Row 4
    ('', '', '', '', '', '', '', '')
  );
  BUTTON_TYPE : array [0..4, 0..7] of integer = (
    ( 0, 0, 0, 5, 2, 1, 1, 1),
    ( 0, 0, 0, 0, 4, 1, 1, 1),  // 0 is a function button
    ( 0, 0, 0, 0, 0, 1, 1, 1),  // 1 is a numeric entry button
    ( 1, 3, 3, 3, 0, 1, 1, 1),  // 2 is the Enter button
    ( 0, 0, 0, 0, 0, 0, 0, 0)   // This row is not displayed;  for expansion
  );

{$R *.lfm}

{ TfrmCalculator }

function GetConfigDir: string;
begin
  if GetEnvironmentVariable('XDG_CONFIG_HOME') <> '' then
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('XDG_CONFIG_HOME'))
  else
    Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('HOME')) + '.config/';
  Result := Result + 'rpncalc/'; // final config dir
  if not DirectoryExists(Result) then
    CreateDir(Result);
end;

procedure TfrmCalculator.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(GetConfigDir + 'rpncalc.ini');
  try
    ini.WriteInteger('Window', 'Left', Left);
    ini.WriteInteger('Window', 'Top', Top);
    ini.WriteInteger('Window', 'Width', Width);
    ini.WriteInteger('Window', 'Height', Height);
  finally
    ini.Free;
  end;
end;

procedure TfrmCalculator.FormCreate(Sender: TObject);
var
  ini: TIniFile;
  r, c: Integer;
  btn: TButton;
  extrapadding : integer;
const
  padding = 8;
begin
  lstStack.Style := lbOwnerDrawFixed;
  ini := TIniFile.Create(GetConfigDir + 'rpncalc.ini');
  try
    Left := ini.ReadInteger('Window', 'Left', Left);
    Top := ini.ReadInteger('Window', 'Top', Top);
    Width := ini.ReadInteger('Window', 'Width', Width);
    Height := ini.ReadInteger('Window', 'Height', Height);
  finally
    ini.Free;
  end;

  t_buttonWidth := 3 * Screen.PixelsPerInch div 4;
  t_buttonHeight := 1 * Screen.PixelsPerInch div 2;
  t_fontHeight := 1 * Screen.PixelsPerInch div 5;

  for r := 0 to 3 do
    for c := 0 to 7 do begin
      if (c > 4) then
        extrapadding := 16
      else
        extrapadding := 0;
      btn := TButton.Create(Self);
      btn.Parent := panKeyGrid;
      btn.Width := t_buttonWidth;
      btn.Height := t_buttonHeight;
      btn.Left := c * (t_buttonWidth + padding) + extrapadding;  // horizontal padding
      btn.Top := r * (t_buttonHeight + padding);  // vertical padding
      btn.Caption := BUTTON_CAPS[r,c];
      btn.Tag := r * 8 + c;  // unique identifier
      btn.TabStop := FALSE;
      btn.Font.Height := t_fontHeight;

      // Assign event handlers
      case BUTTON_TYPE[r,c] of
        1: btn.OnClick := @btnNumberClick;
        2: btn.OnClick := @btnEnterClick;
      else
        btn.OnClick := @btnOperatorClick;
      end;

      // Assign colours
      case BUTTON_TYPE[r,c] of
        0 : btn.Color := clSilver;
        1 : btn.Color := clWhite;
        2 : btn.Color := clMoneyGreen;
        3 : btn.Color := clSkyBlue;
        4 : btn.Color := $CCCCFF;
        5 : btn.Color := clGray;
      end;
      Buttons[c,r] := btn;
    end;
  PrimedToExit := FALSE
end;

procedure TfrmCalculator.KeyPress(Sender: TObject; var Key: char);
begin
  case Key of
    #27 :
      if (PrimedToExit) then
        Close
      else
        PrimedToExit := TRUE;
    '0'..'9':
      txtEntry.Text := txtEntry.Text + Key;  // same as btnNumberClick
    '.':
      if (Pos('.', txtEntry.Text) = 0) then
        txtEntry.Text := txtEntry.Text + '.';
    #8:  // Backspace
      if Length(txtEntry.Text) > 0 then
        txtEntry.Text := Copy(txtEntry.Text, 1, Length(txtEntry.Text) - 1);
    #13:  // Enter key
      btnEnterClick(self);  // trigger Enter
    '*' : // *
      btnOperation (8);
    '+' : // +
      btnOperation (9);
    '-' : // -
      btnOperation (10);
    '/' : // /
      btnOperation (11);
  end;

  if (key <> #27) then
      PrimedToExit := FALSE;

  FocusEntry;
  Key := #0; // prevent further processing
end;

procedure TfrmCalculator.lstStackDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
var
  s: string;
  wText: Integer;
  numberStr: string;
  padding: Integer;
  displayIndex: Integer;
begin
  s := lstStack.Items[Index];

  // --- Background ---
  if odSelected in State then
    lstStack.Canvas.Brush.Color := clHighlight
  else
    lstStack.Canvas.Brush.Color := lstStack.Color;
  lstStack.Canvas.FillRect(ARect);

  // --- Reversed line number (last item = #1) ---
  displayIndex := lstStack.Items.Count - Index;
  numberStr := IntToStr(displayIndex) + '. ';

  // --- Text width ---
  wText := lstStack.Canvas.TextWidth(s);

  // Optional padding between number and text
  padding := 4;

  // --- Draw number on the left ---
  lstStack.Canvas.TextOut(ARect.Left, ARect.Top, numberStr);

  // --- Draw text right-aligned ---
  lstStack.Canvas.TextOut(ARect.Right - wText - 2, ARect.Top, s);
end;

procedure TfrmCalculator.btnEnterClick(Sender: TObject);
begin
  Push (StrToFloat (txtEntry.Text));
  txtEntry.Text := '';
  FocusEntry;
end;

procedure TfrmCalculator.btnNumberClick(Sender: TObject);
var
  s : string;
begin
  s := TButton(Sender).Caption;
  if (TButton(Sender).Tag = 24) then // Pi button pressed
    txtEntry.Text := FloatToStr (Pi)
  else if (TButton(Sender).Tag = 31) then begin // ± button pressed
    if (txtEntry.Text = '') then
      txtEntry.Text := '0'
    else
      txtEntry.Text := FloatToStr (-StrToFloat (txtEntry.Text))
  end else
    KeyPress (Sender, s [1]);
  FocusEntry;
end;

procedure TfrmCalculator.btnOperation (aTag : integer);
var
  a,
  b: double;
  Error : string;
  StackLen : integer;
begin
  if (aTag = 12) then
    if (length (txtEntry.Text) > 0) then
      txtEntry.Text := ''
    else
      SetLength(t_stack, 0);

  Error := '';
  if (length (txtEntry.Text) > 0) then
    Push (StrToFloat (txtEntry.Text));

  StackLen := Length (t_stack);
  case (aTag) of
    0: // sin
      if (StackLen >= 1) then
        begin
          a := Pop;
          case angles of
            0 : b := pi / 180; // degrees
            1 : b := 1;        // radians
            2 : b := pi / 200; // gradians
          end;
          a := sin (a * b);
          Push (a);
        end;
    1: // cos
      if (StackLen >= 1) then
        begin
          a := Pop;
          case angles of
            0 : b := pi / 180; // degrees
            1 : b := 1;        // radians
            2 : b := pi / 200; // gradians
          end;
          a := cos (a * b);
          Push (a);
        end;
    2: // tan
      if (StackLen >= 1) then
        begin
          a := Pop;
          case angles of
            0 : b := pi / 180; // degrees
            1 : b := 1;        // radians
            2 : b := pi / 200; // gradians
          end;
          try
            a := tan (a * b);
          except
            Error := 'Tangent undefined for this angle';
          end;
          Push (a);
        end;
    8 : // *
      if (StackLen >= 2) then
        begin
          a := Pop;
          b := Pop;
          a := a * b;
          Push (a);
        end;
    9 : // +
      if (StackLen >= 2) then
        begin
          a := Pop;
          b := Pop;
          a := a + b;
          Push (a);
        end;
    10 : // -
      if (StackLen >= 2) then
        begin
          b := Pop;
          a := Pop;
          a := a - b;
          Push (a);
        end;
    11 : // /
      if (StackLen >= 2) then
        begin
          b := Pop;
          a := Pop;
          if (b = 0) then
            Error := 'Not A Number'
          else
            a := a / b;
          Push (a);
        end;
    16 : // x^2
      if (StackLen >= 1) then
        begin
          a := Pop;
          a := a * a;
          Push (a);
        end;
    17 : // x^(1/2)
      if (StackLen >= 1) then
        begin
          a := Pop;
          if (a < 0) then
            Error := 'Imaginary Number'
          else
            a := sqrt (a);
          Push (a);
        end;
    18 : // ln(x)
      if (StackLen >= 1) then
        begin
          a := Pop;
          if (a <= 0) then
            Error := 'Logarithm undefined for x < 0'
          else
            a := ln (a);
          Push (a);
        end;
    19 : // log10
      if (StackLen >= 1) then
        begin
          a := Pop;
          if (a <= 0) then
            Error := 'Logarithm undefined for x < 0'
          else
            a := ln (a) / ln (10);
          Push (a);
        end;
    20 : // y^x
      if (StackLen >= 1) then
        begin
          a := Pop;
          b := Pop;
          a := exp (ln (b) * a);
          Push (a);
        end;
    25 : // Dup
      begin
        a := Pop;
        Push (a);
        Push (a);
      end;
    26 : // Swap
      if (StackLen >= 2) then
        begin
          a := Pop;
          b := Pop;
          Push (a);
          Push (b);
        end;
    27 : // Drop
      if (StackLen >= 1) then
        begin
          a := Pop; // a is a scratch variable, and is discarded at the
        end;        // end of the procedure
    28 : // 1/x
      if (StackLen >= 1) then
        begin
          a := Pop;
          if (a = 0) then
            Error := 'Not A Number'
          else begin
            b := 1 / a;
            Push (b)
          end;
        end;
  end;

  UpdateStackDisplay;
  if (Error <> '') then begin
    txtEntry.Text := Error;
    txtEntry.SetFocus
  end else begin
    txtEntry.Text := '';
    FocusEntry;
  end;
end;

procedure TfrmCalculator.btnOperatorClick(Sender: TObject);
begin
  if (tButton (Sender).Tag = 3) then begin
    inc (angles);
    if (angles > 2) then
      angles := 0;
    case angles of
      0 : TButton (Sender).Caption := 'deg';
      1 : TButton (Sender).Caption := 'rad';
      2 : TButton (Sender).Caption := 'gra';
    end;
  end else
    btnOperation (tButton (Sender).Tag);
end;


procedure TfrmCalculator.Push(Value: Double);
begin
  SetLength(t_stack, Length(t_stack) + 1);
  t_stack[High(t_stack)] := Value;
  UpdateStackDisplay;
  FocusEntry;
end;

function TfrmCalculator.Pop: Double;
begin
  if Length(t_stack) > 0 then begin
    Result := t_stack[High(t_stack)];
    SetLength(t_stack, Length(t_stack) - 1);
    UpdateStackDisplay;
    FocusEntry;
  end;
end;

procedure TfrmCalculator.UpdateStackDisplay;
var
  i: Integer;
begin
  lstStack.Clear;
  for i := 0 to High(t_stack) do
    lstStack.Items.Add(FloatToStr(t_stack[i]));
  if lstStack.Count > 0 then
    lstStack.ItemIndex := lstStack.Count - 1;
end;

procedure TfrmCalculator.FocusEntry;
begin
  txtEntry.SetFocus;
  txtEntry.SelStart := Length(txtEntry.Text);  // move caret to end
  txtEntry.SelLength := 0;                     // remove selection
end;

end.

