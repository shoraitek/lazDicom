unit About;

interface

uses
Windows, StdCtrls, ExtCtrls, Controls, Buttons, Classes,Forms;
//SysUtils;//, Classes, Graphics, Forms,Controls, StdCtrls, Buttons, ExtCtrls, Dialogs;
const

     kRadCon = pi/180;
     kMaxECAT = 512;
     PixelCountMax = 32768;
type

  xRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = ARRAY[0..PixelCountMax-1] OF TRGBTriple;

  TAboutBox = class(TForm)
    OKButton: TButton;
    Memo1: TMemo;
    SpeedButton1: TSpeedButton;
    Image1: TImage;
    Label1: TLabel;
    Version: TLabel;
    procedure OKButtonClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

uses Main;

{$R *.LFM}
procedure TAboutBox.OKButtonClick(Sender: TObject);
begin
	Close;
end;

end.

