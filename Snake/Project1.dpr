program Project1;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Window};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TWindow, Window);
  Application.Run;
end.
