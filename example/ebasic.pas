Unit
eBasic;
// Wolfgang Krug and Chris Rorden - www.psychology.nottingham.ac.uk/staff/Chris.Rorden/
{If compiling for Pascal compilers other than Delphi 2+, gDynStr must be changed!}
 {Limitations:
  1.) Does not load custom colour palette  s
  2.) Does not extract compressed images
  3.) big endian and 12-bit features have not been heavily tested}
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,DICOM, Analyze,ExtCtrls, ComCtrls, Buttons, ToolWin,
  Dialogs, Spin;
{$H+} //use long, dynamic strings
type
    TInteger8 = Comp;  // 8-byte integer, since disk sizes may be > 2 GB
    Int64 = ^TInteger8;

  TeDICOMform = class(TForm)
    OpenDialog1: TOpenDialog;
    SaveDialog: TSaveDialog;
    ToolBar1: TToolBar;
    SpeedButton4: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SaveBtn: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton5: TSpeedButton;
    TrackBar1: TTrackBar;
    Image: TImage;
    SumPanel: TPanel;
    Memo1: TMemo;
    SpeedButton6: TSpeedButton;
    procedure Button1Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
procedure DisplayImage (lSlice: integer; lForceRedraw: boolean);
  end;
type
  ByteRA = array [0..0] of byte;
  Bytep0 = ^ByteRA;  
  SmallIntRA = array [0..0] of SmallInt;
  SMallIntp0 = ^SmallIntRA;
const gImgOK: boolean = false;
      gHdrOK: boolean = false;
var
  eDICOMform: TeDICOMform;
  gDICOMData: DiCOMDATA;
  gViewSlice: integer;

implementation

{$R *.DFM}

procedure TeDICOMform.DisplayImage (lSlice: integer; lForceRedraw: boolean);
var
  lBuff,TmpBuff   : bYTEp0;
  lBuff16: SmallIntP0;
  infp: file;
  max16 : LongInt;
  min16 : LongInt;
  size   : Integer;
  value : LongInt;
  lScanLineSz,lStoreSliceVox,lCol,lXdim,lImageStart,lAllocSLiceSz,lStoreSliceSz,I,I12       : Integer;
	hBmp    : HBITMAP;
  BI      : PBitmapInfo;
  BIH     : TBitmapInfoHeader;
  Bmp     : TBitmap;
  pixmap  : Pointer;
  PPal: PLogPalette;
//  TmpDC   : hDC;
  ImagoDC : hDC;
begin
     if not gImgOK then exit;
     if (lSlice = gViewSlice) and (not lForceRedraw) then exit;
  if (gDicomData.GenesisCpt) or (gDicomdata.GenesisPackHdr <> 0) then begin
        showmessage('This file is compressed or packed. You will require a more advanced viewer.');
        exit;
  end;
     gViewSlice := lSlice;
  lAllocSLiceSz := (gDICOMdata.XYZdim[1]*gDICOMdata.XYZdim[2]{height * width} * gDICOMdata.Allocbits_per_pixel+7) div 8 ;
  if (lAllocSLiceSz) < 1 then exit;
     AssignFile(infp, OpenDialog1.FileName);
     FileMode := 0; //Read only
	  Reset(infp, 1);
   lImageStart := gDicomData.ImageStart + ((lSlice-1) * lAllocSliceSz);
  if (lImageStart + lAllocSliceSz) > (FileSize(infp)) then begin
        showmessage('This file does not have enough data for the image size.');
        closefile(infp);
        FileMode := 2; //read/write
        exit;
  end;
  Seek(infp, lImageStart);
  case gDICOMdata.Allocbits_per_pixel of
       8: begin
                   GetMem( lbuff, lAllocSliceSz);
                   BlockRead(infp, lbuff^, lAllocSliceSz{, n});
                   CloseFile(infp);
                   FileMode := 2; //read/write
                   end;
       16: begin
                   GetMem( lbuff16, lAllocSliceSz);
                   BlockRead(infp, lbuff16^, lAllocSliceSz{, n});
                   CloseFile(infp);
                   FileMode := 2; //read/write

       end;
       12: begin
           GetMem( tmpbuff, lAllocSliceSz);
           BlockRead(infp, tmpbuff^, lAllocSliceSz{, n});
           CloseFile(infp);
           FileMode := 2; //read/write
           lStoreSliceVox := gDICOMdata.XYZdim[1]*gDICOMdata.XYZdim[2];
           lStoreSLiceSz := lStoreSliceVox * 2;
           GetMem( lbuff16, lStoreSLiceSz);
           I12 := 0;
           I := 0;
           repeat
                 lbuff16[I] := (((tmpbuff[I12]) shr 4) shl 8) + (((tmpbuff[I12+1]) and 15) + (((tmpbuff[I12]) and 15) shl 4) );
                 inc(I);
                 if I < lStoreSliceVox then
                    lbuff16[i] :=  (((tmpbuff[I12+2]) and 15) shl 8) +((((tmpbuff[I12+1]) shr 4 ) shl 4)+((tmpbuff[I12+2]) shr 4)  );//char (((integer(tmpbuff[I12+2]) and 16) shl 4)+ (integer(tmpbuff[I12+1]) shr 4));
                 inc(I);
                 I12 := I12 + 3;
           until I >= lStoreSliceVox;
           FreeMem( tmpbuff);
           end;
       else exit;
  end;
  if  (gDICOMdata.Storedbits_per_pixel)  > 8 then begin
  size := gDicomData.XYZdim[1]*gDicomData.XYZdim[2] {2*width*height};
  if gDicomdata.little_endian <> 1 then  //convert big-endian data to Intel friendly little endian
     for i := (Size-1) downto 0 do
         lbuff16[i] := swap(lbuff16[i]);
  value := lbuff16[0];
  max16 := value;
  min16 := value;
  i:=0;
  while I < Size do begin
    value := lbuff16[i];
    if value < min16 then min16 := value;
    if value > max16 then max16 := value;
    i := i+1;
  end;
  size := (gDicomData.XYZdim[1]*gDicomData.XYZdim[2])-1 {width*height-1 };
  GetMem( lbuff,size+1 {width * height});
  value := (max16-min16);
  if value = 0 then value := 1;
  for i := 0 to size do begin
  	lbuff[i] := (Trunc(255*((lBuff16[i])-min16) / value));
  end;
  FreeMem( lbuff16 );
end;
if (gDICOMdata.XYZdim[1] mod 8) <> 0 then begin
   lXdim :=  ((gDICOMdata.XYZdim[1]+7) div 8) * 8;
   lAllocSLiceSz := lXdim*gDICOMdata.XYZdim[2] ;
       GetMem( tmpbuff, lAllocSliceSz);
       I := 0;
       lCol := 1;
       I12 := 0;
       repeat
             if lCol <= gDICOMdata.XYZdim[1] then begin
                tmpbuff[I] := lbuff[I12];
                inc(I12);
             end else
                 tmpbuff[I] := (0);
             inc(lCol);
             if lCol > lXdim then lCol := 1;
             Inc(I);
       until I >= (lAllocSliceSz);
       freemem(lBuff);
       lbuff := tmpbuff;
end else
         lXdim := gDICOMdata.XYZdim[1];
	BIH.biSize   		 	 	:= Sizeof(BIH);
	BIH.biWidth  		 	 	:= lXdim;//gDICOMdata.XYZdim[1]{width};
  BIH.biHeight 		 	 	:= gDICOMdata.XYZdim[2]{-height};
	BIH.biPlanes 		 	 	:= 1;
  BIH.biBitCount 	 	 	:= 8;
	BIH.biCompression 	:= BI_RGB;
  BIH.biSizeImage	 	 	:= 0;
	BIH.biXPelsPerMeter := 0;
  BIH.biYPelsPerMeter := 0;
	BIH.biClrUsed       := 0;
  BIH.biClrImportant  := 0;
{$P+,S-,W-,R-}

 		// Create DIB Bitmap Info with actual color table
	BI := AllocMem(SizeOf(TBitmapInfoHeader) + 256*Sizeof(TRGBQuad));
	try
	  BI^.bmiHeader := BIH;
       for I:=0 to 255 do begin
  		     BI^.bmiColors[I].rgbBlue     := Byte( I );
                BI^.bmiColors[I].rgbGreen    := Byte( I );
	           BI^.bmiColors[I].rgbRed      := Byte( I );
		     BI^.bmiColors[I].rgbReserved := 0;
       end;
	  Bmp        := TBitmap.Create;
   	  Bmp.Height := gDICOMdata.XYZdim[2]{width};
	  Bmp.Width  := lXdim{gDICOMdata.XYZdim[2]{height};

       ImagoDC := GetDC(Self.Handle);
          Pixmap:=nil;
          hBmp:= CreateDIBSection(imagodc,bi^,DIB_RGB_COLORS,pixmap,0,0);
          lScanLineSz := {BMp.width}lXdim;
           if (hBmp = 0) or (pixmap = nil) then
             if GetLastError = 0 then ShowMessage('Error!') else RaiseLastWin32Error;
          try
        For i:= (Bmp.Height-1)  downto 0 do
         begin
          CopyMemory(Pointer(Integer(pixmap)+lScanLineSz*(i)),
                     Pointer(Integer(lBuff)+(Bmp.Height-(i+1))*lScanLineSz),
                     lScanLineSz);
        end;
          except
           DeleteObject(hBmp);
          end;
          ReleaseDC(0,ImagoDC);
	  Bmp.Handle := hBmp;

	  Bmp.Handle := hBmp;
          Bmp.ReleasePalette;
GetMem (PPal,SizeOf(TLogPalette)+255*SizeOf(TPaletteEntry));
  with PPal^ do
   begin
      PalVersion := $300;
      PalNumEntries := 256;
   {$R-}
    for i := 0 to 255 do
     begin
      PalPalEntry[i].peRed   := BI^.bmiColors[I].rgbRed;
      PalPalEntry[i].peGreen := BI^.bmiColors[I].rgbGreen;
      PalPalEntry[i].peBlue  := BI^.bmiColors[I].rgbBlue;
      PalPalEntry[i].peFlags := BI^.bmiColors[I].rgbReserved;
     end;

   end;
 Bmp.Palette:= CreatePalette(PPal^);
FreeMem (PPal,SizeOf(TLogPalette)+255*SizeOf(TPaletteEntry));
Image.Picture.Assign( Bmp );
  Image.Refresh;
  Bmp.Free;
  except
	  exit;
  end;
  FreeMem( BI, SizeOf(TBitmapInfoHeader) + 256*Sizeof(TRGBQuad));
  freemem(lBuff);
{$P-,S+,W+,R+}
end;



(***********************************************************)
procedure TeDICOMform.Button1Click(Sender: TObject);
var
lLen,lI: integer;
lStr,lDynStr: string;
lf: file of byte;
begin
  if (Sender as TSpeedbutton).tag = 1 then
     OpenDialog1.Filter := 'Analyze Header (*.hdr)|*.hdr' {*.jpg;*.bmp;*.gif}
  else
     OpenDialog1.Filter := 'Medical Image (*.*)|*.*'; {*.jpg;*.bmp;*.gif}
  if OpenDialog1.Execute then begin
     lStr := OpenDialog1.FileName;
     if not fileexists(lStr) then exit;
     filemode := 0;
     AssignFile(lf, lStr);
     Reset(lf);
     lLen := filesize(lf);
     closefile(lf);
     filemode := 2;
     if ((Sender as TSpeedbutton).tag = 1) or ((lLen = 348) and (ExtractFileExt(lStr)='.hdr')) then begin
        OpenAnalyze (gHdrOK,gImgOK,lDynStr,lStr, gDicomData);
     end else
         read_dicom_data(false,true,false,false,true,true,false,gDICOMdata,gHdrOK,gImgOK,lDynStr,lStr {infp});
//procedure read_dicom_data(lVerboseRead,lAutoDECAT7,lReadECAToffsetTables,lAutodetectInterfile,lAutoDetectGenesis,lReadColorTables: boolean; var lDICOMdata: DICOMdata; var lHdrOK, lImageFormatOK: boolean; var lDynStr: string;var lFileName: string);
     OpenDialog1.FileName := lStr;
     if (gImgOK) and ((gDicomData.CompressSz > 0) or (gDICOMdata.SamplesPerPixel > 1)) then begin
         showmessage('This software can not read compressed or 24-bit color files.');
         gImgOK := false;
     end;
     if gDICOMdata.XYZdim[3] < 2 then
          TrackBar1.visible := false
       else begin
            TrackBar1.position := 1;
            TrackBar1.Min := 1;
            TrackBar1.Max := gDICOMdata.XYZdim[3];
            TrackBar1.visible := true;
       end;
    if not gHdrOK then begin
       showmessage('Unable to load DICOM header segment. Is this really a DICOM compliant file?');
       lDynStr := '';
       //exit;
    end;
    lLen := Length (lDynStr);
    Memo1.Lines.Clear;
    if lLen > 0 then begin
       lStr := '';
       for lI := 1 to lLen do begin
           if lDynStr[lI] <> kCR then
              lStr := lStr + lDynStr[lI]
           else begin
                Memo1.Lines.add(lStr);
                lStr := '';
           end;
       end;
       Memo1.Lines.Add(lStr);
    end;
lDynStr := '';
 if gImgOK then
    DisplayImage(1, true);//force redraw: new image
  end;
end;

procedure TeDICOMform.TrackBar1Change(Sender: TObject);
var lSlice: integer;
begin
     lSlice := TrackBar1.Position;
     If (not gImgOK) or (lSlice > gDicomData.XYZdim[3]) then exit;
     DisplayImage(lSlice,false); //don't force redraw: Delphi calls TrackBarChange BEFORE and after each change
end;

procedure TeDICOMform.SaveBtnClick(Sender: TObject);
var lF: textfile;
    lInc: integer;
begin
	if Memo1.Lines.Count < 1 then begin
        ShowMessage('DICOM summary is empty.');
        exit;
     end;
	SaveDialog.DefaultExt := '.TXT';
	  SaveDialog.Filter := 'Text files (*.TXT)|*.TXT';
	  SaveDialog.Options := [ofOVerWritePrompt];
	  if SaveDialog.Execute then begin
		AssignFile(lF, SaveDialog.FileName); {WIN}
		{$I-}
		Rewrite(lF);
		{$I+}
		if IoResult = 0 then begin
		   for lInc  := 0 to Memo1.Lines.Count do begin
			Writeln(lF, Memo1.Lines[lInc]);
              end;
              CloseFile(lF);
		end; {i/o error}
       end; {save dlg execute}
end;
procedure TeDICOMform.SpeedButton1Click(Sender: TObject);
begin
	if Memo1.Lines.Count < 1 then begin
        ShowMessage('DICOM summary is empty.');
        exit;
     end;
     Memo1.SelectAll;
     Memo1.CopyToClipBoard
end;

procedure TeDICOMform.SpeedButton2Click(Sender: TObject);
begin
	  SaveDialog.Filter := 'Bitmap Files (*.BMP)|*.BMP';
	  SaveDialog.Options := [ofOVerWritePrompt];
	  SaveDialog.DefaultExt := 'bmp';
	  if SaveDialog.Execute then
          Image.Picture.SaveToFile(SaveDialog.Filename);
end;

procedure TeDICOMform.SpeedButton3Click(Sender: TObject);
begin
    Showmessage('eDICOM is a basic DICOM medical image viewer. The program was written by Wolfgang Krug and Chris Rorden.'+kCR+'version 1.2 rev 19'+kCR+' www.mricro.com');
end;

procedure TeDICOMform.SpeedButton5Click(Sender: TObject);
begin
 SumPanel.visible := not sumpanel.visible;
end;

procedure TeDICOMform.FormCreate(Sender: TObject);
begin
DecimalSeparator := '.';
end;

end.
