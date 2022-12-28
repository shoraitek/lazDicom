unit uMultislice;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Spin, Buttons;

type
  TMultiSliceForm = class(TForm)
    OKBtn: TSpeedButton;
    ColEdit: TSpinEdit;
    RowEdit: TSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    FirstEdit: TSpinEdit;
    LastEdit: TSpinEdit;
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ColEditChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    gMaxMultiSlices: integer;
  end;

var
  MultiSliceForm: TMultiSliceForm;

implementation

{$R *.DFM}

procedure TMultiSliceForm.OKBtnClick(Sender: TObject);
begin
	Close;
end;

procedure TMultiSliceForm.FormShow(Sender: TObject);
begin
     LastEdit.MaxValue := gMaxMultiSlices;
     FirstEdit.MaxValue := gMaxMultiSlices;
     FirstEdit.Value := 1;
     LastEdit.value := gMaxMultiSlices;
     ColEditChange(nil);
     //FirstEdit.value + (ColEdit.value * RowEdit.value) - 1;
     //if LastEdit.value > gMaxMultiSlices then
     //   LastEdit.value := gMaxMultiSlices;  //not req, as > maxvalue?
end;

procedure TMultiSliceForm.ColEditChange(Sender: TObject);
begin
 if (ColEdit.Value *  RowEdit.Value) >= FirstEdit.MaxValue then begin
    FirstEdit.value := 1;
    LastEdit.value := LastEdit.maxvalue;
    FirstEdit.enabled := false;
    LastEdit.Enabled := false;
 end else begin
    FirstEdit.enabled := true;
    LastEdit.Enabled := true;

 end;
end;

end.
