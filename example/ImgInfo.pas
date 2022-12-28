(*
 *  ImgInfo.pas - ezDICOM: Image Information
 *  Project: ezDICOM
 *  Purpose: Display's DICOM information
 *  Rev:
 *	01-Jul-97, wk: first implementation coded
 *   30-Oct-99, cr: updated for pixelgraphic
 *)
 unit ImgInfo;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ChildWin,Dialogs, ToolWin, ComCtrls;

type
  TImgInfoDlg = class(TForm)
    Memo1: TMemo;
    SaveDialog: TSaveDialog;
    ToolBar1: TToolBar;
    SaveBtn: TSpeedButton;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ImgInfoDlg: TImgInfoDlg;

implementation

uses Main;

{$R *.DFM}

(*========================================================================*)
procedure TImgInfoDlg.SpeedButton1Click(Sender: TObject);
begin
	if Memo1.Lines.Count < 1 then begin
        ShowMessage('DICOM summary is empty.');
        exit;
     end;
     Memo1.SelectAll;
     Memo1.CopyToClipBoard

end;

procedure TImgInfoDlg.SaveBtnClick(Sender: TObject);
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

end.
