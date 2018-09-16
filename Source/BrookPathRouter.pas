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

unit BrookPathRouter;

{$I Brook.inc}

interface

uses
  SysUtils,
  Classes,
  Platform,
  Marshalling,
{$IFDEF VER3_0_0}
  FPC300Fixes,
{$ENDIF}
  libsagui,
  BrookUtils,
  BrookHandledClasses,
  BrookStringMap;

resourcestring
  SBrookInactiveRouter = 'Inactive router.';
  SBrookNoRoutesDefined = 'No routes defined.';
  SBrookEmptyRoutePattern = '%s: pattern cannot be empty.';
  SBrookRouteAlreadyExists = '%s: pattern ''%s'' already exists in ''%s''.';

type
  TBrookCustomPathRoute = class;

  TBrookCustomPathRouteClass = class of TBrookCustomPathRoute;

  TBrookPathRoutes = class;

  TBrookCustomPathRouter = class;

  TBrookPathRouteMatchEvent = procedure(ARoute: TBrookCustomPathRoute) of object;

  EBrookRoute = class(Exception);

  EBrookRoutes = class(Exception);

  TBrookCustomPathRoute = class(TBrookHandleCollectionItem)
  private
    FRoutes: TBrookPathRoutes;
    FVariables: TBrookStringMap;
    FHandle: Psg_route;
    Fvars: Psg_strmap;
    FPattern: string;
    FOnMath: TBrookPathRouteMatchEvent;
    function GetSegments: TArray<string>; inline;
    function GetPattern: string;
    function GetPath: string;
    function GetRawPattern: string;
    function GetVariables: TBrookStringMap;
    function GetRegexHandle: Pointer;
    function GetUserData: Pointer;
    procedure SetPattern(const AValue: string);
  protected
    class procedure DoRouteCallback(Acls: Pcvoid;
      Aroute: Psg_route); cdecl; static;
    class function DoGetSegmentsCallback(Acls: Pcvoid;
      const Asegment: Pcchar): cint; cdecl; static;
    class function DoGetVarsCallback(Acls: Pcvoid;
      const Aname: Pcchar; const Aval: Pcchar): cint; cdecl; static;
    function GetHandle: Pointer; override;
    procedure DoMatch(ARoute: TBrookCustomPathRoute); virtual;
    property Routes: TBrookPathRoutes read FRoutes;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure Validate; inline;
    property RegexHandle: Pointer read GetRegexHandle;
    property Segments: TArray<string> read GetSegments;
    property Variables: TBrookStringMap read GetVariables;
    property Pattern: string read GetPattern write SetPattern;
    property RawPattern: string read GetRawPattern;
    property Path: string read GetPath;
    property UserData: Pointer read GetUserData;
    property OnMath: TBrookPathRouteMatchEvent read FOnMath write FOnMath;
  end;

  TBrookPathRoute = class(TBrookCustomPathRoute)
  published
    property Pattern;
    property Path;
    property OnMath;
  end;

  TBrookPathRoutesEnumerator = class(TCollectionEnumerator)
  public
    function GetCurrent: TBrookCustomPathRoute;
    property Current: TBrookCustomPathRoute read GetCurrent;
  end;

  TBrookPathRoutes = class(TBrookHandleOwnedCollection)
  private
    FHandle: Psg_route;
    function GetItem(AIndex: Integer): TBrookCustomPathRoute;
    procedure SetItem(AIndex: Integer; AValue: TBrookCustomPathRoute);
    procedure InternalAdd(ARoute: TBrookCustomPathRoute);
  protected
    function GetHandle: Pointer; override;
    class function GetRoutePattern(
      ARoute: TBrookCustomPathRoute): string; virtual;
    class function GetPathLabel: string; virtual;
    procedure Prepare; virtual;
  public
    constructor Create(AOwner: TPersistent); virtual;
    class function GetRouterClass: TBrookCustomPathRouteClass; virtual;
    function GetEnumerator: TBrookPathRoutesEnumerator;
    procedure Assign(ASource: TPersistent); override;
    function NewPattern: string; virtual;
    function Add: TBrookCustomPathRoute; virtual;
    function First: TBrookCustomPathRoute; virtual;
    function Last: TBrookCustomPathRoute; virtual;
    function IndexOf(const APattern: string): Integer; virtual;
    function Find(const APattern: string): TBrookCustomPathRoute; virtual;
    function Remove(const APattern: string): Boolean; virtual;
    procedure Clear; virtual;
    property Items[AIndex: Integer]: TBrookCustomPathRoute read GetItem
      write SetItem; default;
  end;

  TBrookCustomPathRouter = class(TBrookHandledComponent)
  private
    FRoutes: TBrookPathRoutes;
    FHandle: Psg_router;
    FActive: Boolean;
    FStreamedActive: Boolean;
    function IsActive: Boolean;
    procedure SetActive(AValue: Boolean);
    procedure SetRoutes(AValue: TBrookPathRoutes);
  protected
    function CreateRoutes: TBrookPathRoutes; virtual;
    procedure Loaded; override;
    function GetHandle: Pointer; override;
    procedure DoOpen; virtual;
    procedure DoClose; virtual;
    procedure CheckActive; inline;
    procedure CheckItems; inline;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    function Route(const APath: string; AUserData: Pointer): Boolean; virtual;
    property Active: Boolean read FActive write SetActive stored IsActive;
    property Routes: TBrookPathRoutes read FRoutes write SetRoutes;
  end;

  TBrookPathRouter = class(TBrookCustomPathRouter)
  published
    property Active;
    property Routes;
  end;

implementation

{ TBrookCustomPathRoute }

constructor TBrookCustomPathRoute.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FVariables := TBrookStringMap.Create(@Fvars);
  if Assigned(ACollection) and (ACollection is TBrookPathRoutes) then
  begin
    FRoutes := ACollection as TBrookPathRoutes;
    FPattern := FRoutes.NewPattern;
  end
  else
    SetPattern('/');
end;

destructor TBrookCustomPathRoute.Destroy;
begin
  FVariables.ClearOnDestroy := False;
  FVariables.Free;
  inherited Destroy;
end;

procedure TBrookCustomPathRoute.Assign(ASource: TPersistent);
begin
  if ASource is TBrookCustomPathRoute then
    FPattern := (ASource as TBrookCustomPathRoute).FPattern
  else
    inherited Assign(ASource);
end;

class procedure TBrookCustomPathRoute.DoRouteCallback(Acls: Pcvoid;
  Aroute: Psg_route);
var
  RT: TBrookCustomPathRoute;
begin
  RT := Acls;
  RT.FHandle := Aroute;
  RT.DoMatch(RT);
end;

class function TBrookCustomPathRoute.DoGetSegmentsCallback(Acls: Pcvoid;
  const Asegment: Pcchar): cint;
var
  VSegments: ^TArray<string>;
begin
  VSegments := Acls;
{$IFDEF VER3_0}
  SetLength(VSegments^, Succ(Length(VSegments^)));
  VSegments^[High(VSegments^)] := TMarshal.ToString(Asegment);
{$ELSE}
  VSegments^ := VSegments^ + [TMarshal.ToString(Asegment)];
{$ENDIF}
  Result := 0;
end;

class function TBrookCustomPathRoute.DoGetVarsCallback(Acls: Pcvoid;
  const Aname: Pcchar; const Aval: Pcchar): cint;
begin
  TBrookStringMap(Acls).Add(TMarshal.ToString(Aname), TMarshal.ToString(Aval));
  Result := 0;
end;

function TBrookCustomPathRoute.GetHandle: Pointer;
begin
  Result := FHandle;
end;

function TBrookCustomPathRoute.GetSegments: TArray<string>;
begin
  Result := nil;
  if not Assigned(FHandle) then
    Exit(nil);
  SgLib.Check;
  SgLib.CheckLastError(sg_route_get_segments(FHandle,
{$IFNDEF VER3_0}@{$ENDIF}DoGetSegmentsCallback, @Result));
end;

function TBrookCustomPathRoute.GetVariables: TBrookStringMap;
begin
  Result := FVariables;
  FVariables.Clear;
  if not Assigned(FHandle) then
    Exit;
  SgLib.CheckLastError(sg_route_get_vars(FHandle,
{$IFNDEF VER3_0}@{$ENDIF}DoGetVarsCallback, FVariables));
end;

function TBrookCustomPathRoute.GetRegexHandle: Pointer;
begin
  if not Assigned(FHandle) then
    Exit(nil);
  SgLib.Check;
  Result := sg_route_handle(FHandle);
end;

function TBrookCustomPathRoute.GetRawPattern: string;
begin
  if not Assigned(FHandle) then
  begin
    if FPattern.IsEmpty then
      Exit('');
    Exit(Concat('^', FPattern, '$'));
  end;
  SgLib.Check;
  Result := TMarshal.ToString(sg_route_rawpattern(FHandle));
end;

function TBrookCustomPathRoute.GetPattern: string;
var
  P: Pcchar;
begin
  if not Assigned(FHandle) then
    Exit(FPattern);
  SgLib.Check;
  P := sg_route_pattern(FHandle);
  try
    Result := TMarshal.ToString(P);
  finally
    sg_free(P);
  end;
end;

function TBrookCustomPathRoute.GetPath: string;
begin
  if not Assigned(FHandle) then
    Exit('');
  SgLib.Check;
  Result := TMarshal.ToString(sg_route_path(FHandle));
end;

function TBrookCustomPathRoute.GetUserData: Pointer;
begin
  if not Assigned(FHandle) then
    Exit(nil);
  SgLib.Check;
  Result := sg_route_user_data(FHandle);
end;

procedure TBrookCustomPathRoute.DoMatch(ARoute: TBrookCustomPathRoute);
begin
  if Assigned(FOnMath) then
    FOnMath(ARoute);
end;

procedure TBrookCustomPathRoute.SetPattern(const AValue: string);
var
  RT: TBrookCustomPathRoute;
  NP: string;
begin
  if (AValue = FPattern) or (not Assigned(FRoutes)) then
    Exit;
  NP := BrookFixPath(AValue);
  RT := FRoutes.Find(NP);
  if Assigned(RT) and (RT <> Self) then
    raise EBrookRoute.CreateResFmt(@SBrookRouteAlreadyExists,
      [GetNamePath, NP, RT.GetNamePath]);
  FPattern := NP;
  if Assigned(FRoutes.FHandle) then
  begin
    SgLib.Check;
    FRoutes.InternalAdd(Self);
  end;
end;

procedure TBrookCustomPathRoute.Validate;
begin
  if FPattern.IsEmpty then
    raise EBrookRoute.CreateResFmt(@SBrookEmptyRoutePattern, [GetNamePath]);
end;

{ TBrookPathRoutesEnumerator }

function TBrookPathRoutesEnumerator.GetCurrent: TBrookCustomPathRoute;
begin
  Result := TBrookCustomPathRoute(inherited GetCurrent);
end;

{ TBrookPathRoutes }

constructor TBrookPathRoutes.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, GetRouterClass);
end;

class function TBrookPathRoutes.GetRouterClass: TBrookCustomPathRouteClass;
begin
  Result := TBrookPathRoute;
end;

class function TBrookPathRoutes.GetRoutePattern(
  ARoute: TBrookCustomPathRoute): string;
begin
  Result := ARoute.FPattern;
end;

class function TBrookPathRoutes.GetPathLabel: string;
begin
  Result := '/path';
end;

function TBrookPathRoutes.GetHandle: Pointer;
begin
  Result := FHandle;
end;

function TBrookPathRoutes.GetEnumerator: TBrookPathRoutesEnumerator;
begin
  Result := TBrookPathRoutesEnumerator.Create(Self);
end;

procedure TBrookPathRoutes.Assign(ASource: TPersistent);
var
  R: TBrookCustomPathRoute;
begin
  if ASource is TBrookPathRoutes then
  begin
    Clear;
    for R in (ASource as TBrookPathRoutes) do
      Add.Assign(R);
  end
  else
    inherited Assign(ASource);
end;

procedure TBrookPathRoutes.InternalAdd(ARoute: TBrookCustomPathRoute);
var
  M: TMarshaller;
  P: array[0..SG_ERR_SIZE-1] of cchar;
  H: Psg_route;
  S: string;
  R: cint;
begin
  P[0] := 0;
  R := sg_routes_add2(@FHandle, @H, M.ToCNullableString(GetRoutePattern(ARoute)),
    @P[0], SG_ERR_SIZE, {$IFNDEF VER3_0}@{$ENDIF}ARoute.DoRouteCallback, ARoute);
  if R = 0 then
    Exit;
  if R = EALREADY then
    raise EBrookRoutes.CreateResFmt(@SBrookRouteAlreadyExists,
      [ARoute.GetNamePath, ARoute.Pattern]);
  S := TMarshal.ToString(@P[0]).TrimRight;
  if S.IsEmpty then
    S := BrookStrError(R);
  raise EBrookRoutes.Create(S);
end;

function TBrookPathRoutes.NewPattern: string;
var
  I: Integer;
begin
  I := 1;
  repeat
    Result := Concat(GetPathLabel, I.ToString);
    Inc(I);
  until IndexOf(Result) < 0;
end;

procedure TBrookPathRoutes.Prepare;
var
  RT: TBrookCustomPathRoute;
begin
  if Assigned(FHandle) or (Count = 0) then
    Exit;
  SgLib.Check;
  SgLib.CheckLastError(sg_routes_cleanup(@FHandle));
  for RT in Self do
  begin
    RT.Validate;
    InternalAdd(RT);
  end;
end;

function TBrookPathRoutes.Add: TBrookCustomPathRoute;
begin
  Result := TBrookPathRoute(inherited Add);
end;

function TBrookPathRoutes.First: TBrookCustomPathRoute;
begin
  if Count = 0 then
    Exit(nil);
  Result := GetItem(0);
end;

function TBrookPathRoutes.Last: TBrookCustomPathRoute;
begin
  if Count = 0 then
    Exit(nil);
  Result := GetItem(Pred(Count));
end;

function TBrookPathRoutes.IndexOf(const APattern: string): Integer;
begin
  for Result := 0 to Pred(Count) do
    if SameText(GetItem(Result).Pattern, APattern) then
      Exit;
  Result := -1;
end;

function TBrookPathRoutes.Find(const APattern: string): TBrookCustomPathRoute;
var
  RT: TBrookCustomPathRoute;
begin
  for RT in Self do
    if SameText(RT.Pattern, APattern) then
      Exit(RT);
  Result := nil;
end;

function TBrookPathRoutes.Remove(const APattern: string): Boolean;
var
  M: TMarshaller;
  I: Integer;
begin
  I := IndexOf(APattern);
  Result := I > -1;
  if Result then
  begin
    if Assigned(FHandle) then
      SgLib.CheckLastError(sg_routes_rm(@FHandle, M.ToCString(APattern)));
    inherited Delete(I);
  end;
end;

function TBrookPathRoutes.GetItem(AIndex: Integer): TBrookCustomPathRoute;
begin
  Result := TBrookCustomPathRoute(inherited GetItem(AIndex));
end;

procedure TBrookPathRoutes.SetItem(AIndex: Integer;
  AValue: TBrookCustomPathRoute);
begin
  inherited SetItem(AIndex, AValue);
end;

procedure TBrookPathRoutes.Clear;
begin
  inherited Clear;
  SgLib.Check;
  SgLib.CheckLastError(sg_routes_cleanup(@FHandle));
end;

{ TBrookCustomPathRouter }

constructor TBrookCustomPathRouter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRoutes := CreateRoutes;
end;

destructor TBrookCustomPathRouter.Destroy;
begin
  FRoutes.Free;
  try
    SetActive(False);
  finally
    inherited Destroy;
  end;
end;

function TBrookCustomPathRouter.CreateRoutes: TBrookPathRoutes;
begin
  Result := TBrookPathRoutes.Create(Self);
end;

procedure TBrookCustomPathRouter.CheckActive;
begin
  if (not (csLoading in ComponentState)) and (not Active) then
    raise EInvalidOpException.CreateRes(@SBrookInactiveRouter);
end;

procedure TBrookCustomPathRouter.CheckItems;
begin
  if FRoutes.Count = 0 then
    raise EBrookRoutes.CreateRes(@SBrookNoRoutesDefined);
end;

procedure TBrookCustomPathRouter.Loaded;
begin
  inherited Loaded;
  try
    if FStreamedActive then
      SetActive(True);
  except
    if csDesigning in ComponentState then
    begin
      if Assigned(ApplicationHandleException) then
        ApplicationHandleException(ExceptObject)
      else
        ShowException(ExceptObject, ExceptAddr);
    end
    else
      raise;
  end;
end;

function TBrookCustomPathRouter.GetHandle: Pointer;
begin
  Result := FHandle;
end;

procedure TBrookCustomPathRouter.SetRoutes(AValue: TBrookPathRoutes);
begin
  if AValue = FRoutes then
    Exit;
  if Assigned(AValue) then
    FRoutes.Assign(AValue)
  else
    FRoutes.Clear;
end;

function TBrookCustomPathRouter.IsActive: Boolean;
begin
  Result := FActive;
end;

procedure TBrookCustomPathRouter.SetActive(AValue: Boolean);
begin
  if AValue = FActive then
    Exit;
  if csDesigning in ComponentState then
  begin
    if not (csLoading in ComponentState) then
      SgLib.Check;
    FActive := AValue;
  end
  else
    if AValue then
    begin
      if csReading in ComponentState then
        FStreamedActive := True
      else
        DoOpen;
    end
    else
      DoClose;
end;

procedure TBrookCustomPathRouter.DoOpen;
begin
  if Assigned(FHandle) then
    Exit;
  FRoutes.Prepare;
  SgLib.Check;
  FHandle := sg_router_new(FRoutes.Handle);
  FActive := Assigned(FHandle);
end;

procedure TBrookCustomPathRouter.DoClose;
begin
  if not Assigned(FHandle) then
    Exit;
  SgLib.Check;
  sg_router_free(FHandle);
  FHandle := nil;
  FActive := False;
end;

procedure TBrookCustomPathRouter.Open;
begin
  SetActive(True);
end;

procedure TBrookCustomPathRouter.Close;
begin
  SetActive(False);
end;

function TBrookCustomPathRouter.Route(const APath: string;
  AUserData: Pointer): Boolean;
var
  M: TMarshaller;
  R: cint;
begin
  CheckItems;
  CheckActive;
  SgLib.Check;
  R := sg_router_dispatch(FHandle, M.ToCNullableString(BrookFixPath(APath)),
    AUserData);
  Result := R = 0;
  if (not Result) and (R <> ENOENT) then
    SgLib.CheckLastError(R);
end;

end.
