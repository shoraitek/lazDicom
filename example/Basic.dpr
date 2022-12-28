program Basic;

uses
  Forms,
  DICOM in 'dicom.pas',
  ebasic in 'ebasic.pas' {eDICOMform};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'eDICOM';
  Application.CreateForm(TeDICOMform, eDICOMform);
  Application.Run;
end.
