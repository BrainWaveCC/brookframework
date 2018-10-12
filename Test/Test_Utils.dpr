(*   _                     _
 *  | |__  _ __ ___   ___ | | __
 *  | '_ \| '__/ _ \ / _ \| |/ /
 *  | |_) | | | (_) | (_) |   <
 *  |_.__/|_|  \___/ \___/|_|\_\
 *
 *  –– microframework which helps to develop web Pascal applications.
 *
 * Copyright (c) 2012-2018 Silvio Clecio <silvioprog@gmail.com>
 *
 * This file is part of Brook framework.
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

program Test_Utils;

{$I Tests.inc}

uses
  SysUtils,
  BrookUtils;

procedure Test_Version;
begin
  Assert(BrookVersion > 0);
  ASSERT(BrookVersionStr <> '');
end;

procedure Test_Memory;
var
  Vbuf: Pointer;
begin
  Vbuf := BrookAlloc(10);
  Assert(Assigned(Vbuf));
  BrookFree(Vbuf);
end;

begin
  Test_Version;
  Test_Memory;
end.
