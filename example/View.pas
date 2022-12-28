unit View;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, RXSlider, PGraphic;
var
   gcWhite,gcBlack,gcSlice,gcnSlice,gcScale,gcZoom: integer;

type
  TViewForm = class(TForm)
    Image1: TPGImage;
    Label7: TLabel;
    Label1: TLabel;
    BlackSlide: TRxSlider;
    WhiteSlide: TRxSlider;
    SliceSlider: TRxSlider;
    SliceLabel: TLabel;
    SchemeDrop: TComboBox;
    ScaleDrop: TComboBox;
    ProDrop: TComboBox;
    procedure FormShow(Sender: TObject);
    procedure BlackSlideChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ViewForm: TViewForm;

implementation

uses Childwin, Main;

{$R *.DFM}

procedure TViewForm.FormShow(Sender: TObject);
begin
{BlackSlide.value := gcBlack;
WhiteSlide.value := gcWhite;}
end;

procedure TViewForm.BlackSlideChange(Sender: TObject);
begin
     if ((Sender as TRxSlider).name <> 'BlackSlide') and(BlackSlide.value > WhiteSlide.value) then
        BlackSlide.value := WhiteSlide.value
     else if (BlackSlide.value > WhiteSlide.value) then
            WhiteSlide.value := BlackSlide.value;
     gcWhite :=WhiteSlide.value;
     gcBlack := BlackSlide.Value;
     TMDIChild(MainForm.ActiveMDIChild).updatepalette;

end;

end.
