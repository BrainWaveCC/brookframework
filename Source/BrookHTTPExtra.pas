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

unit BrookHTTPExtra;

{$I Brook.inc}

interface

const
  BROOK_BLOCK_SIZE = {$IFDEF CPUARM}1024{~1Kb}{$ELSE}4096{~4kB}{$ENDIF};
  BROOK_POST_BUFFER_SIZE = {$IFDEF CPUARM}1024{~1Kb}{$ELSE}4096{~4kB}{$ENDIF};
  BROOK_PAYLOAD_LIMIT = {$IFDEF CPUARM}1048576{~1MB}{$ELSE}4194304{~4MB}{$ENDIF};
  BROOK_UPLOADS_LIMIT = {$IFDEF CPUARM}16777216{~16MB}{$ELSE}67108864{~64MB}{$ENDIF};
  BROOK_CONTENT_TYPE = 'text/plain; charset=utf-8';

implementation

end.
