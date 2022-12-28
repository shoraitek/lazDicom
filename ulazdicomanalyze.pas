unit uLazDicomanalyze;
{$A-} {turn off byte alignment!!!} //Check if works in Laz
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,uLazDicomDefineTypes,dialogs;

type
 AHdr = packed record
   HdrSz : longint;
   Data_Type: array [1..10] of char;
   db_name: array [1..18] of char;
   extents: longint;                            (* 32 + 4    *)
   session_error: smallint;                (* 36 + 2    *)
   regular: char;                           (* 38 + 1    *)
   hkey_un0: char;                          (* 39 + 1    *)
   dim: array[0..7] of smallint;                       (* 0 + 16    *)
   vox_units: array[1..4] of char;                      (* 16 + 4    *)
   (*   up to 3 characters for the voxels units label; i.e. mm., um., cm.*)
   cal_units: array [1..8] of char;                      (* 20 + 4    *)
   (*   up to 7 characters for the calibration units label; i.e. HU *)
   unused1: smallint;                      (* 24 + 2    *)
   datatype: smallint ;                     (* 30 + 2    *)
   bitpix: smallint;                       (* 32 + 2    *)
   dim_un0: smallint ;                      (* 34 + 2    *)
   pixdim: array[1..8]of single;                        (* 36 + 32   *)
                        (*
                                pixdim[] specifies the voxel dimensions:
                                pixdim[1] - voxel width  {in SPM [2]}
                                pixdim[2] - voxel height  {in SPM [3]}
                                pixdim[3] - interslice distance {in SPM [4]}
                                        ..etc
                        *)
   vox_offset: single;                       (* 68 + 4    *)
   roi_scale: single;                        (* 72 + 4    *)
   funused1: single;                         (* 76 + 4    *)
   funused2: single;                         (* 80 + 4    *)
   cal_max: single;                          (* 84 + 4    *)
   cal_min: single;                          (* 88 + 4    *)
   compressed: longint;                         (* 92 + 4    *)
   verified: longint;                           (* 96 + 4    *)
   glmax, glmin: longint;                       (* 100 + 8   *)
   descrip: array[1..80] of char;                       (* 0 + 80    *)
   aux_file: array[1..24] of char;                      (* 80 + 24   *)
   orient: char;                            (* 104 + 1   *)
   // originator: array [1..10] of char;                   (* 105 + 10  *)
   originator: array [1..5] of smallint;                    (* 105 + 10  *)
   generated: array[1..10]of char;                     (* 115 + 10  *)
   scannum: array[1..10]of char; //array [1..10] of char {extended??}                       (* 125 + 10  *)
   patient_id: array [1..10] of char;                    (* 135 + 10  *)
   exp_date: array [1..10] of char;                      (* 145 + 10  *)
   exp_time: array[1..10] of char;                      (* 155 + 10  *)
   hist_un0: array [1..3] of char;                       (* 165 + 3   *)
   views: longint;                              (* 168 + 4   *)
   vols_added: longint;                         (* 172 + 4   *)
   start_field: longint;                        (* 176 + 4   *)
   field_skip: longint;                         (* 180 + 4   *)
   omax,omin: longint;                          (* 184 + 8   *)
   smax,smin:longint;                          (* 192 + 8   *)
{} end;
function OpenAnalyze (var lHdrOK,lImgOK : boolean; var lDynStr, lFileName: string; var lDicomData: DicomData): boolean;
function SaveAnalyzeHdr (lHdrName: string; lDicomData: DicomData): boolean;

implementation
procedure Swap2 (var lInt: SmallInt);
begin
 lInt := swap(lInt);
end;

function swap64r(s : double):double;
type
  swaptype = packed record
    case byte of
      0:(Word1,Word2,Word3,Word4 : word); //word is 16 bit
      1:(float:double);
  end;
  swaptypep = ^swaptype;
var
  inguy:swaptypep;
  outguy:swaptype;
begin
  inguy := @s; //assign address of s to inguy
  outguy.Word1 := swap(inguy^.Word4);
  outguy.Word2 := swap(inguy^.Word3);
  outguy.Word3 := swap(inguy^.Word2);
  outguy.Word4 := swap(inguy^.Word1);
  try
    swap64r:=outguy.float;
  except
        swap64r := 0;
        exit;
  end;{}
end;

function swap32i(var s : LongInt): Longint;
type
  swaptype = packed record
    case byte of
      0:(Word1,Word2 : word); //word is 16 bit
      1:(Long:LongInt);
  end;
  swaptypep = ^swaptype;
var
  inguy:swaptypep;
  outguy:swaptype;
begin
  inguy := @s; //assign address of s to inguy
  outguy.Word1 := swap(inguy^.Word2);
  outguy.Word2 := swap(inguy^.Word1);
  swap32i:=outguy.Long;
end;
procedure swap4r(var s : single);
type
  swaptype = packed record
    case byte of
      0:(Word1,Word2 : word); //word is 16 bit
      1:(sing:single);
  end;
  swaptypep = ^swaptype;
var
  inguy:swaptypep;
  outguy:swaptype;
begin
  inguy := @s; //assign address of s to inguy
  outguy.Word1 := swap(inguy^.Word2);
  outguy.Word2 := swap(inguy^.Word1);
  s:=outguy.sing;
end;

function fswap4r (s:single): single;
type
  swaptype = packed record
    case byte of
      0:(Word1,Word2 : word); //word is 16 bit
      1:(float:single);
  end;
  swaptypep = ^swaptype;
var
  inguy:swaptypep;
  outguy:swaptype;
begin
  inguy := @s; //assign address of s to inguy
  outguy.Word1 := swap(inguy^.Word2);
  outguy.Word2 := swap(inguy^.Word1);
  fswap4r:=outguy.float;
end;
{procedure Swap4r (var lR: single);
begin
     lR := fswap4r(lR)
end;      }
procedure swap4(var s : LongInt);
type
  swaptype = packed record
    case byte of
      0:(Word1,Word2 : word); //word is 16 bit
      1:(Long:LongInt);
  end;
  swaptypep = ^swaptype;
var
  inguy:swaptypep;
  outguy:swaptype;
begin
  inguy := @s; //assign address of s to inguy
  outguy.Word1 := swap(inguy^.Word2);
  outguy.Word2 := swap(inguy^.Word1);
  s:=outguy.Long;
end;
function fswap4 (s:longint): longint;
var l: longint;
begin
     l := s;
     swap4(l);
     fswap4 := l;
end;

function fswap8 (s:double): double;
type
  swaptype8 = packed record
    case byte of
      0:(Word1,Word2,Word3,Word4 : word); //word is 16 bit
      1:(Dbl:Double);
  end;
  swaptype8p = ^swaptype8;
var
  inguy:swaptype8p;
  outguy:swaptype8;
begin
  inguy := @s; //assign address of s to inguy
  outguy.Word1 := swap(inguy^.Word4);
  outguy.Word2 := swap(inguy^.Word3);
  outguy.Word3 := swap(inguy^.Word2);
  outguy.Word4 := swap(inguy^.Word1);
  fswap8:=outguy.Dbl;
end;

procedure SwapBytes (var lAHdr: AHdr);
var
//   l10 : array [1..10] of byte;
   lInc: integer;
begin
    with lAHdr do begin
         swap4(hdrsz);
         {for lInc := 1 to 10 do
             Data_Type[lInc] := chr(0);  for chars: no need to swap 1 byte
         for lInc := 1 to 18 do
             db_name[lInc] := chr(0);}
         swap4(extents);                            (* 32 + 4    *)
         swap2(session_error);                (* 36 + 2    *)
         {regular:=chr(0);                           (* 38 + 1    *)
         hkey_un0:=chr(0);}                          (* 39 + 1    *)
         for lInc := 0 to 7 do
             swap2(dim[lInc]);                       (* 0 + 16    *)
         {for lInc := 1 to 4 do
             vox_units[lInc] := chr(0);                      (* 16 + 4    *)
         for lInc := 1 to 4 do
             cal_units[lInc] := chr(0);}                      (* 20 + 4    *)
         swap2(unused1);                      (* 24 + 2    *)
         swap2(datatype);                     (* 30 + 2    *)
         swap2(bitpix);                       (* 32 + 2    *)
         swap2(dim_un0);                      (* 34 + 2    *)
         for lInc := 1 to 4 do
             swap4r(pixdim[linc]);                        (* 36 + 32   *)
         swap4r(vox_offset);
{roi scale = 1}
         swap4r(roi_scale);
         swap4r(funused1);                         (* 76 + 4    *)
         swap4r(funused2);                         (* 80 + 4    *)
         swap4r(cal_max);                          (* 84 + 4    *)
         swap4r(cal_min);                          (* 88 + 4    *)
         swap4(compressed);                         (* 92 + 4    *)
         swap4(verified);                           (* 96 + 4    *)
         swap4(glmax);
         swap4(glmin);                       (* 100 + 8   *)
         (*for lInc := 1 to 80 do
             gAHdr.descrip[lInc] := chr(0);{80 spaces}
         for lInc := 1 to 24 do
             gAHdr.aux_file[lInc] := chr(0);{24 spaces} *)
         orient:= chr(0);                            (* 104 + 1   *)
         //originator: array [1..10] of char;                   (* 105 + 10  *)
         for lInc := 1 to 5 do
             swap2(originator[lInc]);                    (* 105 + 10  *)
         (* for lInc := 1 to 10 do
             generated[lInc] := chr(0);                     (* 115 + 10  *)
         for lInc := 1 to 10 do
             scannum[lInc] := chr(0);{}
        // scannum := 0{fswap10(scannum)};
                                    //* 125 + 10
         for lInc := 1 to 10 do
             patient_id[lInc] := chr(0);                    (* 135 + 10  *)
         for lInc := 1 to 10 do
             exp_date[lInc] := chr(0);                    (* 135 + 10  *)
         for lInc := 1 to 10 do
             exp_time[lInc] := chr(0);                    (* 135 + 10  *)
         for lInc := 1 to 3 do
             hist_un0[lInc] := chr(0);                    (* 135 + 10  *)
         {} *)
         swap4(views);                              (* 168 + 4   *)
         swap4(vols_added);                         (* 172 + 4   *)
         swap4(start_field);                        (* 176 + 4   *)
         swap4(field_skip);                         (* 180 + 4   *)
         swap4(omax);
         swap4(omin);                          (* 184 + 8   *)
         swap4(smax);
         swap4(smin);                          (* 192 + 8   *)
    end; {with}
end;



function ParseFileName (lFilewExt:String): string;
var
   lLen,lInc: integer;
   lName: String;
begin
	lName := '';
     lLen := length(lFilewExt);
	lInc := lLen+1;
     if  lLen > 0 then
	   repeat
              dec(lInc);
        until (lFileWExt[lInc] = '.') or (lInc = 1);
     if lInc > 1 then
        for lLen := 1 to (lInc - 1) do
            lName := lName + lFileWExt[lLen]
     else
         lName := lFilewExt; //no extension
        ParseFileName := lName;
end;
function FSize (lFName: String): longint;
var SearchRec: TSearchRec;
begin
  FSize := 0;
  if not FileExists(lFName) then exit;
  FindFirst(lFName, faAnyFile, SearchRec);
  FSize := SearchRec.size;
  FindClose(SearchRec);
end;

function OpenAnalyze (var lHdrOK,lImgOK  : boolean; var lDynStr,lFileName: string; var lDicomData: DicomData): boolean;
var
  F: file;
  lFSz: LongInt;
  lHdrSz : Longint;
  gAHdr : AHdr;
begin
     result := false;
     lImgOK := false;
     lHdrOK:= false;
     lDynStr := '';
     lDICOMdata.RunLengthEncoding := false;
     lDICOMdata.JPEGlosslessCpt := false;
     lDICOMdata.JPEGlossyCpt := false;
     lDICOMdata.PlanarConfig:= 1; //only used in RGB values
     lDICOMdata.GenesisCpt := false;
     lDICOMdata.GenesisPackHdr := 0;
     lDICOMdata.SamplesPerPixel := 1;
     lDICOMdata.WindowCenter := 0;
     lDICOMdata.WindowWidth := 0;
     lDICOMdata.monochrome := 2; {most common}
     lDICOMdata.XYZmm[1] := 1;
     lDICOMdata.XYZmm[2] := 1;
     lDICOMdata.XYZmm[3] := 1;
     lDICOMdata.XYZdim[1] := 1;
     lDICOMdata.XYZdim[2] := 1;
     lDICOMdata.XYZdim[3] := 1;
     lDICOMdata.ImageStart := 0;
     lDICOMdata.Little_Endian := 1;
     if not FileExists(lFileName) then exit;
     lFSz := FSize(lFileName);
     if (lFSz) <> sizeof(gAHdr) then begin
        {CloseFile(F);}
        ShowMessage('This header file is the wrong size to be in Analyze format.'+
        ' Required: '+inttostr(sizeof(gAHdr))+'  Selected:'+inttostr(lFSz));
        exit;
     end;
     AssignFile(F, lFileName);
     FileMode := 0;  { Set file access to read only }
     Reset(F, 1);
     {$I+}
     if ioresult <> 0 then
        ShowMessage('Potential error in reading Analyze header.'+inttostr(IOResult));
     BlockRead(F, gAHdr{Buffer^}, lFSz);
     CloseFile(F);
     if (IOResult <> 0) then exit;
     FileMode := 2;
      lHdrSz := gAHdr.HdrSz;
      Swap4(lHdrSz);
      if gAHdr.HdrSz = sizeof(gAHdr) then begin
         lDicomData.little_endian := 1;
      end else if SizeOf(gAHdr) = lHdrSz then begin
         lDicomData.little_endian := 0;
             SwapBytes (gAHdr);
      end else begin
              ShowMessage('This software can not read this header file.'+
               'The header file is not in Analyze format.');
              CloseFile(F);
              exit;
      end;
      result := true;
      lImgOK := true;
      lHdrOK := true;
      lDICOMdata.XYZdim[1]  :=gAHdr.Dim[1];
      lDICOMdata.XYZdim[2] := gAHdr.Dim[2];
      lDICOMdata.XYZdim[3] := gAHdr.Dim[3];
      lDicomData.IntenScale := gAHdr.roi_scale;
      lDICOMdata.XYZmm[1] := gAHdr.pixdim[2];
      lDICOMdata.XYZmm[2] := gAHdr.pixdim[3];
      lDICOMdata.XYZmm[3] := gAHdr.pixdim[4];{}
      lDynStr := 'Analyze format'+kCR+'XYZ dim:' +inttostr(lDicomData.XYZdim[1])+'/'
      +inttostr(lDicomData.XYZdim[2])+'/'+inttostr(lDicomData.XYZdim[3])
      +kCR+'XYZ mm:'+floattostrf(lDicomData.XYZmm[1],ffFixed,8,2)+'/'
       +floattostrf(lDicomData.XYZmm[2],ffFixed,8,2)+'/'+floattostrf(lDicomData.XYZmm[3],ffFixed,8,2)+
       kCR+'Bits per pixel: '+ inttostr(gAHdr.bitpix);
      lDicomData.Allocbits_per_pixel := gAHdr.bitpix;
      lDicomData.Storedbits_per_pixel := gAHdr.bitpix;
      if gAHdr.bitpix = 24 then begin
               lDicomData.Allocbits_per_pixel := 8;
               lDicomData.Storedbits_per_pixel := 8;
               lDicomData.SamplesPerPixel := 3;
               lDicomData.PlanarConfig := 0;
      end else if gAHdr.bitpix = 32  then begin
         lImgOK := false;
         showmessage('This software can not read 32-bit Analyze images.');
         //would need a buffer for 32-bit images... changes to displayimage near 12: begin
         if gAHdr.Datatype >= 16 then begin
            lDICOMdata.Float := true;
            lDynStr := lDynStr+kCR+'Floating point data';
         end;
         lDicomData.Allocbits_per_pixel := 32;
         lDicomData.Storedbits_per_pixel := 32;
      end else if gAHdr.bitpix = 64  then begin
         lImgOK := false;
         showmessage('This software can not read 64-bit Analyze images.');
      end;

      lDICOMdata.ImageStart := round(gAHdr.vox_offset);
      lFileName :=ExtractFilePath(lFileName)+ParseFileName(ExtractFileName(lFileName))+'.img';
      (*if not fileexists(lFilename) then begin
         lImgOK := false;
         Showmessage('Unable to find the Analyze image named '+lFilename);
          exit;
      end;*)
end;

procedure ClearHdr (var lHdr: AHdr);
var lInc: byte;
begin
    with lHdr do begin
         {set to 0}
         HdrSz := sizeof(AHdr);
         for lInc := 1 to 10 do
             Data_Type[lInc] := chr(0);
         for lInc := 1 to 18 do
             db_name[lInc] := chr(0);
         extents:=0;                            (* 32 + 4    *)
         session_error:= 0;                (* 36 + 2    *)
         regular:='r'{chr(0)};                           (* 38 + 1    *)
         hkey_un0:=chr(0);
         dim[0] := 4;                          (* 39 + 1    *)
         for lInc := 1 to 7 do
             dim[lInc] := 0;                       (* 0 + 16    *)
         for lInc := 1 to 4 do
             vox_units[lInc] := chr(0);                      (* 16 + 4    *)
         for lInc := 1 to 4 do
             cal_units[lInc] := chr(0);                      (* 20 + 4    *)
         unused1:=0;                      (* 24 + 2    *)
         datatype:=0 ;                     (* 30 + 2    *)
         bitpix:=0;                       (* 32 + 2    *)
         dim_un0:=0;                      (* 34 + 2    *)
         for lInc := 1 to 4 do
             pixdim[linc]:= 2.0;                        (* 36 + 32   *)
         vox_offset:= 0.0;
         roi_scale:= 0.00392157{1.1};
         funused1:= 0.0;                         (* 76 + 4    *)
         funused2:= 0.0;                         (* 80 + 4    *)
         cal_max:= 0.0;                          (* 84 + 4    *)
         cal_min:= 0.0;                          (* 88 + 4    *)
         compressed:=0;                         (* 92 + 4    *)
         verified:= 0;                           (* 96 + 4    *)
         glmax:= 0;
         glmin:= 0;                       (* 100 + 8   *)
         for lInc := 1 to 80 do
             lHdr.descrip[lInc] := chr(0);{80 spaces}
         for lInc := 1 to 24 do
             lHdr.aux_file[lInc] := chr(0);{80 spaces}
         orient:= chr(0);                            (* 104 + 1   *)
         //originator: array [1..10] of char;                   (* 105 + 10  *)
         for lInc := 1 to 5 do
             originator[lInc] := 0;                    (* 105 + 10  *)
         for lInc := 1 to 10 do
             generated[lInc] := chr(0);                     (* 115 + 10  *)
         for lInc := 1 to 10 do
             scannum[lInc] := chr(0);
         for lInc := 1 to 10 do
             patient_id[lInc] := chr(0);                    (* 135 + 10  *)
         for lInc := 1 to 10 do
             exp_date[lInc] := chr(0);                    (* 135 + 10  *)
         for lInc := 1 to 10 do
             exp_time[lInc] := chr(0);                    (* 135 + 10  *)
         for lInc := 1 to 3 do
             hist_un0[lInc] := chr(0);                    (* 135 + 10  *)
         views:=0;                              (* 168 + 4   *)
         vols_added:=0;                         (* 172 + 4   *)
         start_field:=0;                        (* 176 + 4   *)
         field_skip:=0;                         (* 180 + 4   *)
         omax:= 0;
         omin:= 0;                          (* 184 + 8   *)
         smax:= 0;
         smin:=0;                          (* 192 + 8   *)
{below are standard settings which are not 0}
         bitpix := 8; {8bits per pixel, e.g. unsigned char}
         DataType := 2;{unsigned char}
         vox_offset := 0;
         Originator[1] := 0;
         Originator[2] := 0;
         Originator[3] := 0;
         Dim[1] := 91;
         Dim[2] := 109;
         Dim[3] := 91;
         Dim[4] := 1; {n vols}
         glMin := 0;
         glMax := 255; {critical!}
         roi_scale := 0.00392157{1.1};
    end;
end;
function SaveAnalyzeHdr (lHdrName: string; lDicomData: DicomData): boolean;
var
lF: file;
lStr : string;
lHdr: AHdr;
 lSwapBytes: boolean;
begin
 lStr := ExtractFilePath(lHdrName)+ParseFileName(ExtractFileName(lHdrName))+'.hdr';
     {if (sizeof(AHdr)> DiskFree(lStr)) then begin
        ShowMessage('There is not enough free space on the destination disk to save the header. '+lStr);
        result := false;
        exit;
     end;  }
     Result := true;
     ClearHdr (lHdr);
     if lDicomData.little_endian = 1 then
        lSwapBytes := false
     else
         lSwapBytes := true;
     lHdr.Dim[1] := lDICOMdata.XYZdim[1];
     lHdr.Dim[2] := lDICOMdata.XYZdim[2];
     lHdr.Dim[3] := lDICOMdata.XYZdim[3];
     lHdr.pixdim[2] := lDICOMdata.XYZmm[1];
     lHdr.pixdim[3] := lDICOMdata.XYZmm[2];
     lHdr.pixdim[4] := lDICOMdata.XYZmm[3];{}
     lHdr.bitpix := lDicomData.Allocbits_per_pixel;
     lHdr.bitpix := lDicomData.Storedbits_per_pixel;
     lHdr.vox_offset := lDICOMdata.ImageStart;
     lHdr.roi_scale := lDicomData.IntenScale;
     case lHdr.bitpix of
         1: lHdr.datatype := 1; {binary}
         8: lHdr.datatype := 2; {8bit int}
         16: lHdr.datatype := 4; {16bit int}
         32: lHdr.datatype := 8; {32 bit long}
         else begin
             showmessage('Unable to save Analyze header '+lHdrName+chr(13)+
               'Use MRIcro to convert this image (ezDICOM can only convert files with 8/16/32 bits per voxel.');
             result := false;
             exit;
         end;
         //4: gAHdr.datatype := 16;{float=32bits}
         //5: gAHdr.datatype := 64; {float=64bits}
     end;

     if lSwapBytes then
        SwapBytes (lHdr);{swap to sun format}
     FileMode := 2; //read/write
     AssignFile(lF,lStr); {WIN}
     Rewrite(lF,sizeof(AHdr));
     BlockWrite(lF,lHdr, 1  {, NumWritten});
     CloseFile(lF);
end;

end.

