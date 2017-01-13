unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Unit2,
  rxcurredit, fpjson, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CurrencyEdit1: TCurrencyEdit;
    CurrencyEdit2: TCurrencyEdit;
    CurrencyEdit3: TCurrencyEdit;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure Button1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  J : TFormataSql;
implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  J := TFormataSql.create (tcPostgresql);
  J.Json := TJsonObject( GetJson( Edit1.text ) );
  J.Run;
  Edit2.text := J.SQL.Text;
  showmessage(inttostr(J.Limit));
  showmessage(inttostr(J.Cursor));
  CurrencyEdit1.AsInteger := J.Limit;
  CurrencyEdit2.AsInteger := J.OffSet;
  Edit3.Text := J.Limitador;
  Edit4.TExt := J.Deslocamento;
  CurrencyEdit3.Value := J.Cursor;


end;

end.

