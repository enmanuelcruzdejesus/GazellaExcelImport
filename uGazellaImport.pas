unit uGazellaImport;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.ExtCtrls, FireDAC.Phys.MSSQL, FireDAC.Phys.MSSQLDef,
  Vcl.Buttons, Vcl.Mask, Vcl.DBCtrls, System.IOUtils, Vcl.FlexCel.Core,
  FlexCel.XlsAdapter, FireDAC.VCLUI.Wait, FireDAC.Comp.UI, System.Rtti,
  Vcl.ComCtrls, System.Generics.Collections;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    btnImport: TButton;
    QHeader: TFDQuery;
    DataSource1: TDataSource;
    QHeaderidarchivo: TIntegerField;
    QHeaderfecha: TSQLTimeStampField;
    QHeaderobservaciones: TStringField;
    QHeaderestatus: TIntegerField;
    QHeadercreated: TSQLTimeStampField;
    QDetail: TFDQuery;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    Label2: TLabel;
    Button1: TButton;
    Fecha: TDateTimePicker;
    DBGrid1: TDBGrid;
    DataSource2: TDataSource;
    QDetailidarchivo: TIntegerField;
    QDetailseq: TIntegerField;
    QDetailfecha: TSQLTimeStampField;
    QDetailcliente: TStringField;
    QDetailtarjeta: TStringField;
    QDetailmonto: TBCDField;
    QDetailnumero_referencia: TStringField;
    QDetailfolio: TStringField;
    QDetailestatus: TStringField;
    QDetailtrans_recibo: TIntegerField;
    btnBuscarArchivo: TButton;
    lbbtnRutaArchivo: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    FDQuery1: TFDQuery;
    QDetailnumero_autorizacion: TStringField;
    procedure ImportarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnBuscarArchivoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    function GetExcelData(FileName: string): TXlsFile;
    function ValidateExcelData(ExcelFile: TXlsFile;
      var Mensaje: string): boolean;
    procedure InsertingData;

  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses MainModule;
{ TForm1 }

procedure TForm1.btnBuscarArchivoClick(Sender: TObject);
begin
  // Display the open file dialog
  if OpenDialog1.Execute then
    lbbtnRutaArchivo.Text := OpenDialog1.FileName;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Fecha.Date:=Now;
end;

function TForm1.GetExcelData(FileName: string): TXlsFile;
var
  xls: TXlsFile;
begin
  try
    xls := TXlsFile.Create(FileName);
    xls.ActiveSheet := 1;
  except
    on E: EFOpenError do
    begin
      ShowMessage('No se selecciono ningun archivo');
      xls.Free;
    end;
  end;
  Result := xls;
end;

procedure TForm1.ImportarClick(Sender: TObject);
begin
  InsertingData;
end;

procedure TForm1.InsertingData;
var
  xls: TXlsFile;
  row, colindex, xf, idarchivo: Integer;
  cell: TCellValue;
  Mensaje: string;
  registro: TList<Variant>;
  spc,spc2: TFDStoredProc;
begin
  xls := GetExcelData(OpenDialog1.FileName);
  if ValidateExcelData(xls, Mensaje) then
  begin
    try
      // Generando el nuevo archvioId
      spc := TFDStoredProc.Create(nil);
      spc.Connection := MainModule.DataModule1.GoConnetion;
      spc.StoredProcName := 'cn_p_buscar_idarchivo';;
      spc.Prepare;
      spc.Open();
      idarchivo := spc.FieldByName('nuevo_archivoid').AsInteger;
    finally
      spc.Close;
    end;
    registro := TList<Variant>.Create;
    QDetail.ParamByName('idarchivo').AsInteger := idarchivo;
    QDetail.Open();
    for row := 2 to xls.RowCount do
    begin
      for colindex := 1 to xls.ColCountInRow(row) do
      begin
        xf := -1;
        cell := xls.GetCellValue(row, colindex, xf);
        if cell.IsNumber then
          registro.Add(cell.AsNumber)
        else if cell.IsString then
          registro.Add(cell.ToString)
        else if cell.IsEmpty then
          registro.Add(cell.ToString);
      end;
      if registro.Count = 9 then
      begin
        if registro[4] > 0 then
        begin
          QDetail.Append;
          QDetail.FieldByName('idarchivo').Value := idarchivo;
          QDetail.FieldByName('seq').Value := registro[0];
          QDetail.FieldByName('fecha').Value := FloatToDateTime(registro[1]);
          QDetail.FieldByName('cliente').Value := registro[2];
          QDetail.FieldByName('tarjeta').Value := registro[3];
          QDetail.FieldByName('monto').Value := registro[4];
          QDetail.FieldByName('numero_autorizacion').Value := registro[5];
          QDetail.FieldByName('numero_referencia').Value := registro[6];
          QDetail.FieldByName('folio').Value := registro[7];
          QDetail.FieldByName('estatus').Value := registro[8];
          QDetail.FieldByName('trans_recibo').Value := 0;
          QDetail.Post;
        end;
      end;
      // Limpiando la lista
      registro.Clear;
    end;

    try
      spc2:=TFDStoredProc.Create(nil);
      spc2.Connection:=MainModule.DataModule1.GoConnetion;
      spc2.StoredProcName := 'cn_p_pagostarjeta';
      spc2.Prepare;
      spc2.Params[1].Value := idarchivo;
      spc2.Open();
      Mensaje := spc2.FieldByName('mensaje').AsString;
    finally
      spc2.Close;
    end;
    QDetail.Close;
    QDetail.Open();
    ShowMessage(Mensaje);
  end
  else
  begin
    ShowMessage(Mensaje);
  end;
end;

function TForm1.ValidateExcelData(ExcelFile: TXlsFile;
  var Mensaje: string): boolean;
var
  row, colindex, xf: Integer;
  cell, cell2,cell3: TCellValue;
  addres: TCellAddress;
  registro: TList<Variant>;
  cant_registro: Integer;
  num_autorizacion: string;
  f1: TDate;
begin
  xf := -1;
  Mensaje := '';
  registro := TList<Variant>.Create;
  // Verificando si el archivo ya fue procesado
  cell2 := ExcelFile.GetCellValueIndexed(2, 6, xf);
  cell3 := ExcelFile.GetCellValueIndexed(2, 2, xf);
  num_autorizacion := cell2.ToString;
  f1:=FloatToDateTime(cell3.AsNumber);
  try
    FDQuery1.Connection := MainModule.DataModule1.GoConnetion;
    FDQuery1.ParamByName('f1').AsDate := f1;
    FDQuery1.Open();
    cant_registro := FDQuery1.FieldByName('cantidad').AsInteger;
  finally
    FDQuery1.Close;
  end;

  for row := 2 to ExcelFile.RowCount do
  begin
    for colindex := 1 to ExcelFile.ColCountInRow(row) do
    begin
      xf := -1;
      cell := ExcelFile.GetCellValue(row, colindex, xf);
      addres := TCellAddress.Create(row, ExcelFile.ColFromIndex(row, colindex));
      if cell.IsNumber then
        registro.Add(cell.AsNumber)
      else if cell.IsString then
        registro.Add(cell.ToString)
      else if cell.IsEmpty then
        registro.Add(cell.ToString);
    end;
    // Validaciones
    if registro.Count = 9 then
    begin
      if (registro[4] > 0) then
      begin
        // Validando que la fecha digita sea igual a la del documento
        if (FormatDateTime('mm/dd/yyyy', FloatToDateTime(registro[1]))) <> (FormatDateTime('mm/dd/yyyy', Fecha.DateTime)) then
        begin
          Mensaje := 'El archivo no contiene registros con la fecha especificada';
          Result := false;
          Exit;
        end;
      end;
    end;
    // Limpiando la lista
    registro.Clear;
  end;

  if cant_registro > 0 then
  begin
    Mensaje := 'Este archivo ya fue procesado';
    Result := false;
    Exit;
  end;
  Result := true;
end;

end.
