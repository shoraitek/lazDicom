unit Childwin;

interface
uses SysUtils, Windows, Classes, Graphics, Forms,
     Controls, ExtCtrls, StdCtrls, Buttons,ulazDicomDefineTypes,ulazDicomdicom,
     ComCtrls, Menus, Dialogs,ulazDicomdecompress,ulsJPEG,Clipbrd, ToolWin,uMultislice,ulazDicomanalyze;
const
     kRadCon = pi/180;
     kMaxECAT = 512;
     gMouseDown : boolean = false;
     gInc: integer = 0;
type
    palentries   = array[0..255] of TPaletteEntry;
    palindices   = array[0..255] of word;
    TMDIChild = class(TForm)
    MainMenu1: TMainMenu;
    OptionsSettingsMenu: TMenuItem;
    OptionsImgInfoItem: TMenuItem;
    N2: TMenuItem;
    Lowerslice1: TMenuItem;
    Higherslice1: TMenuItem;
    SelectZoom1: TMenuItem;
    ContrastAutobalance1: TMenuItem;
    ScrollBox1: TScrollBox;
    Image: TImage;
    Memo1: TMemo;
    CopyItem: TMenuItem;
    EditMenu: TMenuItem;
    Timer1: TTimer;
    StudyMenu: TMenuItem;
    Previous1: TMenuItem;
    Next1: TMenuItem;
    Mosaic1: TMenuItem;
    N1x11: TMenuItem;
    N2x21: TMenuItem;
    N3x31: TMenuItem;
    N4x41: TMenuItem;
    Other1: TMenuItem;
    Smooth1: TMenuItem;
    Overlay1: TMenuItem;
    None1: TMenuItem;
    White1: TMenuItem;
    Black1: TMenuItem;
    ContrastSuggested1: TMenuItem;
    ContrastCTPresets1: TMenuItem;
    Bone1: TMenuItem;
    Chest1: TMenuItem;
    Lung1: TMenuItem;
    //procedure decompressJPEG24x (lFilename: string; var lOutputBuff: ByteP0; lImageVoxels,lImageStart{gECATposra[lSlice]}: integer);

    procedure RescaleInit;
    procedure RescaleClear;
    function RescaleFromBuffer(lIn:integer):integer;
    function RescaleToBuffer(lIn:integer):integer;
    procedure FreeBackupBitmap;
    procedure UpdatePalette (lApply: boolean; lWid0ForSlope:integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FileOpenItemClick(Sender: TObject);
    procedure FileExitItemClick(Sender: TObject);
    procedure OptionsImgInfoItemClick(Sender: TObject);
    procedure FileOpenpicture1Click(Sender: TObject);
    procedure Lowerslice1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure LoadColorScheme(lStr: string; lScheme: integer);
    procedure DetermineZoom;
    procedure AutoMaximise;
    procedure ImageMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ImageMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ImageMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SelectZoom1Click(Sender: TObject);
    procedure ContrastAutobalance1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure CopyItemClick(Sender: TObject);
    procedure DICOMImageRefreshAndSize;
    procedure SetDimension(lInPGHt,lInPGWid ,lInBits:integer; lInBuff: ByteP0; lUseWinCenWid: boolean);
    procedure Scale16to8bit(lWinCen,lWinWid: integer);
    function VxlVal(X,Y: integer; lRGB_greenOnly: boolean):integer;
    procedure Vxl(X,Y: integer);
    procedure Timer1Timer(Sender: TObject);
    procedure Previous1Click(Sender: TObject);
    procedure N1x11Click(Sender: TObject);
    procedure Smooth1Click(Sender: TObject);
    procedure None1Click(Sender: TObject);
    procedure ContrastSuggested1Click(Sender: TObject);
    procedure CTpreset(Sender: TObject);
  private
    { Private declarations }
      FLastDown,gSelectOrigin: TPoint;
     // gMagRect,gSelectRect: TRect;
    FFileName,gFilePath     : string;
    gRra,gGra,gBra: array [0..255] of byte;
    gECATslices: integer;
    gECATposra,gECATszra: array[1..kMaxECAT] of longint;
    gDynStr: string;
    gAbort: boolean;
  public
    BackupBitmap: TBitmap;
    gSelectRect,gMagRect,gLine: TRect;
    gLineLenMM: double;
    gMultiFirst,gMultiLast,gMultiRow,gMultiCol,g100pctImageWid, g100pctImageHt{,gMaxRGB,gMinRGB,gMinHt,gMinWid}: integer;
    gFastCheck,gSmooth,gImgOK,FDICOM: boolean;
    gBuff16: SmallIntP0;
    gBuff8,gBuff24: Bytep0;
    gDicomData: DIcomData;
    gIntenScaleInt,gIntenInterceptInt :integer;
    gIntRescale :boolean;
    gStringList : TStringList;
    gVideoSpeed,gBuff24sz,gBuff8sz, gBuff16sz,gCustomPalette: integer;
    //gRaw16Min,gRaw16Max,
    gFileListSz,gCurrentPosInFileList,gWinCen,gWinWid,gSlice,gnSLice,gXStart,gStartSlope,gStartCen,gYStart,gImgMin,gImgMax,gImgCen,gImgWid,gWinMin,gWinMax,gWHite,gBlack,gScheme,gZoomPct,gPro,gScale: integer;
    gContrastStr: string;
    gFastSlope,gFastCen : integer;
    { Public declarations }
    procedure OverlayData;
    function  LoadData( lFileName : string; lAnalyze,lECAT,l2dImage,lRaw: boolean ) : Boolean;
    procedure LoadFileList;
    procedure ReleaseDICOMmemory;
    procedure DisplayImage(lUpdateCon,lForceDraw: boolean; lSlice,lInWinWid,lInWincen: integer);
    procedure HdrShow;
    procedure RefreshZoom;
    PROCEDURE ShowMagnifier (CONST X,Y:  INTEGER);//requires backup bitmap
  end;
var
   MDIChild : TMDIChild;


implementation

uses Main;

var
gMaxRGB,gMinRGB,gMinHt,gMinWid: integer;
{$R *.LFM}

procedure TMDIChild.OverlayData;
//Overlays Text onto the image reporting image brightness/contrast
var lZOomPct,lMultiSlice,lRowPos,lColPos,lDiv,lFOntSpacing,lSpace,lRow,lSlice,lCol: integer;
lMultiSliceInc : single;
begin
     if None1.checked then exit;
     if gSmooth then
        lZoomPct := gZoomPct
     else
         lZoomPct := 100;
     if gMultiCol > 0 then
        lDiv := gMultiCol
     else
         lDiv := 1;
     case (image.Picture.Width div lDiv) of
          0..63: lFontSpacing := 8;
          64..127: lFontSpacing := 8;//9;
          128..255: lFontSpacing := 9;//10;
          256..511: lFontSpacing := 10;//12;
          512..767: lFontSpacing := 12;//14;
          else lFontSpacing := 14;//26;
     end;
     Image.Canvas.Font.Name := 'MS Sans Serif';
     Image.Canvas.Brush.Style := bsClear;
     Image.Canvas.Font.Size := lFontSpacing;
     if White1.Checked then
              Image.Canvas.Font.Color := gMaxRGB
     else
              Image.Canvas.Font.Color := gMinRGB;
     if ((gMultiRow > 1) or (gMultiCol > 1)) and (gMultiROw > 0) and (gMultiCol > 0) then begin
               lMultiSliceInc := (gMultiLast -gMultiFirst) / ((gMultiRow * gMultiCol)-1);
               if lMultiSliceInc < 1 then
                  lMultiSliceInc := 1;
               lMultiSlice := 0;
               for lRow := 0 to (gMultiRow-1)  do begin
                   lRowPos := 6+(lROw * (((gDICOMdata.XYZdim[2] )* lZoomPct) div 100 ));
                   for lCol := 0 to (gMultiCOl-1)  do begin
                       lColPos :=6+ (lCol * (((gDICOMdata.XYZdim[1] )* lZoomPct) div 100 ));
                       lSlice := gMultiFirst+round (lMultiSliceInc*(lMultiSlice))-1;
                       //showmessage(inttostr(lColPos)+':'+inttostr(lROwPos));
                       if (gDicomData.XYZdim[3] > 1) then begin
                          if (lSLice < gDicomData.XYZdim[3]) then begin
                            if (lRow=0) and (lCol=0) then
                             Image.Canvas.TextOut(lColPos,lROwPos,inttostr(lSlice+1)+':'+extractfilename(ffilename))
                            else
                             Image.Canvas.TextOut(lColPos,lROwPos,inttostr(lSlice+1))

                          end
                       end else if (lSlice < gFileListSz) and (lSlice >= 0) then
                            Image.Canvas.TextOut(lColPos,lRowPos,inttostr(lSlice+1)+':'+(gStringList.Strings[lSlice]));
                       inc(lMultiSlice);
                   end;//for lROw
               end; //for lCol.
     end else //not multislice mosaic
               Image.Canvas.TextOut(6,6,extractfilename(FFilename));
     lSpace := 6+2+lFontSpacing;
              Image.Canvas.TextOut(6,lSpace,'C: '+inttostr(gWinCen));
              lSpace :=lSpace+ 2+lFontSpacing;
              Image.Canvas.TextOut(6,lSpace,'W: '+inttostr(gWinWid));
  end;



procedure TMDIChild.RefreshZoom;
//redraws the image to the correct size, minimizes flicker
begin
  LockWindowUpdate(Self.Handle);
  if gBuff24sz > 0 then
        SetDimension(g100pctImageHt,g100pctImageWid,24,gBuff24,false)
  else if gBuff16sz > 0 then
         Scale16to8bit( Self.gWinCen, Self.gWinWid)
  else if  (gBuff8sz > 0) then begin
       SetDimension(g100pctImageHt,g100pctImageWid,8,gBuff8,true);
  end else begin
       MainForm.StatusBar.Panels[1].text := inttostr(gZoomPct)+'%';
       image.Height:= round((image.Picture.Height * gZoomPct) div 100);
       image.Width := round((image.Picture.Width* gZoomPct) div 100) ;
       IMage.refresh;
       LockWindowUpdate(0);
       exit;
  end;
  if gDicomData.Allocbits_per_pixel < 9 then begin
     if (gWinWid >= maxint)  then begin
               gContrastStr := 'Window Cen/Wid: '+inttostr(gWinCen)+'/inf';
     end else begin
                gContrastStr := 'Window Cen/Wid: '+inttostr(gWinCen)+'/'+inttostr(gWinWid)
     end;
  end;
  MainForm.StatusBar.Panels[1].text := inttostr(gZoomPct)+'%';
  DICOMImageRefreshAndSize;
  LockWindowUpdate(0);
end;

procedure TMDIChild.DICOMImageRefreshAndSize;
//Checks image scale and redraws the image
begin
  if gSmooth then begin
     image.Height:= image.Picture.Height;
     image.Width := image.Picture.Width ;
  end else begin
       image.Height:= round((image.Picture.Height * gZoomPct) div 100);
       image.Width := round((image.Picture.Width* gZoomPct) div 100) ;
  end;
  OverlayData;
  Image.refresh;
end;

procedure TMDIChild.FreeBackupBitmap;
//release dynamic memory used for magnifying glass
begin
     if BackupBItmap <> nil then begin
        Backupbitmap.free;
        Backupbitmap := nil;
     end;
     gMagRect := Rect(0,0,0,0);
end;

procedure   TMDIChild.ReleaseDICOMmemory;
//release dynamic memory allocation
begin
  FreeBackupBitmap;
  if (gBuff24sz > 0) then begin
     freemem(gBuff24);
     gBuff24sz := 0;
  end;
  if (gBuff16sz > 0) then begin
     freemem(gBuff16);
     gBuff16sz := 0;
  end;
  if (gBuff8sz > 0) then begin
     freemem(gBuff8);
     gBuff8sz := 0;
  end;
     if red_table_size > 0 then begin
        freemem(red_table);
        red_table_size := 0;
     end;
     if green_table_size > 0 then begin
        freemem(green_table);
        green_table_size := 0;
     end;
     if blue_table_size > 0 then begin
        freemem(blue_table);
        blue_table_size := 0;
     end;
     gCustomPalette := 0;
     gECATslices:= 0;
end;

procedure ShellSort (first, last: integer; var lPositionRA{,lIndexRA}: longintP; lIndexRA: DWordP; var lRepeatedValues: boolean);
{Shell sort chuck uses this- see 'Numerical Recipes in C' for similar sorts.}
{less memory intensive than recursive quicksort}
label
     555;
const
     tiny = 1.0e-5;
     aln2i = 1.442695022;
var
   n,t, nn, m, lognb2, l, k, j, i, s: INTEGER;
begin
     lRepeatedValues := false;
     n := abs(last - first + 1);
     lognb2 := trunc(ln(n) * aln2i + tiny);
     m := last;
     for nn := 1 to lognb2 do
         begin
              m := m div 2;
              k := last - m;
              for j := 1 to k do begin
                  i := j;
                  555: {<- LABEL}
                  l := i + m;
                  if lIndexRA[lPositionRA[l]] = lIndexRA[lPositionRA[i]] then begin

                      //showmessage(inttostr(lIndexRA[lPositionRA[l]] shr 24 and 255 )+'-'+inttostr(lIndexRA[lPositionRA[l]] shr 16 and 255 )+'-'+inttostr(lIndexRA[lPositionRA[l]] and 65535 ) );
                      lRepeatedValues := true;
                      exit;
                  end;
                  if lIndexRA[lPositionRA[l]] < lIndexRA[lPositionRA[i]] then begin
                     //swap values for i and l
                     t := lPositionRA[i];
                     lPositionRA[i] := lPositionRA[l];
                     lPositionRA[l] := t;
                     i := i - m;
                     if (i >= 1) then
                        goto 555;
                  end
              end
         end
     end;           (**)

procedure TMDIChild.LoadFileList;
//Searches for other DICOM images in the same folder (so user can cycle through images
var
  lSearchRec: TSearchRec;
  lName,lFilenameWOPath,lExt : string;
  lSz,lDICMcode: integer;
  lDICM: boolean;
  FP: file;
  lIndex: DWord;
  lInc,lItems: longint;//vixen
  lDicomData: DicomData; //vixen
  lRepeatedValues,lHdrOK,lImgOK: boolean; //vixen
  lFilename,lDynStr,lFoldername: String;//vixen
  lStringList : TStringList; //vixen
  lTimeD:DWord;
    lIndexRA: DWordP;
  lPositionRA{,lIndexRA}: longintP;//vixen
begin
     lFilenameWOPath := extractfilename(FFilename);
     lExt := ExtractFileExt(FFileName);
     if length(lExt) > 0 then
        for lSz := 1 to length(lExt) do
            lExt[lSz] := upcase(lExt[lSz]);
 if (gDicomData.NamePos > 0) then begin //real DICOM file
     if FindFirst(gFilePath+'*.*', faAnyFile-faSysFile-faDirectory, lSearchRec) = 0 then begin
        repeat
              lExt := AnsiUpperCase(extractfileext(lSearchRec.Name));
              lName := AnsiUpperCase(lSearchRec.name);
              if (lSearchRec.Size > 1024)and (lName <> 'DICOMDIR') then begin
                 lDICM := false;
                 if ('.DCM' = lExt) then lDICM := true;
                 if ('.DCM'<>  lExt) then begin
                    Filemode := 0;
                    AssignFile(fp, gFilePath+lSearchRec.Name);
                    try
                       Filemode := 0; //read only - might be CD
                       Reset(fp, 1);
                       Seek(FP,128);
                       BlockRead(fp, lDICMcode, 4);
                       if lDICMcode = 1296255300 then lDICM := true;
                    finally
                       CloseFile(fp);
                    end; //try..finally open file
                    Filemode := 2; //read/write
                 end; //Ext <> DCM
                 if lDICM then
                    gStringList.Add(lSearchRec.Name);{}
              end; //FileSize > 512
        until (FindNext(lSearchRec) <> 0);
        Filemode := 2;
     end; //some files found
     SysUtils.FindClose(lSearchRec);
     if gStringlist.Count > 0 then begin
        {start vixen}
        lItems := gStringlist.Count;
        getmem(lIndexRA,lItems*sizeof({longint}DWord));
        getmem(lPositionRA,lItems*sizeof(longint));
        lFolderName := extractfiledir(FFilename);
        lTimeD := GetTickCount;
        for lInc := 1 to lItems do begin
            lFilename := lFolderName+pathdelim+gStringList.Strings[lInc-1];
            //showmessage(lFilename);
            read_dicom_data({true}false,false{not verbose},true,true,true,true,false, lDICOMdata, lHdrOK, lImgOK, lDynStr,lFileName );
            //if lDicomData.SiemensMosaicX <> 1 then showmessage(lFilename+' '+inttostr(lDicomData.SiemensMosaicX));
            application.ProcessMessages;

            lIndex := ((lDicomData.PatientIDInt and 65535) shl 32)+((lDicomData.SeriesNum and 255) shl 24)+((lDicomData.AcquNum and 255) shl 16) +lDicomData.ImageNum;
            lIndexRA[lInc] := lIndex;
            lPositionRA[lInc] := lInc;
        end;
        lTimeD := GetTickCount-lTimeD; //70 ms
       // Showmessage(inttostr(lItems)+'  '+inttostr(lTimeD)+'x');


        ShellSort (1, lItems,lPositionRA,lIndexRA, lRepeatedValues);
        //for lInc := 1 to lItems do
        //showmessage(inttostr(lPositionRA[lInc])+' = ' +  inttostr(lIndexRA[lPositionRA[lInc]]));

        if not lRepeatedValues then begin
           lStringList := TStringList.Create;
           for lInc := 1 to lItems do
            lStringList.Add(gStringList[lPositionRA[lInc]-1]);
            //[lInc-1] := gStringList[lPositionRA[lInc]-1]; //place items in correct order
           for lInc := 1 to lItems do
               gStringList[lInc-1] := lStringList[lInc-1]; //put sorted items into correct list
           lStringList.Free;
        end else
            gStringlist.Sort; //repeated index - sort name by filename instead
        //sort stringlist based on indexRA
        freemem(lPositionRA);
        freemem(lIndexRA);
        {end vixen}
        for lSz := (gStringList.count-1) downto 0 do begin
            if gStringList.Strings[lSz] = lFilenameWOPath then gCurrentPosInFileList := lSz;
        end;
     end;
     gFileListSz := gStringList.count;
  end; //NamePos > 0    *)
  if (gStringlist.Count > 1) then begin
      StudyMenu.enabled := true;
  end;
end;(**)


(*old primitive->
procedure TMDIChild.LoadFileList;
//Searches for other DICOM images in the same folder (so user can cycle through images
var
  lSearchRec: TSearchRec;
  lName,lFilenameWOPath,lExt : string;
  lSz,lDICMcode: integer;
  lDICM: boolean;
     FP: file;
begin
     lFilenameWOPath := extractfilename(FFilename);
     lExt := ExtractFileExt(FFileName);
     if length(lExt) > 0 then
        for lSz := 1 to length(lExt) do
            lExt[lSz] := upcase(lExt[lSz]);
 if (gDicomData.NamePos > 0) then begin //real DICOM file
     if FindFirst(gFilePath+'*.*', faAnyFile-faSysFile-faDirectory, lSearchRec) = 0 then begin
        repeat
              lExt := AnsiUpperCase(extractfileext(lSearchRec.Name));
              lName := AnsiUpperCase(lSearchRec.name);
              if (lSearchRec.Size > 1024)and (lName <> 'DICOMDIR') then begin
                 lDICM := false;
                 if ('.DCM' = lExt) then lDICM := true;
                 if ('.DCM'<>  lExt) then begin
                    Filemode := 0;
                    AssignFile(fp, gFilePath+lSearchRec.Name);
                    Filemode := 0; //read only - might be CD
                    Reset(fp, 1);
                    Seek(FP,128);
                    BlockRead(fp, lDICMcode, 4);
                    if lDICMcode = 1296255300 then lDICM := true;
                    CloseFile(fp);
                    Filemode := 2; //read/write
                 end; //Ext <> DCM
                 if lDICM then
                    gStringList.Add(lSearchRec.Name);{}
              end; //FileSize > 512
        until (FindNext(lSearchRec) <> 0);
        Filemode := 2;
     end; //some files found
     SysUtils.FindClose(lSearchRec);
     gStringlist.Sort;
     if gStringlist.Count > 0 then begin
        for lSz := (gStringList.count-1) downto 0 do begin
            if gStringList.Strings[lSz] = lFilenameWOPath then gCurrentPosInFileList := lSz;
        end;
     end;
     gFileListSz := gStringList.count;
  end; //NamePos > 0    *)
(*  if (gStringlist.Count > 1) then begin
      StudyMenu.enabled := true;
  end;
end; *)

procedure TMDIChild.RescaleClear;
//resets slope/intercept for image brightness/contrast (e.g. to convert stored image intensity to Hounsfield units)
begin
     gIntenScaleInt := 1;
     gIntenInterceptInt := 0;
     gIntRescale := true;
end;

procedure TMDIChild.RescaleInit;
//updates slope/intercept for image brightness/contrast (e.g. to convert stored image intensity to Hounsfield units)
var lS,lI: single;
 lSi, lIi: integer;
begin
     RescaleClear;
     if gDICOMdata.IntenScale = 0 then
        gDICOMdata.IntenScale := 1;
     lS := gDICOMdata.IntenScale;
     lI := gDICOMdata.IntenIntercept;
     lSi := round(lS);
     lIi := round(lI);
     if (lS=lSi) and (lI=lIi) then begin
        gIntenScaleInt := lSi;
        gIntenInterceptInt := lIi;
        gIntRescale := true;
     end else
         gIntRescale := false;
end;

function TMDIChild.RescaleFromBuffer(lIn:integer):integer;
//converts image brightness to Hounsfield units using Slope and Intercept
// Output := (StoredImageIntensity*Slope)+zero_intercpet
begin
     if gIntRescale then
        result := round((lIn*gIntenScaleInt)+ gIntenInterceptInt)
     else
          result := round((lIn*gDICOMdata.IntenScale)+ gDICOMdata.intenIntercept);

end;

function TMDIChild.RescaleToBuffer(lIn:integer):integer;
//converts Hounsfield units to Stored image intensity using Slope and Intercept
// Output := (HounsfieldUnit / Slope)-zero_intercpet
begin
     result := round((lIn- gDICOMdata.intenIntercept)/gDICOMdata.IntenScale);//ChayMarch2003
//     result := round((lIn/gDICOMdata.IntenScale)- gDICOMdata.intenIntercept);
end;

procedure TMDIChild.Scale16to8bit(lWinCen,lWinWid: integer);
//Given a 16-bit input, this generates an 8-bit output, based on user's contrast/brightness settings
//Uses integer multiplication for fast computations on old CPUs
var
  lStartTime, lEndTime: DWord;
   lRngi,lMinVal,lMaxVal,lInt,lInc,lRange,i,lScaleShl10,lSz,min16,max16,lCen,lWid  :integer;
    lBuff: bytep0;
   lBuffx: ByteP0;
begin
     //MainForm.StatusBar.Panels[3].text := 'ax'+inttostr(random(888));

  if gBuff16 = nil then exit;
  gWinCen := lWinCen;
  gWinWid := lWinWid;
  if Self.Active then begin
     gContrastStr := 'Window Center/Width: '+inttostr(lWinCen)+'/'+inttostr(lWinWid){+':'+inttostr(round(lSlopeReal))};
     MainForm.StatusBar.Panels[4].text := gContrastStr;

     //gContrastStr := 'ABBA: '+floattostr(gDICOMdata.IntenIntercept)+'/'+floattostr(gDICOMdata.IntenScale){+':'+inttostr(round(lSlopeReal))};
     //MainForm.StatusBar.Panels[3].text := gContrastStr;

  end;
  //showmessage(floattostr(gDICOMdata.Intenscale));
  //gDICOMdata.Intenscale := 1;

  lCen := RescaleToBuffer(lWinCen);
  //showmessage(inttostr(lWinCen));
  lWid := abs(trunc((lWinWid/ gDICOMdata.IntenScale) /2));
  min16 := lCen - lWid;
  max16 := lCen + lWid;
  gWinMin := min16;
  gWinMax := max16;
  lSz:= (g100pctImageWid*g100pctImageHt);
  GetMem( lbuffx,lSz {width * height});
  lSz := lSz -1;
  lRange := (max16-min16);
  //MainForm.StatusBar.Panels[0].text := inttostr(value)+'tx'+inttostr(random(888));
  lStartTime := GetTickCount;
  //value = range
  if (lRange = 0) or (trunc((1024/lRange) * 255) = 0) then begin
      if lWinWid > 1024 then begin
         for i := 0 to lSz do
          lbuffx[i] := 128;

      end else begin
      for i := 0 to lSz do
          if gBuff16[i] < lWinCen then
             lbuffx[i] := 0
          else
               lbuffx[i] := 255;
      end;
  end else begin
      lScaleShl10 := trunc((1024/lRange) * 255); //value = range,Scale = 255/range
    (*
    if lSz > 131070  then begin //large image: make a look up table  x2 speedup
    //Using this code speeds up rescaling slightly, but not well tested...
               lMinVal := RescaleToBuffer(gImgMin)-1; //gRaw16Min;//
               lMaxVal := RescaleToBuffer(gImgMax)+1; //gRaw16Max;//
               lRngi := ROund(lMaxVal-lMinVal);
               getmem(lBuff, lRngi+1);  //+1 if the only values are 0,1,2 the range is 2, but there are 3 values!
               //max16 := max16-2;
               for lInc := (lRngi) downto 0 do begin
                   lInt := lInc+lMinVal; //32 bit math fastest
                    if lInt < min16 then
                        lBuff[lInc] := 0 //0
                   else if lInt > max16 then
                        lBuff[lInc] := 255
                   else
                       lBuff[lInc] :=  (((lInt)-min16) * lScaleShl10)  shr 10;
               end;
               lInc := 1;
               for i := 0 to lSz do
                   lbuffx[i] := lBuff[gBuff16[i]-lMinVal] ;
               freemem(lBuff);
    end else*) begin //if lSz -> use look up table for large images
      for i := 0 to lSz do begin
          if gBuff16[i] < min16 then
             lbuffx[i] := 0
          else if gBuff16[i] > max16 then
               lbuffx[i] := 255
          else
              lbuffx[i] := (((gBuff16[i])-min16) * lScaleShl10)  shr 10;
            //NOTE: integer maths increases speed x7!
            //  	    lbuff[i] := (Trunc(255*((gBuff16[i])-min16) / (value)));
      end;
    end; //if lSz ,,large image  .. else ...
  end; //lRange > 0
  //self.caption :=('update(ms): '+inttostr(GetTickCount-lStartTime)); //70 ms
  SetDimension(g100pctImageHt,g100pctImageWid,8,lBuffx,false);
  DICOMImageRefreshAndSize;
  FreeMem( lbuffx );
end;



function TMDIChild.VxlVal (X,Y: integer; lRGB_greenOnly: boolean): integer;
//Reports the intensity of a voxel at location X/Y
//If lRGB_greenOnly = TRUE, then the RRGGBB value #112233 will be #22 (useful for estimating approximate brightness at a voxel
//If lRGB_greenOnly = TRUE, then the RRGGBB value #112233 will be #112233 (actual RGB value)
var
   lVxl,lVxl24: integer;
begin
  RESULT := 0;
  lVxl := (Y* g100PctImageWid) +X; //rel20 Wid not Ht
  lVxl24 := (Y* g100PctImageWid*3) +(X * 3);
  if (gBuff16Sz > 0) and (lVxl >= 0) and (lVxl < gBuff16Sz) then
     result := RescaleFromBuffer(gBuff16[lVxl])
  else if (gBuff8sz > 0) and (lVxl >= 0) and (lVxl < gBuff8Sz) then
     result := gbuff8[lVxl]
  else if (gBuff24Sz > 0) and (lVxl24 >= 0) and (lVxl24 < gBuff24Sz) then begin
     if lRGB_greenOnly then
         result := (gbuff24[lVxl24+1]){green}
     else
         result := gbuff24[lVxl24+2]{blue}+(gbuff24[lVxl24+1] shl 8){green}+(gbuff24[lVxl24] shl 16){red};
  end;
end;

procedure TMDIChild.Vxl (X,Y: integer);
//Reports Brightness of voxel under the cursor
begin
  if (gBuff8sz > 0) or (gBuff16sz > 0) then
     MainForm.StatusBar.Panels[0].text := inttostr(VxlVal(X,Y,false))
  else if (gBuff24sz > 0) then
     MainForm.StatusBar.Panels[0].text :='#'+ Format('%*.*x', [6, 6, VxlVal(X,Y,false)])
  else
      MainForm.StatusBar.Panels[0].text := '';
end;
     
procedure TMDIChild.SetDimension(lInPGHt,lInPGWid ,lInBits:integer; lInBuff: ByteP0; lUseWinCenWid: boolean);
//Draws a graphic using the values in lInBuff
//Contains the nested procedure ScaleStretch, that resizes the image using linear interpolation (minimizing jaggies)
var
  lBuff: ByteP0;
  lPGwid,lPGHt,lBits: integer;
procedure ScaleStretch(lSrcHt,lSrcWid: integer; lInXYRatio: single);
var
lKScale: byte;
lrRA,lbRA,lgRA: array [0..255] of byte;
  //lBuff: ByteP0;
  lPos,xP,yP,yP2,xP2,t,z, z2,iz2,w1,w2,w3,w4,lTopPos,lBotPos,
  lINSz,  lDstWidM,{lDstWid,lDstHt,}x,y,lLT,lLB,lRT,lRB: integer;
    lXRatio,lYRatio: single;
  begin
  yP:=0;
  lXRatio := lInXYRatio;
  lYRatio := lInXYRatio;
  lInSz := lSrcWid *lSrcHt;
  lPGwid := {round}round(lSrcWid*lXRatio);//*lZoom;
  lPGHt := {round}round(lSrcHt*lYRatio);//*lZoom;
  lkScale := 1;
  xP2:=((lSrcWid-1)shl 15)div (lPGWid -1 );
  yP2:=((lSrcHt-1)shl 15)div (lPGHt -1);
  lPos := 0;
  lDstWidM := lPGWid - 1;
if lBIts = 24 then begin
  getmem(lBuff, lPGHt*lPGWid*3);
  lInSz := lInSz * 3; //24bytesperpixel
  for y:=0 to lPGHt-1 do begin
      xP:= 0;
      lTopPos:=lSrcWid *(yP shr 15) *3; //top row
      if yP shr 16<lSrcHt-1 then
         lBotPos:=lSrcWid *(yP shr 15+1) *3 //bottom column
      else
          lBotPos:=lTopPos;
      z2:=yP and $7FFF;
      iz2:=$8000-z2;
      x := 0;
      while x < lPGWid do begin
        t:=(xP shr 15) * 3;
        if ((lBotPos+t+6) > lInSz) or ((lTopPos+t) < 0) then begin
           lBuff[lPos] :=0; inc(lPos); //reds
           lBuff[lPos] :=0; inc(lPos); //greens
           lBuff[lPos] :=0; inc(lPos); //blues
        end else begin
            z:=xP and $7FFF;
            w2:=(z*iz2)shr 15;
            w1:=iz2-w2;
            w4:=(z*z2)shr 15;
            w3:=z2-w4;
            lBuff[lPos] :=(lInBuff[lTopPos+t]*w1+lInBuff[lTopPos+t+3]*w2
            +lInBuff[lBotPos+t]*w3+lInBuff[lBotPos+t+3]*w4)shr 15;
            inc(lPos); //reds
            lBuff[lPos] :=(lInBuff[lTopPos+t+1]*w1+lInBuff[lTopPos+t+4]*w2
            +lInBuff[lBotPos+t+1]*w3+lInBuff[lBotPos+t+4]*w4)shr 15;
            inc(lPos); //greens
            lBuff[lPos] :=(lInBuff[lTopPos+t+2]*w1+lInBuff[lTopPos+t+5]*w2
            +lInBuff[lBotPos+t+2]*w3+lInBuff[lBotPos+t+5]*w4)shr 15;
            inc(lPos); //blues
        end;
        Inc(xP,xP2);
        inc(x);
      end;   //inner loop
      Inc(yP,yP2);
    end;
end else if gCustomPalette > 0 then begin //<>24bits,custompal
   lBits := 24;
   for y := 0 to 255 do begin
    lrRA[y] := grRA[y];
    lgra[y] := ggRA[y]  ;
    lbra[y] := gbRA[y];
   end;
  getmem(lBuff, lPGHt*lPGWid*3);
  for y:=0 to lPGHt-1 do begin
      xP:= 0;
      lTopPos:=lSrcWid *(yP shr 15);  //Line1
      if yP shr 16<lSrcHt-1 then
         lBotPos:=lSrcWid *(yP shr 15+1)   //Line2
      else
          lBotPos:=lTopPos;//lSrcWid *(yP shr 15);
      z2:=yP and $7FFF;
      iz2:=$8000-z2;
      x := 0;
      while x < lPGWid do begin
        t:=xP shr 15;
      if ((lBotPos+t+2) > lInSz) or ((lTopPos+t{-1}) < 0) then begin
        lLT := 0;
        lRT := 0;
        lLB := 0;
        lRB := 0;
      end else begin
        lLT := lInBuff[lTopPos+t];
        lRT := lInBuff[lTopPos+t+1];
        lLB := lInBuff[lBotPos+t];
        lRB := lInBuff[lBotPos+t+1];
      end;
        z:=xP and $7FFF;
        w2:=(z*iz2)shr 15;
        w1:=iz2-w2;
        w4:=(z*z2)shr 15;
        w3:=z2-w4;
        lBuff[lPos] :=(lrRA[lLT]*w1+lrRA[lRT]*w2
        +lrRA[lLB]*w3+lrRA[lRB]*w4)shr 15;
        inc(lPos);
        lBuff[lPos] :=(lgRA[lLT]*w1+lgRA[lRT]*w2
        +lgRA[lLB]*w3+lgRA[lRB]*w4)shr 15;
        inc(lPos);
        lBuff[lPos] :=(lbRA[lLT]*w1+lbRA[lRT]*w2
        +lbRA[lLB]*w3+lbRA[lRB]*w4)shr 15;
        inc(lPos);
        Inc(xP,xP2);
        inc(x);
      end;   //inner loop
      Inc(yP,yP2);
    end;
end else begin //<>24bits,custompal
  getmem(lBuff, lPGHt*lPGWid{*3});
  for y:=0 to lPGHt-1 do begin
      xP:= 0;
      lTopPos:=lSrcWid *(yP shr 15);  //Line1
      if yP shr 16<lSrcHt-1 then
         lBotPos:=lSrcWid *(yP shr 15+1)   //Line2
      else
          lBotPos:=lTopPos;//lSrcWid *(yP shr 15);
      z2:=yP and $7FFF;
      iz2:=$8000-z2;
      //      for x:=0 to lDstWid-1 do begin
      x := 0;
      while x < lPGWid do begin
        t:=xP shr 15;
      if ((lBotPos+t+2) > lInSz) or ((lTopPos+t{-1}) < 0) then begin
        lLT := 0;
        lRT := 0;
        lLB := 0;
        lRB := 0;
      end else begin
        lLT := lInBuff[lTopPos+t{+1}];
        lRT := lInBuff[lTopPos+t{+2}+1];
        lLB := lInBuff[lBotPos+t{+1}];
        lRB := lInBuff[lBotPos+t{+2}+1];
      end;
        z:=xP and $7FFF;
        w2:=(z*iz2)shr 15;
        w1:=iz2-w2;
        w4:=(z*z2)shr 15;
        w3:=z2-w4;
        lBuff[lPos] :=(lLT*w1+lRT*w2
        +lLB*w3+lRB*w4)shr 15;
        inc(lPos);
        Inc(xP,xP2);
        inc(x);
      end;   //inner loop
      Inc(yP,yP2);
    end;
end;  //<>24bits,custompal
  end;
var
//lStartTime, lEndTime: DWord;
   lBufferUsed: boolean;
   PixMap: pointer;
   Bmp     : TBitmap;
   hBmp    : HBITMAP;
   BI      : PBitmapInfo;
   BIH     : TBitmapInfoHeader;
   lSlope,lScale: single;
   lPixmapInt,lBuffInt: integer ;
   ImagoDC : hDC;
   lByteRA: array[0..255] of byte;
   lRow:  pRGBTripleArray;
   lWinScaleShl16,
  lWinC,lWinW, lMinPal,lMaxPal,lL,lTemp,lHt,lWid,I,J,lScanLineSz,lScanLineSz8: integer;
begin
  gLine.Left := -666;
  gLineLenMM := 0;
 FreeBackupBitmap;
 lScale := gZoomPct / 100;
 lBits := lInBits;
 {rotate}
 

 if (lScale = 1) or (not gSmooth) then begin
     lPGWid := lInPGWid;
     lPGHt := lInPGHt;
     lBuff := @lInBuff^;
     lBufferUsed := false;
 end else begin
     lBufferUsed := true;
    ScaleStretch(lInPGHt,lInPGWid, lScale);
 end;
 if (lBits = 24) {or (lBits = 25)} then begin
   if ( Self.gDICOMdata.RLERedSz <> 0)  or ( Self.gDICOMdata.SamplesPerPixel > 1) or ( Self.gCustomPalette > 0) then begin
       lWinC := gWinCen;
       lWinW := gWinWid;
       //lStartTime := GetTickCount;
       if ((lWinC = 127) and (lWinW = 255)) or (lWinW = 0) then
         //scaling not required
       else begin
           if not lBufferUsed then begin
                getmem(lBuff, lPGHt*lPGWid*3);
                CopyMemory(Pointer(lBuff),Pointer(lInBuff),lPGHt*lPGWid*3);
                lBufferUsed := true;
           end;
           lWinScaleShl16 := 1 shl 16;
           lWinScaleShl16 := round (lWinScaleShl16*(256/lWinW));
           for lL := 0 to 255 do begin //lookup buffer for scaling
                lTemp := lL-lWinC;
                lTemp :=  (lTemp * lWinScaleShl16);
                lTemp := lTemp div 65536;
                lTemp := 128 +  lTemp;
                if lTemp < 0 then lTemp := 0
                else if lTemp > 255 then lTemp := 255;
                lByteRA[lL] := lTemp;
           end;
           J := (lPGWid * lPGHt * 3) -1;
            for lL := 0 to J do begin
                lBuff[lL] := lByteRA[lBuff[lL]];

            end;
       end; //scaling required
       //self.caption :=('update(ms): '+inttostr(GetTickCount-lStartTime)); //70 ms
   end;
        BMP := TBitmap.Create;
        lL := 0;
        TRY
           BMP.PixelFormat := pf24bit;
           BMP.Width := lPGwid;
           BMP.Height := lPGHt;
        if lBuff <> nil then begin
           //if VertFlipItem.checked then
           //   J := BMP.Height-1
           //else
              J := 0;
           REPEAT
             lRow := BMP.Scanline[j];
             (*if HorFlipItem.checked then begin
               FOR i := BMP.Width-1 downto 0 DO BEGIN
                   WITH lRow[i] DO BEGIN
                     rgbtRed    := lBuff[lL];
                     inc(lL);
                     rgbtGreen := lBuff[lL];
                     inc(lL);
                     rgbtBlue  := lBuff[lL];
                     inc(lL);
                  END //with row
               END;  //for width
             end else begin //horflip {*)
               FOR i := 0 TO BMP.Width-1 DO BEGIN
                   WITH lRow[i] DO BEGIN
                     rgbtRed    := lBuff[lL];
                     inc(lL);
                     rgbtGreen := lBuff[lL];
                     inc(lL);
                     rgbtBlue  := lBuff[lL];
                     inc(lL);
                   END //with row
               END;  //for width
             //end; //horflip
               //if VertFlipItem.checked then
               //   Dec(J)
               //else
                  Inc(J)
           UNTIL (J < 0) or (J >= BMP.Height); //for J
        end;
           Image.Picture.Graphic := BMP;
        FINALLY
               BMP.Free;
        END;
        if (lBufferUsed) then //alpha1415ABBA: required
           freemem(lBuff);
        exit;
     end;  //24bit
     BIH.biSize:= Sizeof(BIH);
     BIH.biWidth:= lPGwid;
     BIH.biHeight := lPGHt;
     BIH.biPlanes  := 1;
     BIH.biBitCount := 8;//lBits
     BIH.biCompression 	:= BI_RGB;
     BIH.biSizeImage := 0;
     BIH.biXPelsPerMeter := 0;
     BIH.biYPelsPerMeter := 0;
     BIH.biClrUsed       := 0;
     BIH.biClrImportant  := 0;
     {$P+,S-,W-,R-}
     BI := AllocMem(SizeOf(TBitmapInfoHeader) + 256*Sizeof(TRGBQuad));
     BI^.bmiHeader := BIH;
      if ( Self.gCustomPalette > 0) and (gWinWid > 0) then begin
         lWinC := gWinCen;
         lWinW := gWinWid;
           lWinScaleShl16 := 1 shl 16;
           lWinScaleShl16 := round (lWinScaleShl16*(256/lWinW));
           for lL := 0 to 255 do begin
                lTemp := gRra[lL]-lWinC;
                lTemp :=  (lTemp * lWinScaleShl16);
                lTemp := lTemp div 65536;
                lTemp := 128 +  lTemp;
                if lTemp < 0 then lTemp := 0
                else if lTemp > 255 then lTemp := 255;
                BI^.bmiColors[lL].rgbRed     := lTemp;
                lTemp := gGra[lL]-lWinC;
                lTemp :=  (lTemp * lWinScaleShl16);
                lTemp := lTemp div 65536;
                lTemp := 128 +  lTemp;
                if lTemp < 0 then lTemp := 0
                else if lTemp > 255 then lTemp := 255;
                BI^.bmiColors[lL].rgbGreen    := lTemp;
                lTemp := gBra[lL]-lWinC;
                lTemp :=  (lTemp * lWinScaleShl16);
                lTemp := lTemp div 65536;
                lTemp := 128 +  lTemp;
                if lTemp < 0 then lTemp := 0
                else if lTemp > 255 then lTemp := 255;
                BI^.bmiColors[lL].rgbBlue      := lTemp;
                BI^.bmiColors[lL].rgbReserved := 0;
            end;
      end else if (lUseWinCenWid) and (gWinWid > 0) then begin
        lMinPal := gWinCen - (gWinWid shr 1);
        lMaxPal := lMinPal + gWinWid;
        lSlope := 255 / gWinWid;
        if (lMinPal < 0) or (lMinPal > 255) then
           lMinPal := 0;
        if (lMaxPal < 0) or (lMaxPal > 255) then
           lMaxPal := 255;
        for I := 0 to lMinPal do begin
                BI^.bmiColors[I].rgbRed     := gRra[0];
                BI^.bmiColors[I].rgbGreen    := gGra[0];
                BI^.bmiColors[I].rgbBlue      := gBra[0];
                BI^.bmiColors[I].rgbReserved := 0;
        end;
        for I := lMaxPal to 255 do begin
                BI^.bmiColors[I].rgbRed     := gRra[255];
                BI^.bmiColors[I].rgbGreen    := gGra[255];
                BI^.bmiColors[I].rgbBlue      := gBra[255];
                BI^.bmiColors[I].rgbReserved := 0;
        end;
        if (lMinPal+1) < (lMaxPal) then begin
            for I := (lMinPal+1) to (lMaxPal-1) do begin
                J := 128+round(lSLope*(I-gWinCen));
                if J < 0 then J := 0
                else if J > 255 then J := 255;
                BI^.bmiColors[I].rgbRed     := gRra[J];
                BI^.bmiColors[I].rgbGreen    := gGra[J];
                BI^.bmiColors[I].rgbBlue      := gBra[J];
                BI^.bmiColors[I].rgbReserved := 0;
            end;
        end;
     end else begin //use wincen/wid
       for I:=0 to 255 do begin
             BI^.bmiColors[I].rgbRed     := gRra[i];
             BI^.bmiColors[I].rgbGreen    := gGra[i];
             BI^.bmiColors[I].rgbBlue      := gBra[i];
             BI^.bmiColors[I].rgbReserved := 0;
       end;
     end; //use wincen/wid
     Bmp        := TBitmap.Create;
     Bmp.Height := lPGHt{width};
     Bmp.Width  := lPGwid;
     ImagoDC := GetDC(Self.Handle);
     hBmp:= CreateDIBSection(imagodc,bi^,DIB_RGB_COLORS,pixmap,0,0);
     lScanLineSz := lPGwid;
     if(lPGwid mod 4) <> 0 then lScanLineSz8 := 4*((lPGWid + 3)div 4)
     else lScanLineSz8 := lPGwid;
     lHt := Bmp.Height-1;
     //lWid := lPGwid -1;
     {if (hBmp = 0) or (pixmap = nil) then
             if GetLastError = 0 then ShowMessage('Error!') else RaiseLastWin32Error;}
     if lBuff <> nil then begin
        {if HorFlipItem.checked then begin
           For i:= (lHt)  downto 0 do begin
               lPixMapInt := i * lScanLineSz;
               for j := (lWid shr 1) downto 0 do begin
                   lTemp :=lBuff[lPixMapInt+j];
                   lBuff[lPixMapInt+j] := lBuff[lPixMapInt+(lWid-j)];
                   lBuff[lPixMapInt+(lWid-j)] := lTemp;
               end;
           end; //i 0..lHt
        end; //horflip}
        lPixmapInt  := Integer(pixmap);
        lBuffInt := Integer(lBuff);
        {if VertFlipItem.checked then begin
           For i:= (lHt)  downto 0 do
               CopyMemory(Pointer(lPixmapInt+lScanLineSz8*(i)),
                     Pointer(lBuffInt+((i))*lScanLineSz),lScanLineSz);
        end else begin}
           For i:= (lHt)  downto 0 do
               CopyMemory(Pointer(lPixmapInt+lScanLineSz8*(i)),
                     Pointer(lBuffInt+((lHt-i))*lScanLineSz),lScanLineSz);
        {end; }
     end; //lBuff full
     ReleaseDC(0,ImagoDC);
     Bmp.Handle := hBmp;
     Bmp.ReleasePalette;

     Image.Picture.Assign(Bmp);
     Bmp.Free;
     FreeMem( BI);
     if (lBufferUsed) then begin
        freemem(lBuff);
     end;
     {$P-,S+,W+,R-}
end;

PROCEDURE TMDIChild.ShowMagnifier (CONST X,Y:  INTEGER);
//Shows a magnifier over one region of the image, saves old region a BackupBitmap
  VAR
    AreaRadius    :  INTEGER;
    Magnification :  INTEGER;
    xActual,yActual{,lMagArea}       :  INTEGER;
BEGIN
if BackupBitmap = nil then exit;
  xActual := round((X *image.Picture.Height)/image.Height);
  yActual := round((Y *image.Picture.Width)/image.Width);


if (xActual < 0) or (yActual < 0) or (xActual > Image.Picture.width)
or (yActual > Image.Picture.height) then
   exit;
if (not gSmooth) and (gZoomPct <> 0) then
AreaRadius := (50 * 100) div gZoomPct
else
    AreaRadius := 50;
Magnification := {round((30*2) / (100))}AreaRadius*2;//round(( (( gZoomPct div 50)+1) * 100)  /gZoomPct * AreaRadius);
if (gMagRect.Left <> gMagRect.Right) then begin
   Image.Picture.Bitmap.Canvas.CopyRect(gMagRect,
                              BackupBitmap.Canvas, // [anme]
                              gMagRect);
end;
gMagRect := Rect(xActual - Magnification,
                                   yActual - Magnification,
                                   xActual + Magnification,
                                   yActual + Magnification);
Image.Picture.Bitmap.Canvas.CopyRect(gMagRect,
                              BackupBitmap.Canvas, // [anme]
                                Rect(xActual - AreaRadius,
                                   yActual - AreaRadius,
                                   xActual + AreaRadius,
                                   yActual + AreaRadius) );
  Image.refresh;
END; {ShowMagnifier}

procedure FireLUT (lIntensity, lTotal: integer; var lR,lG,lB: integer);
//Generates a 'hot metal' style color lookup table
var l255scale: integer;
begin
     l255Scale := round ( lIntensity/lTotal * 255);
     lR := (l255Scale - 52) * 3;
     if lR < 0 then lR := 0
     else if lR > 255 then lR := 255;
     lG := (l255Scale - 108) * 2;
     if lG < 0 then lG := 0
     else if lG > 255 then lG := 255;
     case l255Scale of
          0..55: lB :=  (l255Scale * 4);
          56..118: lB := 220-((l255Scale-55)*3);
          119..235: lB := 0;
          else lB := ((l255Scale-235)*10);
     end; {case}
     if lB < 0 then lB := 0
     else if lB > 255 then lB := 255;
end;


procedure TMDIChild.LoadColorScheme(lStr: string; lScheme: integer);
//Loads a color lookup tabel from disk.
//Lookup tables can either be in Osiris format (TEXT) or ImageJ format (BINARY: 768 bytes)
const UNIXeoln = chr(10);
var
   lF: textfile;
   lBuff: bytep0;
   lFdata: file;
   lCh: char;
   lNumStr: String;
   lRi,lGi,lBi,lZ: integer;
   lByte,lIndex,lRed,lBlue,lGreen: byte;
   lType,lIndx,lLong,lR,lG,lB: boolean;
procedure ResetBools;
begin
    lType := false;
    lIndx := false;
    lR := false;
    lG := false;
    lB := false;
    lNumStr := '';
end;
begin
     gScheme := lScheme;
     if lScheme < 3 then begin //AUTOGENERATE LUT 0/1/2 are internally generated: do not read from disk
        case lScheme of
           0: for lZ:=0 to 255 do begin //1: low intensity=white, high intensity = black
              gRra[lZ] := 255-lZ;
              gGra[lZ] := 255-lZ;
              gBra[lZ] := 255-lZ;
             end;
            2:  for lZ:=0 to 255 do begin //Hot metal LUT
                FireLUT (lZ,255,lRi,lGi,lBi);
                gRra[lZ] :=  lRi;
                gGra[lZ] := lGi;
                gBra[lZ]      := lBi ;
             end;
           else for lZ:=0 to 255 do begin //1: low intensity=black, high intensity = white
                gRra[lZ] := lZ;
                gGra[lZ] := lZ;
                gBra[lZ] := lZ;

             end;
        end; //case
        gMaxRGB := (gRra[255] + (gGra[255] shl 8)+(gBra[255] shl 16));
        gMinRGB := (gRra[0] + (gGra[0] shl 8)+(gBra[0] shl 16));
        exit;
     end; //AUTOGENERATE LUT
     lIndex := 0;
     lRed := 0;
     lGreen := 0;
     if gCustomPalette > 0 then exit;
     if not fileexists(lStr) then exit;
     assignfile(lFdata,lStr);
     filemode := 0;
     reset(lFdata,1);
     lZ := FileSize(lFData);
     if (lZ =768) or (lZ = 800) or (lZ = 970) then begin
        GetMem( lBuff, 768);
        Seek(lFData,lZ-768);
        BlockRead(lFdata, lBuff^, 768);
        closeFile(lFdata);
        for lZ := 0 to 255 do begin
            //lZ := (lIndex);
            gRra[lZ] := lBuff[lZ];
            gGra[lZ] := lBuff[lZ+256];
            gBra[lZ] := lBuff[lZ+512];
        end;

        {write output ->  
     filemode := 1;
     lZ := 256;
     AssignFile(lFData, 'C:\Documents and Settings\Chris\My Documents\imagen\smash.lut');
     Rewrite(lFData,1);
     BlockWrite(lFdata, lBuff[0], lZ);   //red
     BlockWrite(lFdata, lBuff[2*lZ], lZ); //blue
     BlockWrite(lFdata, lBuff[lZ], lZ); //green
     //BlockWrite(lFdata, lBuff^, lZ);
     CloseFile(lFData);

        end write output}

        freemem(lBuff);
        gMaxRGB := (gRra[255] + (gGra[255] shl 8)+(gBra[255] shl 16));
        gMinRGB := (gRra[0] + (gGra[0] shl 8)+(gBra[0] shl 16));

        exit;

     end;
     closefile(lFdata);
     lLong := false;
     assignfile(lF,lStr);
     filemode := 0;
     reset(lF);
     ResetBools;
     for lByte := 0 to 255 do begin
         gRra[lByte] := 0;
         gGra[lByte] := 0;
         gBra[lByte] := 0;
     end;

(*Start PaintShopProConverter
        lNumStr := '';
        lCh := ' ';
            while (not EOF(lF)) and (lCh <> kCR) and (lCh <> UNIXeoln) do begin
                  read(lF,lCh); //header signatur JASC-PAL
                  lNumStr := lNumStr + lCh;
            end;
        lCh := ' ';
            while (not EOF(lF)) and (lCh <> kCR) and (lCh <> UNIXeoln) do begin
                  read(lF,lCh); //jasc header version 0100
                  lNumStr := lNumStr + lCh;
            end;
        lCh := ' ';
            while (not EOF(lF)) and (lCh <> kCR) and (lCh <> UNIXeoln) do begin
                  read(lF,lCh); //jasc header index items, e.g. 256
                  lNumStr := lNumStr + lCh;
            end;
//            showmessage(lNumStr);
            for lIndex := 0 to 255 do begin
              for lZ := 1 to 3 do begin
                lNumStr := '';
                repeat
                      read(lF,lCh);
                      if lCh in ['0'..'9'] then
                         lNumStr := lNumStr + lCh;
                until (lNumStr <> '') and (not (lCh in ['0'..'9']));
                case lZ of
                   1: gGra[lIndex] := strtoint(lNumStr);
                   2: grra[lIndex] := strtoint(lNumStr);
                   else gBra[lIndex] := strtoint(lNumStr);

                end; //case lZ
              end; //for lZ r,g,b loops

            end; //for lIndex 0..255 loops
            lIndex := 0;
     filemode := 1;
     lZ := 256;
     AssignFile(lFData, 'C:\Documents and Settings\Chris\My Documents\imagen\newlut.lut');
     Rewrite(lFData,1);
     BlockWrite(lFdata, gRra[1], lZ);   //red
     BlockWrite(lFdata, gGra[1], lZ); //blue
     BlockWrite(lFdata, gBra[1], lZ); //green
     //BlockWrite(lFdata, lBuff^, lZ);
     CloseFile(lFData);
     exit;
 (*end - PaintShopPro format*)

 begin Osiris format reader *)

     //if EOF(lF) then
       //do not start reading
     //else repeat
     while not EOF(lF) do begin
         read(lF,lCh);
         if lCh = '*' then //comment character
            while (not EOF(lF)) and (lCh <> kCR) and (lCh <> UNIXeoln) do
                  read(lF,lCh);
         if (lCh = 'L') or (lCh = 'l') then begin
            lType := true;
            lLong := true;
         end; //'l'
         if (lCh = 's') or (lCh = 'S') then begin
            lType := true;
            lLong := false;
         end; //'s'
         if lCh in ['0'..'9'] then
             lNumStr := lNumStr + lCh;
         //note on next line: revised 9/9/2003: will read final line of text even if EOF instead of EOLN for final index
         if ((not(lCh in ['0'..'9'])) or (EOF(lF)) ) and (length(lNumStr) > 0) then begin //not a number = space??? try to read number string
              if not lIndx then begin
                 lIndex := strtoint(lNumStr);
                 lIndx := true;
              end else begin //not index
                  if lLong then
                     lByte := trunc(strtoint(lNumStr) / 256)
                  else
                      lByte := strtoint(lNumStr);
                  if not lR then begin
                     lRed := lByte;
                     lR := true;
                  end else if not lG then begin
                      lGreen := lByte;
                      lG := true;
                  end else if not lB then begin
                      lBlue := lByte;
                      //if (lIndex > 253) then showmessage(inttostr(lIndex));
                      lB := true;
                      gRra[lIndex] := lRed;
                      gGra[lIndex] := lGreen;
                      gBra[lIndex] := lBlue;
                      //if lIndex = 236 then showmessage(inttostr(lBlue));
                      ResetBools;
                  end;
              end;
              lNumStr := '';
         end;
     end;
     //until EOF(lF); //not eof
(*end osiris reader  *)
{write as ImageJ format  
     filemode := 1;
     lZ := 256;
     AssignFile(lFData, 'C:\Documents and Settings\Chris\My Documents\imagen\cortex.lut');
     Rewrite(lFData,1);
     BlockWrite(lFdata, gRra[1], lZ);   //red
     BlockWrite(lFdata, gGra[1], lZ); //blue
     BlockWrite(lFdata, gBra[1], lZ); //green
     CloseFile(lFData);
end write}
     gMaxRGB := (gRra[255] + (gGra[255] shl 8)+(gBra[255] shl 16));
     gMinRGB := (gRra[0] + (gGra[0] shl 8)+(gBra[0] shl 16));
     closefile(lF);
     filemode := 2;
end;

procedure TMDIChild.FormClose(Sender: TObject; var Action: TCloseAction);
//release dynamic memory
begin
  gDynStr:= '';
  gSelectRect := rect(0,0,0,0);
  gSelectOrigin.X := -1;
  Action := caFree;
  MainForm.ColUpdate;
  gStringList.Free; //rev20
  ReleaseDICOMmemory;
  MainForm.UpdateMenuItems(nil);
end;

procedure TMDIChild.FormCreate(Sender: TObject);
//Initialize form
begin
     gSmooth := false;
     Smooth1.Checked := gSmooth;
     gMultiRow := 1;
     gMultiCol := 1;
     BackupBitmap := nil;
     gScheme := 1;
     gWinCen := 0;
     gWinWid := 0;
     gStringList := TStringList.Create;
     gFileListSz := 0;
     gCurrentPosInFileList := -1;
     gBuff16sz := 0;
     gVideoSpeed := 0;
     gBuff8sz := 0;
  FFileName    := '';
  gContrastStr := '';
  gDICOMdata.Allocbits_per_pixel := 0;
  gCustomPalette := 0;
  gMinHt := 10;
  gMinWid := 10;
  gDICOMData.XYZdim[1]        := 0;
  gDICOMData.XYZdim[2]       := 0;
  g100PctImageWid := 0;
  g100PctImageHt := 0;
  gZoomPct := 100;
  //for lInc := 0 to 255 do
  //    gRGBquadRA[lInc].rgbReserved := 0;
end;

procedure TMDIChild.DetermineZoom;
//Work out scale of image.
//Can scale image to fit the form size
var lHZoom: single;
    lZoom,lZoomPct: integer;
begin
     if (not MainForm.BestFitItem.checked) then exit;
     lHZoom := (ClientWidth)/g100pctImageWid;
     if ((ClientHeight)/g100pctImageHt) < lHZoom then
        lHZoom := ((ClientHeight)/g100pctImageHt);
     lZoomPct := trunc(100*lHZoom);
     if lZoomPct < 11 then
        lZoom := 10 //.5 zoom
     else if lZoomPct > 500 then
          lZoom := 500
     else lZoom := lZoomPct;
     gZoomPct := lZoom;
end;

procedure TMDIChild.AutoMaximise;
//Rescales image to fit form
var lZoom: integer;
begin
     if (not MainForm.BestFitItem.checked) or (g100pctImageHt < 1) or (g100pctImageWid < 1) then exit;
     lZoom := gZoomPct;
     DetermineZoom;
     if lZoom <> gZoomPct then begin
        RefreshZoom;
        MainForm.ZoomSlider.Position := lZoom;
     end;
end;

function FSize (lFName: String): longint;
var infp: file;
begin
     assign(infp,lFName);
     FileMode := 0; //Read only
     Reset(infp, 1);

     result := FileSize(infp);
     closefile(infp);
     Filemode := 2;
end;


function TMDIChild.LoadData(lFileName : string; lAnalyze,lECAT,l2dImage,lRaw: boolean ) : Boolean;
//Loads and displays a medical image, also searches for other DICOM images in the same folder as the image you have opened
//  This latter feature allows the user to quickly cycle between successive images
var
     lHdrOK: boolean;
     lAllocSLiceSz,lS: integer;
     lExt : string;
     JPG:  TJPEGImage;
     Stream: TmemoryStream;
     BMP: TBitmap;
     lImage: TImage;
begin
  ReleaseDICOMmemory;
  RescaleClear;
  gFilePath := extractfilepath(lFileName);
  FDICOM := true;
  gScheme := 1;
  gSlice := 1;
  LoadColorScheme('',gScheme); //load Black and white
  Result := TRUE;
  gImgOK := false;
  FFileName := lFileName;
  gAbort:= true;
  if not fileexists(lFilename) then begin
     result := false;
     showmessage('Unable to find the file: '+lFilename);
     exit;
  end;
     Self.caption := extractfilename(lFilename);
     lExt := UpperCase(ExtractFileExt(FFileName));
     if (l2DImage) or ('.JPG'= lExt) or ('.JPEG'= lExt) or('.BMP'= lExt) then begin
        FDICOM := false;
        if ('.JPG'= lExt) or ('.JPEG'= lExt) then begin
           {JPEGOriginal := TJPEGImage.Create;
           TRY
              JPEGOriginal.LoadFromFile(FFilename);
              Image.Picture.Graphic := JPEGOriginal
           FINALLY
               JPEGOriginal.Free
           END;}
           //the following longer method makes sure the user can save the JPEG file...
           {Stream := TMemoryStream.Create;
           try
              Stream.LoadFromFile(FFilename);
              Stream.Seek(0, soFromBeginning);
              Jpg := TJPEGImage.Create;
              try
                 Jpg.LoadFromStream(Stream);
                 BMP := TBitmap.create;
                 try
                    BMP.Height := JPG.Height;
                    BMP.Width := JPG.Width;
                    BMP.PixelFormat := pf24bit;
                    BMP.Canvas.Draw(0,0, JPG);
                    Image.Picture.Graphic := BMP;
                 finally
                        BMP.Free;
                 end;
              finally
                     JPG.Free;
              end;
           finally
                  Stream.Free;
           end;}
//next bit allows contrast adjustable JPEG images....
           Stream := TMemoryStream.Create;
           try
              Stream.LoadFromFile(FFilename);
              Stream.Seek(0, soFromBeginning);
              Jpg := TJPEGImage.Create;
              try
                 Jpg.LoadFromStream(Stream);
        gDICOMData.XYZdim[1] :=JPG.Width;
        gDICOMData.XYZdim[2] := JPG.Height;
        Image.Width :=  JPG.Width;
        Image.Height :=  JPG.Height;

{                 BMP := TBitmap.create;
                 try
                    BMP.Height := JPG.Height;
                    BMP.Width := JPG.Width;
                    BMP.PixelFormat := pf24bit;
                    BMP.Canvas.Draw(0,0, JPG);
                    Image.Picture.Graphic := BMP;
                 finally
                        BMP.Free;
                 end;}
              finally
                     JPG.Free;
              end;
           finally
                  Stream.Free;
           end;


        gDICOMData.SamplesPerPixel := 3;
        gDICOMData.Storedbits_per_pixel := 8;
        gDICOMData.Allocbits_per_pixel := 8;
        gDICOMData.ImageStart := 0;
        g100PctImageWid := gDICOMData.XYZdim[1];
        g100PctImageHt := gDICOMData.XYZdim[2];
        gDICOMData.XYZdim[3] := 1;
        gECATposra[1] := 0;
        //CloseFile(infp); //we will read this file directly
        lAllocSLiceSz := (gDICOMdata.XYZdim[1]*gDICOMdata.XYZdim[2]); //24bits per pixel: number of voxels in each colour plane
        gBuff24Sz := lAllocSliceSz*3;
        GetMem( gBuff24, lAllocSliceSz*3);
        decompressJPEG24 (FFilename,gBuff24,lAllocSliceSz,gECATposra[1],Image);
        MainForm.ColUpdate;
                 DetermineZoom;
         SetDimension(gDIcomData.XYZdim[2],gDIcomData.XYZdim[1] ,24, gBuff24,false);
         DICOMImageRefreshAndSize;
         Image.Refresh;
        FDICOM := true;
  gImgMin := 0;
  gImgMax := 255;
  gWinMin := 0;
  gWinMax := 255;


        {}
        //?? what if gDICOMdata.monochrome = 4 -> is YcBcR photometric interpretation dealt with by the JPEG comrpession or not? I have never seen such an image, so I guess this is an impossible combination
        //Reset(infp, 1); //other routines expect this to be left open


        end else
            Image.Picture.Bitmap.LoadFromFile(FFilename);
        //if Image.Picture.Bitmap.PixelFormat = pf8 then
        gDICOMData.SamplesPerPixel := 3;
        gDICOMData.Storedbits_per_pixel := 8;
        gDICOMData.Allocbits_per_pixel := 8;
        gDICOMData.ImageStart := 54;
        gDICOMData.XYZdim[1] := Image.Picture.Width;
        gDICOMData.XYZdim[2] := Image.Picture.Height;
        g100PctImageWid := gDICOMData.XYZdim[1];
        g100PctImageHt := gDICOMData.XYZdim[2];
        Image.Width :=  Image.Picture.Width;
        Image.Height :=  Image.Picture.Height;
        gDICOMData.XYZdim[3] := 1;
        if self.WindowState <> wsMaximized then begin
           self.ClientHeight:=gDICOMdata.XYZdim[2];
           self.ClientWidth:= (gDICOMData.XYZdim[1]);
        end;
        MainForm.ColUpdate;
        ContrastAutobalance1.enabled := false;
        OptionsImgInfoItem.enabled := false;
        gImgOK := true;
        automaximise;
        Image.Refresh;
        exit;
     end;
     FDICOM := true;
     if lRaw then begin
         lHdrOK := true;
         gImgOK := true;
     end else if lAnalyze then
         OpenAnalyze (lHdrOK,gImgOK,gDynStr,FFileName, gDicomData)
     else if lECAT then
         read_ecat_data(gDICOMdata,true{verbose},true{offset tables supported},lHdrOK,gImgOK,gDynStr,FFileName)
     else
      read_dicom_data(true,true,true,true,true,true,true, gDICOMdata, lHdrOK, gImgOK, gDynStr,FFileName );
     rescaleInit;

     if gDICOMdata.ElscintCompress then begin
         showmessage('Unable to descode Elscint compressed images.');
         gImgOK := false;
     end;
     if (lHdrOK) and (gImgOK) and (not fileexists(FFileName)) then begin
        MainForm.OpenDialog.Title := 'Select Interfile image file...';
            if MainForm.OpenDialog.Execute and Fileexists (MainForm.OpenDialog.Filename)  then
               FFilename := MainForm.OpenDialog.Filename
            else
                gImgOK := false;
        MainForm.OpenDialog.Title := 'Open';
     end; //1.33
     HdrShow;
     if gECATJPEG_table_entries > 0 then begin
         //showmessage('ecatabba'+inttostr(gDICOMdata.CompressOffset));
         //gDicomData.ImageStart := gECATJPEG_pos_table[1];
         {if (gECATJPEG_table_entries = 1) then begin
                 gECATposra[1]:=gDICOMdata.CompressOffset;
                 gECATszra[1]:=gDICOMdata.CompressSz;
         end else}  if (gECATJPEG_table_entries > kMaxECAT) then begin
            gImgOK := false;
            Showmessage('This ECAT file has too many slices ('+inttostr(gECATJPEG_table_entries)+').');
         end else begin
             gECATslices:= gECATJPEG_table_entries;
             for lS := 1 to gECATslices do begin
                 //gECATslices
                 //showmessage(inttostr(lS)+'@abba'+inttostr(gECATJPEG_pos_table[lS]));
                 gECATposra[lS]:=gECATJPEG_pos_table[lS];
                 gECATszra[lS]:=gECATJPEG_size_table[lS];
             end;
         end;
         freemem(gECATJPEG_pos_table);
         freemem(gECATJPEG_size_table);
         gECATJPEG_table_entries := 0;
      end;
  gBlack := 1;
  gScale := 1;
  gPro := 0;
  gCustomPalette := 0;
  if red_table_size > 0 then begin
     //gCustomPalette := 0;
  end else begin
      if gDICOMdata.monochrome = 1 then
         gScheme := 0
      else
          gScheme := 1;
  LoadColorScheme('',gScheme); //load Black and white
end;
  gWinCen := 0;
  gWinWid := 0;
  if (gDICOMdata.XYZdim[2] < 1) or (gDICOMdata.XYZdim[1] < 1) or (not lHdrOK) or (not gImgOK) then begin
     showmessage('LoadData: Error reading image.');
     ReleaseDICOMmemory;
     OptionsImgInfoItemClick(nil);
     exit;
  end;
  LowerSlice1.enabled := gDicomdata.XYZdim[3] > 1;
  HigherSlice1.enabled := gDicomdata.XYZdim[3] > 1;
  Mosaic1.enabled := gDicomdata.XYZdim[3] > 1;
  if self.WindowState <> wsMaximized then begin
      self.ClientHeight:=gDICOMdata.XYZdim[2];
      self.ClientWidth:= (gDICOMData.XYZdim[1]);
  end;
  if (gDICOMdata.RLERedSz > 0) or (gDICOMdata.SamplesPerPixel > 1) or (gCustomPalette > 0) then begin
     gDICOMdata.WindowCenter := 127;
     gDICOMdata.WindowWidth := 255;
     gImgMin := 0;
     gImgMax := 255;
     gWinCen := gDICOMdata.WindowCenter;
     gWinWid := 0;//gDICOMdata.WindowWidth;
     gFastCen := 128;
     gFastSlope := 128;
  end;
  gAbort := false;
  Overlay1.enabled := true;
  gSlice := 0; {force a new image to be displayed - so gSlice should be different from displayimage requested slice}
  DisplayImage(True,True,1,-1,0);
  Screen.Cursor := crDefault;
  if Self.Active then
        MainForm.ColUpdate;
    MainForm.StatusBar.Panels[5].text := 'id:s:a:i '+inttostr(gDicomData.PatientIDInt)+':'+inttostr(gDicomData.SeriesNum)+':'+inttostr(gDicomData.AcquNum)+':'+inttostr(gDicomData.ImageNum);

end;

procedure TMDIChild.FileOpenItemClick(Sender: TObject);
//File menu, OPEN
begin
	MainForm.FileOpenItemClick(Sender);
end;

procedure TMDIChild.FileExitItemClick(Sender: TObject);
begin
	MainForm.FileExitItemClick(Sender);
end;

procedure TMDIChild.HdrShow;
var lLen,lI : integer;
lStr: string;
begin
  if not FDICOM then begin
     //showmessage('Unable to show DICOM header information. This is not a DICOM file.');
     EXIT;
  end;
  Memo1.Lines.Clear;
  //Memo1.lines.add(inttostr(gDicomData.ImageStart));
  lLen := Length (gDynStr);
  if lLen > 0 then begin
       lStr := '';
       for lI := 1 to lLen do begin
           if gDynStr[lI] <> kCR then
              lStr := lStr + gDynStr[lI]
           else begin
                Memo1.Lines.add(lStr);
                lStr := '';
           end;
       end;
       Memo1.Lines.Add(lStr);
  end; //lLen > 0
end;

procedure TMDIChild.OptionsImgInfoItemClick(Sender: TObject);
begin
     MainForm.HdrBtn.Down := not  MainForm.HdrBtn.Down;
     MainForm.HdrBtn.Click;
end;
        (*
procedure TMDIChild.decompressJPEG24x (lFilename: string; var lOutputBuff: ByteP0; lImageVoxels,lImageStart{gECATposra[lSlice]}: integer);
var
   Stream: Tmemorystream;
   Jpg: TJPEGImage;

   TmpBmp: TPicture;
   lImage: Timage;
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
        //lImage.Create(Image);


        Image.Height := JPG.Height;
        Image.Width := JPG.Width;



        //Image.Picture.Graphic:=JPG;
        //Image.Picture.Assign(jpg);
        Image.Picture.Bitmap.Assign(jpg);
        {Image.Picture.Bitmap.Height := JPG.Height;
        Image.Picture.Bitmap.Width := JPG.Width;
        Image.Picture.Bitmap.PixelFormat := pf24bit;
             {}
        //lImageVoxels = (JPG.Height*JPG.Width);
        lWid0 := JPG.Width-1;
        lHt0 := JPG.Height-1;
        lInc := (3*lImageVoxels)-1; //*3 because 24-bit, -1 since index is from 0
        //showmessage(inttostr(lWid0)+'@'+inttostr(lHt0));
        FOR j := lHt0-1 DOWNTO 0 DO BEGIN
                          lRow := Image.Picture.Bitmap.ScanLine[j];
                          //lRow := TmpImage.Picture.Bitmap.Scanline[j];
                          FOR i := lWid0 downto 0 DO BEGIN
                              lOutputBuff[lInc] := (lRow[i].rgbtBlue) and 255;//lRow[i].rgbtRed;
                              lOutputBuff[lInc-1] := (lRow[i].rgbtGreen) and 255;//lRow[i].rgbtRed;
                              lOutputBuff[lInc-2] := (lRow[i].rgbtRed) and 255;//lRow[i].rgbtRed;
                              dec(lInc,3);
                          END; //for i.. each column
        END; //for j...each row
        {}
        //lImage.Free;
        //TmpBmp.Create;
        //TmpBmp.Graphic := Jpg;
        //TmpBmp.Free;
      finally //try..finally
        Jpg.Free;
      end;
    finally
      Stream.Free;
    end; //try..finally
end;  *)

procedure TMDIChild.DisplayImage(lUpdateCon,lForceDraw: boolean;lSlice,lInWinWid,lInWinCen: integer);
//Draws an image: can create mosaics (showing multiple slices simultaneously)
label
123;
var
//  Stream: TMemoryStream;
//  Jpg: TJPEGImage;
  lWinCen,lWinWid,Hd: Integer;
  lStartTime: DWord;
  lLookup16,lCompressLine16: SmallIntP0;
  lMultiBuff,CptBuff,lBuff,TmpBuff   : bYTEp0;
  lPtr: Pointer;
  lRow:  pRGBTripleArray;
  lCptPos,lFullSz,lCompSz,lTmpPos,lTmpSz,lLastPixel: longint;
  lMultiSliceInc: single;
  lTime,lMultiMaxSlice,lMultiFullRowSz,lMultiCol,lMultiRow,
  lMultiStart,lMultiLineSz,lMultiSliceSz,lMultiColSz,lnMultiRow,lMultiSlice,lnMultiCol,lnMultiSlice: integer;
  lSmall: word;//smallint;
  l16Signed,l16Signed2 : smallint;
  lFileName: string;
  infp: file;
  max16 : LongInt;
  min16 : LongInt;
  lShort: ShortInt;
  lCptVal,lRunVal,lByte2,lByte: byte;
  lLineLen,{lScaleShl10,}lL,j,size,lScanLineSz,lBufEntries,lLine,lImgPos,lLineStart,lLineEnd,lPos,value,
  lInc,lCol,lXdim,lStoreSliceVox,lImageStart,lAllocSLiceSz,lStoreSliceSz,I,I12       : Integer;
  lY,lCb,lCr,lR,lG,lB: integer;
  hBmp    : HBITMAP;
  BI      : PBitmapInfo;
  BIH     : TBitmapInfoHeader;
  Bmp     : TBitmap;
  ImagoDC : hDC;
  pixmap  : Pointer;
  PPal: PLogPalette;
begin
     lMultiColSz := 1;
     lMultiLineSz := 1;
     if lUpdateCon then begin
        gFastSlope := 128;
        gFastCen := 128;
        UpdatePalette(false,0);
        if gDICOMdata.Allocbits_per_pixel > 8 then begin
           gFastSlope := 512{256};  {CONTRAST change here}
           gFastCen := 512{256}; {CONTRAST change here}
        end;
     end;
     lFileName := FFilename;
     lWinWid := lInWinWid;
     lWinCen := lInWinCen;
     if (lWInWid < 0) {and (gUseRecommendedContrast)}and true and (gDICOMdata.WindowWidth <> 0) then begin //autocontrast
        lWinWId := gDICOMdata.WindowWidth;
        lWinCen := gDICOMdata.WindowCenter;
     end;
     if (not lUpdateCon) and (gSlice = lSlice) {and (gScheme = lScheme)} and (lWinCen = gWinCen) and (lWinWid = gWinWid) then
        exit; {no change: delphi sends two on change commands each time a slider changes: this wastes a lot of display time}
     gImgMin :=0;
     gImgMax := 0;
     if (gDICOMdata.SamplesPerPixel > 1) or (gDICOMdata.RLERedSz > 0) then
        gImgMax := 255;
     gImgCen := 0;
     gImgWid := 0;
     gWinMin := gImgMin;
     gWinMax := gImgMax;
     gWinCen := lWinCen;
     gWinWid := lWinWid;
     if (not gImgOK) or (gAbort) then
        exit;
     if lSlice < 1 then
        lSlice := 1;
     g100pctImageWid := gDICOMdata.XYZdim[1];
     g100pctImageHt :=  gDICOMdata.XYZdim[2];
     gSlice := lSlice;
     lnMultiRow := gMultiRow;
     if lnMultiRow < 1 then
        lnMultiRow := 1;
     lnMultiCol := gMultiCol;
     if lnMultiCol < 1 then lnMultiCol := 1;
     lnMultiSlice := lnMultiRow*lnMultiCol;
     lMultiMaxSlice :=  gDicomData.XYZdim[3];
     if lnMultiSlice > 1 then begin //compute if single multiframe file or multiple files
        if gDicomData.XYZdim[3] > 1 then  begin
           if (lnMultiSLice > gDicomData.XYZdim[3]) then begin
              lnMultiSLice := gDicomData.XYZdim[3];
              gMultiFirst := 1;
              gMultiLast := lnMultiSlice;
           end;
        end else lnMultiSlice := 1;
     end; //MOSAIC
if lnMultiSlice > 1 then begin
   Self.caption := 'Multislice';
   g100pctImageWid := g100pctImageWid * lnMultiCol;
   g100pctImageHt := g100pctImageHt * lnMultiRow;
   if gDICOMdata.SamplesPerPixel > 1 then
      lMultiColSz := gDICOMdata.XYZdim[1]* gDICOMdata.SamplesPerPixel
   else
      lMultiColSz := gDICOMdata.XYZdim[1];
  lMultiLineSz := lMultiColSz * lnMultiCol;
  lMultiFullRowSz := lMultiLineSz * gDICOMdata.XYZdim[2];
  lMultiSliceSz := lMultiLineSz * gDICOMdata.XYZdim[2]*lnMultiRow;
  If (gDICOMdata.Allocbits_per_pixel > 8) then
    getmem(lMultiBuff{lMultiBuff16},lMultiSliceSz*2)
  else
      getmem(lMultiBuff,lMultiSliceSz);
  //fillchar(lMultiBuff,lMultiSliceSz,0);
  if gMultiFirst > lMultiMaxSlice then
     gMultiFirst := 1;
  lSlice := gMultiFirst;
  if (gMultiLast > lMultiMaxSlice) or (gMultiLast < gMultiFirst) then
     gMultiLast := lMultiMaxSlice;
  lMultiSliceInc := (gMultiLast -gMultiFirst) / (lnMultiSlice-1);
  if lMultiSliceInc < 1 then lMultiSliceInc := 1;
end else begin
         Self.caption := extractfilename(FFilename);
end;
lMultiSlice := 1; //1stSlice
123: //return here for multislice view              xx
lMultiCol := lMultiSlice mod lnMultiCol;
if lMultiCol = 0 then lMultiCol := lnMultiCol;
lMultiCol := lMultiCol - 1; //index from 0
lMultiRow := (lMultiSlice-1) div lnMultiCol;
  lAllocSLiceSz := (gDICOMdata.XYZdim[1]*gDICOMdata.XYZdim[2] * gDICOMdata.Allocbits_per_pixel+7) div 8 ;
  if (lAllocSLiceSz) < 1 then exit;
  AssignFile(infp, lFilename);
  FileMode := 0; //Read only
  Reset(infp, 1);
  //if not lMultiMultiFile then
  if (gECATslices >= lSlice) then //build18 + next 2 lines
     lImageStart := gECATposra[lSlice]
  else
      lImageStart := gDicomData.ImageStart + ((lSlice-1) * (lAllocSliceSz*gDICOMdata.SamplesPerPixel));
  if (not gDicomData.GenesisCpt) and (gDicomData.CompressSz=0) and (not gDicomData.RunLengthEncoding)and ((lImageStart + (lAllocSliceSz*gDICOMdata.SamplesPerPixel)) > (FileSize(infp))) then begin
        showmessage('This file does not have enough data for the image size:'+lFilename+kCR+'Image start: '+inttostr(lImageStart)+kCR+'Image size: '+inttostr(lAllocSliceSz*gDICOMdata.SamplesPerPixel));
        closefile(infp);
        FileMode := 2; //read/write
        exit;
  end;
  Seek(infp, lImageStart);
  if (gDICOMdata.RLERedOffset <>0) or ((gDICOMdata.Allocbits_per_pixel = 8) and(gDICOMdata.SamplesPerPixel = 3)) then begin
     lAllocSLiceSz := (gDICOMdata.XYZdim[1]*gDICOMdata.XYZdim[2]); //24bits per pixel: number of voxels in each colour plane
     size := lAllocSliceSz-1;
     if gBuff24Sz <>(lAllocSliceSz*3) then begin //gDICOMdata.SamplesPerPixel
        if gBuff24Sz <> 0 then
           Freemem(gBuff24);
        gBuff24Sz := lAllocSliceSz*3;
        GetMem( gBuff24, lAllocSliceSz*3);
     end;
     if (gDICOMdata.JPEGLossyCpt) then begin
        CloseFile(infp); //we will read this file directly
        //lStartTime := GetTickCount;
        //if lSlice > 18 then
           //showmessage(inttostr(lSlice)+'@'+inttostr(gECATposra[lSlice]));
        decompressJPEG24 (lFilename,gBuff24,lAllocSliceSz,gECATposra[lSlice],Image);
        exit;
        //self.caption :=('update(ms): '+inttostr(GetTickCount-lStartTime)); //70 ms
        //?? what if gDICOMdata.monochrome = 4 -> is YcBcR photometric interpretation dealt with by the JPEG comrpession or not? I have never seen such an image, so I guess this is an impossible combination
        //Reset(infp, 1); //other routines expect this to be left open
     end else if (gDICOMdata.JPEGLosslessCpt) then
        DecodeJPEG(infp,gBuff16,gBuff24, gBuff24Sz,gECATposra[lSlice],gECATszra[lSlice],false)
     else if (gDICOMdata.planarconfig = 0) and (gDICOMdata.RunLengthEncoding = false) then begin
         BlockRead(infp, gBuff24^, lAllocSliceSz*gDICOMdata.SamplesPerPixel);
     end else if (gDICOMdata.RLERedOffset <>0)  then begin
                DecompressRLE16toRGB(infp,gBuff24,lAllocSLiceSz,gDICOMdata.CompressOffset,gDICOMdata.CompressSz,gDICOMdata.RLERedOffset,gDICOMdata.RLEGreenOffset,gDICOMdata.RLEBlueOffset,gDICOMdata.RLERedSz ,gDICOMdata.RLEGreenSz,gDICOMdata.RLEBlueSz);
     end else if gDICOMdata.CompressSz > 0 then begin
         DecompressRLE8(infp, gBuff24,3{gDICOMdata.SamplesPerPixel},lAllocSliceSz,gECATposra[lSlice],gECATszra[lSlice]);//1496: use gECAT array
         //DecompressRLE8(infp, gBuff24,3{gDICOMdata.SamplesPerPixel},lAllocSliceSz,gDICOMdata.CompressOffset,gDICOMdata.CompressSz);
     end else begin //not compressed
            GetMem( TmpBuff, lAllocSliceSz);
            BlockRead(infp, TmpBuff^, lAllocSliceSz{, n});
            size := lAllocSliceSz-1;
            j := 0;
            for i := 0 to size do begin
                gBuff24[j] := TmpBuff[i];
                j := j + 3;
            end;
            BlockRead(infp, TmpBuff^, lAllocSliceSz{, n});
            size := lAllocSliceSz-1;
            j := 1;
            for i := 0 to size do begin
             gBuff24[j] := TmpBuff[i];
             j := j + 3;
            end;
            BlockRead(infp, TmpBuff^, lAllocSliceSz{, n});
            size := lAllocSliceSz-1;
            j := 2;
            for i := 0 to size do begin
             gBuff24[j] := TmpBuff[i];
             j := j + 3;
            end;
            FreeMem( TmpBuff);
     end; //no compression, swap planar compression
     CloseFile(infp);
     FileMode := 2; //read/write
     if gDICOMdata.monochrome = 4 then begin  //xappa
              j:= 0;
           for i := 0 to size do begin  //convert YcBcR to RGB
             lY := gBuff24[j];
             lCb := gBuff24[j+1]-128;
             lCr := gBuff24[j+2]-128;
             lR := round(lY+1.4022*lCr);
             lG := lY+round(-0.3456*lCb -0.7145*lCr);
             lB := round(lY+1.771 *lCb );
             if lR < 0 then lR := 0;
             if lR > 255 then lR := 255;
             if lG < 0 then lG := 0;
             if lG > 255 then lG := 255;
             if lB < 0 then lB := 0;
             if lB > 255 then lB := 255;
             gBuff24[j] := lR;
             gBuff24[j+1] := lG;
             gBuff24[j+2] := lB;  //red
             j := j + 3;
           end; //for loop
         end; //convert YcBcR to RGB
         DetermineZoom;
         SetDimension(gDIcomData.XYZdim[2],gDIcomData.XYZdim[1] ,24, gBuff24,false);
         DICOMImageRefreshAndSize;
         Image.Refresh;
   exit;
  end; //24-bit RGB
  case gDICOMdata.Allocbits_per_pixel of
       8: begin
          if lAllocSliceSz <> gBuff8Sz then begin
             if gBuff8Sz <> 0 then freemem(gBuff8);
             GetMem( gbuff8, lAllocSliceSz);
          end;
          gBuff8Sz := lAllocSliceSz;
          if gDICOMdata.JPEGlossyCpt then begin
                          CloseFile(infp);
                          decompressJPEG8 (lFilename,gBuff8,lAllocSliceSz,gECATposra[lSlice]);
          end else  if gDicomData.JPEGlosslessCpt then
             DecodeJPEG(infp,gBuff16,gBuff8, lAllocSliceSz,gECATposra[lSlice],gECATszra[lSlice],false)
          else if gDICOMdata.CompressSz > 0 then begin
                  DecompressRLE8(infp, gBuff8,1,lAllocSliceSz,gECATposra[lSlice],gECATszra[lSlice]);
//                  DecompressRLE8(infp, gBuff8,1,lAllocSliceSz,gDICOMdata.CompressOffset,gDICOMdata.CompressSz);
          end else begin
                  BlockRead(infp, gBuff8^, lAllocSliceSz{, n});
          end;
          if not gDICOMdata.JPEGlossyCpt then
             CloseFile(infp);
          FileMode := 2; //read/write
  size := gDicomData.XYZdim[1]*gDicomData.XYZdim[2] {2*width*height};
  value := gBuff8[0];
  max16 := value;
  min16 := value;
  i:=0;
  while I < (Size) do begin
    value := gBuff8[i];
    if value < min16 then min16 := value;
    if value > max16 then max16 := value;
    i := i+1;
  end;
  gImgMin := min16;
  gImgMax := max16;
  gWinMin := min16;
  gWinMax := max16;
  gImgWid := gImgMax-gImgMin;
  gImgCen := gImgMin + ((gImgWid)shr 1);
  if lWinWid < 0 then begin //autocontrast
    gWinMin := gImgMin;
    gWinMax := gImgMax;
    gWinWid := gImgWid;
    gWinCen := gImgCen;
  end;

  if (gCustomPalette>0) or ((red_table_size > 0) and (red_table_size <= 256) and (red_table_size=green_table_size) and (red_table_size=blue_table_size)) then begin
     if  gCustomPalette = 0 then begin
             gCustomPalette := red_table_size-1;
             for lInc := (gCustomPalette-1) downto 0 do begin
                 gRra[gCustomPalette-lInc] := red_table[lInc+1];//red_table[lInc+1];
                 gGra[gCustomPalette-lInc] := green_table[lInc+1];
                 gBra[gCustomPalette-lInc] := blue_table[lInc+1];//blue_table[lInc+1];
             end;
             freemem(red_table);
             red_table_size := 0;
             freemem(green_table);
             green_table_size := 0;
             freemem(blue_table);
             blue_table_size := 0;
     end; //red_size > 0
  end;
  if lnMultiSlice > 1 then begin
      lMultiStart := ((lMultiCol) * lMultiColSz)+(lMultiRow * lMultiFullRowSz);//both indexed from 0
      for j := (gDICOMdata.XYZdim[2]-1) downto 0 do begin
        i := j * lMultiColSz;
        move(gBuff8[i],lMultiBuff[lMultiStart+ (J*lMultiLineSz)],lMultiColSz);
      end;
      lSlice := gMultiFirst+round (lMultiSliceInc*lMultiSlice);
      inc(lMultiSlice);
      if (lMultiSlice <= lnMultiSlice) and (lSlice <= {lMultiMaxSlice}gMultiLast) then goto 123;
      freemem(gBuff8);
      getmem(gBuff8,lMultiSliceSz);
      move(lMultiBuff[0],gBuff8[0],lMultiSliceSz);
      freemem(lMultiBuff);
      gBuff8Sz := lMultiSliceSz;
  end;
  DetermineZoom;
  SetDimension(g100pctImageHt,g100pctImageWid,8,gBuff8,true);
  UpdatePalette(true,0);
  DICOMImageRefreshAndSize;
  if Self.Active then
     MainForm.ColUpdate;
  exit;
          end;
       16: begin

           if gECATslices >= lSlice then
              seek(infp, gECATposra[lSlice])
           else
               Seek(infp, lImageStart);
           if (gBuff16Sz <> (lAllocSliceSz shr 1)) then begin
              if gBuff16sz <> 0 then
                 Freemem(gBuff16);
              gBuff16Sz := 0;
           end;
           if gBuff16sz = 0 then
           GetMem( gbuff16, lAllocSliceSz);
           gBuff16sz := (lAllocSliceSz shr 1);
           if gDicomData.RunLengthEncoding then begin
              gDicomData.Maxintensity :=32767; //convert 16 bit to 15bit
              //DecompressRLE16toRGB(infp,gBuff24,lAllocSLiceSz,,gDICOMdata.RLERedOffset,gDICOMdata.RLEGreenOffset,gDICOMdata.RLEBlueOffset,gDICOMdata.RLERedSz ,gDICOMdata.RLEGreenSz,gDICOMdata.RLEBlueSz);
              DecompressRLE16(infp,gBuff16,gBuff16sz,gECATposra[lSlice],gECATszra[lSlice]);//1496: use gECAT array

              //DecompressRLE16(infp,gBuff16,gBuff16sz,gDICOMdata.CompressOffset,gDICOMdata.CompressSz);
           end else if gDicomData.JPEGlosslessCpt then
              DecodeJPEG(infp,gBuff16,lBuff, lAllocSliceSz,gECATposra[lSlice],gECATszra[lSlice],false)
           else if gDicomData.GenesisCpt then begin
                DecompressGE(infp,gBuff16,lImageStart,gDicomData.XYZdim[1],gDicomData.XYZdim[2],gDicomData.GenesisPackHdr);
                end else begin //not genesis
                   BlockRead(infp, gbuff16^, lAllocSliceSz{, n});
                end;
                CloseFile(infp);
                FileMode := 2; //read/write
       end;
       32: begin
          //x        showmessage('x');

       end;
       12: begin  //
           GetMem( tmpbuff, lAllocSliceSz);
           BlockRead(infp, tmpbuff^, lAllocSliceSz{, n});
           CloseFile(infp);
           FileMode := 2; //read/write
           lStoreSliceVox := gDICOMdata.XYZdim[1]*gDICOMdata.XYZdim[2];
           lStoreSLiceSz := lStoreSliceVox * 2;
           if (gBuff16Sz <> (lStoreSLiceSz shr 1)) then begin
              if gBuff16sz <> 0 then
                 Freemem(gBuff16); //asdf
              gBuff16Sz := 0;
           end;
           if gBuff16sz = 0 then
           GetMem( gbuff16, lStoreSLiceSz);
           gBuff16sz := lStoreSLiceSz shr 1;
           I12 := 0;
           I := 0;
         if gDicomData.little_endian = 1 then begin
          repeat
                 gbuff16[I] := tmpbuff[I12] + ((tmpbuff[I12+1] and 15) shl 8);
                 inc(I);
                 if I < lStoreSliceVox then
                    gbuff16[i] :=  (tmpbuff[I12+2] shl 4) +((tmpbuff[I12+1] and 240) shr 4 );
                 inc(I);
                 I12 := I12 + 3;
           until I >= lStoreSliceVox;
        end else begin
           repeat
                 gbuff16[I] := tmpbuff[I12] shl 4 + (tmpbuff[I12+1] and 15);
                 inc(I);
                 if I < lStoreSliceVox then
                    gbuff16[i] :=  (((tmpbuff[I12+2]) and 15) shl 8) +((((tmpbuff[I12+1]) shr 4 ) shl 4)+((tmpbuff[I12+2]) shr 4)  );
                 inc(I);
                 I12 := I12 + 3;
           until I >= lStoreSliceVox;
         end;
           FreeMem( tmpbuff);
           end;
       else exit;
  end;
  size := gDicomData.XYZdim[1]*gDicomData.XYZdim[2] {2*width*height};
  if (gDicomdata.little_endian <> 1) and (not gDicomData.GenesisCpt) and (not (gDicomData.RunLengthEncoding))then  //convert big-endian data to Intel friendly little endian
     for i := (Size-1) downto 0 do
         gbuff16[i] := swap(gbuff16[i]);
 if gDicomData.Maxintensity >32767 then begin
    //if  then there will be wrap around if read as signed value
    i:=0;
    while I < (Size) do begin
          if gbuff16[i] >= 0 then gbuff16[i] := gbuff16[i] - 32768
          else
            gbuff16[i] := 32768+gbuff16[i];
          i := i+1;
    end;
    gDICOMdata.MinIntensitySet := false;
  end; //prevent image wrapping > 32767{}
  value := gbuff16[0];
  max16 := value;
  min16 := value;
  i:=0;
  while I < (Size) do begin
    value := gbuff16[i];
    if value < min16 then min16 := value;
    if value > max16 then max16 := value;
    i := i+1;
  end;
  //showmessage(inttostr(min16)+'....'+inttostr(max16));
  //gRaw16Min := min16;
  //gRaw16Max := max16;
  //gImgMin := min16;
  //gImgMax := max16;
  if (gDICOMdata.IntenScale*max16) < 1 then begin
      gDICOMdata.IntenScale := 1;
  end; //prevents images from being underscaled
  //showmessage(floattostr(gDICOMdata.IntenScale*max16)+'  ='+inttostr(min16)+'..'+inttostr(max16));
  if {(min16 < 0) and (gDICOMdata.MinIntensity >min16)} gDICOMdata.MinIntensitySet then
     min16 := gDICOMdata.MinIntensity;
  gImgMin := rescalefrombuffer(min16);
  gImgMax := rescalefrombuffer(max16);
  gImgWid := gImgMax-gImgMin;
  gImgCen := gImgMin + ((gImgWid)shr 1);
  if lWinWid < 0 then begin //autocontrast
    gWinMin := gImgMin;
    gWinMax := gImgMax;
    gWinCen := gImgCen;
    gWinWid := gImgWid;
    gFastCen := gImgCen;
  end;

  if lnMultiSlice > 1 then begin
      //showmessage(inttostr(lMultiSlice)+':'+inttostr(lnMultiSlice)+':'+inttostr(g100pctImageWid));
      lMultiStart := ((lMultiCol) * lMultiColSz)+(lMultiRow * lMultiFullRowSz);//both indexed from 0
      for j := (gDICOMdata.XYZdim[2]-1) downto 0 do begin
        i := j * lMultiColSz;
        move(gBuff16[i],lMultiBuff[(lMultiStart+ (J*lMultiLineSz)) shl 1],lMultiColSz shl 1);
      end;
      lSlice := gMultiFirst+round (lMultiSliceInc*lMultiSlice);

      inc(lMultiSlice);
      if (lMultiSlice <= lnMultiSlice) and (lSlice <= {lMultiMaxSlice}gMultiLast) then goto 123;
      freemem(gBuff16);
      getmem(gBuff16,lMultiSliceSz shl 1);
      gBuff16sz := (lMultiSliceSz);
      move(lMultiBuff[0],gBuff16[0],lMultiSliceSz shl 1);
      freemem(lMultiBuff);   {}
      //gBuff16 := @lMultiBuff^;

  end;
  DetermineZoom;
  Scale16to8bit(gWinCen,gWinWid);
DICOMImageRefreshAndSize;
  if Self.Active then
     MainForm.ColUpdate;
  exit;

  {$P-,S+,W+,R+}
end;

procedure TMDIChild.FileOpenpicture1Click(Sender: TObject);
begin
	MainForm.Opengraphic1Click(Sender);
end;

procedure TMDIChild.Lowerslice1Click(Sender: TObject);
var
   lSlice: integer;
begin
    gMultiCol := 1;
    gMultiRow := 1;
  if (sender as TMenuItem).tag = 1 then begin{increment}
     if gSlice >= gDICOMdata.XYZdim[3] then
        lSlice := 1
     else
         lSlice := gSlice + 1;
  end else begin
     if gSlice > 1 then
        lSlice := gSlice -1
     else
         lSlice := gDICOMdata.XYZdim[3];
  end;
  MainForm.SliceSlider.position := lSlice;
  MainForm.SliceSliderChange(nil);
end;

procedure TMDIChild.FormActivate(Sender: TObject);
begin
     MainForm.ColUpdate;
     automaximise;
end;

procedure TMDIChild.ImageMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//Respond to user clicking on image: ZOOM, CHANGE CONTRAST, etc depending on tool
var
   lX,lY: integer;
   lSlopeReal: single;
begin
  if (ssShift in Shift) and (ssCtrl in Shift)then begin
        gMouseDown := true;
        Image.Canvas.Pen.Mode := pmCopy;
        Image.Canvas.Pen.Color := clwhite;
        if (BackupBitmap = nil) then begin
                BackupBitmap := TBitmap.Create;
                BackupBitmap.Assign(Image.Picture.Bitmap);
        end;
        if not gSmooth then begin
                lX := (X * 100) div gZoomPct;
                lY := (Y * 100) div gZoomPct;
        end else begin
            lX := X;
            lY := Y;
        end;
        if (abs(lX - gLine.Right) < 5) and (abs(lY-gLine.Bottom) < 5) then begin
           gLine.Right := gLine.Left;
           gLine.Bottom := gLine.Top;
           gLine.Left := -666;
           exit
        end;
        if (abs(lX - gLine.Left) < 5) and (abs(lY-gLine.Top) < 5) then begin
           gLine.Left := -666;
           ImageMouseMove(Sender,Shift,X,Y);
           exit
        end;
        gLine.Left := -666;
        gLine.Right := lX;
        gLine.Bottom :=lY;
        ImageMouseMove(Sender,Shift,X,Y);
        exit;
  end;
  if (button = mbLeft) and (ssCtrl{Shift} in Shift) then  begin
           Screen.Cursor := crDrag;
           gMouseDown := true;
           lX := round((X *image.Picture.Height)/image.Height);
           lY := round((Y *image.Picture.Width)/image.Width);
           //lX := ((X * 100) div gZoomPct);
           //lY := ((Y * 100) div gZoomPct);
           gSelectOrigin.X := lX;
           gSelectOrigin.Y := lY;
  end else  if (button = mbLeft) and (ssAlt in Shift) then  begin
           Screen.Cursor := crHandPoint;
           GetCursorPos( FLastDown );
           gMouseDown := true;
   end  else if (button = mbLeft) and (ssShift in Shift) then begin
         if (BackupBitmap = nil) then begin
            {if gPalUpdated then begin
               lSlice := gSlice;
               gSlice := 0;  //force redraw
               DisplayImage(false,true,lSlice,gWinWid,gWinCen);
            end; dsa}
            BackupBitmap := TBitmap.Create;
            BackupBitmap.Assign(Image.Picture.Bitmap);
         end;
             FLastDown := Point( - 1, - 1);
         gMouseDown := true;
         ShowMagnifier (X,Y); {}
   end else if (button = mbLeft) and (FDicom) {and (gCustomPalette = 0) and (gDicomdata.SamplesPerPixel = 1)} then begin
             FLastDown := Point( - 1, - 1);
        if gBuff16sz > 0 then begin
            if (gImgMax-gIMgMin) > 0 then
            gFastCen := round( ((gWinCen-gImgMin)/(gImgMax-gIMgMin))* 1024{512})
            else
                gFastCen := 512;
            if gWinWId > 0 then
               lSlopeReal := (gImgMax-gIMgMin)/ gWinWid
            else lSlopeReal := 666;
            gFastSlope := round(( arctan(lSlopeReal)/kRadCon)/0.0878);

        end else begin
            gFastCen := gWinCen;
            if gWinWId > 0 then
               lSlopeReal := 255 / gWinWid
            else lSlopeReal := 45;
            gFastSlope := round(( arctan(lSlopeReal)/kRadCon)/0.352059);
        end;

        gXstart := X;
        gYstart := Y;
        gStartSlope := gFastSlope;
        gStartCen := gFastCen;
        gMouseDown := true;
     end;
end;

procedure TMDIChild.UpdatePalette (lApply: boolean;lWid0ForSlope:integer);
//Refresh Contrast/Brightness
var
   lMin,lMax: integer;
   lSlopeReal: single;
begin
   if (gDICOMdata.Allocbits_per_pixel > 8) and (gBuff24Sz = 0){16-BITPALETTE} then begin
        if not lApply then exit;
        refreshzoom;
        exit;
   end;
   if lWid0ForSlope = 0 then begin

      lSlopeReal := gFastSlope * 0.352059;
      lSlopeReal := sin(lSlopeReal*kRadCon)/cos(lSlopeReal*kRadCon);
      if lSlopeReal <> 0 then begin
           lMax := round(128 / lSlopeReal);
           lMin := gFastCen-lMax;
           lMax := gFastCen+lMax;
      end else begin
            lMin := 0;
            lMax := 0;
      end;
   end else begin //lWid0ForSlope
       lMin := gFastCen - (lWid0ForSlope shr 1);
       lMax := lMin + lWid0ForSlope;
       lSlopeReal := 255 / lWid0ForSlope;
       gFastSlope := round(( arctan(lSlopeReal)/kRadCon)/0.352059);
   end;
        if (gDicomData.Allocbits_per_pixel < 9) or (gDICOMdata.RLERedSz > 0) then begin
            gWinCen := (gFastCen);
            if ((lMax - lMin) > maxint) or ((lMin=0) and (lMax=0)) then begin
               gContrastStr := 'Window Cen/Wid: '+inttostr(gFastCen)+'/inf';
                gWInWid := maxint;
            end else begin
                gContrastStr := 'Window Cen/Wid: '+inttostr(gFastCen)+'/'+inttostr(lMax - lMin);
                gWInWid := (lMax - lMin);
            end;
        end;
        if gBuff8Sz > 0 then begin
           SetDimension(g100pctImageHt,g100pctImageWid,8,gBuff8,true);
           DICOMImageRefreshAndSize;
        end else if gBuff24Sz > 0 then begin
           //fargo
           SetDimension(g100pctImageHt,g100pctImageWid,24,gBuff24,true);
           DICOMImageRefreshAndSize;
        end;
end;

procedure TMDIChild.ImageMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
//Respond to user moving image: typically show image intensity under the mouse
var
  lMsgStr: string;
  lLineWidmm,lLineHtmm,lLineLenMM: double;
  lTextL,lTextT,lTextWid,lTextHt,lLineWid,lLineHt,
       lX,lY,lWid: integer;
     lSlopeReal: single;
  pt: TPoint;
begin
  if not gMouseDown then begin
   lX := ((X * 100) div gZoomPct);
   lY := ((Y * 100) div gZoomPct);
   Vxl(lX,lY);
   exit;
  end;
  if (ssShift in Shift) and (ssCtrl in Shift) then begin
     if (gMagRect.Left <> gMagRect.Right) then
        Image.Picture.Bitmap.Canvas.CopyRect(gMagRect,BackupBitmap.Canvas,gMagRect);
     if not gSmooth then begin
       lX := (X * 100) div gZoomPct;
       lY := (Y * 100) div gZoomPct;
     end else begin
       lX := X;
       lY := Y;
     end;
     gLine.Left := lX;
     gLine.Top := lY;
     lLineWid := abs(gLine.Left - gLine.Right);
     lLineHt := abs(gLine.Top - gLine.Bottom);
     if gSmooth then begin
       lLineWid := ((lLineWid * 100) div gZoomPct);
       lLineHt := ((lLineHt * 100) div gZoomPct);
     end;
     lLineHtmm := lLineHt * gDICOMdata.XYZmm[2];
     lLineWidmm := lLineWid * gDICOMdata.XYZmm[1];
     lLineLenMM := sqrt( sqr(lLineWidmm)+sqr(lLineHtmm));
     gLineLenMM := lLineLenMM;
     lMsgStr := floattostrf(lLineLenMM,ffFixed,8,2)+'mm';
     lTextWid := Image.Canvas.TextWidth(lMsgStr);
     lTextHt := Image.Canvas.TextHeight(lMsgStr);
     if gLine.Left < gLine.Right then
        gMagRect.Left := gLine.Left
     else
        gMagRect.Left := gLine.Right;
     if gLine.Top < gLine.Bottom then
        gMagRect.Top := gLine.Top
     else
        gMagRect.Top := gLine.Bottom;
     if (abs(gLine.Left-gLine.Right)) > (lTextWid+10) then begin
        lTextL := gMagRect.Left+(((abs(gLine.Left-gLine.Right))-lTextWid) div 2);
     end else
        lTextL := gMagRect.Left;
     if (abs(gLine.Top-gLine.Bottom)) > (lTextHt+10) then
        lTextT := gMagRect.Top+(((abs(gLine.Top-gLine.Bottom))-lTextHt) div 2)
     else if gMagRect.Top > 14 then
        lTextT := gMagRect.Top -14
     else
        lTextT := gLine.Bottom + 2;
     if gLine.Left < gLine.Right then begin
        gMagRect.Left := gLine.Left-1;
        gMagRect.Right := gLine.Right+1+lTextWid;
     end else begin
        gMagRect.Left := gLine.Right-1;
        gMagRect.Right := gLine.Left+1+lTextWid;
     end;
     if gLine.Top < gLine.Bottom then begin
        gMagRect.Top := gLine.Top-15;
        gMagRect.Bottom := gLine.Bottom+15;
     end else begin
        gMagRect.Top := gLine.Bottom-14;
        gMagRect.Bottom := gLine.Top+14;
     end;
     Image.Canvas.MoveTo(gLine.Right, gLine.Bottom);
     Image.Canvas.LineTo(gLine.Left, gLine.Top);
     Image.Canvas.Brush.Style := bsClear;
     {if gOverlayColor = 1 then begin
       Image.Canvas.Font.Color := 0;
       Image.Canvas.Brush.Color := clWhite;
     end else begin
      abba}  Image.Canvas.Font.Color := $FFFFFF;
        Image.Canvas.Brush.Color := clBlack;
     //end;
     Image.Canvas.TextOut(lTextL,lTextT,lMsgStr);
     exit;
end;
if (ssCtrl in Shift) then begin
   Image.Canvas.DrawFocusRect(gSelectRect);
   lX := round((X *image.Picture.Height)/image.Height);
   lY := round((Y *image.Picture.Width)/image.Width);
   if gSelectOrigin.X < 1 then begin
        gSelectOrigin.X := lX;
        gSelectOrigin.Y := lY;
   end;
   if lX < gSelectOrigin.X then begin
        gSelectRect.Right := gSelectOrigin.X;
        gSelectRect.Left := lX;
   end else begin
         gSelectRect.Right := lX;
         gSelectRect.Left := gSelectOrigin.X;
   end;
   if lY < gSelectOrigin.Y then begin
        gSelectRect.Bottom := gSelectOrigin.Y;
        gSelectRect.Top := lY;
   end else begin
         gSelectRect.Bottom := (lY);
         gSelectRect.Top := gSelectOrigin.Y
   end;
   Image.Canvas.DrawFocusRect(gSelectRect);
  end else
  if {(ssLeft In Shift) gMouseDown and} (FLastDown.X >= 0) then begin
    GetCursorPos( pt );
    Scrollbox1.VertScrollBar.Position := Scrollbox1.VertScrollBar.Position + FLastDown.Y - pt.Y;
    Scrollbox1.HorzScrollBar.POsition := Scrollbox1.HorzScrollBar.Position + FLastDown.X - pt.X;
    FLastDown := pt;
  end else if (BackupBitmap <> nil) then begin
         ShowMagnifier (X,Y);
  end else if gBuff16sz > 0 then begin
     lX := x-gXStart;
     if ((lX+gStartSlope) > 1024) then
           gFastSlope := 1024
     else if ((lX+gStartSlope) < 1) then
             gFastSlope := 1
     else
         gFastSlope := lX+gStartSlope;
     lSlopeReal := gFastSlope * 0.0878{0.175781 CONTRAST change here};
     lWid := trunc((gImgMax-gIMgMin)/(sin(lSlopeReal*kRadCon)/cos(lSlopeReal*kRadCon)));
     lY := y-gYStart;
     if ((gStartCen + lY)> 1024) then
           gFastCen := 1024
     else if ((lY+gStartCen) < 0) then
             gFastCen := 0
     else
         gFastCen := gStartCen + lY;{}
     lY := round(((gFastCen/ 1024)*(gImgMax-gIMgMin))+gImgMin); {CONTRAST change here: /n where n is amount of mouse movement}
     Scale16to8bit(lY,lWid);
     DICOMImageRefreshAndSize;
  end else begin
     lX := x-gXStart;
     if ((lX+gStartSlope) > 255) then
           gFastSlope := 255
     else if ((lX+gStartSlope) < 0) then
             gFastSlope := 0
     else
         gFastSlope := lX+gStartSlope;
     lY := y-gYStart;
     if ((gStartCen + lY)> 255) then
           gFastCen := 255
     else if ((lY+gStartCen) < 0) then
             gFastCen := 0
     else
         gFastCen := gStartCen + lY;
     UpdatePalette(true,0);
     MainForm.StatusBar.Panels[4].text := gContrastStr;
  end;
end;

procedure TMDIChild.ImageMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//Respond to user releasing mouse: Response depends on tool.
//For area contrast tool, the image intensity in the selected rectangle is evaluated, and the contrast adjust accordingly
procedure MinMaxRect (var lIn: integer; lMaxPlus1: integer);
begin
    if lIn < 0 then lIn := 0;
    if lIn >= lMaxPlus1 then lIn := lMaxPlus1 -1;
end;
var lWinWid,lWinCen,lVal,lMin,lMax,lCol,lROw: integer;
begin
     FLastDown := Point( - 1, - 1);
     Screen.Cursor := crDefault;
     if (gSelectRect.left <> gSelectRect.right) and (gSelectRect.top <> gSelectRect.bottom) then begin
        Image.Canvas.DrawFocusRect(gSelectRect);
        if gSmooth then begin
           gSelectRect.Left := ((gSelectRect.Left * 100) div gZoomPct);
           gSelectRect.Top := ((gSelectRect.Top * 100) div gZoomPct);
           gSelectRect.Right := ((gSelectRect.Right * 100) div gZoomPct);
           gSelectRect.Bottom := ((gSelectRect.Bottom * 100) div gZoomPct);
        end;
        MinMaxRect(gSelectRect.Left,g100pctImageWid);
        MinMaxRect(gSelectRect.Top,g100pctImageHt);
        MinMaxRect(gSelectRect.Right,g100pctImageWid);
        MinMaxRect(gSelectRect.Bottom,g100pctImageHt);
        lMin := VxlVal((gSelectRect.Left),(( gSelectRect.Top )),true);
        lMax := lMin;
        for lCol := gSelectRect.Left to gSelectRect.Right do begin
            for lRow := gSelectRect.Top to gSelectRect.Bottom do begin
                lVal := VxlVal(lCol,lRow,true);
                if lVal < lMin then lMin := lVal;
                if lVal > lMax then lMax := lVal;
            end; //row
        end; //column
        gSelectRect := Rect(0,0,0,0);
        gSelectOrigin.X := -1;
        lWinWid := lMax - lMin;  //max now = windowwid
        lWinCen := lMin + (lWinWid shr 1);
        gWinWid := lWinWid;
        gWinCen := LwinCen;
        gFastCen := lWinCen;
        if gBuff16sz > 0 then begin
           RefreshZoom;
        end else begin
            if lWinWid = 0 then lWinWid := 1;
            UpdatePalette(true,lWinWid);
        end;
     end else
     if (BackupBitmap <> nil) then begin//magnifier was on
        Image.Picture.Graphic  := BackupBitmap;  // Restore base image
        BackupBitmap.Free;
        BackupBitmap := nil;
        IMage.refresh;
     end else if (gMOuseDown) and (gBuff16sz > 0) then begin
         Mainform.WinCenEdit.value := gWinCen;
         MainForm.WinWidEdit.value := gWinWid;

     end;
     gMouseDown := false;
end;

procedure TMDIChild.SelectZoom1Click(Sender: TObject);
begin
if MainForm.ZoomSlider.enabled then
   MainForm.ZoomSlider.SetFocus
else if MainForm.SchemeDrop.enabled then
   MainForm.SchemeDrop.SetFocus;
end;

procedure TMDIChild.ContrastAutobalance1Click(Sender: TObject);
begin
MainForm.AutoBal.Click;
end;

procedure TMDIChild.FormResize(Sender: TObject);
begin
     //if (MainForm.BestFitItem.checked) {and (not gZoomSlider)} then
     automaximise;
end;

procedure TMDIChild.CopyItemClick(Sender: TObject);
var
  MyFormat : Word;
  AData: THandle;
  APalette : HPalette;
begin
    if (Memo1.Visible) and (gDynStr <> '') then begin
       ClipBoard.AsText := gDynStr;
       exit;
    end;
     if (Image.Picture.Bitmap = nil) or (Image.Picture.Width < 1) or (Image.Picture.Height < 1) then exit;
    Image.Picture.Bitmap.SaveToClipBoardFormat(MyFormat);//*CHECK hadd to remove params,AData,APalette
//    ClipBoard.SetAsHandle(MyFormat,AData); //*CHECK Dont exist in Laz
end;

procedure TMDIChild.Timer1Timer(Sender: TObject);
var lSlice: integer;
begin
 if gDicomdata.XYZdim[3] > 1 then begin
     if gSlice >= gDICOMdata.XYZdim[3] then
        lSlice := 1
     else
         lSlice := gSlice + 1;
      DisplayImage(false,false,lSlice,gWinWid,gWinCen);
 end else begin
  Timer1.enabled := false;
  gVideoSpeed := 0;
  MainForm.VideoBtn.Caption := '0';
 end;
end;

procedure TMDIChild.Previous1Click(Sender: TObject);
begin
    gMultiCol := 1;
    gMultiRow := 1;
     if (sender as TMenuItem).tag = 1 then begin //increment
        gCurrentPosInFileList := gCurrentPosInFileList+1;
     end else
         gCurrentPosInFileList := gCurrentPosInFileList-1;
     if (gCurrentPosInFileList >= gFileListSz) then gCurrentPosInFileList := 0;
     if (gCurrentPosInFileList < 0) then gCurrentPosInFileList := gFileListSz-1;
     LoadData( gFilePath+gStringList.Strings[gCurrentPosInFileList] ,false,false,false,false );
     MainForm.ColUpdate;
     automaximise;
end;

procedure TMDIChild.N1x11Click(Sender: TObject);
//Draw a mosaic image, with several slices
var lSize : integer;
begin
 lSize := (sender as TMenuItem).tag;
 Timer1.enabled := false;
 gVideoSpeed := 0;
 MainForm.VideoBtn.Caption := '0';
 if lSize < 5 then begin
    gMultiCol := lSize;
    gMultiRow := lSize;
    gMultiFirst := 1;
    gMultiLast := gDICOMdata.XYZdim[3];
    lSize := gSlice;
    gSlice := 0; //force redraw
    DisplayImage(false,false,lSize,gWinWid,gWinCen);
    automaximise;
 end else begin
     MultiSliceForm.gMaxMultiSlices := gDICOMdata.XYZdim[3];
     MultiSliceForm.ShowModal;
     gMultiCol := MultiSliceForm.ColEdit.value;
     gMultiRow := MultiSliceForm.RowEdit.value;
    gMultiFirst := MultiSliceForm.FirstEdit.value;
    gMultiLast := MultiSliceForm.LastEdit.value;
    lSize := gSlice;
    gSlice := 0; //force redraw
    DisplayImage(false,false,lSize,gWinWid,gWinCen);
    automaximise;
 end;
end;

procedure TMDIChild.Smooth1Click(Sender: TObject);
begin
    Smooth1.checked :=  not Smooth1.checked;
     gSmooth := Smooth1.checked;
     RefreshZoom;
end;

procedure TMDIChild.None1Click(Sender: TObject);
begin
(sender as tmenuitem).checked := true;
RefreshZoom;
end;

procedure TMDIChild.ContrastSuggested1Click(Sender: TObject);
begin
if MainForm.FileContrast.Enabled then
   MainForm.FileContrast.Click;
end;

procedure TMDIChild.CTpreset(Sender: TObject);
begin
     MainForm.ContrastPreset((sender as tmenuitem).tag);
end;

end.



