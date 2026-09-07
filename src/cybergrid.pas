unit CyberGrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Grids, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberGrid }

  TCyberGrid = class(TStringGrid)
  private
    FHoverCol, FHoverRow: Integer;
    procedure SetHoverCell(ACol, ARow: Integer);
  protected
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    // Membajak proses penggambaran sel
    procedure DrawCell(ACol, ARow: Integer; ARect: TRect; AState: TGridDrawState); override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberGrid]);
end;

{ TCyberGrid }

constructor TCyberGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;

  // Reset hover state
  FHoverCol := -1;
  FHoverRow := -1;

  // Pengaturan default TStringGrid agar siap di-kustomisasi
  BorderStyle := bsNone; // Hilangkan border luar 3D bawaan Windows
  Color := clBlack;
  FixedColor := clBlack;

  // Nonaktifkan garis bawaan dan fokus putus-putus
  Options := Options - [goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected]
                     + [goRowSelect, goSmoothScroll];

  // Font bergaya terminal
  Font.Name := 'Courier New';
  Font.Size := 9;
  Font.Color := clWhite;
end;

procedure TCyberGrid.SetHoverCell(ACol, ARow: Integer);
begin
  if (FHoverCol = ACol) and (FHoverRow = ARow) then Exit;

  // Trik Optimasi: Jangan gunakan Invalidate; (redraw seluruh grid) karena akan sangat berat.
  // Gunakan InvalidateCell bawaan LCL agar hanya merender ulang sel yang berubah.
  if (FHoverCol >= 0) and (FHoverRow >= 0) then
    InvalidateCell(FHoverCol, FHoverRow); // Hapus efek hover dari sel lama

  FHoverCol := ACol;
  FHoverRow := ARow;

  if (FHoverCol >= 0) and (FHoverRow >= 0) then
    InvalidateCell(FHoverCol, FHoverRow); // Gambar efek hover di sel baru
end;

procedure TCyberGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  C, R: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  // Konversi koordinat mouse (X,Y) ke indeks Kolom dan Baris
  MouseToCell(X, Y, C, R);
  SetHoverCell(C, R);
end;

procedure TCyberGrid.MouseLeave;
begin
  inherited MouseLeave;
  SetHoverCell(-1, -1); // Matikan efek hover saat mouse keluar dari area grid
end;

procedure TCyberGrid.DrawCell(ACol, ARow: Integer; ARect: TRect; AState: TGridDrawState);
var
  CellBmp: TBGRABitmap;
  W, H: Integer;
  NeonColor, BgColor, TxtColor: TBGRAPixel;
  IsHovered, IsSelected, IsFixed: Boolean;
  CellText: string;

  // Variabel baru untuk perbaikan Error
  Pts: array[0..3] of TPointF;
  TextY: Integer;
begin
  W := ARect.Width;
  H := ARect.Height;
  if (W <= 0) or (H <= 0) then Exit;

  CellBmp := TBGRABitmap.Create(W, H);
  try
    IsHovered := (ACol = FHoverCol) and (ARow = FHoverRow);
    IsSelected := gdSelected in AState;
    IsFixed := gdFixed in AState;

    // 1. Ambil warna global dari CyberTheme
    NeonColor := CyberThemeData.PrimaryNeon;
    TxtColor := CyberThemeData.TextNormal;

    // 2. Tentukan logika warna berdasarkan State
    if IsFixed then
    begin
      BgColor := CyberThemeData.BgLighter;
      TxtColor := CyberThemeData.SecondaryNeon;
    end
    else if IsSelected then
    begin
      BgColor := NeonColor;
      BgColor.alpha := 60;
      TxtColor := CyberThemeData.TextHighlight;
    end
    else if IsHovered then
    begin
      BgColor := NeonColor;
      BgColor.alpha := 20;
      TxtColor := CyberThemeData.TextHighlight;
    end
    else
      BgColor := CyberThemeData.BgDark;

    // 3. Gambar Latar Belakang Sel
    CellBmp.Fill(BgColor);

    // 4. Gambar Elemen Tactical HUD (Border Custom)
    if IsFixed then
    begin
      CellBmp.DrawLineAntialias(0, H - 1, W, H - 1, CyberThemeData.SecondaryNeon, 1.5);
    end
    else
    begin
      CellBmp.DrawLineAntialias(0, H - 1, W, H - 1, CyberThemeData.BgLighter, 1);
      CellBmp.DrawLineAntialias(W - 1, 0, W - 1, H, CyberThemeData.BgLighter, 1);

      if IsSelected or IsHovered then
      begin
        // PERBAIKAN ERROR 1: Gunakan DrawPolyLineAntialias sebagai pengganti DrawRectAntialias
        Pts[0] := PointF(0, 0);
        Pts[1] := PointF(W - 1, 0);
        Pts[2] := PointF(W - 1, H - 1);
        Pts[3] := PointF(0, H - 1);
        CellBmp.DrawPolyLineAntialias(Pts, NeonColor, 2.0, True); // True = Poligon tertutup

        // Aksen HUD: Tambahkan kotak kecil/titik menyala di 4 sudut sel
        CellBmp.FillRect(0, 0, 3, 3, CyberThemeData.TextHighlight);
        CellBmp.FillRect(W-3, 0, W, 3, CyberThemeData.TextHighlight);
        CellBmp.FillRect(0, H-3, 3, H, CyberThemeData.TextHighlight);
        CellBmp.FillRect(W-3, H-3, W, H, CyberThemeData.TextHighlight);
      end;
    end;

    // 5. Render Teks / Data Sel
    CellText := Cells[ACol, ARow];
    if CellText <> '' then
    begin
      CellBmp.FontName := Font.Name;
      CellBmp.FontHeight := Abs(Font.Height);
      CellBmp.FontStyle := Font.Style;

      // PERBAIKAN ERROR 2: Hitung posisi Y manual tanpa tlCenter
      TextY := (H - CellBmp.TextSize(CellText).cy) div 2;

      // Margin kiri 5 pixel
      CellBmp.TextOut(5, TextY, CellText, TxtColor, taLeftJustify);
    end;

    // 6. Proyeksikan ke Canvas Utama LCL
    CellBmp.Draw(Canvas, ARect.Left, ARect.Top, True);
  finally
    CellBmp.Free;
  end;
end;

end.
