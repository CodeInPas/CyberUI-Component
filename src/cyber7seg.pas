unit Cyber7Seg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyber7Seg }

  TCyber7Seg = class(TGraphicControl)
  private
    FBuffer: TBGRABitmap;
    FText: string;
    FDigitWidth: Integer;
    FDigitSpacing: Integer;
    FThickness: Single;

    procedure SetText(AValue: string);
    procedure SetDigitWidth(AValue: Integer);
    procedure SetDigitSpacing(AValue: Integer);
    procedure SetThickness(AValue: Single);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure DrawDigit(AX, AY, AWidth, AHeight: Single; AChar: Char; ANeonColor: TBGRAPixel);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Text: string read FText write SetText; // Contoh: "06:13"
    property DigitWidth: Integer read FDigitWidth write SetDigitWidth default 24;
    property DigitSpacing: Integer read FDigitSpacing write SetDigitSpacing default 8;
    property Thickness: Single read FThickness write SetThickness default 4.0;

    property Align;
    property Anchors;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyber7Seg]);
end;

{ TCyber7Seg }

constructor TCyber7Seg.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 50;
  FText := '06:13';
  FDigitWidth := 24;
  FDigitSpacing := 8;
  FThickness := 4.0;
  FBuffer := TBGRABitmap.Create(Width, Height);
end;

destructor TCyber7Seg.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyber7Seg.SetText(AValue: string);
begin
  if FText = AValue then Exit;
  FText := AValue;
  Invalidate;
end;

procedure TCyber7Seg.SetDigitWidth(AValue: Integer);
begin
  if FDigitWidth = AValue then Exit;
  FDigitWidth := AValue;
  Invalidate;
end;

procedure TCyber7Seg.SetDigitSpacing(AValue: Integer);
begin
  if FDigitSpacing = AValue then Exit;
  FDigitSpacing := AValue;
  Invalidate;
end;

procedure TCyber7Seg.SetThickness(AValue: Single);
begin
  if FThickness = AValue then Exit;
  FThickness := AValue;
  Invalidate;
end;

procedure TCyber7Seg.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyber7Seg.DrawDigit(AX, AY, AWidth, AHeight: Single; AChar: Char; ANeonColor: TBGRAPixel);
const
  // Peta Segmen: A(Top), B(TopRight), C(BotRight), D(Bottom), E(BotLeft), F(TopLeft), G(Middle)
  SegMap: array['0'..'9'] of Byte = (
    %01111110, // 0: A,B,C,D,E,F
    %00110000, // 1: B,C
    %01101101, // 2: A,B,D,E,G
    %01111001, // 3: A,B,C,D,G
    %00110011, // 4: B,C,F,G
    %01011011, // 5: A,C,D,F,G
    %01011111, // 6: A,C,D,E,F,G
    %01110000, // 7: A,B,C
    %01111111, // 8: A,B,C,D,E,F,G
    %01111011  // 9: A,B,C,D,F,G
  );
var
  i: Integer;
  IsOn: Boolean;
  P1, P2: TPointF;
  MapVal: Byte;
  DrawColor, GhostColor: TBGRAPixel;
  Gap: Single;

  // PERBAIKAN 2: Fungsi Helper Lokal untuk Menggambar Lingkaran (Glow Titik Dua)
  procedure DrawCustomCircle(Center_X, Center_Y, Rad: Single; Clr: TBGRAPixel; LineThick: Single);
  var
    j: Integer;
    CircPts: array[0..36] of TPointF;
  begin
    for j := 0 to 36 do
    begin
      CircPts[j] := PointF(Center_X + (Rad * Cos(DegToRad(j * 10))),
                           Center_Y + (Rad * Sin(DegToRad(j * 10))));
    end;
    FBuffer.DrawPolyLineAntialias(CircPts, Clr, LineThick, True);
  end;

begin
  // PERBAIKAN 1: Kalkulasi manual BlendPixel untuk GhostColor (Bobot 30/255)
  GhostColor.red := (CyberThemeData.BgDark.red * (255 - 30) + ANeonColor.red * 30) div 255;
  GhostColor.green := (CyberThemeData.BgDark.green * (255 - 30) + ANeonColor.green * 30) div 255;
  GhostColor.blue := (CyberThemeData.BgDark.blue * (255 - 30) + ANeonColor.blue * 30) div 255;
  GhostColor.alpha := 255;

  Gap := FThickness / 2; // Celah antar segmen agar tidak menempel

  // Khusus untuk karakter titik dua ':'
  if AChar = ':' then
  begin
    FBuffer.FillEllipseAntialias(AX + AWidth/2, AY + AHeight*0.3, FThickness, FThickness, ANeonColor);
    FBuffer.FillEllipseAntialias(AX + AWidth/2, AY + AHeight*0.7, FThickness, FThickness, ANeonColor);

    // Glow titik dua menggunakan helper manual
    ANeonColor.alpha := 80;
    DrawCustomCircle(AX + AWidth/2, AY + AHeight*0.3, FThickness+2, ANeonColor, 3);
    DrawCustomCircle(AX + AWidth/2, AY + AHeight*0.7, FThickness+2, ANeonColor, 3);
    Exit;
  end;

  if (AChar >= '0') and (AChar <= '9') then
    MapVal := SegMap[AChar]
  else
    MapVal := 0; // Kosong jika karakter tidak dikenali

  // Gambar 7 Segmen
  for i := 0 to 6 do
  begin
    IsOn := (MapVal and (1 shl (6 - i))) <> 0;

    // Tentukan koordinat tiap segmen
    case i of
      0: begin P1 := PointF(AX + Gap, AY); P2 := PointF(AX + AWidth - Gap, AY); end; // A
      1: begin P1 := PointF(AX + AWidth, AY + Gap); P2 := PointF(AX + AWidth, AY + AHeight/2 - Gap/2); end; // B
      2: begin P1 := PointF(AX + AWidth, AY + AHeight/2 + Gap/2); P2 := PointF(AX + AWidth, AY + AHeight - Gap); end; // C
      3: begin P1 := PointF(AX + Gap, AY + AHeight); P2 := PointF(AX + AWidth - Gap, AY + AHeight); end; // D
      4: begin P1 := PointF(AX, AY + AHeight/2 + Gap/2); P2 := PointF(AX, AY + AHeight - Gap); end; // E
      5: begin P1 := PointF(AX, AY + Gap); P2 := PointF(AX, AY + AHeight/2 - Gap/2); end; // F
      6: begin P1 := PointF(AX + Gap, AY + AHeight/2); P2 := PointF(AX + AWidth - Gap, AY + AHeight/2); end; // G
    end;

    if IsOn then
    begin
      DrawColor := ANeonColor;

      // Outer Glow
      DrawColor.alpha := 80;
      FBuffer.DrawLineAntialias(P1.x, P1.y, P2.x, P2.y, DrawColor, FThickness * 2.5);

      // Solid Core
      DrawColor.alpha := 255;
      FBuffer.DrawLineAntialias(P1.x, P1.y, P2.x, P2.y, DrawColor, FThickness);
    end
    else
    begin
      // Draw Ghosting Segment dengan warna yang telah dikalkulasi
      FBuffer.DrawLineAntialias(P1.x, P1.y, P2.x, P2.y, GhostColor, FThickness);
    end;
  end;
end;

procedure TCyber7Seg.Paint;
var
  i: Integer;
  CurrentX, DrawY, DrawHeight: Single;
  NeonColor: TBGRAPixel;
begin
  FBuffer.Fill(CyberThemeData.BgDark); // Bersihkan background

  // Untuk hijau seperti di foto, gunakan PrimaryNeon,
  // pastikan CyberThemeData diset ke mode ctmMatrixGreen di form Anda.
  NeonColor := CyberThemeData.PrimaryNeon;

  CurrentX := 10;
  DrawY := 10;
  DrawHeight := Height - 20;

  for i := 1 to Length(FText) do
  begin
    DrawDigit(CurrentX, DrawY, FDigitWidth, DrawHeight, FText[i], NeonColor);

    // Titik dua lebih sempit
    if FText[i] = ':' then
      CurrentX := CurrentX + (FDigitWidth / 2) + FDigitSpacing
    else
      CurrentX := CurrentX + FDigitWidth + FDigitSpacing;
  end;

  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
