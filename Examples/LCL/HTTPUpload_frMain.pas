(*   _                     _
 *  | |__  _ __ ___   ___ | | __
 *  | '_ \| '__/ _ \ / _ \| |/ /
 *  | |_) | | | (_) | (_) |   <
 *  |_.__/|_|  \___/ \___/|_|\_\
 *
 *  –– an ideal Pascal microframework to develop cross-platform HTTP servers.
 *
 * Copyright (c) 2012-2018 Silvio Clecio <silvioprog@gmail.com>
 *
 * This file is part of Brook library.
 *
 * Brook framework is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Brook framework is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Brook framework.  If not, see <http://www.gnu.org/licenses/>.
 *)

unit HTTPUpload_frMain;

{$MODE DELPHI}
{$PUSH}{$WARN 5024 OFF}

interface

uses
  SysUtils,
  Classes,
  StdCtrls,
  ActnList,
  Graphics,
  Spin,
  Dialogs,
  Forms,
  LCLIntf,
{$IFDEF VER3_0_0}
  FPC300Fixes,
{$ENDIF}
  BrookUtils,
  BrookHTTPUploads,
  BrookHTTPRequest,
  BrookHTTPResponse,
  BrookHTTPServer;

type
  TfrMain = class(TForm)
    acStart: TAction;
    acStop: TAction;
    alMain: TActionList;
    BrookHTTPServer1: TBrookHTTPServer;
    btStart: TButton;
    btStop: TButton;
    edPort: TSpinEdit;
    lbLink: TLabel;
    lbPort: TLabel;
    procedure acStartExecute(Sender: TObject);
    procedure acStopExecute(Sender: TObject);
    procedure alMainUpdate(AAction: TBasicAction; var Handled: Boolean);
    procedure BrookHTTPServer1Error(ASender: TObject; AException: Exception);
    procedure BrookHTTPServer1Request(ASender: TObject;
      ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
    procedure BrookHTTPServer1RequestError(ASender: TObject;
      ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
      AException: Exception);
    procedure edPortChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbLinkClick(Sender: TObject);
    procedure lbLinkMouseEnter(Sender: TObject);
    procedure lbLinkMouseLeave(Sender: TObject);
  protected
    procedure DoError(AData: PtrInt);
  public
    procedure UpdateLink;
  end;

const
  PAGE_FORM = Concat(
    '<html>',
    '<body>',
    '<form action="" method="post" enctype="multipart/form-data">',
    '<fieldset>',
    '<legend>Choose the files:</legend>',
    'File 1: <input type="file" name="file1"/><br>',
    'File 2: <input type="file" name="file2"/><br>',
    '<input type="submit"/>',
    '</fieldset>',
    '</form>',
    '</body>',
    '</html>'
  );
  PAGE_DONE = Concat(
    '<html>',
    '<head>',
    '<title>Uploads</title>',
    '</head>',
    '<body>',
    '<strong>Uploaded files:</strong><br>',
    '%s',
    '</body>',
    '</html>'
  );
  CONTENT_TYPE = 'text/html; charset=utf-8';

var
  frMain: TfrMain;

implementation

{$R *.lfm}

procedure TfrMain.FormCreate(Sender: TObject);
begin
  if BrookHTTPServer1.UploadsDir.IsEmpty then
    BrookHTTPServer1.UploadsDir := BrookTmpDir;
end;

procedure TfrMain.DoError(AData: PtrInt);
var
  S: PString absolute AData;
begin
  try
    MessageDlg(S^, mtError, [mbOK], 0);
  finally
    DisposeStr(S);
  end;
end;

procedure TfrMain.UpdateLink;
begin
  lbLink.Caption := Concat('http://localhost:', edPort.Value.ToString);
end;

procedure TfrMain.acStartExecute(Sender: TObject);
begin
  BrookHTTPServer1.Port := edPort.Value;
  BrookHTTPServer1.Open;
  if edPort.Value = 0 then
    edPort.Value := BrookHTTPServer1.Port;
  UpdateLink;
end;

procedure TfrMain.acStopExecute(Sender: TObject);
begin
  BrookHTTPServer1.Close;
end;

procedure TfrMain.edPortChange(Sender: TObject);
begin
  UpdateLink;
end;

procedure TfrMain.lbLinkMouseEnter(Sender: TObject);
begin
  lbLink.Font.Style := lbLink.Font.Style + [fsUnderline];
end;

procedure TfrMain.lbLinkMouseLeave(Sender: TObject);
begin
  lbLink.Font.Style := lbLink.Font.Style - [fsUnderline];
end;

procedure TfrMain.lbLinkClick(Sender: TObject);
begin
  OpenURL(lbLink.Caption);
end;

procedure TfrMain.alMainUpdate(AAction: TBasicAction; var Handled: Boolean);
begin
  acStart.Enabled := not BrookHTTPServer1.Active;
  acStop.Enabled := not acStart.Enabled;
  edPort.Enabled := acStart.Enabled;
  lbLink.Enabled := not acStart.Enabled;
end;

procedure TfrMain.BrookHTTPServer1Request(ASender: TObject;
  ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse);
var
  VUpload: TBrookHTTPUpload;
  VFile, VList, VError: string;
begin
  if ARequest.IsUploading then
  begin
    VList := '<ol>';
    for VUpload in ARequest.Uploads do
      if VUpload.Save(False, VError) then
        VList := Concat(VList, '<li><a href="?file=', VUpload.Name, '">',
          VUpload.Name, '</a></li>')
      else
        VList := Concat(VList, '<li><font color="red">', VUpload.Name,
          ' - failed - ', VError, '</font></li>');
    VList := Concat(VList, '</ol>');
    AResponse.Send(PAGE_DONE, [VList], CONTENT_TYPE, 200);
  end
  else
  begin
    if ARequest.Params.TryValue('file', VFile) then
      AResponse.SendFile(Concat(BrookHTTPServer1.UploadsDir, PathDelim, VFile))
    else
      AResponse.Send(PAGE_FORM, CONTENT_TYPE, 200);
  end;
end;

procedure TfrMain.BrookHTTPServer1RequestError(ASender: TObject;
  ARequest: TBrookHTTPRequest; AResponse: TBrookHTTPResponse;
  AException: Exception);
begin
  AResponse.Send(
    '<html><head><title>Error</title></head><body><font color="red">%s</font></body></html>',
    [AException.Message], 'text/html; charset=utf-8', 500);
end;

{$PUSH}{$WARN 4055 OFF}
procedure TfrMain.BrookHTTPServer1Error(ASender: TObject;
  AException: Exception);
begin
  Application.QueueAsyncCall(DoError, PtrInt(NewStr(AException.Message)));
end;
{$POP}

{$POP}

end.
