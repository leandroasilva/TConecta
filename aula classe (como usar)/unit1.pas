unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, memds, db, pqconnection, FileUtil, Forms, Controls,
  Graphics, Dialogs, StdCtrls, DBGrids, DbCtrls, ExtCtrls, Menus, conecta,
  Unit2, ZConnection, ZDataset;

type

  { TForm1 }
  TEstado = (esVisualizando,esEditando,EsGravando,EsLimpar, EsBotoesAlterar,EsBotoesNormais);

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    MemDataset1: TMemDataset;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
  public
    procedure LeQuery(Frm : TForm; Qry : TBaseQuery; estado : Testado);
  end;



var
  Form1: TForm1;
  MyCon : TConecta;
  MyQuery : TBaseQuery;


implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.FormCreate(Sender: TObject);
begin
  MyCon := Tconecta.create;
  MyQuery := MyCon.CriarQuery;
  DBGrid1.DataSource := Myquery.DataSource;
  DBNavigator1.DataSource := Myquery.DataSource;

  FormatSettings.ShortDateFormat := 'dd/mm/yyyy';
  FormatSettings.CurrencyString := 'R$';
  FormatSettings.CurrencyFormat := 0;
  FormatSettings.NegCurrFormat := 14;
  FormatSettings.ThousandSeparator := '.';
  FormatSettings.DecimalSeparator := ',';
  FormatSettings.CurrencyDecimals := 2;
  FormatSettings.DateSeparator := '/';
  FormatSettings.TimeSeparator := ':';
  FormatSettings.TimeAMString := 'AM';
  FormatSettings.TimePMString := 'PM';
  FormatSettings.ShortTimeFormat := 'hh:mm:ss';

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  MyQuery.close;
  FreeAndNil(MyQuery);
  MyCon.Free;
end;

procedure TForm1.LeQuery(Frm: TForm; Qry: TBaseQuery; estado: Testado);
var
  x : Integer;
  s : string;
begin
//para ativar e desativar botoes de acordo com o estado do query
Case Estado Of
   EsBotoesAlterar  :
                       Begin
                          (frm.FindComponent('btgravar') as TButton).Enabled := true;
                          (frm.FindComponent('btnovo') as TButton).Enabled := false;
                          (frm.FindComponent('bteditar') as TButton).Enabled := false;
                          (frm.FindComponent('btapagar') as TButton).Enabled := false;
                          (frm.FindComponent('btcancelar') as TButton).Enabled := true;
                          (frm.FindComponent('btfechar') as TButton).Enabled := false;
                          (frm.FindComponent('DbNavigator1') as TDBNavigator).Enabled := false;
                       end;
  EsBotoesNormais   :
                       Begin
                          (frm.FindComponent('btgravar') as TButton).Enabled := false;
                          (frm.FindComponent('btnovo') as TButton).Enabled := true;
                          (frm.FindComponent('bteditar') as TButton).Enabled := true;
                          (frm.FindComponent('btapagar') as TButton).Enabled := true;
                          (frm.FindComponent('btcancelar') as TButton).Enabled := false;
                          (frm.FindComponent('btfechar') as TButton).Enabled := true;
                          (frm.FindComponent('DbNavigator1') as TDBNavigator).Enabled := True;
                       end;
 end;

//configurado para 3 componentes... mas pode adicionar mais de acordo com suas necessidades.
for x := 0 to pred(Qry.Fields.Count) do
   begin
      Case Estado of
        esVisualizando :
                            begin
                               if frm.FindComponent( Qry.Fields.fields[x].displayName  ) is TEdit then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].displayname  ) as TEdit) do
                                        begin
                                            text := Qry.Fields.FieldByName(Qry.Fields.fields[x].displayname).asstring;
                                            MaxLength:= Qry.Fields.FieldByName(Qry.Fields.fields[x].displayname).DisplayWidth;
                                            readOnly := true;
                                        end;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].displayName  ) is TCombobox then
                                   begin
                                       With frm.FindComponent( Qry.Fields.fields[x].displayname  ) as TCombobox do
                                        begin
                                            MaxLength:= Qry.Fields.FieldByName(Qry.Fields.fields[x].displayname).DisplayWidth;
                                            text := Qry.Fields.FieldByName(Qry.Fields.fields[x].displayname).asstring;
                                            Enabled := false;
                                        end;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].displayName  ) is TRadioGroup then
                                   begin
                                       With frm.FindComponent( Qry.Fields.fields[x].displayname  ) as TRadioGroup do
                                        begin
                                            Case Qry.Fields.fields[x].asstring[1] of //se os dados do banco for um (S)im / (N)ão - (F)isica / (J)uridica - (F)eminino / (M)asculino - '1'/'2'
                                              'S','1','F' : itemindex := 0;
                                              'N','2','J','M' : itemindex := 1;
                                            end;
                                            Enabled := false;
                                        end;
                                   end;

                            end;
        esEditando :
                            begin
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TEdit then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TEdit) do
                                            readOnly := false;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TCombobox then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TCombobox) do
                                            Enabled := true;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TRadioGroup then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TRadioGroup) do
                                            Enabled := True;
                                   end;
                            end;
        esGravando :
                            begin
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TEdit then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TEdit) do
                                            readOnly := true;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TCombobox then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TCombobox) do
                                            Enabled := False
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TRadioGroup then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TRadioGroup) do
                                            Enabled := False;
                                   end;
                            end;
        esLimpar  :
                            begin
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TEdit then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TEdit) do
                                          begin
                                            text := '';
                                            readOnly := false;
                                          end;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TCombobox then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TCombobox) do
                                          begin
                                            text := '';
                                            Enabled := true;
                                          end;
                                   end;
                               if frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) is TRadioGroup then
                                   begin
                                       With (frm.FindComponent( Qry.Fields.fields[x].DisplayName  ) as TRadioGroup) do
                                          begin
                                            ItemIndex := -1;
                                            Enabled := True;
                                          end;
                                   end;
                            end;
    end;

  end;


end;

procedure TForm1.Button2Click(Sender: TObject);
begin
    With MyQuery do
        begin
           Close;
           Sql.text := 'select marca,descricao from VEICULO order by cast(codigo as integer)';
           Open;
        end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  With MyQuery do
      begin
         Close;
         Sql.text := 'delete from veiculo where codigo=:codigo ';
         Parambyname('codigo').asstring := '306';
         ExecSql;
         Close;
         Sql.text := 'select * from veiculo order by cast(codigo as integer)';
         Open;
      end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Form2 := TForm2.create(nil);
  Form2.show;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  With MyQuery do
      begin
         Close;
         Sql.text := 'insert into veiculo (codigo,dataregistro,marca,modelo) values (:codigo,:dataregistro,:marca,:modelo) ';
         Parambyname('codigo').asstring := '306';
         Parambyname('dataregistro').asdate := date;
         Parambyname('marca').asstring := 'ford34';
         Parambyname('modelo').asstring := 'fiesta34';
         ExecSql;
         Close;
         Sql.text := 'select * from veiculo order by cast(codigo as integer)';
         Open;
      end;
end;

end.

