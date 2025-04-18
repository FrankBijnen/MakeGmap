﻿{ VerySimpleXML v2.0.5 - a lightweight, one-unit, cross-platform XML reader/writer
  for Delphi 2010 - 10.3.2 by Dennis Spreen
  http://blog.spreendigital.de/2014/09/13/verysimplexml-2-0/

  (c) Copyrights 2011-2019 Dennis D. Spreen <dennis@spreendigital.de>
  This unit is free and can be used for any needs. The introduction of
  any changes and the use of those changed library is permitted without
  limitations. Only requirement:
  This text must be present without changes in all modifications of library.

  * The contents of this file are used with permission, subject to
  * the Mozilla Public License Version 1.1 (the "License"); you may   *
  * not use this file except in compliance with the License. You may  *
  * obtain a copy of the License at                                   *
  * http:  www.mozilla.org/MPL/MPL-1.1.html                           *
  *                                                                   *
  * Software distributed under the License is distributed on an       *
  * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or    *
  * implied. See the License for the specific language governing      *
  * rights and limitations under the License.                         *
}

// Changed for ExifToolGUI
// - Add utf16

unit Xml.VerySimple;

interface

uses
  System.Classes, System.SysUtils, Generics.Defaults, Generics.Collections, System.Rtti;

const
  TXmlSpaces = #$20 + #$0A + #$0D + #9;

type
  TXmlVerySimple = class;
  TXmlNode = class;
  TXmlNodeType = (ntElement, ntText, ntCData, ntProcessingInstr, ntComment, ntDocument, ntDocType, ntXmlDecl);
  TXmlNodeTypes = set of TXmlNodeType;
  TXmlNodeList = class;
  TXmlAttributeType = (atValue, atSingle);
  TXmlOptions = set of (doNodeAutoIndent, doCompact, doParseProcessingInstr, doPreserveWhiteSpace, doCaseInsensitive,
    doWriteBOM, doNoHeader); //FB. Add doNoHeader
  TExtractTextOptions = set of (etoDeleteStopChar, etoStopString);

  {$IFNDEF AUTOREFCOUNT}
  WeakAttribute = class(TCustomAttribute);
  {$ENDIF}

  TStreamReaderFillBuffer = procedure(var Encoding: TEncoding) of object;

  TXmlStreamReader = class(TStreamReader)
  protected
    FBufferedData: TStringBuilder;
    FNoDataInStream: PBoolean;
    FFillBuffer: TStreamReaderFillBuffer;
    procedure FillBuffer;
    /// <summary> Call to FillBuffer method of TStreamreader </summary>
  public
    /// <summary> Extend the TStreamReader with RTTI pointers </summary>
    constructor Create(Stream: TStream; Encoding: TEncoding; DetectBOM: Boolean = False; BufferSize: Integer = 4096);
    /// <summary> Assures the read buffer holds at least Value characters </summary>
    function PrepareBuffer(Value: Integer): Boolean;
    /// <summary> Extract text until chars found in StopChars </summary>
    function ReadText(const StopChars: String; Options: TExtractTextOptions): String; virtual;
    /// <summary> Returns fist char but does not removes it from the buffer </summary>
    function FirstChar: String;
    /// <summary> Proceed with the next character(s) (value optional, default 1) </summary>
    procedure IncCharPos(Value: Integer = 1); virtual;
    /// <summary> Returns True if the first uppercased characters at the current position match Value </summary>
    function IsUppercaseText(const Value: String): Boolean; virtual;
  end;


  TXmlAttribute = class(TObject)
  private
    FValue: String;
  protected
    procedure SetValue(const Value: String); virtual;
  public
    /// <summary> Attribute name </summary>
    Name: String;
    /// <summary> Attributes without values are set to atSingle, else to atValue </summary>
    AttributeType: TXmlAttributeType;
    /// <summary> Create a new attribute </summary>
    constructor Create; virtual;
    /// <summary> Return the attribute as a String </summary>
    function AsString: String;
    /// <summary> Escapes XML control characters </summar>
    class function Escape(const Value: String): String; virtual;
    /// <summary> Assign attribute values from source attribute </summary>
    procedure Assign(Source: TXmlAttribute); virtual;
    /// <summary> Attribute value (always a String) </summary>
    property Value: String read FValue write SetValue;
  end;

  TXmlAttributeList = class(TObjectList<TXmlAttribute>)
  public
    /// <summary> The xml document of the attribute list of the node</summary>
    [Weak] Document: TXmlVerySimple;
    /// <summary> Add a name only attribute </summary>
    function Add(const Name: String): TXmlAttribute; overload; virtual;
    /// <summary> Returns the attribute given by name (case insensitive), NIL if no attribute found </summary>
    function Find(const Name: String): TXmlAttribute; virtual;
    /// <summary> Deletes an attribute given by name (case insensitive) </summary>
    procedure Delete(const Name: String); overload; virtual;
    /// <summary> Returns True if an attribute with the given name is found (case insensitive) </summary>
    function HasAttribute(const AttrName: String): Boolean; virtual;
    /// <summary> Returns the attributes in string representation </summary>
    function AsString: String; virtual;
    /// <summary> Clears current attributes and assigns all attributes from source attributes </summary>
    procedure Assign(Source: TXmlAttributeList); virtual;
  end;

  TXmlNode = class(TObject)
  protected
    [Weak] FDocument: TXmlVerySimple;
    procedure SetDocument(Value: TXmlVerySimple);
    function GetAttr(const AttrName: String): String; virtual;
    procedure SetAttr(const AttrName: String; const AttrValue: String); virtual;
  public
    /// <summary> All attributes of the node </summary>
    AttributeList: TXmlAttributeList;
    /// <summary> List of child nodes, never NIL </summary>
    ChildNodes: TXmlNodeList;
    /// <summary> Name of the node </summary>
    Name: String; // Node name
    /// <summary> The node type, see TXmlNodeType </summary>
    NodeType: TXmlNodeType;
    /// <summary> Parent node, may be NIL </summary>
    [Weak] Parent: TXmlNode;
    /// <summary> Text value of the node </summary>
    Text: String;
    /// <summary> Creates a new XML node </summary>
    constructor Create(ANodeType: TXmlNodeType = ntElement); virtual;
    /// <summary> Removes the node from its parent and frees all of its childs </summary>
    destructor Destroy; override;
    /// <summary> Clears the attributes, the text and all of its child nodes (but not the name) </summary>
    procedure Clear;
//FB
    /// <summary> Find position of a node, returns -1 if no node is found </summary>
    function FindPos(Node: TXmlNode): Integer; overload; virtual;
    /// <summary> Find position of a node by its name (case sensitive), returns -1 if no node is found </summary>
    function FindPos(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer; overload; virtual;
    /// <summary> Find a child node by name and node value </summary>
    function FindPos(const Name, NodeValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer; overload; virtual;
//FB_X
    /// <summary> Find a child node by its name </summary>
    function Find(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; overload; virtual;
    /// <summary> Find a child node by name and attribute name </summary>
    function Find(const Name, AttrName: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; overload; virtual;
    /// <summary> Find a child node by name, attribute name and attribute value </summary>
    function Find(const Name, AttrName, AttrValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; overload; virtual;
    /// <summary> Return a list of child nodes with the given name and (optional) node types </summary>
    function FindNodes(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNodeList; virtual;
    /// <summary> Returns True if the attribute exists </summary>
    function HasAttribute(const AttrName: String): Boolean; virtual;
    /// <summary> Returns True if a child node with that name exits </summary>
    function HasChild(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Boolean; virtual;
    /// <summary> Add a child node with an optional NodeType (default: ntElement)</summary>
    function AddChild(const AName: String; ANodeType: TXmlNodeType = ntElement): TXmlNode; virtual;
    /// <summary> Insert a child node at a specific position with a (optional) NodeType (default: ntElement)</summary>
    function InsertChild(const Name: String; Position: Integer; NodeType: TXmlNodeType = ntElement): TXmlNode; virtual;
    /// <summary> Fluent interface for setting the text of the node </summary>
    function SetText(const Value: String): TXmlNode; virtual;
    /// <summary> Fluent interface for setting the node attribute given by attribute name and attribute value </summary>
    function SetAttribute(const AttrName, AttrValue: String): TXmlNode; virtual;
    /// <summary> Returns first child or NIL if there aren't any child nodes </summary>
    function FirstChild: TXmlNode; virtual;
    /// <summary> Returns last child node or NIL if there aren't any child nodes </summary>
    function LastChild: TXmlNode; virtual;
    /// <summary> Returns next sibling </summary>
    function NextSibling: TXmlNode; overload; virtual;
    /// <summary> Returns previous sibling </summary>
    function PreviousSibling: TXmlNode; overload; virtual;
    /// <summary> Returns True if the node has at least one child node </summary>
    function HasChildNodes: Boolean; virtual;
    /// <summary> Returns True if the node has a text content and no child nodes </summary>
    function IsTextElement: Boolean; virtual;
    /// <summary> Fluent interface for setting the node type </summary>
    function SetNodeType(Value: TXmlNodeType): TXmlNode; virtual;
    /// <summary> Attributes of a node, accessible by attribute name (case insensitive) </summary>
    property Attributes[const AttrName: String]: String read GetAttr write SetAttr;
    /// <summary> The xml document of the node </summary>
    property Document: TXmlVerySimple read FDocument write SetDocument;
    /// <summary> The node name, same as property Name </summary>
    property NodeName: String read Name write Name;
    /// <summary> The node text, same as property Text </summary>
    property NodeValue: String read Text write Text;
  end;

  TXmlNodeList = class(TObjectList<TXmlNode>)
  protected
    function IsSame(const Value1, Value2: String): Boolean; virtual;
  public
    /// <summary> The xml document of the node list </summary>
    [Weak] Document: TXmlVerySimple;
    /// <summary> The parent node of the node list </summary>
    [Weak] Parent: TXmlNode;
    /// <summary> Adds a node and sets the parent of the node to the parent of the list </summary>
    function Add(Value: TXmlNode): Integer; overload; virtual;
    /// <summary> Creates a new node of type NodeType (default ntElement) and adds it to the list </summary>
    function Add(NodeType: TXmlNodeType = ntElement): TXmlNode; overload; virtual;
    /// <summary> Add a child node with an optional NodeType (default: ntElement)</summary>
    function Add(const Name: String; NodeType: TXmlNodeType = ntElement): TXmlNode; overload; virtual;
//FB
    /// <summary> Find position of a node, returns -1 if no node is found </summary>
    function FindPos(Node: TXmlNode): Integer; overload; virtual;
    /// <summary> Find position of a node by its name (case sensitive), returns -1 if no node is found </summary>
    function FindPos(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer; overload; virtual;
    /// <summary> Find a child node by name and node value </summary>
    function FindPos(const Name, NodeValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer; overload; virtual;
//FB_x
    /// <summary> Find a node by its name (case sensitive), returns NIL if no node is found </summary>
    function Find(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; overload; virtual;
    /// <summary> Same as Find(), returnsa a node by its name (case sensitive) </summary>
    function FindNode(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; virtual;
    /// <summary> Find a node that has the the given attribute, returns NIL if no node is found </summary>
    function Find(const Name, AttrName: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; overload; virtual;
    /// <summary> Find a node that as the given attribute name and value, returns NIL otherwise </summary>
    function Find(const Name, AttrName, AttrValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode; overload; virtual;
    /// <summary> Return a list of child nodes with the given name and (optional) node types </summary>
    function FindNodes(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNodeList; virtual;
    /// <summary> Returns True if the list contains a node with the given name </summary>
    function HasNode(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Boolean; virtual;
    /// <summary> Inserts a node at the given position </summary>
    function Insert(const Name: String; Position: Integer; NodeType: TXmlNodeType = ntElement): TXmlNode; overload; virtual;
    /// <summary> Returns the first child node, same as .First </summary>
    function FirstChild: TXmlNode; virtual;
    /// <summary> Returns next sibling node </summary>
    function NextSibling(Node: TXmlNode): TXmlNode; virtual;
    /// <summary> Returns previous sibling node </summary>
    function PreviousSibling(Node: TXmlNode): TXmlNode; virtual;
    /// <summary> Returns the node at the given position </summary>
    function Get(Index: Integer): TXmlNode; virtual;
  end;

  TXmlVerySimple = class(TObject)
  protected
    Root: TXmlNode;
    [Weak] FHeader: TXmlNode;
    [Weak] FDocumentElement: TXmlNode;
    SkipIndent: Boolean;
    procedure Parse(Reader: TXmlStreamReader); virtual;
    procedure ParseComment(Reader: TXmlStreamReader; var Parent: TXmlNode); virtual;
    procedure ParseDocType(Reader: TXmlStreamReader; var Parent: TXmlNode); virtual;
    procedure ParseProcessingInstr(Reader: TXmlStreamReader; var Parent: TXmlNode); virtual;
    procedure ParseCData(Reader: TXmlStreamReader; var Parent: TXmlNode); virtual;
    procedure ParseText(const Line: String; Parent: TXmlNode); virtual;
    function ParseTag(Reader: TXmlStreamReader; ParseText: Boolean; var Parent: TXmlNode): TXmlNode; overload; virtual;
    function ParseTag(const TagStr: String; var Parent: TXmlNode): TXmlNode; overload; virtual;
    procedure Walk(Writer: TStreamWriter; const PrefixNode: String; Node: TXmlNode); virtual;
    procedure SetText(const Value: String); virtual;
    function GetText: String; virtual;
    procedure SetEncoding(const Value: String); virtual;
    function GetEncoding: String; virtual;
    procedure SetVersion(const Value: String); virtual;
    function GetVersion: String; virtual;
    procedure Compose(Writer: TStreamWriter); virtual;
    procedure SetStandAlone(const Value: String); virtual;
    function GetStandAlone: String; virtual;
    function GetChildNodes: TXmlNodeList; virtual;
    procedure CreateHeaderNode; virtual;
    function ExtractText(var Line: String; const StopChars: String; Options: TExtractTextOptions): String; virtual;
    procedure SetDocumentElement(Value: TXMlNode); virtual;
    procedure SetPreserveWhitespace(Value: Boolean);
    function GetPreserveWhitespace: Boolean;
    function IsSame(const Value1, Value2: String): Boolean;
  public
    /// <summary> Indent used for the xml output </summary>
    NodeIndentStr: String;
    /// <summary> LineBreak used for the xml output, default set to sLineBreak which is OS dependent </summary>
    LineBreak: String;
    /// <summary> Options for xml output like indentation type </summary>
    Options: TXmlOptions;
    /// <summary> Creates a new XML document parser </summary>
    constructor Create; virtual;
    /// <summary> Destroys the XML document parser </summary>
    destructor Destroy; override;
    /// <summary> Deletes all nodes </summary>
    procedure Clear; virtual;
    /// <summary> Adds a new node to the document, if it's the first ntElement then sets it as .DocumentElement </summary>
    function AddChild(const Name: String; NodeType: TXmlNodeType = ntElement): TXmlNode; virtual;
    /// <summary> Creates a new node but doesn't adds it to the document nodes </summary>
    function CreateNode(const Name: String; NodeType: TXmlNodeType = ntElement): TXmlNode; virtual;
    /// <summary> Escapes XML control characters </summar>
    class function Escape(const Value: String): String; virtual;
    /// <summary> Translates escaped characters back into XML control characters </summar>
    class function Unescape(const Value: String): String; virtual;
    /// <summary> Loads the XML from a file </summary>
    function LoadFromFile(const FileName: String; BufferSize: Integer = 4096): TXmlVerySimple; virtual;
    /// <summary> Loads the XML from a stream </summary>
    function LoadFromStream(const Stream: TStream; BufferSize: Integer = 4096): TXmlVerySimple; virtual;
    /// <summary> Parse attributes into the attribute list for a given string </summary>
    procedure ParseAttributes(const AttribStr: String; AttributeList: TXmlAttributeList); virtual;
    /// <summary> Saves the XML to a file </summary>
    function SaveToFile(const FileName: String): TXmlVerySimple; virtual;
    /// <summary> Saves the XML to a stream, the encoding is specified in the .Encoding property </summary>
    function SaveToStream(const Stream: TStream): TXmlVerySimple; virtual;
    /// <summary> A list of all root nodes of the document </summary>
    property ChildNodes: TXmlNodeList read GetChildNodes;
    /// <summary> Returns the first element node </summary>
    property DocumentElement: TXmlNode read FDocumentElement write SetDocumentElement;
    /// <summary> Specifies the encoding of the XML file, anything else then 'utf-8' is considered as ANSI </summary>
    property Encoding: String read GetEncoding write SetEncoding;
    /// <summary> XML declarations are stored in here as Attributes </summary>
    property Header: TXmlNode read FHeader;
    /// <summary> Set to True if all spaces and linebreaks should be included as a text node, same as doPreserve option </summary>
    property PreserveWhitespace: Boolean read GetPreserveWhitespace write SetPreserveWhitespace;
    /// <summary> Defines the xml declaration property "StandAlone", set it to "yes" or "no" </summary>
    property StandAlone: String read GetStandAlone write SetStandAlone;
    /// <summary> The XML as a string representation </summary>
    property Text: String read GetText write SetText;
    /// <summary> Defines the xml declaration property "Version", default set to "1.0" </summary>
    property Version: String read GetVersion write SetVersion;
    /// <summary> The XML as a string representation, same as .Text </summary>
    property Xml: String read GetText write SetText;
  end;

implementation

uses
  System.StrUtils;

type
  TStreamReaderHelper = class helper for TStreamReader
  public
    procedure GetFillBuffer(var Method: TStreamReaderFillBuffer);
  end;

const
{$IF CompilerVersion >= 24} // Delphi XE3+ can use Low(), High() and TEncoding.ANSI
  LowStr = Low(String); // Get string index base, may be 0 (NextGen compiler) or 1 (standard compiler)

{$ELSE} // For any previous Delphi version overwrite High() function and use 1 as string index base
  LowStr = 1;  // Use 1 as string index base

function High(const Value: String): Integer; inline;
begin
  Result := Length(Value);
end;

//Delphi XE3 added PosEx as an overloaded Pos function, so we need to wrap it in every other Delphi version
function Pos(const SubStr, S: string; Offset: Integer): Integer; overload; Inline;
begin
  Result := PosEx(SubStr, S, Offset);
end;
{$IFEND}

{$IF CompilerVersion < 23}  //Delphi XE2 added ANSI as Encoding, in every other Delphi version use TEncoding.Default
type
  TEncodingHelper = class helper for TEncoding
    class function GetANSI: TEncoding; static;
    class property ANSI: TEncoding read GetANSI;
  end;

class function TEncodingHelper.GetANSI: TEncoding;
begin
  Result := TEncoding.Default;
end;
{$IFEND}

{ TVerySimpleXml }

function TXmlVerySimple.AddChild(const Name: String; NodeType: TXmlNodeType = ntElement): TXmlNode;
begin
  Result := CreateNode(Name, NodeType);
  if (NodeType = ntElement) and (not Assigned(FDocumentElement)) then
    FDocumentElement := Result;
  try
    Root.ChildNodes.Add(Result);
  except
    Result.Free;
    raise;
  end;
  Result.Document := Self;
end;

procedure TXmlVerySimple.Clear;
begin
  FDocumentElement := NIL;
  FHeader := NIL;
  Root.Clear;
end;

constructor TXmlVerySimple.Create;
begin
  inherited;
  Root := TXmlNode.Create;
  Root.NodeType := ntDocument;
  Root.Parent := Root;
  Root.Document := Self;
  NodeIndentStr := '  ';
  Options := [doNodeAutoIndent, doWriteBOM];
  LineBreak := sLineBreak;
  CreateHeaderNode;
end;

procedure TXmlVerySimple.CreateHeaderNode;
begin
  if Assigned(FHeader) then
    Exit;
  FHeader := Root.ChildNodes.Insert('xml', 0, ntXmlDecl);
  FHeader.Attributes['version'] := '1.0';  // Default XML version
  FHeader.Attributes['encoding'] := 'utf-8';
end;

function TXmlVerySimple.CreateNode(const Name: String; NodeType: TXmlNodeType): TXmlNode;
begin
  Result := TXmlNode.Create(NodeType);
  Result.Name := Name;
  Result.Document := Self;
end;

destructor TXmlVerySimple.Destroy;
begin
  Root.Parent := NIL;
  Root.Clear;
  Root.Free;
  inherited;
end;

function TXmlVerySimple.GetChildNodes: TXmlNodeList;
begin
  Result := Root.ChildNodes;
end;

function TXmlVerySimple.GetEncoding: String;
begin
  if Assigned(FHeader) then
    Result := FHeader.Attributes['encoding']
  else
    Result := '';
end;

function TXmlVerySimple.GetPreserveWhitespace: Boolean;
begin
  Result := doPreserveWhitespace in Options;
end;

function TXmlVerySimple.GetStandAlone: String;
begin
  if Assigned(FHeader) then
    Result := FHeader.Attributes['standalone']
  else
    Result := '';
end;

function TXmlVerySimple.GetVersion: String;
begin
  if Assigned(FHeader) then
    Result := FHeader.Attributes['version']
  else
    Result := '';
end;

function TXmlVerySimple.IsSame(const Value1, Value2: String): Boolean;
begin
  if doCaseInsensitive in Options then
    Result := AnsiSameText(Value1, Value2)
  else
    Result := (Value1 = Value2);
end;

function TXmlVerySimple.GetText: String;
var
  Stream: TStringStream;
begin
  if AnsiSameText(Encoding, 'utf-8') then
    Stream := TStringStream.Create('', TEncoding.UTF8)
  else
    Stream := TStringStream.Create('', TEncoding.ANSI);
  try
    SaveToStream(Stream);
    Result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

procedure TXmlVerySimple.Compose(Writer: TStreamWriter);
var
  Child: TXmlNode;
begin
  if doCompact in Options then
  begin
    Writer.NewLine := '';
    LineBreak := '';
  end
  else
    Writer.NewLine := LineBreak;

  SkipIndent := False;
  for Child in Root.ChildNodes do
    Walk(Writer, '', Child);
end;

function TXmlVerySimple.LoadFromFile(const FileName: String; BufferSize: Integer = 4096): TXmlVerySimple;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead + fmShareDenyWrite);
  try
    LoadFromStream(Stream, BufferSize);
  finally
    Stream.Free;
  end;
  Result := Self;
end;

function TXmlVerySimple.LoadFromStream(const Stream: TStream; BufferSize: Integer = 4096): TXmlVerySimple;
var
  Reader: TXmlStreamReader;
begin
  if Encoding = '' then // none specified then use UTF8 with DetectBom
    Reader := TXmlStreamReader.Create(Stream, TEncoding.UTF8, True, BufferSize)
  else
  if AnsiSameText(Encoding, 'utf-8') then
    Reader := TXmlStreamReader.Create(Stream, TEncoding.UTF8, False, BufferSize)
//ExifToolGUI Add utf16
  else if AnsiSameText(Encoding, 'utf-16') then
    Reader := TXmlStreamReader.Create(Stream, TEncoding.Unicode, False, BufferSize)
  else if AnsiSameText(Encoding, 'utf-16be') then
    Reader := TXmlStreamReader.Create(Stream, TEncoding.BigEndianUnicode, False, BufferSize)
//ExifToolGUI_x
  else
    Reader := TXmlStreamReader.Create(Stream, TEncoding.ANSI, False, BufferSize);
  try
    Parse(Reader);
  finally
    Reader.Free;
  end;
  Result := Self;
end;

procedure TXmlVerySimple.Parse(Reader: TXmlStreamReader);
var
  Parent, Node: TXmlNode;
  FirstChar: String;
  ALine: String;
begin
  Clear;
  Parent := Root;

  while not Reader.EndOfStream do
  begin
    ALine := Reader.ReadText('<', [etoDeleteStopChar]);
    if ALine <> '' then  // Check for text nodes
    begin
      ParseText(Aline, Parent);
      if Reader.EndOfStream then  // if no chars available then exit
        Break;
    end;
    FirstChar := Reader.FirstChar;
//FB Dont add last empty node. If the XML File ends with 0x0a, or 0x0d0a for example.
    if ((FirstChar = #10) or (FirstChar = #13)) and
        not Reader.PrepareBuffer(3) then // At least 3 more chars should be available
      Continue;
//FB_X
    if FirstChar = '!' then
      if Reader.IsUppercaseText('!--') then  // check for a comment node
        ParseComment(Reader, Parent)
      else
      if Reader.IsUppercaseText('!DOCTYPE') then // check for a doctype node
        ParseDocType(Reader, Parent)
      else
      if Reader.IsUppercaseText('![CDATA[') then // check for a cdata node
        ParseCData(Reader, Parent)
      else
        ParseTag(Reader, False, Parent) // try to parse as tag
    else // Check for XML header / processing instructions
    if FirstChar = '?' then // could be header or processing instruction
      ParseProcessingInstr(Reader, Parent)
    else
    if FirstChar <> '' then
    begin // Parse a tag, the first tag in a document is the DocumentElement
      Node := ParseTag(Reader, True, Parent);
      if (not Assigned(FDocumentElement)) and (Parent = Root) then
        FDocumentElement := Node;
    end;
  end;
end;

procedure TXmlVerySimple.ParseAttributes(const AttribStr: String; AttributeList: TXmlAttributeList);
var
  Attribute: TXmlAttribute;
  AttrName, AttrText: String;
  Quote: String;
  Value: String;
begin
  Value := TrimLeft(AttribStr);
  while Value <> '' do
  begin
    AttrName := ExtractText(Value, ' =', []);
    Value := TrimLeft(Value);

    Attribute := AttributeList.Add(AttrName);
    if (Value = '') or (Value[LowStr]<>'=') then
      Continue;

    Delete(Value, 1, 1);
    Attribute.AttributeType := atValue;
    ExtractText(Value, '''' + '"', []);
    Value := TrimLeft(Value);
    if Value <> '' then
    begin
      Quote := Value[LowStr];
      Delete(Value, 1, 1);
      AttrText := ExtractText(Value, Quote, [etoDeleteStopChar]); // Get Attribute Value
      Attribute.Value := Unescape(AttrText);
      Value := TrimLeft(Value);
    end;
  end;
end;


procedure TXmlVerySimple.ParseText(const Line: String; Parent: TXmlNode);
var
  SingleChar: Char;
  Node: TXmlNode;
  TextNode: Boolean;
begin
  if PreserveWhiteSpace then
    TextNode := True
  else
  begin
    TextNode := False;
    for SingleChar in Line do
      if AnsiStrScan(TXmlSpaces, SingleChar) = NIL then
      begin
        TextNode := True;
        Break;
      end;
  end;

  if TextNode then
  begin
    Node := Parent.ChildNodes.Add(ntText);
    Node.Text := Line;
  end;
end;

procedure TXmlVerySimple.ParseCData(Reader: TXmlStreamReader; var Parent: TXmlNode);
var
  Node: TXmlNode;
begin
  Node := Parent.ChildNodes.Add(ntCData);
  Node.Text := Reader.ReadText(']]>', [etoDeleteStopChar, etoStopString]);
end;

procedure TXmlVerySimple.ParseComment(Reader: TXmlStreamReader; var Parent: TXmlNode);
var
  Node: TXmlNode;
begin
  Node := Parent.ChildNodes.Add(ntComment);
  Node.Text := Reader.ReadText('-->', [etoDeleteStopChar, etoStopString]);
end;

procedure TXmlVerySimple.ParseDocType(Reader: TXmlStreamReader; var Parent: TXmlNode);
var
  Node: TXmlNode;
  Quote: String;
begin
  Node := Parent.ChildNodes.Add(ntDocType);
  Node.Text := Reader.ReadText('>[', []);
  if not Reader.EndOfStream then
  begin
    Quote := Reader.FirstChar;
    Reader.IncCharPos;
    if Quote = '[' then
      Node.Text := Node.Text + Quote + Reader.ReadText(']',[etoDeleteStopChar]) + ']' +
        Reader.ReadText('>', [etoDeleteStopChar]);
  end;
end;

procedure TXmlVerySimple.ParseProcessingInstr(Reader: TXmlStreamReader; var Parent: TXmlNode);
var
  Node: TXmlNode;
  Tag: String;
begin
  Reader.IncCharPos; // omit the '?'
  Tag := Reader.ReadText('?>', [etoDeleteStopChar, etoStopString]);
  Node := ParseTag(Tag, Parent);
  if lowercase(Node.Name) = 'xml' then
  begin
    FHeader := Node;
    FHeader.NodeType := ntXmlDecl;
  end
  else
  begin
    Node.NodeType := ntProcessingInstr;
    if not (doParseProcessingInstr in Options) then
    begin
      Node.Text := Tag;
      Node.AttributeList.Clear;
    end;
  end;
  Parent := Node.Parent;
end;

function TXmlVerySimple.ParseTag(Reader: TXmlStreamReader; ParseText: Boolean; var Parent: TXmlNode): TXmlNode;
var
  Tag: String;
  ALine: String;
  SingleChar: Char;
begin
  Tag := Reader.ReadText('>', [etoDeleteStopChar]);
  Result := ParseTag(Tag, Parent);
  if (Result = Parent) and (ParseText) then // only non-self closing nodes may have a text
  begin
    ALine := Reader.ReadText('<', []);
    ALine := Unescape(ALine);

    if PreserveWhiteSpace then
      Result.Text := ALine
    else
      for SingleChar in ALine do
        if AnsiStrScan(TXmlSpaces, SingleChar) = NIL then
        begin
          Result.Text := ALine;
          Break;
        end;
  end;
end;

function TXmlVerySimple.ParseTag(const TagStr: String; var Parent: TXmlNode): TXmlNode;
var
  Node: TXmlNode;
  ALine: String;
  CharPos: Integer;
  Tag: String;
begin
  // A closing tag does not have any attributes nor text
  if (TagStr <> '') and (TagStr[LowStr] = '/') then
  begin
    Result := Parent;
    Parent := Parent.Parent;
    Exit;
  end;

  // Creat a new new ntElement node
  Node := Parent.ChildNodes.Add;
  Result := Node;
  Tag := TagStr;

  // Check for a self-closing Tag (does not have any text)
  if (Tag <> '') and (Tag[High(Tag)] = '/') then
    Delete(Tag, Length(Tag), 1)
  else
    Parent := Node;

  CharPos := Pos(' ', Tag);
  if CharPos <> 0 then // Tag may have attributes
  begin
    ALine := Tag;
    Delete(Tag, CharPos, Length(Tag));
    Delete(ALine, 1, CharPos);
    if ALine <> '' then
      ParseAttributes(ALine, Node.AttributeList);
  end;

  Node.Name := Tag;
end;


function TXmlVerySimple.SaveToFile(const FileName: String): TXmlVerySimple;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
  Result := Self;
end;

function TXmlVerySimple.SaveToStream(const Stream: TStream): TXmlVerySimple;
var
  Writer: TStreamWriter;
begin
  if AnsiSameText(Self.Encoding, 'utf-8') then
    if doWriteBOM in Options then
      Writer := TStreamWriter.Create(Stream, TEncoding.UTF8)
    else
      Writer := TStreamWriter.Create(Stream)
  else
    Writer := TStreamWriter.Create(Stream, TEncoding.ANSI);
  try
    Compose(Writer);
  finally
    Writer.Free;
  end;
  Result := Self;
end;

procedure TXmlVerySimple.SetDocumentElement(Value: TXMlNode);
begin
  FDocumentElement := Value;
  if Value.Parent = NIL then
    Root.ChildNodes.Add(Value);
end;

procedure TXmlVerySimple.SetEncoding(const Value: String);
begin
  CreateHeaderNode;
  FHeader.Attributes['encoding'] := Value;
end;

procedure TXmlVerySimple.SetPreserveWhitespace(Value: Boolean);
begin
  if Value then
    Options := Options + [doPreserveWhitespace]
  else
    Options := Options - [doPreserveWhitespace]
end;

procedure TXmlVerySimple.SetStandAlone(const Value: String);
begin
  CreateHeaderNode;
  FHeader.Attributes['standalone'] := Value;
end;

procedure TXmlVerySimple.SetVersion(const Value: String);
begin
  CreateHeaderNode;
  FHeader.Attributes['version'] := Value;
end;


class function TXmlVerySimple.Unescape(const Value: String): String;
begin
  Result := ReplaceStr(Value, '&lt;', '<');
  Result := ReplaceStr(Result, '&gt;', '>');
  Result := ReplaceStr(Result, '&quot;', '"');
  Result := ReplaceStr(Result, '&apos;', '''');
  Result := ReplaceStr(Result, '&amp;', '&');
end;

procedure TXmlVerySimple.SetText(const Value: String);
var
  Stream: TStringStream;
begin
  Stream := TStringStream.Create('', TEncoding.UTF8);
  try
    Stream.WriteString(Value);
    Stream.Position := 0;
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TXmlVerySimple.Walk(Writer: TStreamWriter; const PrefixNode: String; Node: TXmlNode);
var
  Child: TXmlNode;
  Line: String;
  Indent: String;
begin
  if (Node = Root.ChildNodes.First) or (SkipIndent) then
  begin
    Line := '<';
    SkipIndent := False;
  end
  else
    Line := LineBreak + PrefixNode + '<';

  case Node.NodeType of
    ntComment:
      begin
        Writer.Write(Line + '!--' + Node.Text + '-->');
        Exit;
      end;
    ntDocType:
      begin
        Writer.Write(Line + '!DOCTYPE ' + Node.Text + '>');
        Exit;
      end;
    ntCData:
      begin
        Writer.Write('<![CDATA[' + Node.Text + ']]>');
        Exit;
      end;
    ntText:
      begin
        Writer.Write(Node.Text);
        SkipIndent := True;
        Exit;
      end;
    ntProcessingInstr:
      begin
        if Node.AttributeList.Count > 0 then
          Writer.Write(Line + '?' + Node.Name + Node.AttributeList.AsString + '?>')
        else
          Writer.Write(Line + '?' + Node.Text + '?>');
        Exit;
      end;
    ntXmlDecl:
      begin
//FB
        if not (doNoHeader in Options) then
//FB_x
          Writer.Write(Line + '?' + Node.Name + Node.AttributeList.AsString + '?>');
        Exit;
      end;
  end;

  Line := Line + Node.Name + Node.AttributeList.AsString;

  // Self closing tags
  if (Node.Text = '') and (not Node.HasChildNodes) then
   begin
    Writer.Write(Line + '/>');
    Exit;
  end;

  Line := Line + '>';
  if Node.Text <> '' then
  begin
    Line := Line + Escape(Node.Text);
    if Node.HasChildNodes then
      SkipIndent := True;
  end;

  Writer.Write(Line);

  // Set indent for child nodes
  if doCompact in Options then
    Indent := ''
  else
    Indent := PrefixNode + NodeIndentStr;

  // Process child nodes
  for Child in Node.ChildNodes do
    Walk(Writer, Indent, Child);

  // If node has child nodes and last child node is not a text node then set indent for closing tag
  if (Node.HasChildNodes) and (not SkipIndent) then
    Indent := LineBreak + PrefixNode
  else
    Indent := '';

  Writer.Write(Indent + '</' + Node.Name + '>');
end;


class function TXmlVerySimple.Escape(const Value: String): String;
begin
  Result := TXmlAttribute.Escape(Value);
  Result := ReplaceStr(Result, '''', '&apos;');
end;

function TXmlVerySimple.ExtractText(var Line: String; const StopChars: String;
  Options: TExtractTextOptions): String;
var
  CharPos, FoundPos: Integer;
  TestChar: Char;
begin
  FoundPos := 0;
  for TestChar in StopChars do
  begin
    CharPos := Pos(TestChar, Line);
    if (CharPos <> 0) and ((FoundPos = 0) or (CharPos < FoundPos)) then
      FoundPos := CharPos;
  end;

  if FoundPos <> 0 then
  begin
    Dec(FoundPos);
    Result := Copy(Line, 1, FoundPos);
    if etoDeleteStopChar in Options then
      Inc(FoundPos);
    Delete(Line, 1, FoundPos);
  end
  else
  begin
    Result := Line;
    Line := '';
  end;
end;

{ TXmlNode }

function TXmlNode.AddChild(const AName: String; ANodeType: TXmlNodeType = ntElement): TXmlNode;
begin
  Result := ChildNodes.Add(AName, ANodeType);
end;

procedure TXmlNode.Clear;
begin
  Text := '';
  AttributeList.Clear;
  ChildNodes.Clear;
end;

constructor TXmlNode.Create(ANodeType: TXmlNodeType = ntElement);
begin
  ChildNodes := TXmlNodeList.Create;
  ChildNodes.Parent := Self;
  AttributeList := TXmlAttributeList.Create;
  NodeType := ANodeType;
end;

destructor TXmlNode.Destroy;
begin
  Clear;
  ChildNodes.Free;
  AttributeList.Free;
  inherited;
end;

//FB
function TXmlNode.FindPos(Node: TXmlNode): Integer;
begin
  Result := ChildNodes.FindPos(Node);
end;

function TXmlNode.FindPos(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer;
begin
  Result := ChildNodes.FindPos(Name, NodeTypes);
end;

function TXmlNode.FindPos(const Name, NodeValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer;
begin
  Result := ChildNodes.FindPos(Name, NodeValue, NodeTypes);
end;
//FB_X

function TXmlNode.Find(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
begin
  Result := ChildNodes.Find(Name, NodeTypes);
end;

function TXmlNode.Find(const Name, AttrName, AttrValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
begin
  Result := ChildNodes.Find(Name, AttrName, AttrValue, NodeTypes);
end;

function TXmlNode.Find(const Name, AttrName: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
begin
  Result := ChildNodes.Find(Name, AttrName, NodeTypes);
end;

function TXmlNode.FindNodes(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNodeList;
begin
  Result := ChildNodes.FindNodes(Name, NodeTypes);
end;

function TXmlNode.FirstChild: TXmlNode;
begin
  Result := ChildNodes.First;
end;

function TXmlNode.GetAttr(const AttrName: String): String;
var
  Attribute: TXmlAttribute;
begin
  Attribute := AttributeList.Find(AttrName);
  if Assigned(Attribute) then
    Result := Attribute.Value
  else
    Result := '';
end;

function TXmlNode.HasAttribute(const AttrName: String): Boolean;
begin
  Result := AttributeList.HasAttribute(AttrName);
end;

function TXmlNode.HasChild(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Boolean;
begin
  Result := ChildNodes.HasNode(Name, NodeTypes);
end;

function TXmlNode.HasChildNodes: Boolean;
begin
  Result := (ChildNodes.Count > 0);
end;

function TXmlNode.InsertChild(const Name: String; Position: Integer; NodeType: TXmlNodeType = ntElement): TXmlNode;
begin
  Result := ChildNodes.Insert(Name, Position, NodeType);
  if Assigned(Result) then
    Result.Parent := Self;
end;

function TXmlNode.IsTextElement: Boolean;
begin
  Result := (Text <> '') and (not HasChildNodes);
end;

function TXmlNode.LastChild: TXmlNode;
begin
  if ChildNodes.Count > 0 then
    Result := ChildNodes.Last
  else
    Result := NIL;
end;

function TXmlNode.NextSibling: TXmlNode;
begin
  if not Assigned(Parent) then
    Result := NIL
  else
    Result := Parent.ChildNodes.NextSibling(Self);
end;

function TXmlNode.PreviousSibling: TXmlNode;
begin
  if not Assigned(Parent) then
    Result := NIL
  else
    Result := Parent.ChildNodes.PreviousSibling(Self);
end;

procedure TXmlNode.SetAttr(const AttrName, AttrValue: String);
begin
  SetAttribute(AttrName, AttrValue);
end;

function TXmlNode.SetAttribute(const AttrName, AttrValue: String): TXmlNode;
var
  Attribute: TXmlAttribute;
begin
  Attribute := AttributeList.Find(AttrName); // Search for given name
  if not Assigned(Attribute) then // If attribute is not found, create one
    Attribute := AttributeList.Add(AttrName);
  Attribute.AttributeType := atValue;
  Attribute.Name := AttrName; // this allows rewriting of the attribute name (lower/upper case)
  Attribute.Value := AttrValue;
  Result := Self;
end;

procedure TXmlNode.SetDocument(Value: TXmlVerySimple);
begin
  FDocument := Value;
  AttributeList.Document := Value;
  ChildNodes.Document := Value;
end;

function TXmlNode.SetNodeType(Value: TXmlNodeType): TXmlNode;
begin
  NodeType := Value;
  Result := Self;
end;

function TXmlNode.SetText(const Value: String): TXmlNode;
begin
  Text := Value;
  Result := Self;
end;

{ TXmlAttributeList }

function TXmlAttributeList.Add(const Name: String): TXmlAttribute;
begin
  Result := TXmlAttribute.Create;
  Result.Name := Name;
  try
    Add(Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TXmlAttributeList.Assign(Source: TXmlAttributeList);
var
  Attribute: TXmlAttribute;
  SourceAttribute: TXmlAttribute;
begin
  Clear;
  for SourceAttribute in Source do
  begin
    Attribute := Add('');
    Attribute.Assign(SourceAttribute);
  end;
end;

function TXmlAttributeList.AsString: String;
var
  Attribute: TXmlAttribute;
begin
  Result := '';
  for Attribute in Self do
    Result := Result + ' ' + Attribute.AsString;
end;

procedure TXmlAttributeList.Delete(const Name: String);
var
  Attribute: TXmlAttribute;
begin
  Attribute := Find(Name);
  if Assigned(Attribute) then
    Remove(Attribute);
end;

function TXmlAttributeList.Find(const Name: String): TXmlAttribute;
var
  Attribute: TXmlAttribute;
begin
  Result := NIL;
  for Attribute in Self do
    if ((Assigned(Document) and Document.IsSame(Attribute.Name, Name)) or // use the documents text comparison
      ((not Assigned(Document)) and (Attribute.Name = Name))) then // or if not assigned then compare names case sensitive
    begin
      Result := Attribute;
      Break;
    end;
end;

function TXmlAttributeList.HasAttribute(const AttrName: String): Boolean;
begin
  Result := Assigned(Find(AttrName));
end;

{ TXmlNodeList }

//FB
function TXmlNodeList.FindPos(Node: TXmlNode): Integer;
begin
  Result := Self.IndexOf(Node);
end;

function TXmlNodeList.FindPos(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer;
begin
  Result := Self.IndexOf(Find(Name, NodeTypes));
end;

function TXmlNodeList.FindPos(const Name, NodeValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): Integer;
var
  Node: TXmlNode;
begin
  Result := -1;
  for Node in Self do
    if ((NodeTypes = []) or (Node.NodeType in NodeTypes)) and
      (IsSame(Node.Name, Name) and (IsSame(Node.NodeValue, NodeValue))) then
    begin
      Result := Self.IndexOf(Node);
      Break;
    end;
end;
//FB_x

function TXmlNodeList.Find(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
var
  Node: TXmlNode;
begin
  Result := NIL;
  for Node in Self do
    if ((NodeTypes = []) or (Node.NodeType in NodeTypes)) and (IsSame(Node.Name, Name)) then
    begin
      Result := Node;
      Break;
    end;
end;

function TXmlNodeList.Add(Value: TXmlNode): Integer;
begin
  Result := inherited Add(Value);
  Value.Parent := Parent;
end;

function TXmlNodeList.Add(NodeType: TXmlNodeType = ntElement): TXmlNode;
begin
  Result := TXmlNode.Create(NodeType);
  try
    Add(Result);
  except
    Result.Free;
    raise;
  end;
  Result.Document := Document;
end;

function TXmlNodeList.Add(const Name: String; NodeType: TXmlNodeType): TXmlNode;
begin
  Result := Add(NodeType);
  Result.Name := Name;
end;

function TXmlNodeList.Find(const Name, AttrName, AttrValue: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
var
  Node: TXmlNode;
begin
  Result := NIL;
  for Node in Self do
    if ((NodeTypes = []) or (Node.NodeType in NodeTypes)) and // if no type specified or node type in types
      IsSame(Node.Name, Name) and Node.HasAttribute(AttrName) and IsSame(Node.Attributes[AttrName], AttrValue) then
    begin
      Result := Node;
      Break;
    end;
end;

function TXmlNodeList.Find(const Name, AttrName: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
var
  Node: TXmlNode;
begin
  Result := NIL;
  for Node in Self do
    if ((NodeTypes = []) or (Node.NodeType in NodeTypes)) and IsSame(Node.Name, Name) and
      Node.HasAttribute(AttrName) then
    begin
      Result := Node;
      Break;
    end;
end;


function TXmlNodeList.FindNode(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNode;
begin
  Result := Find(Name, NodeTypes);
end;

function TXmlNodeList.FindNodes(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): TXmlNodeList;
var
  Node: TXmlNode;
begin
  Result := TXmlNodeList.Create(False);
  Result.Document := Document;
  try
    for Node in Self do
      if ((NodeTypes = []) or (Node.NodeType in NodeTypes)) and IsSame(Node.Name, Name) then
        begin
          Result.Parent := Node.Parent;
          Result.Add(Node);
        end;
    Result.Parent := NIL;
  except
    Result.Free;
    raise;
  end;
end;

function TXmlNodeList.FirstChild: TXmlNode;
begin
  Result := First;
end;


function TXmlNodeList.Get(Index: Integer): TXmlNode;
begin
  Result := Items[Index];
end;

function TXmlNodeList.HasNode(const Name: String; NodeTypes: TXmlNodeTypes = [ntElement]): Boolean;
begin
  Result := Assigned(Find(Name, NodeTypes));
end;

function TXmlNodeList.Insert(const Name: String; Position: Integer; NodeType: TXmlNodeType = ntElement): TXmlNode;
begin
  Result := TXmlNode.Create;
  Result.Document := Document;
  try
    Result.Name := Name;
    Result.NodeType := NodeType;
    Insert(Position, Result);
  except
    Result.Free;
    raise;
  end;
end;

function TXmlNodeList.IsSame(const Value1, Value2: String): Boolean;
begin
  Result := ((Assigned(Document) and Document.IsSame(Value1, Value2)) or // use the documents text comparison
    ((not Assigned(Document)) and (Value1 = Value2))); // or if not assigned then compare names case sensitive
end;

function TXmlNodeList.NextSibling(Node: TXmlNode): TXmlNode;
var
  Index: Integer;
begin
  if (not Assigned(Node)) and (Count > 0) then
    Result := First
  else
  begin
    Index := Self.IndexOf(Node);
    if (Index >= 0) and (Index + 1 < Count) then
      Result := Self[Index + 1]
    else
      Result := NIL;
  end;
end;

function TXmlNodeList.PreviousSibling(Node: TXmlNode): TXmlNode;
var
  Index: Integer;
begin
  Index := Self.IndexOf(Node);
  if Index - 1 >= 0 then
    Result := Self[Index - 1]
  else
    Result := NIL;
end;

{ TXmlAttribute }

procedure TXmlAttribute.Assign(Source: TXmlAttribute);
begin
  FValue := Source.Value;
  Name := Source.Name;
  AttributeType := Source.AttributeType;
end;

function TXmlAttribute.AsString: String;
begin
  Result := Name;
  if AttributeType = atSingle then
    Exit;
  Result := Result + '="' + Escape(Value) + '"';
end;

constructor TXmlAttribute.Create;
begin
  AttributeType := atSingle;
end;

class function TXmlAttribute.Escape(const Value: String): String;
begin
  Result := ReplaceStr(Value, '&', '&amp;');
  Result := ReplaceStr(Result, '<', '&lt;');
  Result := ReplaceStr(Result, '>', '&gt;');
  Result := ReplaceStr(Result, '"', '&quot;');
end;

procedure TXmlAttribute.SetValue(const Value: String);
begin
  FValue := Value;
  AttributeType := atValue;
end;

{ TXmlStreamReader }

constructor TXmlStreamReader.Create(Stream: TStream; Encoding: TEncoding;
  DetectBOM: Boolean; BufferSize: Integer);
begin
  inherited;
  FBufferedData := TRttiContext.Create.GetType(TStreamReader).GetField('FBufferedData').GetValue(Self).AsObject as TStringBuilder;
  FNoDataInStream := Pointer(NativeInt(Self) + TRttiContext.Create.GetType(TStreamReader).GetField('FNoDataInStream').Offset);
  GetFillBuffer(FFillBuffer);
end;

procedure TXmlStreamReader.FillBuffer;
var
  TempEncoding: TEncoding;
begin
  TempEncoding := CurrentEncoding;
  FFillBuffer(TempEncoding);
  if TempEncoding <> CurrentEncoding then
    TRttiContext.Create.GetType(TStreamReader).GetField('FEncoding').SetValue(Self, TempEncoding)
end;

function TXmlStreamReader.FirstChar: String;
begin
  if PrepareBuffer(1) then
    Result := Self.FBufferedData.Chars[0]
  else
    Result := '';
end;

procedure TXmlStreamReader.IncCharPos(Value: Integer);
begin
  if PrepareBuffer(Value) then
    Self.FBufferedData.Remove(0, Value);
end;

function TXmlStreamReader.IsUppercaseText(const Value: String): Boolean;
var
  ValueLength: Integer;
  Text: String;
begin
  Result := False;
  ValueLength := Length(Value);

  if PrepareBuffer(ValueLength) then
  begin
    Text := Self.FBufferedData.ToString(0, ValueLength);
    if Text = Value then
    begin
      Self.FBufferedData.Remove(0, ValueLength);
      Result := True;
    end;
  end;
end;

function TXmlStreamReader.PrepareBuffer(Value: Integer): Boolean;
begin
  Result := False;

  if Self.FBufferedData = NIL then
    Exit;

  if (Self.FBufferedData.Length < Value) and (not Self.FNoDataInStream^) then
    FillBuffer;

  Result := (Self.FBufferedData.Length >= Value);
end;

function TXmlStreamReader.ReadText(const StopChars: String; Options: TExtractTextOptions): String;
var
  NewLineIndex: Integer;
  PostNewLineIndex: Integer;
  StopChar: Char;
  Found: Boolean;
  TempIndex: Integer;
  StopCharLength: Integer;
  PrevLength: Integer;
begin
  Result := '';
  if Self.FBufferedData = NIL then
    Exit;
  NewLineIndex := 0;
  PostNewLineIndex := 0;
  StopCharLength := Length(StopChars);

  while True do
  begin
    // if we're searching for a string then assure the buffer is wide enough
    if (etoStopString in Options) and (NewLineIndex + StopCharLength > Self.FBufferedData.Length) and
      (not Self.FNoDataInStream^) then
      FillBuffer;

    if NewLineIndex >= Self.FBufferedData.Length then
    begin
      if Self.FNoDataInStream^ then
      begin
        PostNewLineIndex := NewLineIndex;
        Break;
      end
      else
      begin
        PrevLength := FBufferedData.Length;
        FillBuffer;
        // Break if no more data
        if (FBufferedData.Length = 0) or (FBufferedData.Length = PrevLength) then
          Break;
      end;
    end;

    if etoStopString in Options then
    begin
      if NewLineIndex + StopCharLength - 1 < Self.FBufferedData.Length then
      begin
        Found := True;
        TempIndex := NewLineIndex;
        for StopChar in StopChars do
          if Self.FBufferedData[TempIndex] <> StopChar then
          begin
            Found := False;
            Break;
          end
          else
            Inc(TempIndex);

        if Found then
        begin
          if etoDeleteStopChar in Options then
            PostNewLineIndex := NewLineIndex + StopCharLength
          else
            PostNewLineIndex := NewLineIndex;
          Break;
        end;
      end;
    end
    else
    begin
      Found := False;
      for StopChar in StopChars do
        if Self.FBufferedData[NewLineIndex] = StopChar then
        begin
            if etoDeleteStopChar in Options then
              PostNewLineIndex := NewLineIndex + 1
            else
              PostNewLineIndex := NewLineIndex;
          Found := True;
          Break;
        end;
      if Found then
        Break;
    end;

    Inc(NewLineIndex);
  end;

  if NewLineIndex > 0 then
    Result := Self.FBufferedData.ToString(0, NewLineIndex);
  Self.FBufferedData.Remove(0, PostNewLineIndex);
end;


{ TStreamReaderHelper }

procedure TStreamReaderHelper.GetFillBuffer(
  var Method: TStreamReaderFillBuffer);
begin
  TMethod(Method).Code := @TStreamReader.FillBuffer;
  TMethod(Method).Data := Self;
end;

end.
