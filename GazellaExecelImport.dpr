program GazellaExecelImport;

uses
  Vcl.Forms,
  uGazellaImport in 'uGazellaImport.pas' {Form1},
  MainModule in 'MainModule.pas' {DataModule1: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.Run;
end.
