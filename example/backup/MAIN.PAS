unit Main;

interface                                            

uses Windows, SysUtils, Classes, Graphics, Forms, Controls,LCLIntf,
     Menus, StdCtrls, Dialogs, Buttons, Messages, ExtCtrls, PrintersDlgs,ChildWin,
     ComCtrls,Registry, ToolWin, ExtDlgs, Spin,uLazDicomdicom,uLazDicomDefineTypes,uanalyze;
             
type
  TMainForm = class(TForm)
    MainMenu1 : TMainMenu;
    FileMenu: TMenuItem;
    FileOpenItem      : TMenuItem;
    N1                : TMenuItem;
    FileExitItem      : TMenuItem;
    WindowMenu: TMenuItem;
    WindowCascadeItem : TMenuItem;
    WindowTileItem    : TMenuItem;
    WindowArrangeItem : TMenuItem;
    WindowMinimizeItem: TMenuItem;
    HelpMenu: TMenuItem;
    HelpAboutItem     : TMenuItem;
    OpenDialog: TOpenDialog;
    Opengraphic1: TMenuItem;
    PGOpenDialog: TOpenDialog;
    OpenAnz: TMenuItem;
    ToolBar1: TToolBar;
    WinCenEdit: TSpinEdit;
    WinWidEdit: TSpinEdit;
    SliceSlider: TTrackBar;
    ApplyCon: TSpeedButton;
    Autobal: TSpeedButton;
    OpenECAT: TMenuItem;
    PGSaveDialog: TSaveDialog;
    SchemeDrop: TComboBox;
    ApplyBright: TSpeedButton;
    FileContrast: TSpeedButton;
    StatusBar: TStatusBar;
    BestFitItem: TMenuItem;
    Print1: TMenuItem;
    Exportaspicture1: TMenuItem;
    Close1: TMenuItem;
    ZoomSlider: TTrackBar;
    AutoFitBtn: TSpeedButton;
    Pct100btn: TSpeedButton;
    HdrBtn: TSpeedButton;
    MaximizeAll1: TMenuItem;
    OpenRaw1: TMenuItem;
    ConverttoDICOM1: TMenuItem;
    Convertto1: TMenuItem;
    ConvertMenu: TMenuItem;
    Convertraw1: TMenuItem;
    Convert2Ana: TMenuItem;
    VideoBtn: TSpeedButton;
    Hints1: TMenuItem;
    PrintDialog1: TPrintDialog;
    procedure ContrastPreset(lPreset:integer);
    function AddMRU (lFilename: string): boolean;
    procedure FormCreate(Sender: TObject);
    procedure WindowCascadeItemClick(Sender: TObject);
    procedure UpdateMenuItems(Sender: TObject);
    procedure WindowTileItemClick(Sender: TObject);
    procedure WindowArrangeItemClick(Sender: TObject);
    procedure AppLaunch;
    procedure FileOpenItemClick(Sender: TObject);
    procedure FileExitItemClick(Sender: TObject);
    procedure WindowMinimizeItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure HelpAboutItemClick(Sender: TObject);
    procedure Opengraphic1Click(Sender: TObject);
    procedure SliceSliderChange(Sender: TObject);
    procedure ColUpdate;
    procedure SchemeDropChange(Sender: TObject);
    procedure ApplyConClick(Sender: TObject);
    procedure LoadDropFile (var lFilename: string);
    procedure PrintImg;
    procedure ConLabelClick;
    procedure BestFitItemClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Print1Click(Sender: TObject);
    procedure Exportaspicture1Click(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure GetRegistryData;
    procedure PutRegistryData;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ZoomSliderChange(Sender: TObject);
    procedure Pct100btnClick(Sender: TObject);
    procedure HdrBtnClick(Sender: TObject);
    procedure AutoFitBtnClick(Sender: TObject);
    procedure MaximizeAll1Click(Sender: TObject);
    procedure HintBtnClick(Sender: TObject);
    procedure OpenRaw1Click(Sender: TObject);
    procedure Convertto1Click(Sender: TObject);
    procedure WinCenEditKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure VideoBtnClick(Sender: TObject);
    procedure VideoBtnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
      Child: TMDIChild;
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure CreateMDIChild(Name: string; lAnz,lECAT,l2dImage,lRaw: boolean);
    procedure MRUClick (Sender: TOBject);
    procedure UpdateMRUMenu;    { Public declarations }
    function ConvertImg (lInName: string; lDICOMdata: DICOMdata; l3ForInterfile4ForAna: integer): boolean;

  end;
var
  MainForm: TMainForm;

implementation
{$R *.LFM}

uses  About,ShellAPI,printers, Raw;
const
  kMaxMRU = 8;
  //gFastCheck: boolean = true;
  gMRUra: array [1..kMaxMRU] of string=('','','','','','','','');
  knMenup1 = 11;
  gKeyRoot: string = '\Software\ezDICOM';


procedure TMAinForm.ContrastPreset(lPreset:integer);
var lWid,lCen: integer;
begin
  if MainForm.MDIChildCount = 0 then exit;
  case lPreset of
     0: begin lcen := 400; lwid := 2000; end; //bone
     1: begin lcen := 50; lwid := 350; end; //chest
     2: begin lcen := -600; lwid := 1500; end; //lung
  end;
  if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gBuff16sz > 0 then
         (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Scale16to8bit(lCen,lWid)
  else begin
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gFastCen := lCen;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.UpdatePalette(true,lWid);
  end;
  //     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.RefreshZoom;
  ConLabelClick;
  //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.RefreshZoom;
end;

procedure TMAinForm.MRUClick (Sender: TOBject);
var lFilename: string;
begin;
    lFileName := gMRUra[(Sender as TMenuItem).tag];
    if AddMRU (lFileName) then
       LoadDropFile (lFileName)
    else showmessage('Unable to find the file '+lFileName);
end;
procedure TMAinForm.UpdateMRUMenu;
var lF,lN: integer;
  NewItem: TMenuItem;
begin
     lF := FileMenu.Count;
     if lF > (knMenup1-1) then
        for lN := lF downto knMenup1 do
          FileMenu.Delete(lN-1);
     lF := 0;
     repeat
           inc(lF);
     until (lF = kMaxMRU) or (gMRUra[lF] = '');
     if gMRUra[lF] = '' then
        lF := lF - 1;
     if lF = 0 then exit;
     NewItem := TMenuItem.Create(Self);
        NewItem.Caption := '-';
        FileMenu.Add(NewItem);
     for lN := 1 to lF do begin
        NewItem := TMenuItem.Create(Self);
        NewItem.Caption := gMRUra[lN];
        NewItem.Tag := lN;
        NewItem.Onclick := MRUClick;
        FileMenu.Add(NewItem);
    end;
end;
procedure TMainForm.WMDropFiles(var Msg: TWMDropFiles);
var
lInc: integer;
lFileName: string;
  CFileName: array[0..MAX_PATH] of Char;
begin
  try
    lInc := 0;
    while DragQueryFile(Msg.Drop, lInc, CFileName, MAX_PATH) > 0 do
    begin
         lFileName := CFileName;
         if AddMRU (lFileName) then
            LoadDropFile(lFileName);
      Msg.Result := 0;
      inc(lInc);
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;
(*procedure TMainForm.WMDropFiles(var Msg: TWMDropFiles);
var
lInc: integer;
  CFileName: array[0..MAX_PATH] of Char;
begin
  try
    if DragQueryFile(Msg.Drop, 0, CFileName, MAX_PATH) > 0 then
    begin
         OpenDialog.FileName := CFileName;
         LoadDropFile;
      Msg.Result := 0;
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;
*)
procedure TMainForm.AppLaunch;
var
lStr: String;
I: integer;
begin
  if (ParamCount > 0) then begin
    I := 0;
    repeat
     lStr := '';
     repeat
        inc(I);
        if I = 1 then
            lStr := ParamStr(I)
        else begin
            if lStr <> '' then
               lStr := lStr +' '+ ParamStr(I)
            else
                lStr := ParamStr(I);
        end;
     until (I=ParamCount) or (fileexists(lStr));
     if fileexists(lStr) then begin
        LoadDropFile(lStr);
     end
     else ShowmEssage('Unable to find the file: *'+lStr+'*');
    until I >= ParamCount;
  end;{param count > 0}
  (*lStr := 'C:\TEST.DCM';
  if fileexists(lStr) then
     LoadDropFile(lStr); {*)

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

function TMainForm.AddMRU (lFilename: string): boolean;
var
    lI,lSlot: integer;
    lAbort: boolean;
begin
  if not fileexists(lFilename) then begin
      //showmessage('Unable to find the file '+ lHdrName);
      lAbort := true;
  end else
      lAbort := false;{}
  lSlot := 1;
  for lI := 1 to kMaxMRU do begin
      if (gMRUra[lI] <> '') and(gMRUra[lI] <> lFilename) and (lSlot <= kMaxMRU) then begin
         gMRUra[lSlot] := gMRUra[lI];
         inc(lSlot);
      end;
  end;
  if lSlot < kMaxMRU then
  for lI := lSLot to kMAxMRU do
      gMRUra[lI] :='';
  if lAbort then begin
      UpdateMRUmenu;
      result := false;
      exit;
  end;
  result := true;
  for lI := (kMAxMRU) downto 2 do
      gMRUra[lI] :=gMRUra[lI-1];
  gMRUra[1] := lFilename;
  UpdateMRUMenu;
end;
procedure TMainForm.LoadDropFile (var lFilename: string);
var lExt,lHDrName: string;
lF: file of byte;
    lI,lLen: integer;
begin
     lExt := ExtractFileExt(lFilename);
     if length(lExt) > 0 then

        for lI := 1 to length(lExt) do
            lExt[lI] := upcase(lExt[lI]);
     if (lExt ='.BMP') or (lExt ='.JPG') then begin
          PGOpenDialog.FileName := '';
          PGOpenDialog.InitialDir := extractfiledir(lFilename);
          CreateMDIChild(lFilename,false,false,true,false);
          exit;
     end;
OpenDialog.InitialDir := extractfiledir(lFilename);
if (lExt ='.IMG') or (lExt ='.HDR') then begin
     lHdrName :=ExtractFilePath(lFilename)+ParseFileName(ExtractFileName(lFilename))+'.hdr';
     if fileexists(lHdrName) then begin
            AssignFile(lf, lHdrName);
            Reset(lf);
            lLen := filesize(lf);
            closefile(lf);
            if lLen=(348) then begin
               CreateMDIChild(lHdrName,true,false,false,false);
               exit;
            end;
     end;
end; //try analyze format
CreateMDIChild(lFilename,false,false,false,false);
end;

procedure TMainForm.FormCreate(Sender: TObject);
  var
  lSearchRec: TSearchRec;
  lDICOMdata: dicomdata;
  lHdrOK,lIMgOK: boolean;
  lDynStr,lFile: string;
begin
{convert an image to dicom at startup->
lFile := 'c:\efilm\rgb.dcm' ;
if fileexists(lFile) then deletefile(lFile);
lFile := 'c:\efilm\rgb.dc' ;
 read_dicom_data(false,false,true,false,true,true,true, lDICOMdata, lHdrOK, lImgOK, lDynStr,lFile );
 ConvertImg(lFile, lDICOMdata,1);}
  DecimalSeparator := '.';
  SchemeDrop.Items.Clear;
  SchemeDrop.Items.Add('White & Black');
  SchemeDrop.Items.Add('Black & White');
  SchemeDrop.Items.Add('Hot Metal');
  SchemeDrop.ItemIndex := 1;
  Screen.OnActiveFormChange := UpdateMenuItems;
  DragAcceptFiles(Handle, True);
  GetRegistryData;
    if BestFitItem.checked then begin
     ZoomSLider.enabled := false;
     Pct100btn.enabled := false;
  end else begin
      ZoomSlider.enabled := true;
      Pct100btn.enabled := true;
  end;
  if FindFirst(extractfilepath(paramstr(0))+'\*.lut', faAnyFile, lSearchRec) <> 0 then begin
     FindClose(lSearchRec);
     exit;
  end;
  SchemeDrop.Items.Add(ParseFileName(ExtractFileName(lSearchRec.Name)));
  while (FindNext(lSearchRec) = 0)  do begin
        SchemeDrop.Items.Add(ParseFileName(ExtractFileName(lSearchRec.Name)));
  end;
  FindClose(lSearchRec);
  UpdateMenuItems(nil);
end;

procedure TMainForm.CreateMDIChild(Name: string;lAnz,lECAT,l2dImage,lRaw: boolean);
(*var
  Child: TMDIChild;
  *)
begin
//  LockWindowUpdate(MainForm.Handle);
  Child := TMDIChild.Create( Application );
  Child.Caption := Name;
  if lRaw then begin
      clear_dicom_data(Child.gDicomData);
      Child.gDicomData.XYZdim[1] := RawForm.WidEdit.value;
      Child.gDicomData.XYZdim[2] := RawForm.HtEdit.value;
      Child.gDicomData.XYZdim[3] := RawForm.SliceEdit.value;
      Child.gDicomData.XYZdim[4] := 1;
      Child.gDicomData.ImageStart := RawForm.OffsetEdit.value;
      if RawForm.LittleEndCheck.checked then
         Child.gDicomData.little_endian := 1
      else
         Child.gDicomData.little_endian := 0;
      Child.gDicomData.Allocbits_per_pixel := RawForm.BitsEdit.value;
      if Child.gDicomData.Allocbits_per_pixel = 24 then begin
                        Child.gDicomData.SamplesPerPixel := 3;
                        Child.gDicomData.Allocbits_per_pixel := 8;
                        if RawForm.PlanarRGBCheck.Checked then
                           Child.gDicomData.PlanarConfig := 1
                        else
                           Child.gDicomData.PlanarConfig := 0;
      end;
      Child.gDicomData.Storedbits_per_pixel := Child.gDicomData.Allocbits_per_pixel;
  end;
  if NOT Child.LoadData( Name,lAnz,lECAT,l2dImage,lRaw ) then
  begin
  	Child.free;
    exit;
  end;
    (* TMDIChild(MainForm.ActiveMDIChild). *) Child.LoadFileList;
 // LockWindowUpdate(0);   Child: TMDIChild;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Screen.OnActiveFormChange := nil;

end;

procedure TMainForm.UpdateMenuItems(Sender: TObject);
begin
  WindowCascadeItem.Enabled  := MDIChildCount > 0;
  WindowTileItem.Enabled     := MDIChildCount > 0;
  WindowArrangeItem.Enabled  := MDIChildCount > 0;
  WindowMinimizeItem.Enabled := MDIChildCount > 0;
  Print1.enabled := MDIChildCount > 0;
  Exportaspicture1.enabled := MDIChildCount > 0;
  Close1.enabled := MDIChildCount > 0;
  ColUpdate;
  //CycleWindowItem.Enabled := MDIChildCount > 1;
end;

procedure TMainForm.FileOpenItemClick(Sender: TObject);
var I,lLen,lTag : Integer;
lF: file of byte;
begin
       lTag := (Sender as TMEnuItem).Tag;
       if lTag = 1 then
          OpenDialog.Filter := 'Analyze Header (*.hdr)|*.hdr'
       {else
           OpenDialog.Filter := 'Medical Image|*.*'};
       if OpenDialog.Execute then  begin
           for I:=0 to OpenDialog.Files.Count-1 do begin
               if AddMRU (OpenDialog.Files[i]) then begin
                  OpenDialog.InitialDir := extractfiledir(OpenDialog.Files[i]);
                  Filemode := 0;
                  AssignFile(lf,OpenDialog.Files[i]);
                  Reset(lf);
                  lLen := filesize(lf);
                  closefile(lf);
                  Filemode := 2;
                  if lTag = 2 then //ecat
                     CreateMDIChild(OpenDialog.Files[i],false,true,false,false)
                  else if (lLen = 348) and (ExtractFileExt(OpenDialog.Filename)='.hdr') then
                       CreateMDIChild(OpenDialog.Files[i],true,false,false,false)
                  else
                      CreateMDIChild(OpenDialog.Files[i],false,false,false,false);
               end; //fileexists
           end;
	end;
        //OpenDialog.Filter := 'Medical Image|*.*';
        OpenDialog.Filter := 'Medical Image|*.*';
        ConLabelClick;
end;


procedure TMainForm.FileExitItemClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.WindowCascadeItemClick(Sender: TObject);
begin
  Cascade;
  //if (not BestFitItem.checked) or (MainForm.MDIChildCount = 0) then exit;
  {for I :=  (MDIChildCount - 1) downto 0 do
        MDIChildren[I].}
        //AutoMaximise;
end;

procedure TMainForm.WindowTileItemClick(Sender: TObject);
begin
  Tile;
end;

procedure TMainForm.WindowArrangeItemClick(Sender: TObject);
begin
  ArrangeIcons;
end;

procedure TMainForm.WindowMinimizeItemClick(Sender: TObject);
var
  I: Integer;
begin
  if MDIChildCount = 0 then exit;
  for I := MDIChildCount - 1 downto 0 do
    MDIChildren[I].WindowState := wsMinimized;
end;

procedure TMainForm.HelpAboutItemClick(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TMainForm.Opengraphic1Click(Sender: TObject);
var I: integer;
begin
     //PGOpenDialog1.filename := '';
     //OpenDialog.Filter := 'Images (*.bmp;*.jpg)|*.bmp;*.jpg|Bitmaps (*.bmp)|*.bmp|JPEGs (*.jpg]|*.jpg';
     //PGOpenDialog.Filter := GraphicFilter(TGraphic);
     if PGOpenDialog.Execute then begin
           for I:=0 to PGOpenDialog.Files.Count-1 do begin
               if AddMRU (PGOpenDialog.Files[i]) then begin
                  PGOpenDialog.InitialDir := extractfilepath(PGOpenDialog.Files[i]);
                  PGSaveDialog.InitialDir := PGOpenDialog.InitialDir;
                  //PGSaveDialog.FileName := extractfilename(PGOpenDialog.FileName);
                  //PGOpenDialog.FileName := extractfilename(PGOpenDialog.FileName);
                  CreateMDIChild(PGOpenDialog.Files[i],false,false,true,false);
               end;
           end; //for I..nfiles
     end; //if execute
     //OpenDialog.Filter :='Medical Image|*.*';
end;

procedure TMainForm.SliceSliderChange(Sender: TObject);
begin
  if MDIChildCount = 0 then exit;
//LockWindowUpdate(MainForm.Handle);
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.DisplayImage(false,false,SliceSlider.position,(* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinWid,
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinCen{WinWidEdit.value,WincenEdit.value});
     conlabelclick;
//LockWindowUpdate(0);

end;
procedure TMainForm.ColUpdate;
//var lVox: integer;
begin
  exit;
if MainForm.MDIChildCount = 0 then begin
     ApplyCon.enabled := false;
     ApplyBright.enabled := false;
     FileContrast.enabled := false;
     AutoBal.enabled := false;
     SchemeDrop.enabled:= false;
     WinWidEdit.enabled := false;
     WinCenEdit.enabled := false;
     VideoBtn.Enabled := false;
     SliceSlider.Enabled := false;
   exit;
end;
(*StatusBar.Panels[1].text := inttostr(MainForm.MDIChildCount)+'x'+inttostr(random(255));
if MainForm.MDIChildCount = 0 then begin
     ApplyCon.visible := false;
     ApplyBright.visible := false;
     FileContrast.visible := false;
     AutoBal.visible := false;
     SchemeDrop.visible:= false;
     WinWidEdit.visible := false;
     WinCenEdit.visible := false;
     exit;
end; *)
     //MainForm.ZoomBox.ItemIndex := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gZoom;
if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Memo1.visible then
   HdrBtn.Down := true
else
    HdrBtn.Down := false;
//mainform.Caption := inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gCustomPalette);
if (not (* TMDIChild(MainForm.ActiveMDIChild). *) Child.FDICOM ) then begin
// or  ((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.SamplesPerPixel > 1) or ((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gCustomPalette > 0) {or ((lVox > 7) and (lVox < 17)) }then begin
     ApplyCon.enabled := false;
     ApplyBright.enabled := false;
     FileContrast.enabled := false;
     AutoBal.enabled := false;
     //mainform.caption := 'NOT_DICOM'+inttostr(random(32));
     SchemeDrop.enabled:= false;
     WinWidEdit.enabled := false;
     WinCenEdit.enabled := false;
end else begin
      //mainform.caption := 'DICOM'+inttostr(random(32));
      MainForm.SchemeDrop.ItemIndex := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gScheme;
      WinCenEdit.value := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinCen;
      WinWidEdit.value := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinWid;
      FileCOntrast.enabled := true;
      if ((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.Allocbits_per_pixel < 9) then begin
         //fargo FileCOntrast.enabled := false;
         ApplyCon.enabled := false;
         ApplyBright.enabled := false;
         WinWidEdit.enabled := false;
         WinCenEdit.enabled := false;
      end else begin
         if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDicomData.WindowWidth <> 0 then
            FileCOntrast.enabled := true
         else
             FileCOntrast.enabled := false;
         ApplyCon.enabled := true;
         ApplyBright.enabled := true;
         WinWidEdit.enabled := true;
         WinCenEdit.enabled := true;
      end;
      AutoBal.enabled :=true;
      SchemeDrop.enabled:= true;
  end;
  ConLabelClick;
  //if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinWid = 0 then   ConLabel.caption := '';
 if (not (* TMDIChild(MainForm.ActiveMDIChild). *) Child.FDICOM ) or((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDicomdata.XYZdim[3] < 2) then begin
     SliceSlider.enabled := false;
     VideoBtn.enabled := false;
     //VideoBtn.down := false;
      SliceSlider.position := 1;
  end else begin
      SliceSlider.enabled := true;
     VideoBtn.caption := inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gVideoSpeed);
     VideoBtn.enabled := true;
      SliceSlider.Max := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.XYZdim[3];
      SliceSlider.position := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gSlice;
      //showmessage(inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gSlice)+'.'+inttostr(SliceSlider.Max));
  end;

end;
procedure TMainForm.SchemeDropChange(Sender: TObject);
var lStr: string;
lSearchRec: TSearchRec;
begin
if MainForm.MDIChildCount = 0 then exit;
     if SchemeDrop.ItemIndex > 2 then begin
       lStr := extractfilepath(paramstr(0)){+'\'}+SchemeDrop.Items.Strings[SchemeDrop.ItemIndex]+'.lut';
       if FindFirst(lStr, faAnyFile, lSearchRec) <> 0 then begin
          SchemeDrop.ItemIndex := 0;
          FindClose(lSearchRec);
          exit;
       end;
       FindClose(lSearchRec);
       (* TMDIChild(MainForm.ActiveMDIChild). *) Child.LoadColorScheme(lStr,SchemeDrop.ItemIndex);
     end else
         (* TMDIChild(MainForm.ActiveMDIChild). *) Child.LoadColorScheme('',SchemeDrop.ItemIndex);
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.UpdatePalette(true,0);
     //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.DisplayImage(false,SliceSlider.position,WinWidEdit.value,WincenEdit.value,MainForm.SchemeDrop.itemindex);
     //zap conlabelclick;
end;

procedure TMainForm.ApplyConClick(Sender: TObject);
var lMin,lWid,lCen: integer;
begin
if MainForm.MDIChildCount = 0 then exit;
case (sender as TSpeedButton).tag of
     1: begin
     lMin := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gImgMin;
     lWid := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gImgMax - lMin;
     lCen := lMin + (lWid shr 1);
     //self.caption := inttostr(lMin)+'abba'+inttostr(lCen)+'aaa'+inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gImgMax);
     if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gBuff16sz > 0 then
         (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Scale16to8bit(lCen,lWid)
     else begin
     //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinCen := lMin + (lWid shr 1);
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gFastCen := lMin + (lWid shr 1);
     //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinWid :=lWid;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.UpdatePalette(true,lWid);
     end;
     ConLabelClick;
     exit;
     end;
     2: begin
     WinWidEdit.value :=((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.WindowWidth);
     WinCenEdit.value :=((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.WindowCenter);
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinWid :=((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.WindowWidth);
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinCen :=((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.WindowCenter);
     end;
     else begin
          (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinWid :=WinWidEdit.value ;
          (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gWinCen :=WinCenEdit.value ;
     end;
     end;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.RefreshZoom;
     //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.DisplayImage(true,false,SliceSlider.position,WinWidEdit.value,WincenEdit.value);
     ConLabelClick;
end;
PROCEDURE PrintBitmap(Canvas:  TCanvas; DestRect:  TRect;  Bitmap:  TBitmap);
  VAR
    BitmapHeader:  pBitmapInfo;
    BitmapImage :  POINTER;
    HeaderSize  :  DWORD;    // Use DWORD for D3-D5 compatibility
    ImageSize   :  DWORD;
BEGIN
  (*GetDIBSizes(Bitmap.Handle, HeaderSize, ImageSize);
  GetMem(BitmapHeader, HeaderSize);
  GetMem(BitmapImage,  ImageSize);
  TRY
    GetDIB(Bitmap.Handle, Bitmap.Palette, BitmapHeader^, BitmapImage^);
    StretchDIBits(Canvas.Handle,
                  DestRect.Left, DestRect.Top,     // Destination Origin
                  DestRect.Right  - DestRect.Left, // Destination Width
                  DestRect.Bottom - DestRect.Top,  // Destination Height
                  0, 0,                            // Source Origin
                  Bitmap.Width, Bitmap.Height,     // Source Width & Height
                  BitmapImage,
                  TBitmapInfo(BitmapHeader^),
                  DIB_RGB_COLORS,
                  SRCCOPY)
  FINALLY
    FreeMem(BitmapHeader);
    FreeMem(BitmapImage)
  END
  *)
END {PrintBitmap};
procedure TMainForm.PrintImg;
VAR
  Bitmap             :  TBitmap;
  liHt,liWid,iFromLeftMargin,iPrintedImageWidth,jDelta,jFromTopOfPage,jPrintedImageHeight:  INTEGER;
begin
  if MainForm.MDIChildCount = 0 then exit;
  if not PrintDialog1.Execute then exit;
  liHt := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Height;
  liWid := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Width;
  if (liHt = 0) or (liWid = 0) then exit;
  Screen.Cursor := crHourGlass;
  TRY
    {if liHt >= liWid then
        Printer.Orientation := poPortrait //image is taller than wide
    else
        Printer.Orientation := poLandscape; //image is wider than tall
     }
      Printer.BeginDoc;
      Printer.Canvas.Font.Size := 12;
      Printer.Canvas.Font.Name := 'Arial';
      jDelta := Printer.Canvas.TextHeight('X');
      //jFromTopOfPage := 3*jDelta;
      //s := 'Image Title';
      //Printer.Canvas.TextOut(CenterText(s), jFromTopOfPage, s);
      // 5th line from top
      jFromTopOfPage := 5*jDelta;

      // Image position and size
      // 12% left and right margin
      iFromLeftMargin    := MulDiv(Printer.PageWidth,12,100);  // 12%
      if (liHt/liWid) > (Printer.PageHeight/Printer.PageWidth) then begin
         //Paper HEIGHT is constrained aspect ration
         // Set printed bitmap with to be 76% of paper HEIGHT
         jPrintedImageHeight := MulDiv(Printer.PageHeight,76,100);  // 76%
         // Set printed bitmap WIDTH to maintain aspect ratio
         iPrintedImageWidth:= liWid*jPrintedImageHeight DIV liHt;
         // maintain aspect ratio of bitmap
      end else begin
         //Paper WIDTH is constrained aspect ration
        // Set printed bitmap with to be 76% of paper WIDTH
           iPrintedImageWidth := MulDiv(Printer.PageWidth,76,100);  // 76%
           // Set printed bitmap height to maintain aspect ratio
           jPrintedImageHeight := liHt*iPrintedImageWidth DIV liWid;
      end;
      Bitmap := TBitmap.Create;
      TRY
        Bitmap.Width  := liWid;
        Bitmap.Height := liHt;
        Bitmap.PixelFormat := pf24bit;
        // Convert JPEG to BMP
        Bitmap.Canvas.Draw(0,0, (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Graphic);
        PrintBitmap (Printer.Canvas,
                    Rect(iFromLeftMargin, jFromTopOfPage,
                        iFromLeftMargin + iPrintedImageWidth,
                         jFromTopOfPage  + jPrintedImageHeight),
                    Bitmap)
      FINALLY
        Bitmap.Free
      END;
    Printer.EndDoc;
  FINALLY
    Screen.Cursor := crDefault
  END;
end;

procedure TMainForm.ConLabelClick;
//var lWid,lCen: integer;
begin

  if (MainForm.MDIChildCount = 0) then exit;
  StatusBar.Panels[1].text := inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gZoomPct)+'%';
  if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMData.XYZdim[3] < 2 then
     StatusBar.Panels[2].text := inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMData.XYZdim[1])+'x'+inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMData.XYZdim[2])
  else
     StatusBar.Panels[2].text := inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gSlice)+'/'+ inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMData.XYZdim[3])+' '+inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMData.XYZdim[1])+'x'+inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMData.XYZdim[2]);
  if ((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gimgmin=0)and ((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gimgmax=0) then
     StatusBar.Panels[3].text := ''
  else
      StatusBar.Panels[3].text := 'Image  Cen/Wid: '
     +inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gimgCen)+'/'+inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gimgWid);
 StatusBar.Panels[4].text := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gContrastStr{+'abba'+inttostr(random(888))};
end;

procedure TMainForm.BestFitItemClick(Sender: TObject);
begin
  BestFitItem.checked := not BestFitItem.checked;
  AutoFitBtn.Down := BestFitItem.checked;
  if BestFitItem.checked then begin
     ZoomSLider.enabled := false;
     Pct100btn.enabled := false;
  end else begin
      ZoomSlider.enabled := true;
      Pct100btn.enabled := true;
  end;
  if MainForm.MDIChildCount = 0 then exit;
  if BestFitItem.checked then
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.AutoMaximise;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if (MainForm.MDIChildCount = 0) or (not BestFitItem.checked) then exit;
  (* TMDIChild(MainForm.ActiveMDIChild). *) Child.AutoMaximise; 
end;

procedure TMainForm.Print1Click(Sender: TObject);
begin
PrintImg;
end;

procedure TMainForm.Exportaspicture1Click(Sender: TObject);
var
   JPG : TJPEGImage;
   BMP: TBitmap;
   lExt: string;
   lS: integer;
begin
     //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.Image = nil then exit;
     if not MainForm.PGSaveDialog.Execute then exit;
     PGOpenDialog.InitialDir := extractfilepath(PGSaveDialog.FileName);
     PGSaveDialog.InitialDir := PGOpenDialog.InitialDir;
     lExt := ExtractFileExt(MainForm.PGSaveDialog.FileName);
     if length(lExt) > 0 then
        for lS := 1 to length(lExt) do
            lExt[lS] := upcase(lExt[lS]);
     if ('.JPG'= lExt) or (lExt='.JPEG') then begin
           JPG := TJPEGImage.Create;
           TRY
              JPG.CompressionQuality := 80;
              //if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.FDICOM and (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gImgOK then
              //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.DisplayImage(true,false,false,SliceSlider.position,WinWidEdit.value,WincenEdit.value{,MainForm.SchemeDrop.itemindex});
              //JPG.Assign((* TMDIChild(MainForm.ActiveMDIChild). *) Child.Image.Picture.Bitmap);
              //following code ensures color palette is saved
              BMP := TBitmap.create;
              try
                 BMP.Height := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Height;
                 BMP.Width := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Width;
                 BMP.PixelFormat := pf24bit;
                 BMP.Canvas.Draw(0,0, (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Graphic);
                 JPG.Assign(BMP);
              finally
                        BMP.Free;
              end;
              JPG.SaveToFile(ChangeFileExt(MainForm.PGSaveDialog.FileName,'.jpg'));
           FINALLY
               JPG.Free
           END;
     end else
  	(* TMDIChild(MainForm.ActiveMDIChild). *) Child.Image.Picture.Bitmap.SaveToFile( ChangeFileExt(MainForm.PGSaveDialog.FileName,'.bmp' ));
     PGSaveDialog.Filename := '';   
end;

procedure TMainForm.Close1Click(Sender: TObject);
begin
if MainForm.MDIChildCount = 0 then UpdateMenuItems(nil);
(* TMDIChild(MainForm.ActiveMDIChild). *) Child.close;
end;
procedure TMainForm.GetRegistryData;
  var
    reg: TRegistry;
    lInc: integer;
    lStr: STRING;
  begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey( gKeyRoot, true ) then begin
      if reg.ValueExists( 'OpenDir' ) then
        lStr := reg.ReadString( 'OpenDir' );
      OpenDialog.InitialDir := lStr;
      if reg.ValueExists( 'PixDir' ) then
        lStr := reg.ReadString( 'PixDir' );
      PGOpenDialog.InitialDir := lStr;
      PGSaveDialog.InitialDir := lStr;
      if reg.ValueExists( 'RawWid' ) then gRawWid := reg.ReadInteger('RawWid');
      if reg.ValueExists( 'RawHt' ) then gRawHt := reg.ReadInteger('RawHt');
      if reg.ValueExists( 'RawSlice' ) then gRawSlice := reg.ReadInteger('RawSlice');
      if reg.ValueExists( 'RawOffset' ) then gRawOffset := reg.ReadInteger('RawOffset');
      if reg.ValueExists( 'RawBits' ) then gRawBits := reg.ReadInteger('RawBits');
      if reg.ValueExists( 'RawLittleEnd' ) then gRawLittleEnd := reg.ReadBool('RawLittleEnd');
      if reg.ValueExists( 'RawPlanarRGB' ) then gRawPlanarRGB := reg.ReadBool('RawPlanarRGB');
      if reg.ValueExists( 'Maximize' ) then
        BestFitItem.checked := reg.ReadBool( 'Maximize' );
      AutoFitBtn.Down := BestFitItem.checked;
      for lInc := 1 to kMaxMRU do
          if reg.ValueExists( 'MRU'+inttostr(lInc) ) then begin
             lStr := reg.ReadString('MRU'+inttostr(lInc) );
             if (length(lStr)>0)  {and (fileexistsex(lStr))} then begin
                gMRUra[lInc] := lStr;
             end;
          end;
      end;
  finally
    reg.Free;
    end;
  UpdateMRUMenu;

  end;

  procedure TMainForm.PutRegistryData;
  var
    reg: TRegistry;
    lInc: integer;
  begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if reg.OpenKey( gKeyRoot, true ) then
      begin
      reg.WriteString( 'OpenDir', OpenDialog.INitialDir );
      reg.WriteString( 'PixDir', PGOpenDialog.InitialDir );
      reg.WriteInteger('RawWid',gRawWid);
      reg.WriteInteger('RawHt',gRawHt);
      reg.WriteInteger('RawSlice',gRawSlice);
      reg.WriteInteger('RawOffset',gRawOffset);
      reg.WriteInteger('RawBits',gRawBits);
      reg.WriteBool( 'RawLittleEnd',gRawLittleEnd);
      reg.WriteBool('RawPlanarRGB',gRawPlanarRGB);
      reg.WriteBool( 'Maximize',BestFitItem.checked );
      for lInc := 1 to kMaxMRU do begin
                reg.WriteString( 'MRU'+inttostr(lInc), gMRUra[lInc] );
      end;
      reg.CloseKey;
      end;
  finally
    reg.Free;
    end;
  end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
PutRegistryData;
end;

procedure TMainForm.ZoomSliderChange(Sender: TObject);
var lZoomPct:integer;
begin
     //gZoomSlider := true;
     //lTMp := WindowmaximizeItem.checked;
     //WindowmaximizeItem.checked := false;
     if MainForm.MDIChildCount = 0 then exit;
     lZoomPct := ZoomSlider.Position;
     if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gZoomPct = lZoomPct then exit;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gZoomPct := lZoomPct;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.RefreshZoom;
{     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gZoomPct := lZoomPct;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Height:= round((* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Height * (lZoomPct/100));
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Width := round((* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.Picture.Width * (lZoomPct/100));
     StatusBar.Panels[1].text := inttostr((* TMDIChild(MainForm.ActiveMDIChild). *) Child.gZoomPct)+'%';
 }    //(* TMDIChild(MainForm.ActiveMDIChild). *) Child.image.refresh;
     //WindowmaximizeItem.checked := lTmp;
     //gZoomSlider := false;
end;

procedure TMainForm.Pct100btnClick(Sender: TObject);
begin
     ZoomSlider.Position := 100;
     ZoomSliderChange(nil);
end;

procedure TMainForm.HdrBtnClick(Sender: TObject);
begin
     if MainForm.MDIChildCount = 0 then exit;
     //HdrBtn.Down := not HdrBtn.Down;
     //if HdrBtn.Down then
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Memo1.visible := HdrBtn.Down;
end;

procedure TMainForm.AutoFitBtnClick(Sender: TObject);
begin
  BestFitItem.Click;
end;

procedure TMainForm.MaximizeAll1Click(Sender: TObject);
var I: integer;
begin
  if MainForm.MDIChildCount = 0 then exit;
  for I :=  (MDIChildCount - 1) downto 0 do
         MDIChildren[I].WindowState := wsMaximized;
 {}
end;

procedure TMainForm.HintBtnClick(Sender: TObject);
begin
Showmessage('You can drag the mouse over an image to change the view. '+kCR+
' Dragging changes the contrast.'+kCR+
' Alt+dragging pans the scrollbars.'+kCR+
' Shift+dragging magnifies the region under the mouse.'+kCR+
' Ctrl+dragging selects a region for contrast optimization.'+kCR+
'When multiple windows are open, use Ctrl+Tab to select an image.');
end;

procedure TMainForm.OpenRaw1Click(Sender: TObject);
var I: integer;
lConv, lConvAny: boolean;
lDICOMdata: DICOMdata;
begin
  //Memo1.lines.add(inttostr(gDicomData.ImageStart));
  if MDIChildCount <> 0 then begin
     gRawOffset := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.ImageStart;
     gRawWid := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.XYZdim[1];
     gRawHt := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.XYZdim[2];
     gRawSlice := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.XYZdim[3];
     if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.SamplesPerPixel = 3 then
         gRawBits := 24
     else
         gRawBits := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.Storedbits_per_pixel;
     if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.little_endian = 1 then
        gRawLittleEnd:= true
     else
         gRawLittleEnd:= false;
     if (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gDICOMdata.PlanarConfig = 1 then
        gRawPlanarRGB := true
     else
         gRawPlanarRGB:= false;
  end;
     //RawForm.WidEditChange(nil);
     RawForm.showmodal;
     if gRawOK = 0 then exit;  //cancel
     if gRawOK > 1 then //user wants to convert file
        showmessage('Note that ezDICOM does not same voxel size [mm] for converted raw files. If required, use MRIcro to convert files.');
     if (RawForm.BitsEdit.value = 20) then begin
         showmessage('The current version of the software is unable to view or convert 20-bit images.');
         exit;
     end;
     if (gRawOK > 2) and (RawForm.BitsEdit.value = 24) then begin
        showmessage('The current version of the software is unable to convert 24-bit images to Analyze/Interfile.');
        exit;
     end;
     lConvAny := false;
     if OpenDialog.Execute then  begin
           for I:=0 to OpenDialog.Files.Count-1 do begin
               if Fileexists (OpenDialog.Files[i]) then begin //do NOT add to MRU!
                  OpenDialog.InitialDir := extractfiledir(OpenDialog.Files[i]);
                  if gRawOK = 1 then //view
                     CreateMDIChild(OpenDialog.Files[i],false,false,false,true)
                  else begin //convert raw to dicom or interfile
                     clear_dicom_data(lDICOMdata);
                     lDicomData.XYZdim[1] := RawForm.WidEdit.value;
                     lDicomData.XYZdim[2] := RawForm.HtEdit.value;
                     lDicomData.XYZdim[3] := RawForm.SliceEdit.value;
                     lDicomData.XYZdim[4] := 1;
                     lDicomData.ImageStart := RawForm.OffsetEdit.value;
                     if RawForm.LittleEndCheck.checked then
                        lDicomData.little_endian := 1
                     else
                         lDicomData.little_endian := 0;
                     lDicomData.Allocbits_per_pixel := RawForm.BitsEdit.value;
                     if lDicomData.Allocbits_per_pixel = 24 then begin
                        lDicomData.SamplesPerPixel := 3;
                        lDicomData.Allocbits_per_pixel := 8;
                        if RawForm.PlanarRGBCheck.Checked then
                           lDicomData.PlanarConfig := 1
                        else
                           lDicomData.PlanarConfig := 0;
                     end;
                     lDicomData.Storedbits_per_pixel := RawForm.BitsEdit.value;
                     lDicomData.ImageSz := (lDicomData.SamplesPerPixel*(lDicomData.XYZdim[1]* lDicomData.XYZdim[2]*lDicomData.Allocbits_per_pixel+7) div 8  )*lDicomData.XYZdim[3];
                     lConv := ConvertImg (OpenDialog.Files[i],lDICOMdata,gRawOK);
                     if lConv then lConvANy := true;
                  end; //convert raw
               end; //fileexists
           end;
	end;
        ConLabelClick;
        if lConvAny then begin
            showmessage('Converted images have been placed in the folder '+extractfilepath(OpenDialog.Filename));
        end;
end;
function TMainForm.ConvertImg (lInName: string; lDICOMdata: DICOMdata; l3ForInterfile4ForAna: integer): boolean;
var lOffset,lSliceSz,lOutHdrSz,lInc : Integer;
lHdrOK: boolean;
lOutHdr,lOutImg: String;
lF,lOutF: file of byte;
lBuff: bytep0;
begin
     result := false;
     lOffset := lDicomdata.ImageStart;
     if (lDicomData.SamplesPerPixel > 1) and ((l3ForInterfile4ForAna= 3) or (l3ForInterfile4ForAna= 4)) then begin
        showmessage('Error: This software can not convert 24-bit RGB images to Analyze or Interfile formats.');
        exit;
     end;
     lDicomData.ImageStart := 0;
     if l3ForInterfile4ForAna = 4 then begin //interfile
        lOutHdr := changefileext(lInname,'.hdr');
        lOutImg := changefileext(lInname,'.img');
     end else if l3ForInterfile4ForAna = 3 then begin //interfile
        lOutHdr := changefileext(lInname,'.i3h');
        lOutImg := changefileext(lInname,'.i3i');
     end else begin //tag <> interfile
         lOutHdr := changefileext(lInName,'.dcm');
         lOutImg := lOutHdr;
     end; //save DCM
     if fileexists(lOutHdr) then showmessage ('The file '+lOutHdr+' already exists.')
     else if fileexists(lOutImg) then showmessage ('The file '+lOutImg+' already exists.')
     else begin  //file does not exist
          lOutHdrSz := 0;
          lHdrOK := true;
          lDicomData.ImageSz := lDicomData.XYZdim[1]*lDicomData.XYZdim[2]*lDicomData.XYZdim[3]*(lDicomData.Storedbits_per_pixel div 8)*lDicomData.SamplesPerPixel;
          if l3ForInterfile4ForAna = 4 then
             lHdrOK := SaveAnalyzeHdr (lOutHdr, lDicomData)
             //write_interfile_hdr (lOutHdr,lOutImg, lDICOMdata)
          else if l3ForInterfile4ForAna = 3 then
             write_interfile_hdr (lOutHdr,lOutImg, lDICOMdata)
          else
              write_dicom (lOutHdr,lDICOMdata,lOutHdrSz, {true}true);
          if (lDICOMdata.XYZdim[3] > 0) and (lHdrOK) then begin
             result := true;
             lSliceSz :=  ((lDICOMdata.XYZdim[1]*lDICOMdata.XYZdim[2]{height * width} * lDICOMdata.Allocbits_per_pixel+7) div 8)*lDicomData.SamplesPerPixel ;
             AssignFile(lF,lInName);
             FileMode := 0; //read Only
             reset(lF);
             if ((lSliceSz * lDICOMdata.XYZdim[3])+lOffset) > filesize(lf) then begin
                showmessage('The input file is too small. Unable to convert data.');
                closefile(lf);
                exit;
             end;
             GetMem( lBuff, lSliceSz);
             Seek(lF,lOffset);
             FileMode := 2; //read/write
             AssignFile(lOutF, lOutImg);
             if lOutHdrSz = 0 then
                Rewrite(lOutF)
             else begin
                  Reset(lOutF);
                  Seek(lOutF,lOutHdrSz);
             end; //hdrsz
             for lInc := 1 to lDICOMdata.XYZdim[3] do begin
                 FileMode := 0; //read only
                 BlockRead(lF, lBuff^, lSliceSz);
                 FileMode := 2; //read/write
                 BlockWrite(lOutF, lBuff^, lSliceSz);
             end; //for each slice
             CloseFile(lF);
             closeFile(lOutF);
          end; //if > 0 slices
     end; //filenames are unique
     FileMode := 2; //read/write
end;

procedure TMainForm.Convertto1Click(Sender: TObject);
var I,lLen,lTag : Integer;
lHdrOK,lImgOK,lConv,lConvAny: boolean;
lDICOMdata: DICOMdata;
lFileName{,lOutHdr,lOutImg},lDynStr: String;
lF: file of byte;
begin
       lTag := (Sender as TMEnuItem).Tag;
       lConv := false;
       lConvAny := false;
       if OpenDialog.Execute then  begin
           for I:=0 to OpenDialog.Files.Count-1 do begin
               if AddMRU (OpenDialog.Files[i]) then begin
                  OpenDialog.InitialDir := extractfiledir(OpenDialog.Files[i]);
                  Filemode := 0;
                  AssignFile(lf,OpenDialog.Files[i]);
                  Reset(lf);
                  lLen := filesize(lf);
                  closefile(lf);
                  Filemode := 2;
                  lFileName :=  OpenDialog.Files[i];
                  if (lLen = 348) then
                       OpenAnalyze (lHdrOK,lImgOK,lDynStr,lFileName,lDicomData)
                  else
                       read_dicom_data(false,false,true,false,true,true,true, lDICOMdata, lHdrOK, lImgOK, lDynStr,lFileName );
                  if (not lImgOK) or (not lHdrOK)  then
                     Showmessage('Unable to read this image: try using MRIcro.')
                  else if (not lImgOK) or (not lHdrOK) or (lDICOMdata.RunLengthEncoding)  or(lDICOMdata.JPEGlosslessCpt) or (lDICOMdata.JPEGlossyCpt)  or(lDICOMdata.GenesisCpt) or (lDICOMdata.GenesisPackHdr<> 0) then begin
                     Showmessage('Unable to convert compressed image data: try using MRIcro.');
                  end else begin
                      if FileExists(lFileName) then
                         lConv := ConvertImg(lFileName, lDICOMdata,lTag);
                      if lConv then lConvAny := true;
                  end;
               end; //fileexists
           end;
	end;
        ConLabelClick;
        if lConvAny then begin
            showmessage('Converted images have been placed in the folder '+extractfilepath(OpenDialog.Filename));
        end;
end;

procedure TMainForm.WinCenEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if MainForm.MDIChildCount = 0 then exit;
//if (ssShift in Shift) then StatusBar.Panels[1].text := inttostr(random(1024));
if key = 13 then
   ApplyCon.Click;
end;

procedure TMainForm.VideoBtnClick(Sender: TObject);
//var lSpeed: integer;
begin
(*  if MainForm.MDIChildCount > 0 then begin
     lSpeed := Child.gvideospeed;
     if lSpeed > 4 then
        lSpeed := 0
     else
         inc(lSpeed);
     Child.gMultiRow := 1;
     Child.gMultiCol := 1;
     Child.gVideoSpeed := lSpeed;
     if lSpeed > 0 then begin
        Child.Timer1.Interval := 100 * lSpeed;
        Child.Timer1.enabled := true;
     end else
         Child.Timer1.enabled := false;
     VideoBtn.Caption := inttostr(lSpeed);
  end;*)
end;

procedure TMainForm.VideoBtnMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var lSpeed: integer;
begin
  if MainForm.MDIChildCount > 0 then begin
     lSpeed := (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gvideospeed;
     if Button = mbLeft then begin
        if lSpeed > 4 then
           lSpeed := 0
        else
         inc(lSpeed);
     end else begin
         if lSpeed < 1 then
            lSpeed := 5
         else
             dec(lSpeed);
     end;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gMultiRow := 1;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gMultiCol := 1;
     (* TMDIChild(MainForm.ActiveMDIChild). *) Child.gVideoSpeed := lSpeed;
     if lSpeed > 0 then begin
        (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Timer1.Interval := 100 * lSpeed;
        (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Timer1.enabled := true;
     end else
        (* TMDIChild(MainForm.ActiveMDIChild). *) Child.Timer1.enabled := false;
     VideoBtn.Caption := inttostr(lSpeed);
  end;
end;

end.
