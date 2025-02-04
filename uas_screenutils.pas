unit UAS_ScreenUtils;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF LINUX} // X11-Unterstützung prüfen
  X, XLib,
  {$ELSE}
  Forms, LCLType, LCLIntf, IntfGraphics, UAS_GraphicUtils,
  {$ENDIF}
  Classes, SysUtils, FPImage;

procedure TakeScreenshot(const Image: TFPCustomImage; const Rect: TRect);

implementation

{$IFDEF LINUX} // X11-Unterstützung prüfen

function XDestroyImage(image: PXImage): integer; cdecl; external 'libX11';

procedure TakeScreenshot(const Image: TFPCustomImage; const Rect: TRect);
var
  Display: PDisplay;
  Root: TWindow;
  XImg: PXImage;
  XScreen: integer;
  x, y, ScreenWidth, ScreenHeight: integer;
  LineOffset: PCardinal;
  Pixel: longword;
  ClippedRect: TRect; // Begrenztes Rechteck auf Bildschirmgröße
  OffsetX, OffsetY, CRectWidth, CRectHeight: integer;
begin
  Display := XOpenDisplay(nil);
  if Display = nil then Exit;

  XScreen := DefaultScreen(Display);
  Root := RootWindow(Display, XScreen);

  // Bildschirmgröße abrufen
  ScreenWidth := DisplayWidth(Display, XScreen);
  ScreenHeight := DisplayHeight(Display, XScreen);

  // Begrenzen des Rect-Bereichs auf den Bildschirmbereich
  ClippedRect := Rect;
  if ClippedRect.Left < 0 then ClippedRect.Left := 0;
  if ClippedRect.Top < 0 then ClippedRect.Top := 0;
  if ClippedRect.Right > ScreenWidth then ClippedRect.Right := ScreenWidth;
  if ClippedRect.Bottom > ScreenHeight then ClippedRect.Bottom := ScreenHeight;

  // Nur gültigen Bereich mit Pixeln füllen
  Image.Width := Rect.Right - Rect.Left;
  Image.Height := Rect.Bottom - Rect.Top;
  CRectWidth := ClippedRect.Right - ClippedRect.Left;
  CRectHeight := ClippedRect.Bottom - ClippedRect.Top;
  if (CRectWidth > 0) and (CRectHeight > 0) then
  begin
    XImg := XGetImage(Display, Root, ClippedRect.Left, ClippedRect.Top,
      CRectWidth, CRectHeight, AllPlanes, ZPixmap);
    if XImg <> nil then
    begin
      OffsetX := ClippedRect.Left - Rect.Left;
      OffsetY := ClippedRect.Top - Rect.Top;

      for y := 0 to CRectHeight - 1 do
      begin
        LineOffset := PCardinal(PtrUInt(XImg^.Data) + y * XImg^.bytes_per_line);
        for x := 0 to CRectWidth - 1 do
        begin
          Pixel := LineOffset[x];
          Image.Colors[x + OffsetX, y + OffsetY] := FPColor( // convert FPColor
            (Pixel and $FF0000) shr 8, // red
            (Pixel and $00FF00),       // green
            (Pixel and $0000FF) shl 8, // blue
            65535);                    // alpha
        end;
      end;

      XDestroyImage(XImg);
    end;
  end;

  XCloseDisplay(Display);
end;

{$ELSE}// Standard-Fallback für Windows, macOS

procedure TakeScreenshot(const Image: TFPCustomImage; const Rect: TRect);
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

{$ENDIF}

end.
