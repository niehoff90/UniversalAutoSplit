unit UAS_GraphicUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, FPImage;

const
  MAX_COLOR_VALUE = 256;

type
  TSingleColorHistogram = array[0..MAX_COLOR_VALUE - 1] of integer;

  TColorHistogram = record
    PixelCount: integer;
    Red: TSingleColorHistogram;
    Green: TSingleColorHistogram;
    Blue: TSingleColorHistogram;
  end;

function CalculateImageSimilarity(I1, I2: TFPCustomImage): double;

procedure CropImage(const Src: TFPCustomImage; const SrcRect: TRect;
  const Dst: TFPCustomImage);
procedure ScaleImage(const Src: TFPCustomImage; const Dst: TFPCustomImage;
  NewWidth, NewHeight: integer);

implementation

function CalculateImageSimilarity(I1, I2: TFPCustomImage): double;
var
  X, Y, W1, W2, H1, H2: integer;
  Color1, Color2: TFPColor;
  Similarity: int64 = 0;
begin
  W1 := I1.Width;
  W2 := I2.Width;
  H1 := I1.Height;
  H2 := I2.Height;

  for Y := 0 to H1 - 1 do
  begin
    for X := 0 to W1 - 1 do
    begin
      Color1 := I1.Colors[X, Y];
      Color2 := I2.Colors[(X * W2) div W1, (Y * H2) div H1];

      Similarity := Similarity + Abs(Color1.Red - Color2.Red);
      Similarity := Similarity + Abs(Color1.Green - Color2.Green);
      Similarity := Similarity + Abs(Color1.Blue - Color2.Blue);
    end;
  end;

  Result := 1.0 - (Similarity / (I1.Width * I1.Height * 65536 * 3));
end;

procedure CropImage(const Src: TFPCustomImage; const SrcRect: TRect;
  const Dst: TFPCustomImage);
var
  X, Y, SrcX, SrcY: integer;
begin
  // Ziel-Bitmap mit der Größe des Crop-Bereichs erstellen
  Dst.Width := SrcRect.Right - SrcRect.Left;
  Dst.Height := SrcRect.Bottom - SrcRect.Top;

  // Direkten Zugriff auf die Rohdaten für Quell- und Ziel-Bitmap
  for Y := 0 to Dst.Height - 1 do
  begin
    for X := 0 to Dst.Width - 1 do
    begin
      SrcX := SrcRect.Left + X;
      SrcY := SrcRect.Top + Y;

      if (SrcX >= 0) and (SrcY >= 0) and (SrcX < Src.Width) and (SrcY < Src.Height) then
      begin
        Dst.Colors[X, Y] := Src.Colors[SrcX, SrcY];
      end
      else
      begin
        Dst.Colors[X, Y] := FPColor(0, 0, 0, 0);
      end;
    end;
  end;
end;

procedure ScaleImage(const Src: TFPCustomImage; const Dst: TFPCustomImage;
  NewWidth, NewHeight: integer);
var
  X, Y, SrcX, SrcY: integer;
begin
  // Ziel-Bitmap mit der Größe des Scale-Bereichs erstellen
  Dst.Width := NewWidth;
  Dst.Height := NewHeight;

  // Direkten Zugriff auf die Rohdaten für Quell- und Ziel-Bitmap
  for Y := 0 to Dst.Height - 1 do
  begin
    for X := 0 to Dst.Width - 1 do
    begin
      Dst.Colors[X, Y] := Src.Colors[(X * Src.Width) div Dst.Width,(Y * Src.Height) div Dst.Height];
    end;
  end;
end;

end.
