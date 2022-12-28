(*
 *  ezDICOM.dpr - ezDICOM: project file
 *  Project: ezDICOM
 *  Purpose: ezDICOM project
 *  Rev:10
 *	01-Jul-97, wk: first implementation coded
 *   7-7-2000, cr: 
 *)
program ezDicom;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
   Interfaces,
{$ENDIF}
  Forms,
  IniFiles,
  SysUtils,
  Dialogs,
  LCLIntf, LCLType, LMessages,
  Main in 'MAIN.PAS' {MainForm},
  About in 'About.pas' {AboutBox},
  Childwin in 'Childwin.pas' {MDIChild},
  Raw in 'Raw.pas' {RawForm},
  uMultislice in 'uMultislice.pas' {MultiSliceForm};

{$R *.res}



begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TRawForm, RawForm);
  Application.CreateForm(TMultiSliceForm, MultiSliceForm);
  Application.Title := 'ezDICOM';
  Application.CreateForm(TAboutBox, AboutBox);
  MainForm.Applaunch;
  Application.Run;

end.
