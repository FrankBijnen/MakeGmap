object DmSettings: TDmSettings
  OnCreate = DataModuleCreate
  Height = 231
  Width = 319
  object TabProjects: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <
      item
        Name = 'TabProjectsIdx'
        Fields = 'MapCode'
        Options = [ixUnique]
      end>
    IndexName = 'TabProjectsIdx'
    Params = <>
    StoreDefs = True
    AfterInsert = TabProjectsAfterInsert
    BeforePost = TabProjectsBeforePost
    AfterPost = TabProjectChanged
    AfterScroll = TabProjectChanged
    Left = 32
    Top = 76
    object TabProjectsMapCode: TStringField
      Tag = 1
      DisplayLabel = 'MapCode (*)'
      FieldName = 'MapCode'
      OnChange = TabProjectsMapCodeChange
      Size = 10
    end
    object TabProjectsMapName: TStringField
      Tag = 1
      DisplayLabel = 'MapName (*)'
      FieldName = 'MapName'
      Size = 255
    end
    object TabProjectsMapId: TIntegerField
      Tag = 1
      DisplayLabel = 'MapId (*)'
      FieldName = 'MapId'
    end
    object TabProjectsStyle: TStringField
      Tag = 1
      FieldName = 'Style'
      Visible = False
      Size = 128
    end
    object TabProjectsStyleLookup: TStringField
      Tag = 1
      DisplayLabel = 'Style file (*)'
      FieldKind = fkLookup
      FieldName = 'StyleLookup'
      LookupDataSet = TabStyle
      LookupKeyFields = 'Style'
      LookupResultField = 'Style'
      KeyFields = 'Style'
      LookupCache = True
      Size = 128
      Lookup = True
    end
    object TabProjectsPoly: TStringField
      Tag = 1
      FieldName = 'Poly'
      Visible = False
      Size = 128
    end
    object TabProjectsPolyLookup: TStringField
      Tag = 1
      DisplayLabel = 'Poly file'
      FieldKind = fkLookup
      FieldName = 'PolyLookup'
      LookupDataSet = TabPoly
      LookupKeyFields = 'Poly'
      LookupResultField = 'Poly'
      KeyFields = 'Poly'
      Size = 128
      Lookup = True
    end
    object TabProjectsGMapi: TBooleanField
      Tag = 1
      DisplayLabel = 'GMapi (Basecamp)'
      FieldName = 'GMapi'
    end
    object TabProjectsGMapSupp: TBooleanField
      Tag = 1
      DisplayLabel = 'GmapSupp (Device)'
      FieldName = 'GMapSupp'
    end
    object TabProjectsSplitGmapSupp: TIntegerField
      Tag = 1
      DisplayLabel = 'Split/Rename GmapSupp (Mb)'
      FieldName = 'SplitGmapSupp'
    end
    object TabProjectsUnicode: TBooleanField
      Tag = 1
      FieldName = 'Unicode'
    end
    object TabProjectsMaxNodes: TIntegerField
      Tag = 10
      DisplayLabel = 'Max nodes'
      FieldName = 'MaxNodes'
    end
    object TabProjectsMaxAreas: TIntegerField
      Tag = 10
      DisplayLabel = 'Max areas'
      FieldName = 'MaxAreas'
    end
    object TabProjectsDrawPrio: TIntegerField
      Tag = 10
      DisplayLabel = 'Draw priority'
      FieldName = 'DrawPrio'
    end
    object TabProjectsTransparent: TBooleanField
      Tag = 10
      FieldName = 'Transparent'
    end
    object TabProjectsCountryList: TStringField
      Tag = 10
      FieldName = 'CountryList'
      Size = 255
    end
  end
  object DsProjects: TDataSource
    DataSet = TabProjects
    OnDataChange = DsProjectsDataChange
    Left = 116
    Top = 76
  end
  object DsGeneral: TDataSource
    DataSet = TabGeneral
    Left = 116
    Top = 11
  end
  object TabGeneral: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <>
    Params = <>
    StoreDefs = True
    Left = 32
    Top = 11
    object TabGeneralInitialized: TBooleanField
      DisplayLabel = 'Config Initialised'
      FieldName = 'Initialized'
      ReadOnly = True
    end
    object TabGeneralDownloadsDir: TStringField
      DisplayLabel = 'Download Directory'
      FieldName = 'DownloadsDir'
      Size = 260
    end
    object TabGeneralTempDir: TStringField
      DisplayLabel = 'Temp Directory'
      FieldName = 'TempDir'
      Size = 260
    end
    object TabGeneralFinalDir: TStringField
      DisplayLabel = 'Final Directory'
      FieldName = 'FinalDir'
      Size = 260
    end
    object TabGeneralMinJavaMem: TIntegerField
      DisplayLabel = 'Min. Memory Java (Gb)'
      FieldName = 'MinJavaMem'
    end
    object TabGeneralMaxJavaMem: TIntegerField
      DisplayLabel = 'Max. Memory Java (Gb)'
      FieldName = 'MaxJavaMem'
    end
    object TabGeneralMaxJavaThreads: TIntegerField
      DisplayLabel = 'Max. JavaThreads'
      FieldName = 'MaxJavaThreads'
    end
    object TabGeneralDownloadChunkSize: TIntegerField
      DisplayLabel = 'Download Chunk Size (Mb)'
      FieldName = 'DownloadChunkSize'
    end
    object TabGeneralMaxDownloadThreads: TIntegerField
      DisplayLabel = 'Max. Download Threads'
      FieldName = 'MaxDownloadThreads'
    end
  end
  object TabProjectsUrls: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <
      item
        Name = 'TabProjectsUrlsIdx'
        Fields = 'MapCode;Url'
      end>
    IndexName = 'TabProjectsUrlsIdx'
    MasterFields = 'MapCode'
    MasterSource = DsProjects
    PacketRecords = 0
    Params = <>
    StoreDefs = True
    Left = 32
    Top = 142
    object TabProjectsUrlsMapCode: TStringField
      DisplayWidth = 10
      FieldName = 'MapCode'
      Size = 10
    end
    object TabProjectsUrlsUrl: TStringField
      FieldName = 'Url'
      Size = 512
    end
  end
  object DsProjectsUrls: TDataSource
    DataSet = TabProjectsUrls
    Left = 116
    Top = 142
  end
  object TabStyle: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 212
    Top = 76
    object TabStyleStyle: TStringField
      FieldName = 'Style'
      Size = 128
    end
  end
  object TabPoly: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <
      item
        Name = 'TabPolyIdx'
        Fields = 'Poly'
      end>
    Params = <>
    StoreDefs = True
    Left = 213
    Top = 142
    object TabPolyPoly: TStringField
      FieldName = 'Poly'
      Size = 50
    end
  end
end
