unit Raw;
        
interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, StdCtrls, Spin;

type
  TRawForm = class(TForm)
    Label1: TLabel;
    WidEdit: TSpinEdit;
    Label2: TLabel;
    HtEdit: TSpinEdit;
    Label3: TLabel;
    SliceEdit: TSpinEdit;
    Label4: TLabel;
    OffsetEdit: TSpinEdit;
    Label5: TLabel;
    BitsEdit: TSpinEdit;
    LittleEndCheck: TCheckBox;
    SzLabel: TLabel;
    CancelBtn: TSpeedButton;
    OKBtn: TSpeedButton;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Label6: TLabel;
    PlanarRGBCheck: TCheckBox;
    procedure WidEditChange(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RawForm: TRawForm;
  gRawOK: integer = 0;
  gRawWid : integer = 256;
gRawHt : integer = 256;
gRawSlice : integer = 1;
gRawOffset : integer = 0;
gRawBits : integer = 8;
gRawLittleEnd: boolean = false;
gRawPlanarRGB: boolean = false;

implementation

{$R *.LFM}

procedure TRawForm.WidEditChange(Sender: TObject);
begin
     {if BitsEdit.value in [8,12,16,24] then begin
        SzLabel.caption := 'File size: '+inttostr(
        (((WidEdit.value*HtEdit.value*SliceEdit.value*BitsEdit.value )+7) div 8) +offsetedit.value);
     end else if

     else
         BitsEdit.value := 24;}
     SzLabel.caption := 'File size: '+inttostr(
     (((WidEdit.value*HtEdit.value*SliceEdit.value*BitsEdit.value )+7) div 8) +offsetedit.value);
     if BitsEdit.value = 24 then
        PlanarRGBCheck.Visible := true
     else
        PlanarRGBCheck.Visible := false;
end;

procedure TRawForm.OKBtnClick(Sender: TObject);
begin
     gRawOK := (Sender as TSpeedbutton).tag;
      gRawWid:= WidEdit.value;
      gRawHt:= HtEdit.value;
      gRawSlice:= SliceEdit.value ;
      gRawOffset:= OffsetEdit.value;
      gRawBits:= BitsEdit.value;
      gRawPlanarRGB := PlanarRGBCheck.checked;
      gRawLittleEnd:= LittleEndCheck.checked;
     RawForm.close;
end;

procedure TRawForm.CancelBtnClick(Sender: TObject);
begin
     gRawOK := 0;
     RawForm.close;
end;

procedure TRawForm.FormShow(Sender: TObject);
begin
     WidEdit.value := gRawWid;
     HtEdit.value := gRawHt;
     SliceEdit.value := gRawSlice;
     OffsetEdit.value := gRawOffset;
     BitsEdit.value := gRawBits;
     LittleEndCheck.checked := gRawLittleEnd;
     PlanarRGBCheck.Checked := gRawPlanarRGB;
end;

end.
