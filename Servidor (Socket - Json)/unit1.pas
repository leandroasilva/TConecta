//////////////////////////////////////////////////////////
//	Desenvolvedor: Humberto Sales de Oliveira       //
//	Email: 	humbertoliveira@hotmail.com		//
//		humbertosales@midassistemas.com.br	//
//		humberto_s_o@yahoo.com.br		//
//	Objetivo:                                       //  
//		1)Servidor Socket Json para internet 	//
//							// 
//                                                      //
//	licensa: free                                   //
//                                                      //
//	*Auterações, modificações serão bem vindos      //
//	Créditos:                                       //      
//                                                      //   
//////////////////////////////////////////////////////////

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, ExtCtrls, Menus, ActnList, blcksock, synautil, sockets, Crt, synsock,
   ZConnection, ZDataset, IniFiles, fpjson, codificacao, jsonlib, db
  {$ifdef windows},windows {$endif};

type

  TTipoConexao = (tcPostgresql,tcFirebird,tcMysql);

  { ThEscuta }

  ThEscuta = Class(TTHRead)
     Private
       FSocket: TSocket;
       ServerOuvinte : TTCPBlockSocket;
       class procedure HookMonitor(Sender: TObject; Writing: Boolean;
         const Buffer: TMemory; Len: Integer);
       class procedure HookStatus(Sender: TObject; Reason: THookSocketReason;
         const Value: string);
     Public
       constructor Create(CreateSuspended: Boolean);
       Destructor Destroy; override;
     Protected
       procedure Execute; override;
     Published
       property Socket: TSocket read FSocket write FSocket;
  end;

  ThServerSocket = Class(TTHRead)
     Private
       FServer : TTCPBlockSocket;
       Msg : String;
       CSock: TSocket;
       MyQuery : TZQuery;
     Public
       Constructor Create (hsock:tSocket);
       Destructor Destroy; override;
       procedure AtualizaLog;
     Protected
       procedure Execute; override;
     Published

  end;


  { TFormataSql }

  TFormataSql = Class

  private
    FTipoConexao : TTipoConexao;
    FGetJson: TJSONObject;
    FLimit: integer;
    FOffSet: integer;
    FPosCursor: Integer;
    FSetJson: TJSONObject;
    FLimitador : String;    //para limit
    FDeslocamento : String; //para offset
    function GetLimit: integer;
    function GetOffSet: integer;
    procedure SetGetJson(AValue: TJSONObject);
    procedure SetLimit(AValue: integer);
    procedure SetOffSet(AValue: integer);
    procedure SetPosCursor(AValue: Integer);
    procedure SetSetJson(AValue: TJSONObject);
    public
      constructor create(Tipo : TTipoConexao);
      destructor Destroy; override;
      function retorno : TJSONObject;
      procedure run;
    published
      property GetJson : TJSONObject read FGetJson write SetGetJson;
      property SetJson : TJSONObject read FSetJson write SetSetJson;
      property Limit  : integer read GetLimit write SetLimit;
      property OffSet : integer read GetOffSet write SetOffSet;
      property PosCursor : Integer read FPosCursor write SetPosCursor;
      property Limitador : String read Flimitador write Flimitador;
      property Deslocamento : String read FDeslocamento write FDeslocamento;

  end;


  { TForm1 }

  TForm1 = class(TForm)
    AcAbrir: TAction;
    AcEsconder: TAction;
    AcFinalizar: TAction;
    ActionList1: TActionList;
    BitBtn1: TBitBtn;
    Button2: TButton;
    CheckBox1: TCheckBox;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    PopupMenu1: TPopupMenu;
    IniciaServidor: TTimer;
    TrayIcon1: TTrayIcon;
    ZConnection1: TZConnection;
    procedure AcAbrirExecute(Sender: TObject);
    procedure AcEsconderExecute(Sender: TObject);
    procedure AcFinalizarExecute(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure IniciaServidorTimer(Sender: TObject);
  private
    procedure CANTOSARREDONDADOS(const CONTROLE: TWINCONTROL);

    { private declarations }
  public
    function IsOnline: boolean;
  end;

var
  Form1: TForm1;
  THOuvinte : THEscuta;
  Con : TZConnection;
  Ini : TIniFile;

  tpConexao : TTipoConexao;
  //variaveis limitadoras;
  TLimite : array[0..2] of string=(' LIMIT ', ' TO ', ' LIMIT ');
  TPOSICAO: array[0..2] of string=(' OFFSET ', ' ROWS ', ' OFFSET ');
  TCursorInicial : array[0..2] of integer=( 0,1,1 );

  //para mover tela
    CAPTURA : BOOLEAN = FALSE;
    XX,YY : INTEGER;

implementation

{$R *.lfm}

{ TFormataSql }

procedure TFormataSql.SetGetJson(AValue: TJSONObject);
begin
  if FGetJson=AValue then Exit;
  FGetJson:=AValue;
end;

function TFormataSql.GetLimit: integer;
begin
  FLimit := FGetJson.Get('Limit',0);
end;

function TFormataSql.GetOffSet: integer;
begin
  FOffSet:= FGetJson.Get('Offset',0);
end;

procedure TFormataSql.SetLimit(AValue: integer);
begin
  if FLimit=AValue then Exit;
  FLimit:=AValue;
end;

procedure TFormataSql.SetOffSet(AValue: integer);
begin
  if FOffSet=AValue then Exit;
  FOffSet:=AValue;
end;

procedure TFormataSql.SetPosCursor(AValue: Integer);
begin
  if FPosCursor=AValue then Exit;
  FPosCursor:=AValue;
end;

procedure TFormataSql.SetSetJson(AValue: TJSONObject);
begin
  if FSetJson=AValue then Exit;
  FSetJson:=AValue;
end;

constructor TFormataSql.create(Tipo: TTipoConexao);
begin
  FTipoConexao:=TipoConexao;
end;

destructor TFormataSql.Destroy;
begin
  inherited Destroy;
end;

function TFormataSql.retorno: TJSONObject;
begin

end;

procedure TFormataSql.run;
begin
  Case FTipoConexao of
     0 :
        begin
          FLimitador := '';
          FDeslomento := '';

        end;
  end;
end;


{ ThEscuta }

class procedure ThEscuta.HookMonitor(Sender: TObject; Writing: Boolean; const Buffer: TMemory; Len: Integer);
var
  s, d: string;
begin
  setlength(s, len);
  move(Buffer^, pointer(s)^, len);
  if writing then
    d := '-> '
  else
    d := '<- ';
  s :=inttohex(integer(Sender), 8) + d + s + CRLF;
  Form1.Memo1.lines.add(s);
end;

class procedure ThEscuta.HookStatus(Sender: TObject; Reason: THookSocketReason; const Value: string);
var
  s: string;
begin
  case Reason of
    HR_ResolvingBegin:
      s := 'Iniciando';
    HR_ResolvingEnd:
      s := 'Inicialização Finalizada em';
    HR_SocketCreate:
      s := 'Criando Socket';
    HR_SocketClose:
      s := 'Fechando Socket';
    HR_Bind:
      s := 'Ligar';
    HR_Connect:
      s := 'Conectando';
    HR_CanRead:
      s := 'Lendo Dados';
    HR_CanWrite:
      s := 'Gravar';
    HR_Listen:
      s := 'Aguardando Conexão...';
    HR_Accept:
      s := 'Aceitando';
    HR_ReadCount:
      s := 'Lendo a quantidade de Dados';
    HR_WriteCount:
      s := 'Gravando a quantidade de Dados';
    HR_Wait:
      s := 'Aguardando';
    HR_Error:
      s := 'Erro';
  else
    s := 'Desconhecido';
  end;
  s := s + ': ' + value + #13;
  Form1.Memo1.lines.add(s);
end;


constructor ThEscuta.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  FreeOnTerminate:=True;
  ServerOuvinte := TTCPBlockSocket.create;
//  ServerOuvinte.OnStatus:= @HookStatus;
//  ServerOuvinte.OnMonitor := @HookMonitor;

end;

destructor ThEscuta.Destroy;
begin
  ServerOuvinte.free;
  inherited Destroy;
end;

procedure ThEscuta.Execute;
Var
   ServerThread : ThServerSocket;
   ClientSock : TSocket;
begin
  ServerOuvinte.CreateSocket;
  ServerOuvinte.setLinger(true,10);
  ServerOuvinte.bind('0.0.0.0','1300');
  ServerOuvinte.listen;
  if ServerOuvinte.LastError = 0 then
  begin
        while true do
           begin
              if terminated then
                 break;
              //Application.ProcessMessages;
              if ServerOuvinte.CanRead(10000) then
                 begin
                   ClientSock := ServerOuvinte.Accept;
                   if ServerOuvinte.LastError = 0  then
                      begin
                        ServerThRead := ThServerSocket.create(ClientSock);
                        ServerThRead.Start;
                      end
                   else begin
                      ServerThRead := ThServerSocket.create(ClientSock);
                      ServerThRead.Start;
                   end;

                 end ;
           end ;

  end
  else
    Form1.Memo1.Lines.add('Erro '+inttostr(ServerOuvinte.LastError)+' '+ServerOuvinte.GetErrorDescEx);

  ServerOuvinte.CloseSocket;
  ServerOuvinte.Purge;

end;

{ ThServerSocket }

constructor ThServerSocket.Create(hsock: tSocket);
begin
  inherited Create(true);
  MyQuery := TZQuery.Create(Nil);
  MyQuery.Connection := Con;

  CSock:= HSock;
  FreeOnTerminate:=True;
end;

destructor ThServerSocket.Destroy;
begin
  inherited Destroy;
  MyQuery.Free;
end;

procedure ThServerSocket.AtualizaLog;
begin
if Form1.CheckBox1.Checked then
   begin
     Form1.Memo1.Lines.add(MSG);
     Form1.Memo1.Lines[ Form1.Memo1.Lines.Count-1 ];
     if Form1.Memo1.lines.Count > 30000 then
         begin
           Form1.Memo1.lines.SaveToFile(formatdatetime('ddmmyy_hhmm',now) + '.txt');
           Form1.Memo1.lines.Clear;
         end;

   end;

end;

procedure ThServerSocket.Execute;
var
  timeout: integer;
  //s : string;
  method, uri, protocol: string;
  OutputDataString: string;
  ResultCode,x: integer;
//////////////////////////////////////processar parametros
  i,J : integer;
  SubNivel : TJsonObject;
  F : TMemoryStream;
  S,G : String;
  FJson : TJSONObject;
begin
  FServer := TTCPBlockSocket.Create;

  Try
    FServer.Socket:= CSock;
    Msg := Format('Socket: %s IP: %s Data/Hora: %s  Ação: %s' ,[Inttostr(fServer.Socket), fServer.GetRemoteSinIP,FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz - ',Now) ,  'Conenctando']);
    Synchronize(@atualizaLog);

    S := fServer.RecvString(15000); //alteracao 2  S := fServer.RecvString(1000);
    Msg := Format('Socket: %s IP: %s Data/Hora: %s  Ação: %s' ,[Inttostr(fServer.Socket), fServer.GetRemoteSinIP,FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz - ',Now) ,  'Recebendo Dados']);
    Synchronize(@atualizaLog);

    if pos('#msg',s) <> 0 then
      begin
         //fServer.SendString(Stringofchar('a',2000) + CRLF);
         fServer.SendString('inicio ' + formatdatetime('hh:mm:ss:zzz',time));
         delete(s,1,4);
         for x := 1 to strtoint(s) do
           begin
             fServer.SendString('0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789: ' + inttostr(x) + #13 );
           end;
         fServer.SendString('fim ' + formatdatetime('hh:mm:ss:zzz',time));
         fServer.SendString(CRLF);
      end;
    if pos('online',lowercase(s)) <> 0 then
      begin
        Msg := Format('Socket: %s IP: %s Data/Hora: %s  Ação: %s' ,[Inttostr(fServer.Socket), fServer.GetRemoteSinIP,FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz - ',Now) ,  S]);
        Synchronize(@atualizaLog);
        fServer.SendString('online');
        fServer.SendString(CRLF);
      end;
    if pos('query=',S) <> 0 then
      begin
          Delete(s,1,6); //remove query=
          if Form1.IsOnline = false then //nao conectado no banco
             Begin
                fServer.SendString('Banco de dados não conectado!');
                fServer.SendString(CRLF);
                exit;
             end;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
          {"sql":"select * from veiculo where codigo = :codigo","posicao":0,"pacotes":10, "parametros":{"codigo":10}}
          Fjson :=  TJsonObject(  GetJson(S)  );
          Msg := Format('Socket: %s IP: %s Data/Hora: %s  Ação: %s' ,[Inttostr(fServer.Socket), fServer.GetRemoteSinIP,FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz - ',Now) ,  S]);
          Synchronize(@AtualizaLog);
          MyQuery.close;
          SubNivel := TJsonObject.Create;
          For i := 0 to pred(FJson.count) do
               begin
                   Case uppercase(Fjson.Names[i]) of
                     'SQL' : Myquery.sql.text := fJson.Items[i].asstring;
                     'PARAMETROS' : BEGIN
                                        Try
                                           SubNivel := TJsonObject(GetJson(fJson.Items[i].AsJson));

                                           For j := 0 to pred(subNivel.Count) do
                                                  begin
                                                      if (SubNivel.Items[j] is TJSONFloatNumber) then
                                                         Myquery.Params.ParamByName(SubNivel.Names[j]).Asfloat := SubNivel.Items[j].Asfloat;
                                                      if (SubNivel.Items[j] is TJSONIntegerNumber) then
                                                         Myquery.Params.ParamByName(SubNivel.Names[j]).AsInteger := SubNivel.Items[j].Asinteger;
                                                      if (SubNivel.Items[j] is TJSONInt64Number) then
                                                         Myquery.Params.ParamByName(SubNivel.Names[j]).AsInteger := SubNivel.Items[j].AsInteger;
                                                      if (SubNivel.Items[j] is TJSONString) then
                                                         if copy(SubNivel.Items[j].AsString ,1,6) = '#blob#' then
                                                            begin
                                                              S := SubNivel.Items[j].AsString;
                                                              Delete(S,1,6);
                                                              S := desconverter(S);
                                                              try
                                                              F := TMemoryStream.create;
                                                              Decode64StringToStream(S,F);
                                                              Myquery.Params.ParamByName(SubNivel.Names[j]).LoadFromStream(F,ftblob);
                                                              finally
                                                                FreeAndNil( F );
                                                              end;
                                                            end
                                                            else
                                                              Myquery.Params.ParamByName(SubNivel.Names[j]).AsString := SubNivel.Items[j].AsString;
                                                      if (SubNivel.Items[j] is TJSONBoolean) then
                                                         Myquery.Params.ParamByName(SubNivel.Names[j]).AsBoolean := SubNivel.Items[j].AsBoolean;
                                                  end;
                                        finally
                                           SubNivel.free;
                                        end;
                                    END;
                     'POSICAO' : BEGIN
                                      if (copy( uppercase(Fjson.items[0].asstring), 1,6) = 'SELECT' ) AND ( LastDelimiter(TPOSICAO[ORD(tpConexao)],UPPERCASE(Fjson.items[0].asstring) ) > 0 ) THEN
                                         Myquery.sql.text := format('%s %s' , [Myquery.sql.text,TPOSICAO[ORD(tpConexao)] + inttostr(Fjson.Items[i].AsInteger + TCURSORINICIAL[ORD(tpConexao)] )]  );
                                 END;
                     'PACOTES' : BEGIN
                                     if ( copy( uppercase(Fjson.items[0].asstring), 1,6) = 'SELECT' )  AND ( LastDelimiter(TLIMITE[ORD(tpConexao)],UPPERCASE(Fjson.items[0].asstring)) > 0 ) THEN
                                            Myquery.sql.text := format('%s %s' , [Myquery.sql.text,TLIMITE[ORD(tpConexao)] + inttostr(Fjson.Items[i].AsInteger)])
                                     Else
                                         IF (copy( uppercase(Fjson.items[0].asstring), 1,6) = 'SELECT' ) AND (  LastDelimiter(TLIMITE[ORD(tpConexao)],uppercase(Fjson.items[0].asstring)) < LastDelimiter('FROM',uppercase(Fjson.items[0].asstring)) ) THEN
                                            Myquery.sql.text := format('%s %s' , [Myquery.sql.text,TLIMITE[ORD(tpConexao)] + inttostr(Fjson.Items[i].AsInteger)])

                                 END;
                     end; //end case

               end;  //end for

//          Msg := fServer.GetRemoteSinIP + FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz',Now) + #13 +  ' SQL -->> ' + Myquery.sql.text;
//          Synchronize(@atualizaLog);
          Case UpperCase(Fjson.Names[0]) of
              'SQL' : BEGIN
                          Try
                                  Case Copy(UpperCase(Myquery.Sql.text),1,Pos(' ',Myquery.Sql.text) -1) of
                                     'SELECT' :
                                                BEGIN
                                                    Myquery.open;
                                                    fServer.SendString( DataSetToJson(MyQuery) + CRLF);
                                                END;
                                     'INSERT','UPDATE','DELETE' :
                                                BEGIN
                                                    Myquery.ExecSql;
                                                    Myquery.Close;
                                                    Myquery.Sql.Text := 'Commit';
                                                    Myquery.ExecSql;
                                                    Case Copy(UpperCase(Myquery.Sql.text),1,Pos(' ',Myquery.Sql.text) -1) of
                                                       'INSERT' : fServer.SendString('{"#msg":"Inserido com sucesso!"}' + CRLF);
                                                       'UPDATE' : fServer.SendString('{"#msg":"Atualizado com sucesso!"}' + CRLF);
                                                       'DELETE' : fServer.SendString('{"#msg":"Removido com sucesso!"}' + CRLF);
                                                    end;
                                                END;

                                  end;
                          Except
                              On E:Exception do
                                 begin
                                     fServer.SendString('{"#msg":"' + E.Message + '"}' + CRLF);
                                     Myquery.Close;
                                 end;
                          end;


                      END;
          end;//case
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      end;


    if fServer.LastError <> 0 then
    begin
      Msg := Format('Socket: %s IP: %s Data/Hora: %s  Ação: %s' ,[Inttostr(fServer.Socket), fServer.GetRemoteSinIP,FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz - ',Now) ,  'Houve um erro ao enviar']);
      Synchronize(@AtualizaLog);
    end;
  finally
    delay(500);
    Msg := Format('Socket: %s IP: %s Data/Hora: %s  Ação: %s' ,[Inttostr(fServer.Socket), fServer.GetRemoteSinIP,FormatDateTime(' dd/mm/yyyy - hh:mm:ss:zzz - ',Now) ,  'Finalizando Conexão']);
    Synchronize(@atualizaLog);
    FServer.CloseSocket ;
    FreeAndNil(FServer);
    Msg := 'Conexão Finalizada!' + #13#10;
    Synchronize(@atualizaLog);
  end;


end;

{ TForm1 }

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
    if THOuvinte <> Nil then
     begin

      Memo1.lines.add('FINALIZANDO SERVIDOR! AGUARDE...');
      Application.ProcessMessages;
      BitBtn1.Font.Color:= clMedGray;
      BitBtn1.Caption := 'Iniciar Servidor';
      THOuvinte.Terminate;
      THOuvinte := Nil;
      Memo1.lines.add('SERVIDOR FINALIZADO.');
      Memo1.lines.SaveToFile(formatdatetime('ddmmyy_hhmm',now) + '.txt');
     end
     Else Begin
        Memo1.lines.clear;
        THOuvinte := THEscuta.Create(False);
        BitBtn1.Font.Color:= clNavy;
        BitBtn1.Caption := 'Parar Servidor';
        Memo1.lines.add('SERVIDOR INICIALIZADO COM SUCESSO!');
        Memo1.lines.add('DATA/HORA INICIALIZAÇÃO: ' + formatdatetime('dd/mm/yyy hh:mm:ss',Now));
        Memo1.lines.add('AGUARDANDO CONEXÃO.');
        Memo1.lines.add('Ativando TrayIcon');
        Memo1.lines.add('');
        Application.ProcessMessages;
        delay(2000);
        Form1.hide;
     end;

end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  Ini.WriteBool('Servidor','Mostrar_log',CheckBox1.Checked);
end;

procedure TForm1.FormCreate(Sender: TObject);
Var
  Parametros : TStringList;
begin
Con := TZConnection.Create(nil);
Try
  Parametros := TStringList.Create;
  With Parametros do
     begin
        LoadFromfile('PathBanco.txt');
        CON.HostName := Values['IP'];
        CON.Port := StrToInt(Values['PORTA']);
        CON.Database := Values['BANCO'];
        CON.User := Values['USUARIO'];
        CON.Password := Values['SENHA'];
        CON.Protocol := Values['TIPOBANCO'];
        //CON.LibraryLocation:= '/usr/lib/i386-linux-gnu/libmysqlclient.so.18.0.0';
        Case UpperCase(Copy(Con.Protocol,1,5)) of
           'POSTG' : tpConexao := tcPostgresql;
           'FIREB' : tpConexao := tcFirebird;
           'MYSQL' : tpConexao := tcMysql;
        end;
        Try
           CON.Connect;
        Except
            Showmessage('Houve um erro ao conectar com o banco de dados');
        end;
     end;
Finally
  Parametros.Free;
end;

Ini := TIniFile.Create( ChangeFileExt( ExtractFilename(Application.exename),'.ini' ));
CheckBox1.Checked := Ini.ReadBool('Servidor','Mostrar_log',true);

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

procedure TForm1.FormDblClick(Sender: TObject);
begin
  CAPTURA:= NOT(CAPTURA);
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   CAPTURA := FALSE;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  xx:= x;
  yy:= y;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
    IF CAPTURA THEN
      BEGIN
        Screen.ActiveForm.Left := Screen.ActiveForm.Left + X - xx;
       Screen.ActiveForm.Top := Screen.ActiveForm.Top + Y - yy;
      end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
   CANTOSARREDONDADOS(Form1);
end;

procedure TForm1.AcAbrirExecute(Sender: TObject);
begin
//  {$IFDEF MSWINDOWS}
//  ShowWindow(FindWindow(nil,'Servidor'),sw_show);
//  ShowWindow(FindWindow(nil,'Form1'),sw_show);
//  {$ENDIF}
  show;
end;

procedure TForm1.AcEsconderExecute(Sender: TObject);
begin
//  {$IFDEF MSWINDOWS}
//  ShowWindow(FindWindow(nil,'Servidor'),sw_hide);
//  ShowWindow(Form1.Handle,sw_hide);
//  {$ELSE}
  Form1.Hide;
//  {$ENDIF}

end;



procedure TForm1.AcFinalizarExecute(Sender: TObject);
begin
  Application.Terminate;
end;



procedure TForm1.FormWindowStateChange(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  if Form1.WindowState = wsMinimized then
     ShowWindow(FindWindow(nil,'Servidor'),sw_hide);
{$ENDIF}

end;

procedure TForm1.IniciaServidorTimer(Sender: TObject);
begin
BitBtn1.Click;
IniciaServidor.Enabled := False;
end;

function TForm1.IsOnline : boolean;
var
  x : Integer;
begin
 x := 0;
 result := false;
 if Con.PingServer then
    result := True
 Else begin
    Con.Connected := False;
    Memo1.Lines.add('Servidor desconectado do banco. Tentativa de Reconexão em 5 segundos');
    while x < 5000 do
       begin
          sleep(1000);
          Memo1.Lines.add('Reiniando conexão em ' + inttostr(5000 - x));
          x := x + 1000;
          if x = 5000 then
            begin
               Con.Connected := true;
               if Con.PingServer then
                 begin
                     result := True;
                     break;
                 end
               else begin
                    x := 0;
               end;
            end;

       end;

 end;
end;


PROCEDURE Tform1.CANTOSARREDONDADOS(const CONTROLE: TWINCONTROL);
VAR
  ABITMAP: Graphics.TBITMAP;
BEGIN
  TRY
      ABITMAP := Graphics.TBitmap.CREATE;
      ABITMAP.MONOCHROME := TRUE;
      ABITMAP.WIDTH := CONTROLE.WIDTH; // OR FORM1.WIDTH
      ABITMAP.HEIGHT := CONTROLE.HEIGHT; // OR FORM1.HEIGHT

      ABITMAP.CANVAS.BRUSH.COLOR:=CLBLACK;
      ABITMAP.CANVAS.FILLRECT(0, 0, CONTROLE.WIDTH, CONTROLE.HEIGHT);

      ABITMAP.CANVAS.BRUSH.COLOR:=CLWHITE;
      ABITMAP.Canvas.RoundRect(0,0,CONTROLE.WIDTH,CONTROLE.HEIGHT,20,20);

      CONTROLE.SETSHAPE(ABITMAP);
  FINALLY
      ABITMAP.FREE;
  END;

END;

end.




//enviar cabeçalho

// Write the headers back to the client
{       fServer.SendString('HTTP/1.0 200' + CRLF);
fServer.SendString('Content-type: Text/Html' + CRLF);
fServer.SendString('Content-length: ' + IntTostr(Length(OutputDataString)) + CRLF);
fServer.SendString('Connection: close' + CRLF);
fServer.SendString('Date: ' + Rfc822DateTime(now) + CRLF);
fServer.SendString('Server: Servidor do Felipe usando Synapse' + CRLF);
fServer.SendString('' + CRLF);}
//fServer.SendString('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"'
//  + ' "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">' + CRLF);
//fServer.SendString('<HTML><BODY>{online:"sim"}</BODY></HTML>' + CRLF);

