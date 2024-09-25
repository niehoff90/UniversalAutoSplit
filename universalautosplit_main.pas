unit UniversalAutoSplit_Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Interfaces,
  LCLType, LCLIntf, FPImage, IntfGraphics, Spin, StdCtrls, ComCtrls, GraphType,
  UAS_GraphicUtils, UAS_SplitterLogic;

type

  { TFormMain }

  TFormMain = class(TForm)
    CheckBoxPreview: TCheckBox;
    ImagePreview: TImage;
    LabelInfo: TLabel;
    SpinEditLeft: TSpinEdit;
    SpinEditWidth: TSpinEdit;
    SpinEditHeight: TSpinEdit;
    SpinEditTop: TSpinEdit;
    TimerScreenshot: TTimer;
    UpDownSplitter: TUpDown;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerScreenshotTimer(Sender: TObject);
    procedure UpDownSplitterClick(Sender: TObject; Button: TUDBtnType);
  private
    Splitter: TSplitter;

    procedure TakeScreenshot(const Image: TFPCustomImage; const Rect: TRect);
    function NewImage: TLazIntfImage;
  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.TimerScreenshotTimer(Sender: TObject);
var
  Screenshot, Preview: TLazIntfImage;
  Rect: TRect;
  startTime: cardinal;
  cd: double;
begin
  startTime := GetTickCount;

  Rect.Left := SpinEditLeft.Value;
  Rect.Top := SpinEditTop.Value;
  Rect.Right := SpinEditWidth.Value + Rect.Left;
  Rect.Bottom := SpinEditHeight.Value + Rect.Top;

  Screenshot := NewImage;
  TakeScreenshot(Screenshot, Rect);

  if CheckBoxPreview.Checked then
  begin
    Preview := NewImage;
    ScaleImage(Screenshot, Preview, ImagePreview.Width, ImagePreview.Height);
    ImagePreview.Picture.Bitmap.LoadFromIntfImage(Preview);
    Preview.Free;
  end;

  LabelInfo.Caption := FloatToStrF(Splitter.Process(Screenshot), ffFixed, 0, 3);
  LabelInfo.Caption := LabelInfo.Caption + ' / ' +
    IntToStr(GetTickCount - startTime) + 'ms';
  LabelInfo.Caption := LabelInfo.Caption + ' / ' + Splitter.CurrentElement.Title;

  Screenshot.Free;
  Application.ProcessMessages;
end;

procedure TFormMain.UpDownSplitterClick(Sender: TObject; Button: TUDBtnType);
begin
  Splitter.SetCurrentElement(UpDownSplitter.Position);
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  TimerScreenshot.Enabled := True;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Splitter := TSplitter.Create('UniversalAutoSplit.ini');
  UpDownSplitter.Max := Splitter.ElementCount - 1;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Splitter.Free;
end;

procedure TFormMain.TakeScreenshot(const Image: TFPCustomImage; const Rect: TRect);
var
  ScreenDC: HDC;
  FullScreenshot: TLazIntfImage;
begin
  FullScreenshot := TLazIntfImage.Create(Screen.Width, Screen.Height);

  ScreenDC := GetDC(0);
  FullScreenshot.LoadFromDevice(ScreenDC);
  ReleaseDC(0, ScreenDC);

  Image.Width := Rect.Right - Rect.Left;
  Image.Height := Rect.Bottom - Rect.Top;
  CropImage(FullScreenshot, Rect, Image);
  FullScreenshot.Free;
end;

function TFormMain.NewImage: TLazIntfImage;
var
  RawImage: TRawImage;
begin
  // create a TLazIntfImage with 32 bits per pixel, alpha 8bit, red 8 bit, green 8bit, blue 8bit,
  // Bits In Order: bit 0 is pixel 0, Top To Bottom: line 0 is top
  RawImage.Init;
  RawImage.Description.Init_BPP32_A8R8G8B8_BIO_TTB(0, 0);
  RawImage.CreateData(False);
  Result := TLazIntfImage.Create(0, 0);
  Result.SetRawImage(RawImage);
end;

end.
