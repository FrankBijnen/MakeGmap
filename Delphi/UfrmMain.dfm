object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'Build Garmin maps from OSM'
  ClientHeight = 621
  ClientWidth = 1124
  Color = clBtnFace
  CustomTitleBar.CaptionAlignment = taCenter
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = Resized
  OnShow = FormShow
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 721
    Top = 0
    Height = 604
    Align = alRight
    ExplicitLeft = 1032
    ExplicitTop = 24
    ExplicitHeight = 658
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 604
    Width = 1124
    Height = 17
    Align = alBottom
    TabOrder = 0
  end
  object PctMain: TPageControl
    Left = 0
    Top = 0
    Width = 721
    Height = 604
    ActivePage = TabConfiguration
    Align = alClient
    TabOrder = 1
    TabStop = False
    OnChange = PctMainChange
    object TabConfiguration: TTabSheet
      Caption = 'Configuration'
      object PnlMainTop: TPanel
        Left = 0
        Top = 0
        Width = 713
        Height = 41
        Align = alTop
        TabOrder = 0
        object BtnCheckConfig: TButton
          Left = 0
          Top = 1
          Width = 195
          Height = 30
          Caption = 'Check configuration'
          TabOrder = 0
          OnClick = BtnCheckConfigClick
        end
        object BtnImportPoly: TButton
          Left = 201
          Top = 5
          Width = 185
          Height = 30
          Caption = 'Import poly from GPX'
          TabOrder = 1
          OnClick = BtnImportPolyClick
        end
      end
      object PnlMainNav: TPanel
        Left = 0
        Top = 41
        Width = 713
        Height = 41
        Align = alTop
        TabOrder = 1
        object DBNavGeneral: TDBNavigator
          Left = 0
          Top = 10
          Width = 224
          Height = 25
          DataSource = DmSettings.DsGeneral
          VisibleButtons = [nbEdit, nbPost, nbCancel, nbRefresh]
          TabOrder = 0
        end
      end
      object PnlGeneralFields: TPanel
        Left = 0
        Top = 82
        Width = 713
        Height = 494
        Align = alClient
        TabOrder = 2
      end
    end
    object TabProjects: TTabSheet
      Caption = 'Projects'
      ImageIndex = 1
      object Splitter2: TSplitter
        Left = 0
        Top = 409
        Width = 713
        Height = 3
        Cursor = crVSplit
        Align = alTop
        ExplicitTop = 370
        ExplicitWidth = 260
      end
      object PnlProjectsTop: TPanel
        Left = 0
        Top = 0
        Width = 713
        Height = 84
        Align = alTop
        TabOrder = 0
        object BtnDownload: TButton
          Left = 2
          Top = 0
          Width = 187
          Height = 25
          Caption = 'Download'
          TabOrder = 0
          OnClick = BtnDownloadClick
        end
        object BtnCancel: TButton
          Left = 2
          Top = 53
          Width = 187
          Height = 25
          Caption = 'Cancel'
          TabOrder = 1
          OnClick = BtnCancelClick
        end
        object BtnExecute: TButton
          Left = 2
          Top = 26
          Width = 187
          Height = 25
          Caption = 'Execute'
          TabOrder = 2
          OnClick = BtnExecuteClick
        end
        object BtnPreviewPoly: TButton
          Left = 191
          Top = 1
          Width = 185
          Height = 25
          Caption = 'Preview Poly'
          TabOrder = 3
          OnClick = BtnPreviewPolyClick
        end
      end
      object PnlProjects: TPanel
        Left = 0
        Top = 84
        Width = 713
        Height = 325
        Align = alTop
        TabOrder = 1
        object PnlProjectsGrid: TPanel
          Left = 1
          Top = 1
          Width = 319
          Height = 323
          Align = alLeft
          TabOrder = 0
          object DBNavProjects: TDBNavigator
            Left = 1
            Top = 1
            Width = 317
            Height = 25
            DataSource = DmSettings.DsProjects
            VisibleButtons = [nbFirst, nbLast, nbInsert, nbDelete, nbPost, nbCancel]
            Align = alTop
            TabOrder = 0
          end
          object DBWPrrojects: TDBWGrid
            Left = 1
            Top = 26
            Width = 317
            Height = 296
            Align = alClient
            BiDiMode = bdLeftToRight
            DataSource = DmSettings.DsProjects
            Options = [dgEditing, dgAlwaysShowEditor, dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit, dgMultiSelect]
            ParentBiDiMode = False
            ReadOnly = True
            TabOrder = 1
            TitleFont.Charset = DEFAULT_CHARSET
            TitleFont.Color = clWindowText
            TitleFont.Height = -11
            TitleFont.Name = 'Tahoma'
            TitleFont.Style = []
            BooleanObjects.Strings = (
              'GMAPSUPP'
              'GMAPI'
              'UNICODE')
            RealScrollBar = True
            Columns = <
              item
                Expanded = False
                FieldName = 'MapCode'
                Width = 50
                Visible = True
              end
              item
                Expanded = False
                FieldName = 'MapName'
                Width = 216
                Visible = True
              end>
          end
        end
        object PctProjects: TPageControl
          Left = 320
          Top = 1
          Width = 392
          Height = 323
          ActivePage = TsBasic
          Align = alClient
          TabOrder = 1
          object TsBasic: TTabSheet
            Caption = 'Basic'
            object PnlBasicProjectsFields: TPanel
              Left = 0
              Top = 0
              Width = 384
              Height = 295
              Align = alClient
              TabOrder = 0
            end
          end
          object TsAdvanced: TTabSheet
            Caption = 'Advanced'
            ImageIndex = 1
            object PnlAdvancedProjectsFields: TPanel
              Left = 0
              Top = 0
              Width = 384
              Height = 295
              Align = alClient
              TabOrder = 0
            end
          end
        end
      end
      object PnlProjectsUrl: TPanel
        Left = 0
        Top = 412
        Width = 713
        Height = 164
        Align = alClient
        Caption = 'PnlProjectsUrl'
        TabOrder = 2
        object DBNavProjectsUrl: TDBNavigator
          Left = 1
          Top = 1
          Width = 711
          Height = 25
          DataSource = DmSettings.DsProjectsUrls
          VisibleButtons = [nbFirst, nbLast, nbInsert, nbDelete, nbPost, nbCancel]
          Align = alTop
          TabOrder = 0
        end
        object DBProjectsUrl: TDBWGrid
          Left = 1
          Top = 26
          Width = 711
          Height = 137
          Align = alClient
          DataSource = DmSettings.DsProjectsUrls
          TabOrder = 1
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -11
          TitleFont.Name = 'Tahoma'
          TitleFont.Style = []
          Columns = <
            item
              Expanded = False
              FieldName = 'Url'
              Width = 650
              Visible = True
            end>
        end
      end
    end
    object TabPreview: TTabSheet
      Caption = 'Preview map style'
      ImageIndex = 3
      object ScPreview: TScrollBox
        Left = 0
        Top = 0
        Width = 713
        Height = 576
        HorzScrollBar.Tracking = True
        VertScrollBar.Tracking = True
        Align = alClient
        TabOrder = 0
        object ImgStyle: TImage
          Left = 0
          Top = 0
          Width = 612
          Height = 397
          AutoSize = True
        end
      end
    end
    object TabInstallmaps: TTabSheet
      Caption = 'Install maps'
      ImageIndex = 3
      object Splitter3: TSplitter
        Left = 403
        Top = 0
        Height = 576
        ExplicitLeft = 415
        ExplicitTop = 226
        ExplicitHeight = 100
      end
      object PnlInstallProjects: TPanel
        Left = 0
        Top = 0
        Width = 403
        Height = 576
        Align = alLeft
        Caption = 'PnlInstallProjects'
        TabOrder = 0
        object DbgrdInstallProjects: TDBGrid
          Left = 1
          Top = 61
          Width = 401
          Height = 495
          Align = alClient
          DataSource = DmSettings.DsProjects
          Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
          ReadOnly = True
          TabOrder = 0
          TitleFont.Charset = DEFAULT_CHARSET
          TitleFont.Color = clWindowText
          TitleFont.Height = -11
          TitleFont.Name = 'Tahoma'
          TitleFont.Style = []
          Columns = <
            item
              Expanded = False
              FieldName = 'MapName'
              Visible = True
            end>
        end
        object PnlTopInstallProjects: TPanel
          Left = 1
          Top = 1
          Width = 401
          Height = 60
          Align = alTop
          Caption = 'Projects'
          TabOrder = 1
          object BtnInstallMap: TButton
            Left = 3
            Top = 5
            Width = 85
            Height = 25
            Caption = 'Install Map'
            TabOrder = 0
            OnClick = BtnInstallMapClick
          end
        end
        object StatusBarProjects: TStatusBar
          Left = 1
          Top = 556
          Width = 401
          Height = 19
          Panels = <>
          SimplePanel = True
        end
      end
      object PnlInstalled: TPanel
        Left = 406
        Top = 0
        Width = 307
        Height = 576
        Align = alClient
        Caption = 'PnlInstalled'
        TabOrder = 1
        object LbInstalled: TListBox
          Left = 1
          Top = 61
          Width = 305
          Height = 495
          Align = alClient
          ItemHeight = 13
          TabOrder = 0
          OnClick = LbInstalledClick
        end
        object PnlTopInstalled: TPanel
          Left = 1
          Top = 1
          Width = 305
          Height = 60
          Align = alTop
          Caption = 'Installed Maps'
          TabOrder = 1
          object BtnUninstallMap: TButton
            Left = 3
            Top = 5
            Width = 85
            Height = 25
            Caption = 'UnInstall Map'
            TabOrder = 0
            OnClick = BtnUninstallMapClick
          end
          object BrnClearTileCache: TButton
            Left = 3
            Top = 29
            Width = 85
            Height = 25
            Caption = 'Clear TileCache'
            TabOrder = 1
            OnClick = BrnClearTileCacheClick
          end
        end
        object StatusBarInstalled: TStatusBar
          Left = 1
          Top = 556
          Width = 305
          Height = 19
          Panels = <>
          SimplePanel = True
        end
      end
    end
  end
  object PnlLog: TPanel
    Left = 724
    Top = 0
    Width = 400
    Height = 604
    Align = alRight
    TabOrder = 2
    OnResize = Resized
    object MemoLog: TRichEdit
      Left = 1
      Top = 68
      Width = 398
      Height = 535
      Align = alClient
      EnableURLs = True
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Lines.Strings = (
        'Memo1')
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      OnLinkClick = MemoLogLinkClick
    end
    object BtnLoadLog: TButton
      Left = 1
      Top = 43
      Width = 398
      Height = 25
      Align = alTop
      Caption = 'Load Log'
      TabOrder = 1
      OnClick = BtnLoadLogClick
    end
    object CmbLogType: TComboBox
      Left = 1
      Top = 22
      Width = 398
      Height = 21
      Align = alTop
      ItemIndex = 0
      TabOrder = 2
      Text = 'Progress Log'
      OnChange = CmbLogTypeChange
      Items.Strings = (
        'Progress Log'
        'Detailed Log'
        'Commands Log')
    end
    object CmbEcho: TComboBox
      Left = 1
      Top = 1
      Width = 398
      Height = 21
      Align = alTop
      ItemIndex = 0
      TabOrder = 3
      Text = 'Echo Off'
      OnChange = CmbLogTypeChange
      Items.Strings = (
        'Echo Off'
        'Echo On (Affects commands.log)')
    end
  end
  object MainMenu: TMainMenu
    Left = 177
    Top = 212
    object Help: TMenuItem
      Caption = 'Help'
      object General1: TMenuItem
        Caption = 'General'
        OnClick = General1Click
      end
      object Gettingstarted1: TMenuItem
        Caption = 'Getting started'
        OnClick = Gettingstarted1Click
      end
    end
  end
  object OpenDialogGpx: TOpenDialog
    DefaultExt = 'gpx'
    Filter = 'GPX files|*.gpx|All|*.*'
    Left = 119
    Top = 213
  end
end
