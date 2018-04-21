(*    _____   _____    _____   _____   _   __
 *   |  _  \ |  _  \  /  _  \ /  _  \ | | / /
 *   | |_) | | |_) |  | | | | | | | | | |/ /
 *   |  _ <  |  _ <   | | | | | | | | |   (
 *   | |_) | | | \ \  | |_| | | |_| | | |\ \
 *   |_____/ |_|  \_\ \_____/ \_____/ |_| \_\
 *
 *   �� a small library which helps you write quickly REST APIs.
 *
 * Copyright (c) 2012-2018 Silvio Clecio <silvioprog@gmail.com>
 *
 * This file is part of Brook library.
 *
 * Brook library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Brook library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Brook library.  If not, see <http://www.gnu.org/licenses/>.
 *)

unit StringMap_frMain;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  FMX.Types,
  FMX.Controls,
  FMX.StdCtrls,
  FMX.ScrollBox,
  FMX.Forms,
  FMX.Grid,
  FMX.Grid.Style,
  FMX.Controls.Presentation,
  BrookStringMap;

type
  TfrMain = class(TForm)
    pnTop: TPanel;
    btAdd: TButton;
    btRemove: TButton;
    btClear: TButton;
    grMap: TGrid;
    coKey: TStringColumn;
    coValue: TStringColumn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btAddClick(Sender: TObject);
    procedure btRemoveClick(Sender: TObject);
    procedure btClearClick(Sender: TObject);
    procedure grMapGetValue(Sender: TObject; const ACol, ARow: Integer;
      var AValue: TValue);
  private
    FMap: TBrookStringMap;
    FMapHandle: Pointer;
    FList: TStrings;
    procedure DoMapChange(ASender: TObject;
      AOperation: TBrookStringMapOperation);
  end;

var
  frMain: TfrMain;

implementation

{$R *.fmx}

procedure TfrMain.FormCreate(Sender: TObject);
begin
  FMap := TBrookStringMap.Create(@FMapHandle);
  FList := TStringList.Create;
  FMap.OnChange := DoMapChange;
end;

procedure TfrMain.FormDestroy(Sender: TObject);
begin
  FMap.Free;
  FList.Free;
end;

procedure TfrMain.btAddClick(Sender: TObject);
var
  S: string;
begin
  S := Succ(FMap.Count).ToString;
  FMap.Add(Concat('Name', S), Concat('Value', S));
end;

procedure TfrMain.btRemoveClick(Sender: TObject);
begin
  FMap.Remove(Concat('Name', FMap.Count.ToString));
end;

procedure TfrMain.btClearClick(Sender: TObject);
begin
  FMap.Clear;
end;

procedure TfrMain.DoMapChange(ASender: TObject;
  AOperation: TBrookStringMapOperation);
var
  P: TBrookStringPair;
begin
  grMap.RowCount := FMap.Count;
  FList.Clear;
  for P in FMap do
    FList.AddPair(P.Name, P.Value);
  btRemove.Enabled := FMap.Count > 0;
  btClear.Enabled := btRemove.Enabled;
end;

procedure TfrMain.grMapGetValue(Sender: TObject; const ACol, ARow: Integer;
  var AValue: TValue);
begin
  if FList.Count = 0 then
    AValue := nil
  else
  begin
    if grMap.Columns[ACol] = coKey then
      AValue := FList.Names[ARow]
    else if grMap.Columns[ACol] = coValue then
      AValue := FList.ValueFromIndex[ARow];
  end;
end;

end.