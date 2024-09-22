unit UAS_SplitterLogic;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, INIFiles, FPImage, MouseAndKeyInput, LCLType, UAS_GraphicUtils;

type

  { TSplitElement }

  TSplitElement = class
  private
    FTitle: string;
    FImage: TFPCustomImage;
    FSimilarity: double;
    FKeyInput: word;
    FWaitMillis: integer;
  public
    constructor Create(imagefilename: string);
    destructor Destroy; override;

    function CalculateSimilarity(Frame: TFPCustomImage): double;

    property Title: string read FTitle write FTitle;
    property Similarity: double read FSimilarity write FSimilarity;
    property KeyInput: word read FKeyInput write FKeyInput;
    property WaitMillis: integer read FWaitMillis write FWaitMillis;
  end;

  { TSplitter }

  TSplitter = class
  private
    FElements: array of TSplitElement;
    FElementCount, FCurrentElement: integer;
    FElementSetTime: int64;
    FLogFolder: string;

    function GetCurrentElement: TSplitElement;
  public
    constructor Create(inifilename: string);
    destructor Destroy; override;

    procedure SetCurrentElement(CurrentElement: integer);
    function Process(Frame: TFPCustomImage): double;

    property CurrentElement: TSplitElement read GetCurrentElement;
    property ElementCount: integer read FElementCount;
  end;

implementation

{ TSplitElement }

constructor TSplitElement.Create(imagefilename: string);
begin
  FImage := TFPMemoryImage.Create(0, 0);
  FImage.LoadFromFile(imagefilename);
end;

destructor TSplitElement.Destroy;
begin
  FImage.Free;

  inherited Destroy;
end;

function TSplitElement.CalculateSimilarity(Frame: TFPCustomImage): double;
begin
  if Frame.Width * Frame.Height < FImage.Width * FImage.Height then
  begin
    Result := CalculateImageSimilarity(Frame, FImage);
  end
  else
  begin
    Result := CalculateImageSimilarity(FImage, Frame);
  end;
end;

{ TSplitter }

function TSplitter.GetCurrentElement: TSplitElement;
begin
  Result := FElements[FCurrentElement];
end;

constructor TSplitter.Create(inifilename: string);
var
  iniFile: TINIFile;
  CurrentIniSection: string;
begin
  FElementCount := 0;
  SetLength(FElements, FElementCount);

  FCurrentElement := 0;
  FElementSetTime := GetTickCount64;

  iniFile := TINIFile.Create(inifilename);
  FLogFolder := iniFile.ReadString('global', 'logs', '');
  if FLogFolder <> '' then
  begin
    FLogFolder := IncludeTrailingPathDelimiter(FLogFolder);
    ForceDirectories(FLogFolder);
  end;

  CurrentIniSection := 'split' + IntToStr(FElementCount);
  while iniFile.SectionExists(CurrentIniSection) do
  begin
    SetLength(FElements, FElementCount + 1);
    FElements[FElementCount] :=
      TSplitElement.Create(iniFile.ReadString(CurrentIniSection, 'image', ''));
    FElements[FElementCount].Title :=
      iniFile.ReadString(CurrentIniSection, 'title', CurrentIniSection);
    FElements[FElementCount].Similarity :=
      iniFile.ReadFloat(CurrentIniSection, 'similarity', 0.95);
    FElements[FElementCount].KeyInput :=
      iniFile.ReadInteger(CurrentIniSection, 'keyinput', 0);
    FElements[FElementCount].WaitMillis :=
      iniFile.ReadInteger(CurrentIniSection, 'waitmillis', 0);

    Inc(FElementCount);
    CurrentIniSection := 'split' + IntToStr(FElementCount);
  end;

  iniFile.Free;
end;

destructor TSplitter.Destroy;
var
  i: integer;
begin
  for i := 0 to FElementCount - 1 do
  begin
    FElements[i].Free;
  end;

  inherited Destroy;
end;

procedure TSplitter.SetCurrentElement(CurrentElement: integer);
begin
  if (CurrentElement >= 0) and (CurrentElement < FElementCount) then
  begin
    FCurrentElement := CurrentElement;
    FElementSetTime := GetTickCount64;
  end;
end;

function TSplitter.Process(Frame: TFPCustomImage): double;
var
  Element: TSplitElement;
  Similarity: double;
  LogImg: TFPCustomImage;
begin
  Element := FElements[FCurrentElement];
  if Element.WaitMillis >= GetTickCount64 - FElementSetTime then
  begin
    Exit(0.0);
  end;

  Similarity := Element.CalculateSimilarity(Frame);
  if Similarity < Element.Similarity then
  begin
    Exit(Similarity);
  end;

  if FLogFolder <> '' then
  begin
    LogImg := TFPMemoryImage.Create(160, 120);
    ScaleImage(Frame, LogImg, LogImg.Width, LogImg.Height);
    LogImg.SaveToFile(FLogFolder + FormatDateTime('YY-MM-DD_hh-nn-ss_', Now) +
      FloatToStrF(Similarity, ffFixed, 0, 5) + '_' + Element.Title + '.png');
  end;

  if Element.KeyInput > 0 then
  begin
    KeyInput.Press(Element.KeyInput);
  end;

  if FCurrentElement + 1 >= FElementCount then
  begin
    FCurrentElement := 0;
    FElementSetTime := GetTickCount64;
    Exit(Similarity);
  end;

  Inc(FCurrentElement);
  FElementSetTime := GetTickCount64;
  Exit(Similarity);
end;

end.
