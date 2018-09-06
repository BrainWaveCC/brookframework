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

unit BrookHTTPAuthentication;

{$I Brook.inc}

interface

uses
  SysUtils,
  Marshalling,
  libsagui,
  BrookHandledClasses;

type
  TBrookCustomHTTPCredentials = class(TBrookHandledPersistent)
  private
    FUserName: string;
    FPassword: string;
    FHandle: Psg_httpauth;
    function GetRealm: string;
    procedure SetRealm(const AValue: string);
  protected
    function GetHandle: Pointer; override;
  public
    constructor Create(AHandle: Pointer); virtual;
    property Realm: string read GetRealm write SetRealm;
    property UserName: string read FUserName;
    property Password: string read FPassword;
  end;

  TBrookHTTPCredentials = class(TBrookCustomHTTPCredentials)
  published
    property Realm;
    property UserName;
    property Password;
  end;

  TBrookHTTPAuthentication = class(TBrookHandledPersistent)
  private
    FCredentials: TBrookCustomHTTPCredentials;
    FHandle: Psg_httpauth;
  protected
    function GetHandle: Pointer; override;
    function CreateCredentials(
      AHandle: Pointer): TBrookCustomHTTPCredentials; virtual;
  public
    constructor Create(AHandle: Pointer); virtual;
    property Credentials: TBrookCustomHTTPCredentials read FCredentials;
    procedure Deny(const AJustification, AContentType: string); overload; virtual;
    procedure Deny(const AFmt: string; const AArgs: array of const;
      const AContentType: string); overload; virtual;
    procedure Cancel; virtual;
  end;

implementation

{ TBrookCustomHTTPCredentials }

constructor TBrookCustomHTTPCredentials.Create(AHandle: Pointer);
begin
  inherited Create;
  FHandle := AHandle;
  FUserName := TMarshal.ToString(sg_httpauth_usr(AHandle));
  FPassword := TMarshal.ToString(sg_httpauth_pwd(AHandle));
end;

function TBrookCustomHTTPCredentials.GetHandle: Pointer;
begin
  Result := FHandle;
end;

function TBrookCustomHTTPCredentials.GetRealm: string;
begin
  SgCheckLibrary;
  Result := TMarshal.ToString(sg_httpauth_realm(FHandle));
end;

procedure TBrookCustomHTTPCredentials.SetRealm(const AValue: string);
var
  M: TMarshaller;
begin
  SgCheckLibrary;
  SgCheckLastError(sg_httpauth_set_realm(FHandle, M.ToCString(AValue)));
end;

{ TBrookHTTPAuthentication }

constructor TBrookHTTPAuthentication.Create(AHandle: Pointer);
begin
  inherited Create;
  FHandle := AHandle;
  FCredentials := CreateCredentials(FHandle);
end;

function TBrookHTTPAuthentication.CreateCredentials(
  AHandle: Pointer): TBrookCustomHTTPCredentials;
begin
  Result := TBrookHTTPCredentials.Create(AHandle);
end;

function TBrookHTTPAuthentication.GetHandle: Pointer;
begin
  Result := FHandle;
end;

procedure TBrookHTTPAuthentication.Deny(const AJustification,
  AContentType: string);
var
  M: TMarshaller;
begin
  SgCheckLibrary;
  SgCheckLastError(sg_httpauth_deny(FHandle, M.ToCString(AJustification),
    M.ToCString(AContentType)));
end;

procedure TBrookHTTPAuthentication.Deny(const AFmt: string;
  const AArgs: array of const; const AContentType: string);
begin
  Deny(Format(AFmt, AArgs), AContentType);
end;

procedure TBrookHTTPAuthentication.Cancel;
begin
  SgCheckLibrary;
  SgCheckLastError(sg_httpauth_cancel(FHandle));
end;

end.
