unit decompress;
//This unit decompresses images encoded by RunLengthEncoding (RLE), lossyJPEG or GE's proprietary compression algorithm
//Note: lossless JPEG are decoded by the separate unit 'lsjpeg.pas'

interface
{$ifdef Linux}
uses sysUtils,define_types,Qdialogs;
{$else}
uses clipbrd,dialogs,sysutils,windows,classes,jpeg,Graphics,define_types,extctrls;
(*uses SysUtils, Windows, Classes, Graphics, Forms,
     Controls, ExtCtrls, StdCtrls, Buttons,define_types,
     ComCtrls, Menus, Dialogs,DICOM,JPEG,analyze,lsJPEG,Clipbrd, ToolWin,uMultislice;
  *)
{$endif}
//declarations
procedure DecompressRLE8(var infp: file; var lOutputBuff: ByteP0;lSamplesPerPixel,lAllocSliceSz,lCompressOffset,lCompressSz: integer);
procedure DecompressRLE16(var infp: file; var lOutputBuff: SmallIntP0;lImageVoxels,lCompressOffset,lCompressSz: integer);
procedure DecompressRLE16toRGB(var infp: file; var lOutputBuffRGB: ByteP0;lImageVoxels,lCompressOffset,lCompressSz,lRedLUTOffset,lGreenLUTOffset,lBlueLUTOffset,lRedLUTSz,lGreenLUTSz,lBlueLUTSz: integer);
procedure DecompressGE(var infp: file; var lOutputBuff: SmallIntP0;lImageStart,lImgWid,lImgHt,lGenesisPackHdr: integer);
procedure decompressJPEG8 (lFilename: string; var lOutputBuff{gBuff8}: ByteP0; lAllocSliceSz,lImageStart{gECATposra[lSlice]}: integer);
procedure decompressJPEG24noImage (lFilename: string; var lOutputBuff: ByteP0; lImageVoxels,lImageStart{gECATposra[lSlice]}: integer);//for console applications
procedure decompressJPEG24 (lFilename: string; var lOutputBuff: ByteP0; lImageVoxels,lImageStart{gECATposra[lSlice]}: integer; var lImage: TImage);


implementation

procedure decompressJPEG24 (lFilename: string; var lOutputBuff: ByteP0; lImageVoxels,lImageStart{gECATposra[lSlice]}: integer; var lImage: TImage);
var
   Stream: Tmemorystream;
   Jpg: TJPEGImage;

//   TmpBmp: TPicture;
//   lImage: Timage;
   lRow:  pRGBTripleArray;
   lHt0,lWid0,lInc,i,j: integer;
begin
  try
      Stream := TMemoryStream.Create;
      Stream.LoadFromFile(lFilename);
      Stream.Seek(lImageStart, soFromBeginning);
      try
        Jpg := TJPEGImage.Create;
        Jpg.LoadFromStream(Stream);
        lImage.Height := JPG.Height;
        lImage.Width := JPG.Width;
        lImage.Picture.Bitmap.Assign(jpg);
        if lImageVoxels = (JPG.Height*JPG.Width) then begin
           lWid0 := JPG.Width-1;
           lHt0 := JPG.Height-1;
           lInc := (3*lImageVoxels)-1; //*3 because 24-bit, -1 since index is from 0
           FOR j := lHt0-1 DOWNTO 0 DO BEGIN
                          lRow := lImage.Picture.Bitmap.ScanLine[j];
                          FOR i := lWid0 downto 0 DO BEGIN
                              lOutputBuff[lInc] := (lRow[i].rgbtBlue) and 255;//lRow[i].rgbtRed;
                              lOutputBuff[lInc-1] := (lRow[i].rgbtGreen) and 255;//lRow[i].rgbtRed;
                              lOutputBuff[lInc-2] := (lRow[i].rgbtRed) and 255;//lRow[i].rgbtRed;
                              dec(lInc,3);
                          END; //for i.. each column
           END; //for j...each row
        end; //correct image size
      finally //try..finally
        Jpg.Free;
      end;
    finally
      Stream.Free;
    end; //try..finally
end;


procedure decompressJPEG24noImage (lFilename: string; var lOutputBuff: ByteP0; lImageVoxels,lImageStart{gECATposra[lSlice]}: integer);
{$ifdef linux}
begin
end;
{$else}
var
   lStream: TMemoryStream;
   lWid0,i,J,lInc: integer;
   Jpg: TJPEGImage;
   lRow:  pRGBTripleArray;
   lStr: string;
   Bmp     : TBitmap;
begin
    try
    lStream := TMemoryStream.Create;
    //showmessage(inttostr(lImageStart));
       // lStr := 'D:\jpeg24.dic';
      //lStream.LoadFromFile(lStr);
      lStream.LoadFromFile(lFilename);
      lStream.Seek(lImageStart, soFromBeginning);
      Jpg := TJPEGImage.Create;
      try
         Jpg.LoadFromStream(lStream);
         BMP := TBitmap.create;
         try
            BMP.Height := JPG.Height;
            BMP.Width := JPG.Width;
            lWid0 := BMP.Width-1;
            BMP.PixelFormat := pf24bit;
            BMP.Canvas.Draw(0,0, JPG);
            if lImageVoxels = (BMP.Height*BMP.Width) then begin
                        lInc := (3*lImageVoxels)-1; //*3 because 24-bit, -1 since index is from 0
                        FOR j := BMP.Height-1 DOWNTO 0 DO BEGIN
                          lRow := BMP.Scanline[j];
                          FOR i := lWid0 downto 0 DO BEGIN
                              lOutputBuff[lInc] := (lRow[i].rgbtBlue) and 255;//lRow[i].rgbtRed;
                              lOutputBuff[lInc-1] := (lRow[i].rgbtGreen) and 255;//lRow[i].rgbtRed;
                              lOutputBuff[lInc-2] := (lRow[i].rgbtRed) and 255;//lRow[i].rgbtRed;
                              dec(lInc,3);
                          END; //for i.. each column
                        END; //for j...each row
            end; //if ImageSize matches buffer size
            //Image.Picture.Graphic := BMP;
         finally
                BMP.Free;
         end;
      finally
             JPG.Free;
      end; //JPEG try..finally
    finally
                  lStream.Free;
    end; //Stream try..finally
  FileMode := 0; //Read only
end; //decompressJPEG24
{$endif}

procedure decompressJPEG8 (lFilename: string; var lOutputBuff: ByteP0; lAllocSliceSz,lImageStart{gECATposra[lSlice]}: integer);
{$ifdef Linux}
begin
end;
{$else}
var
   Stream: TMemoryStream;
   i,J,lInc: integer;
   Jpg: TJPEGImage;
   lRow:  pRGBTripleArray;
   Bmp     : TBitmap;
begin
Stream := TMemoryStream.Create;
             try
                Stream.LoadFromFile(lFilename);
                Stream.Seek(lImageStart, soFromBeginning);
                Jpg := TJPEGImage.Create;
                try
                   Jpg.LoadFromStream(Stream);
                   BMP := TBitmap.create;
                   try
                      BMP.Height := JPG.Height;
                      BMP.Width := JPG.Width;
                      BMP.PixelFormat := pf24bit;
                      BMP.Canvas.Draw(0,0, JPG);
                      if lAllocSliceSz = (BMP.Height*BMP.Width) then begin
                        lInc := lAllocSliceSz-1;
                        FOR j := BMP.Height-1 DOWNTO 0 DO BEGIN
                          lRow := BMP.Scanline[j];
                          FOR i := (BMP.Width - 1) downto 0 DO BEGIN
                              lOutputBuff[lInc] := (lRow[i].rgbtRed) and 255;//lRow[i].rgbtRed;
                              dec(lInc);
                          END; //for i.. each column
                        END; //for j...each row
                      end; //if ImageSize matches buffer size
                   finally
                           BMP.Free;
                   end; //BMP try..finally
                finally
                        Jpg.Free;
                end; //JPG try..finally
             finally
                    Stream.Free;
             end; //Stream try..finally
end; //decompressJPEG8
{$endif}

procedure DecompressGE(var infp: file; var lOutputBuff: SmallIntP0;lImageStart,lImgWid,lImgHt,lGenesisPackHdr: integer);
label 444;
var J,I,lPos,lTmpSz,lTmpPos,lImgPos,lLine,lLastPixel,lBufEntries,lAllocSliceSz,lLineStart,lLineEnd: integer;
    TmpBuff   : bYTEp0;
    lByte,lByte2: byte;
function swap16i(lPos: longint): smallint;
var
   s : SmallInt;
begin
     seek(infp,lPos);
  BlockRead(infp, s, 2{, n});
  swap16i:=swap(s);
end;
function GetByte: byte;
begin
     if lTmpPos >= lTmpSz then begin //whoops GE "compression" has made the file BIGGER!
 {Worst case scenario filesize = 150% uncompressed, so this can only happen once}
        lTmpSz := FileSize(inFp)-lImageStart;
        if (lAllocSliceSz < lTmpSz) then
           lTmpSz := lAllocSliceSz; {idea: for multi slice images, limit compression}
        if lTmpSz < 1 then begin
            Showmessage('Error with GE Genesis compression.');
            GetByte := 0;
            exit;
        end;
        FreeMem(TmpBuff);
        GetMem( TmpBuff, lTmpSz);
        BlockRead(inFp, TmpBuff^, lTmpSz);
        lTmpPos := 0;
     end;
     if lTmpPos > 0 then GetByte := TmpBuff[lTmpPos]
     else GetByte := 0;
     inc(lTMpPos);
end;

begin
                lAllocSliceSz := lImgHt*lImgWid * 2;
                lLastPixel := 0;
                lBufEntries := lAllocSliceSz div 2;
                lTmpSz := FileSize(infp)-lImageStart;
                if (lAllocSliceSz < lTmpSz) then
                lTmpSz := FileSize(infp)-lImageStart;
                if (lAllocSliceSz < lTmpSz) then
                   lTmpSz := lAllocSliceSz; {idea: for multi slice images, limit compression}
                lTmpSz := lTmpSz - 2;
                GetMem( TmpBuff, lTmpSz);
                BlockRead(inFp, TmpBuff^, lTmpSz);
                {$R-}
                   lTmpPos := 0;
                   lImgPos := 0;
                   lLineStart := 1;
                   lLineEnd := lImgWid;
                   for lLine := 1 to lImgHt do begin
                       if lGenesisPackHdr <> 0 then begin
                              lLineStart :=swap16i(lGenesisPackHdr+((lLine-1)*4));
                              lLineEnd := -1+lLineStart+ swap16i(2+lGenesisPackHdr+((lLine-1)*4));
                              //if lLine < 10 then showmessage(inttostr(lLineStart));
                              if lLinestart >0 then
                                 for lPos := 1 to (lLineStart) do begin
                                  lOutputBuff[lImgPos] := 0;
                                  inc(lImgPos);
                              end;
                          end;
                          for lPos := lLineStart to lLineEnd do begin
                             lByte := GetByte;
                             if (lByte > 127) then begin
                                if ((lByte and 64)=64) then begin {new 16 bits}
                                   I := GetByte;//lByte2;
                                   lByte := GetByte;
                                   lLastPixel := ((I shl 8)+lByte);
                                end else begin {not lbyte and 64: 14 byte delta}
                                 lByte2 := getbyte;
                                 J := lByte2;
                                 if ((lByte and 32)=32) then {subtract delta}  //shl1=2,shl2=4,shl3=8,shl4=16,shl5=32
                                    I := (lByte or $E0)
                                 else
                                     I := lByte and $1F;
                                 lLastPixel := lLastPixel + smallint(((I)shl 8)+ (J {shl 5}))
                                end; {14 byte delta}
                             end else begin {not lbyte and 128: 7 byte delta}
                                 if (lByte > 63) then {subtract delta}
                                    lByte := lByte or $C0;
                                 lLastPixel := lLastPixel + shortInt(lByte);
                         end; //lbyte values
                             if lImgPos <= lBufEntries then
                                lOutputBuff[lImgPos] := lLastPixel
                             else //imgpos >= lAlloc
                                 goto 444;
                             inc(lImgPos);
                       end; //lPos
                       if (lLineEnd+1) < lImgWid then begin
                              for lPos := lImgWid downto (lLineEnd+2) do begin
                                  //if lLine < (512) then
                                  lOutputBuff[lImgPos] := 0;
                                  inc(lImgPos);
                              end;
                       end;
                   end; //for lines
                   444:
                   Freemem(TmpBuff);
end; //DecompressGE

procedure DecompressRLE8(var infp: file; var lOutputBuff: ByteP0;lSamplesPerPixel,lAllocSliceSz,lCompressOffset,lCompressSz: integer);
var
  lRGBsegmentOffset: array [1..3] of longint;
  lShort: ShortInt;
  lSamples,lUncompressedSegmentSz0,lUncompressedSegmentEnd,lSegment,J,i,lCompSz,lCptPos,lCptVal,lRunVal: integer;
  lTmpBuff,lCptBuff: bYTEp0;
begin
     lSamples := lSamplesPerPixel;
     if lSamples = 3 then begin
        //lFullSz := lAllocSliceSz*3;
        GetMem( lTmpBuff, lAllocSliceSz*3);
     end else begin
         lTmpBuff := @lOutputBuff^;
         lSamples := 1;
     end;
     Seek(infp,lCompressOffset+4);
     BlockRead(infp, lRGBsegmentOffset[1], 4); //1st Offset: RED
     BlockRead(infp, lRGBsegmentOffset[2], 4); //2nd Offset: GREEN, unused for monochrome
     BlockRead(infp, lRGBsegmentOffset[3], 4); //3rd Offset: BLUE, unused for monochrome
     lCompSz := FileSize(infp) - (lCompressOffset);
     if lCompSz >lCompressSz then
        lCompSz := lCompressSz;
     Seek(infp, lCompressOffset);
     GetMem( lCptBuff, lCompSz);
     BlockRead(infp, lCptBuff^, lCompSz{, n});
     lUncompressedSegmentSz0 :=lAllocSliceSz-1;
     J := 0;
     for lSegment := 1 to lSamples do begin
             lUncompressedSegmentEnd := (lUncompressedSegmentSz0 * lSegment)-1;
             lCptPos := lRGBsegmentOffset[lSegment];
             repeat
                   lCptVal := lCptBuff[lCptPos];
                   inc(lCptPos);
                   lShort := shortint(lCptVal);
                   case lShort{lCptVal} of
                        -128: ;
                        0..127 : begin
                                 for i := 0 {0->n+1 bytes} to lShort do begin
                                   if J < lUncompressedSegmentEnd then
                                      lTmpBuff[J] := lCptBuff[lCptPos];
                                   inc(J);
                                   inc(lCptPos);
                                 end;
                               end;
                        else begin
                             lCptVal := (-lShort);
                             lRunVal := lCptBuff[lCptPos];
                             inc(lCptPos);
                             for i := 0 {0->n+1 bytes} to lCptVal do begin
                                   if J < lUncompressedSegmentEnd then
                                      lTmpBuff[J] := lRunVal;
                                   inc(J);
                                 end;
                        end;
                   end;
             until (lCptPos >= lCompressSz) or (J > lUncompressedSegmentEnd);
     end;// for each segment lUncompressedSegmentSize
     FreeMem(lCptBuff);
     if lSamples = 3 then begin //Samples=3, swizzle RRRGGGBBB to triplets RGBRGBRGB
         j:= 0;
         lUncompressedSegmentSz0 := lAllocSliceSz-1;
         for i := 0 to lUncompressedSegmentSz0 do begin
             lOutputBuff[j] := lTmpBuff[i]; //red
             lOutputBuff[j+1] := lTmpBuff[i+lAllocSliceSz];
             lOutputBuff[j+2] := lTmpBuff[i+lAllocSliceSz+lAllocSliceSz];  //blue
             j := j + 3;
         end; //for loop
         FreeMem( lTmpBuff);
     end; //Samples=3, swizzle RRRGGGBBB to triplets RGBRGBRGB
end;

procedure DecompressRLE16(var infp: file; var lOutputBuff: SmallIntP0;lImageVoxels,lCompressOffset,lCompressSz: integer);
//NOTE: output as 15-bit integer: fine for SIGNED and UNSIGNED data, loss fo LeastSignificantBit
var
  lHiLoSegmentOffset: array [1..2] of longint;
  lShort: ShortInt;
  J,i,lCompSz,lCptPos,lCptVal,lRunVal: integer;
  lCptBuff: ByteP0;
begin
     Seek(infp,lCompressOffset+4);
     BlockRead(infp, lHiLoSegmentOffset[1], 4); //1st Offset: LO
     BlockRead(infp, lHiLoSegmentOffset[2], 4); //2nd Offset: HI
     lCompSz := FileSize(infp) - (lCompressOffset);
     if lCompSz >lCompressSz then
        lCompSz := lCompressSz;
     Seek(infp, lCompressOffset);
     GetMem( lCptBuff, lCompSz);
     BlockRead(infp, lCptBuff^, lCompSz{, n});
     //First Pass: read LO bits
     J := 0;
     lCptPos := lHiLosegmentOffset[2];
     repeat
                   lCptVal := lCptBuff[lCptPos];
                   inc(lCptPos);
                   lShort := shortint(lCptVal);
                   case lShort of
                        -128: ;
                        0..127 : begin
                                 for i := 0  to lShort do begin //0->n+1 bytes
                                   if J < lImageVoxels then
                                      lOutputBuff[J] := lCptBuff[lCptPos];
                                   inc(J);
                                   inc(lCptPos);
                                 end;
                               end;
                        else begin
                             lCptVal := (-lShort);
                             lRunVal := lCptBuff[lCptPos];
                             inc(lCptPos);
                             for i := 0  to lCptVal do begin  //0->n+1 bytes
                                   if J < lImageVoxels then
                                      lOutputBuff[J] := lRunVal;
                                   inc(J);
                                 end;
                        end;
                   end;
     until (lCptPos >= lCompressSz) or (J >= lImageVoxels);

     lCompSz := lImageVoxels -1;
     for J := 0 to lCompSz do
         lOutputBuff[J] := lOutputBuff[J] shr 1; //divide each value by 2: we will generate a 15-bit image instead of 16-bit
         //because we want a SIGNED 16-bit int, not an UNSIGNED value
     //Second Pass: read HI bits
     lCptPos := lHiLosegmentOffset[1];
     J := 0;
     repeat
                   lCptVal := lCptBuff[lCptPos];
                   inc(lCptPos);
                   lShort := shortint(lCptVal);
                   case lShort of
                        -128: ;
                        0..127 : begin
                                 for i := 0  to lShort do begin
                                   if J < lImageVoxels then
                                      lOutputBuff[J] := (lCptBuff[lCptPos] shl 7)+lOutputBuff[J];
                                   inc(J);
                                   inc(lCptPos);
                                 end;
                               end;
                        else begin
                             lCptVal := (-lShort);
                             lRunVal := lCptBuff[lCptPos];
                             inc(lCptPos);
                             for i := 0  to lCptVal do begin
                                   if J < lImageVoxels then
                                      lOutputBuff[J] :=(lRunVal shl 7)+lOutputBuff[J];
                                   inc(J);
                                 end;
                        end;
                   end;
     until (lCptPos >= lCompressSz) or (J >= lImageVoxels);
     FreeMem(lCptBuff);
end;

procedure DecompressRLE16toRGB(var infp: file; var lOutputBuffRGB: ByteP0;lImageVoxels,lCompressOffset,lCompressSz,lRedLUTOffset,lGreenLUTOffset,lBlueLUTOffset,lRedLUTSz,lGreenLUTSz,lBlueLUTSz: integer);
//This is for paletted run-length-encoded (RLE) 16-bit images see C.7.9.2 of DICOM standard
var
  lHiLoSegmentOffset: array [1..2] of longint;
  lwordLUTra: array [0..65535] of word; //16-bit LUT value
  lrgbLUTra: array [1..3,0..65536] of byte;//24-bit RGB code for each indexed value
  lShort: ShortInt;
  lCptLUTWordRA,lDecodedRA: WordP0;
  lSlope: double;
  lSz,lJumpPosAfterIndirect,lnIndirectSegments,lIndex,lStartVal,lRunLen,lEndVal,lOpCode,lSegmentsRead,lColor, J,i,lCptSz,lCptPos,lCptVal,lRunVal: integer;
  lCptBuff: ByteP0;
begin
     //first: decode red/green/blue lookup tables
     //for details of this stage, see C.7.9.2 of DICOM standard
     for I := 1 to 3 do
         for J := 0 to 65535 do
             lrgbLUTra[I,J] := 0;
     for lColor := 1 to 3 do begin //Read LUT for each color: red/green/blue
         case lColor of //set offsets
              1: lCptPos := lRedLUTOffset;
              2: lCptPos := lGreenLUTOffset;
              else lCptPos := lBlueLUTOffset;
         end; //case lColor
         case lColor of //set offsets
              1: lCptSz := lRedLUTSz;
              2: lCptSz := lGreenLUTSz;
              else lCptSz := lBlueLUTSz;
         end; //case lColor
         if odd(lCptSz) then lCptSz := lCptSz -1; //should be impossible: all 16-bit values, all DICOM entries must be even number of bytes
         getmem(lCptLUTWordRA,lCptSz);
         Seek(infp,lCptPos); //start of LUT
         BlockRead(infp, lCptLUTWordRA[0], lCptSz); //1st Offset: start of segment with LO bytes

         lCptSz := (lCptSz shr 1) -1; //div 2: 16bit uints, -1: overflow check is incremented from 0
         lCptPos := 0; //start with first index
         lIndex := 0;
         lnIndirectSegments := 0;
         lSegmentsRead := 0; //used by indirect segments
         repeat //read all LUT
                //read a single segment
                lSegmentsRead := lSegmentsRead +1;
                lOpCode :=  lCptLUTWordRA[lCptPos];
                inc(lCptPos);
                case lOpCode of //opcode specifies discrete, linear or indirect segment
                     0: begin //0=DISCRETE: read n sequential values uncompressed
                          J:= lCptLUTWordRA[lCptPos]; //number of indexes to read
                          inc(lCptPos);
                          for I := 1 to J do begin
                               lwordLUTra[lIndex] := lCptLUTWordRA[lCptPos]; //number of indexes to read
                               inc(lCptPos);
                               inc(lIndex);
                          end;
                     end;//Opcode = 0        xxx
                     1: begin //1=LINEAR: linearly interpolate values
                         lStartVal := lwordLUTra[lIndex-1];//read previous sample
                         lRunLen :=  lCptLUTWordRA[lCptPos]; //number of indexes to read
                         //showmessage(inttostr(lRunLen));
                         inc(lCptPos);
                         lEndVal :=  lCptLUTWordRA[lCptPos]; //number of indexes to read
                         inc(lCptPos);
                         lSlope := (lEndVal - lStartVal) / lRunLen;
                         for I := 1 to lRunLen do begin
                             lwordLUTra[lIndex] := lStartVal + round(lSlope*I);
                             inc(lIndex);
                         end;
                     end;//Opcode = 1
                     2: begin//2=INDIRECT, e.g. jump back for n previous tables
                        lnIndirectSegments := lCptLUTWordRA[lCptPos]; //number of indexes to read
                        lJumpPosAfterIndirect := lCptPos + 3;//3=length of this segment
                        lCptPos := lCptLUTWordRA[lCptPos+1] + (256*lCptLUTWordRA[lCptPos+2]);
                        lSegmentsRead := 0;
                     end;//Opcode=2
                     else begin
                         showmessage('File corrupted: Invalid segemented palette color opcode: '+inttostr(lOpCode));
                         freemem(lCptLUTWordRA);
                         exit;
                     end;
                     if (lnIndirectSegments>0) and (lnIndirectSegments=lSegmentsRead) then begin //IndirectSegments completed
                        lnIndirectSegments := 0;
                        //showmessage('indy');
                        lCptPos := lJumpPosAfterIndirect
                     end; //IndirectSegments completed
                end; //Case of  OpCode
         until (lIndex > 65535) or (lCptPos >= lCptSz);//read LUT
         //showmessage(inttostr(lIndex));
         //freemem(lCptLUTWordRA);
         for J := 0 to 65535 do
             lrgbLUTra[lColor,J] := lwordLUTra[J]  shr 8; //Convert16bit uint to 8bit int
     end; //for color := 1 to 3 RGB
     //done reading LUTs


     //next, decode index
     getmem(lDecodedRA,lImageVoxels * sizeof(word));
     Seek(infp,lCompressOffset+4); //ignore 1st 4 bytes: describes number of segments: Assume value is 2
     BlockRead(infp, lHiLoSegmentOffset[1], 4); //1st Offset: start of segment with LO bytes
     BlockRead(infp, lHiLoSegmentOffset[2], 4); //2nd Offset: start of segment with HI bytes
     lCptSz := FileSize(infp) - (lCompressOffset);
     if lCptSz >lCompressSz then
        lCptSz := lCompressSz;
     Seek(infp, lCompressOffset);
     GetMem( lCptBuff, lCptSz);
     BlockRead(infp, lCptBuff^, lCptSz{, n});
     //First Pass: read LO bits
     J := 0;
     lCptPos := lHiLosegmentOffset[2];
     repeat
                   lCptVal := lCptBuff[lCptPos];
                   inc(lCptPos);
                   lShort := shortint(lCptVal);
                   case lShort of
                        -128: ;
                        0..127 : begin
                                 for i := 0  to lShort do begin //0->n+1 bytes
                                   if J < lImageVoxels then
                                      lDecodedRA[J] := lCptBuff[lCptPos];
                                   inc(J);
                                   inc(lCptPos);
                                 end;
                               end;
                        else begin
                             lCptVal := (-lShort);
                             lRunVal := lCptBuff[lCptPos];
                             inc(lCptPos);
                             for i := 0  to lCptVal do begin  //0->n+1 bytes
                                   if J < lImageVoxels then
                                      lDecodedRA[J] := lRunVal;
                                   inc(J);
                                 end;
                        end;
                   end;
     until (lCptPos >= lCompressSz) or (J >= lImageVoxels);
     //Second Pass: read HI bits
     lCptPos := lHiLosegmentOffset[1];
     J := 0;
     repeat
                   lCptVal := lCptBuff[lCptPos];
                   inc(lCptPos);
                   lShort := shortint(lCptVal);
                   case lShort of
                        -128: ;
                        0..127 : begin
                                 for i := 0  to lShort do begin
                                   if J < lImageVoxels then begin
                                      lRunVal := lCptBuff[lCptPos];
                                      lRunVal := lRunVal shl 8;
                                      lDecodedRA[J] := lRunVal+lDecodedRA[J];
                                   end;
                                   inc(J);
                                   inc(lCptPos);
                                 end;
                               end;
                        else begin
                             lCptVal := (-lShort);
                             lRunVal := lCptBuff[lCptPos];
                             lRunVal := lRunVal shl 8;
                             inc(lCptPos);
                             for i := 0  to lCptVal do begin
                                   if J < lImageVoxels then
                                      lDecodedRA[J] :=(lRunVal)+lDecodedRA[J];
                                   inc(J);
                                 end;
                        end;
                   end;
     until (lCptPos >= lCompressSz) or (J >= lImageVoxels);
     FreeMem(lCptBuff);
     lSz := lImageVoxels -1; //lDecodedRA indexed from 0
     I := 0;
     for J := 0 to lSz do begin
         lOutputBuffRGB[I]   := lrgbLUTra[1,lDecodedRA[J]];
         lOutputBuffRGB[I+1] := lrgbLUTra[2,lDecodedRA[J]];
         lOutputBuffRGB[I+2] := lrgbLUTra[3,lDecodedRA[J]];
         I := I + 3;
     end;
     FreeMem(lDecodedRA);
end; //DecompressRLE16toRGB

end.
 