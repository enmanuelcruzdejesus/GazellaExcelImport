object DataModule1: TDataModule1
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 215
  object GoConnetion: TFDConnection
    Params.Strings = (
      'Database=GOFFICE_DATA_EXCEL'
      'User_Name=sa'
      'Password=Entrada01'
      'Server=QS006'
      'DriverID=MSSQL')
    Connected = True
    LoginPrompt = False
    Left = 31
    Top = 32
  end
end
