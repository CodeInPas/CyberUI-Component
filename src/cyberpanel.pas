unit CyberPanel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberPanel }

  TCyberPanel = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FCaption: string;
    procedure SetCaption(AValue: string);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Caption: string read FCaption write SetCaption;

    // Properti standar untuk kontainer
    property Align;
    property Anchors;
    property BorderSpacing;
    property Font;
    property Visible;
    property Enabled;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberPanel]);
end;

{ TCyberPanel }

constructor TCyberPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // csAcceptsControls sangat krusial agar panel ini bisa menjadi induk (Parent) bagi komponen lain
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls];
  DoubleBuffered := True;

  Width := 300;
  Height := 200;
  FCaption := 'SYS_PANEL';

  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

destructor TCyberPanel.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberPanel.SetCaption(AValue: string);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  Invalidate;
end;

procedure TCyberPanel.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberPanel.Paint;
var
  Pts: array[0..5] of TPointF;
  CutSize: Single;
  NeonColor, BgColor: TBGRAPixel;
  TextSz: TSize;
  HeaderRect: TRect;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  PtsRect: array[0..3] of TPointF;
begin
  // 1. Ambil warna dari Theme Manager
  BgColor := CyberThemeData.BgLighter;
  NeonColor := CyberThemeData.PrimaryNeon;

  // 2. Bersihkan latar belakang
  FBuffer.Fill(CyberThemeData.BgDark);

  CutSize := 20.0; // Ukuran potongan sudut chamfer

  // 3. Tentukan Geometri Segi Enam (Kiri Atas & Kanan Bawah terpotong)
  Pts[0] := PointF(CutSize, 0);
  Pts[1] := PointF(Width - 1, 0);
  Pts[2] := PointF(Width - 1, Height - 1 - CutSize);
  Pts[3] := PointF(Width - 1 - CutSize, Height - 1);
  Pts[4] := PointF(0, Height - 1);
  Pts[5] := PointF(0, CutSize);

  // 4. Isi warna panel
  BgColor.alpha := 240;
  FBuffer.FillPolyAntialias(Pts, BgColor);

  // 5. Gambar border utama
  NeonColor.alpha := 150;
  FBuffer.DrawPolyLineAntialias(Pts, NeonColor, 2.0, True);

  NeonColor.alpha := 255;
  FBuffer.DrawPolyLineAntialias(Pts, NeonColor, 1.0, True);

  // 6. Aksen HUD / Dekorasi Pinggiran
  FBuffer.DrawLineAntialias(Width - 5, 5, Width - 15, 5, CyberThemeData.SecondaryNeon, 2.0);
  FBuffer.DrawLineAntialias(Width - 5, 9, Width - 10, 9, CyberThemeData.SecondaryNeon, 2.0);
  FBuffer.DrawLineAntialias(Width - 5, 13, Width - 8, 13, CyberThemeData.SecondaryNeon, 2.0);

  FBuffer.FillRect(5, Height - 10, 10, Height - 5, CyberThemeData.SecondaryNeon, dmSet);
  FBuffer.FillRect(12, Height - 10, 17, Height - 5, CyberThemeData.TextNormal, dmSet);
  FBuffer.FillRect(19, Height - 10, 24, Height - 5, CyberThemeData.SecondaryNeon, dmSet);

  // 7. Render Caption (Jika ada teksnya)
  if FCaption <> '' then
  begin
    FBuffer.FontName := Font.Name;
    FBuffer.FontHeight := Abs(Font.Height);
    FBuffer.FontStyle := Font.Style;

    TextSz := FBuffer.TextSize(FCaption);

    HeaderRect := Rect(Round(CutSize) + 5, 0, Round(CutSize) + TextSz.cx + 25, TextSz.cy + 6);
    FBuffer.FillRect(HeaderRect.Left, HeaderRect.Top, HeaderRect.Right, HeaderRect.Bottom, NeonColor, dmSet);

    // PERBAIKAN ERROR 1: Hapus argumen tlTop, gunakan 5 argumen saja
    FBuffer.TextOut(HeaderRect.Left + 10, HeaderRect.Top + 3, FCaption,
                    CyberThemeData.BgDark, taLeftJustify);

    FBuffer.DrawLineAntialias(HeaderRect.Right, 0, HeaderRect.Right + 10, HeaderRect.Bottom, NeonColor, 2.0);
    FBuffer.DrawLineAntialias(HeaderRect.Right, HeaderRect.Bottom, HeaderRect.Left, HeaderRect.Bottom, NeonColor, 1.5);
  end;

  // 8. Mode Desain: Gambar grid panduan samar
  if csDesigning in ComponentState then
  begin
    // PERBAIKAN ERROR 2: Gunakan DrawPolyLineAntialias untuk menggambar kotak
    PtsRect[0] := PointF(10, 10);
    PtsRect[1] := PointF(Width - 10, 10);
    PtsRect[2] := PointF(Width - 10, Height - 10);
    PtsRect[3] := PointF(10, Height - 10);
    FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.TextNormal, 1.0, True);
  end;

  // 9. Proyeksikan ke Canvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
