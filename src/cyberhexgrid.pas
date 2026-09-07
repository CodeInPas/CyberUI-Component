unit CyberHexGrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  // Event khusus saat node hexagon diklik (mengirim kordinat Kolom dan Baris)
  THexNodeEvent = procedure(Sender: TObject; ACol, ARow: Integer) of object;

  TCyberHexGrid = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FHexSize: Integer;
    FColCount: Integer;
    FRowCount: Integer;
    FHoverCol: Integer;
    FHoverRow: Integer;
    FSelectedCol: Integer;
    FSelectedRow: Integer;
    FOnNodeClick: THexNodeEvent;

    procedure SetHexSize(AValue: Integer);
    procedure SetColCount(AValue: Integer);
    procedure SetRowCount(AValue: Integer);
    procedure SetSelectedCol(AValue: Integer);
    procedure SetSelectedRow(AValue: Integer);
    function GetHexCenter(ACol, ARow: Integer): TPointF;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property HexSize: Integer read FHexSize write SetHexSize default 30;
    property ColCount: Integer read FColCount write SetColCount default 5;
    property RowCount: Integer read FRowCount write SetRowCount default 4;
    property SelectedCol: Integer read FSelectedCol write SetSelectedCol default -1;
    property SelectedRow: Integer read FSelectedRow write SetSelectedRow default -1;
    property Align;
    property Anchors;
    property Font;
    property OnNodeClick: THexNodeEvent read FOnNodeClick write FOnNodeClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberHexGrid]);
end;

{ TCyberHexGrid }

constructor TCyberHexGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  DoubleBuffered := True;
  Width := 400;
  Height := 300;
  FHexSize := 30;
  FColCount := 5;
  FRowCount := 4;
  FHoverCol := -1;
  FHoverRow := -1;
  FSelectedCol := -1;
  FSelectedRow := -1;
  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 9;
  Font.Style := [fsBold];
end;

destructor TCyberHexGrid.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberHexGrid.SetHexSize(AValue: Integer);
begin
  if FHexSize = AValue then Exit;
  if AValue < 10 then AValue := 10;
  FHexSize := AValue;
  Invalidate;
end;

procedure TCyberHexGrid.SetColCount(AValue: Integer);
begin
  if FColCount = AValue then Exit;
  if AValue < 1 then AValue := 1;
  FColCount := AValue;
  Invalidate;
end;

procedure TCyberHexGrid.SetRowCount(AValue: Integer);
begin
  if FRowCount = AValue then Exit;
  if AValue < 1 then AValue := 1;
  FRowCount := AValue;
  Invalidate;
end;

procedure TCyberHexGrid.SetSelectedCol(AValue: Integer);
begin
  if FSelectedCol = AValue then Exit;
  FSelectedCol := AValue;
  Invalidate;
end;

procedure TCyberHexGrid.SetSelectedRow(AValue: Integer);
begin
  if FSelectedRow = AValue then Exit;
  FSelectedRow := AValue;
  Invalidate;
end;

procedure TCyberHexGrid.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

function TCyberHexGrid.GetHexCenter(ACol, ARow: Integer): TPointF;
var
  W, H, XOffset, YOffset: Single;
begin
  // Algoritma tata letak "Pointy-Topped Hexagon"
  W := Sqrt(3) * FHexSize;
  H := 2 * FHexSize;

  // Baris ganjil digeser setengah lebar ke kanan
  XOffset := (ACol + 0.5 * (ARow mod 2)) * W;
  YOffset := ARow * (H * 0.75); // Jarak vertikal menjorok ke dalam

  // Margin agar grid rata tengah di area kiri atas
  Result.X := 20 + FHexSize + XOffset;
  Result.Y := 20 + FHexSize + YOffset;
end;

procedure TCyberHexGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  c, r: Integer;
  Pt: TPointF;
  Dist: Single;
  FoundCol, FoundRow: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  FoundCol := -1;
  FoundRow := -1;

  // Pengecekan jarak pointer mouse ke pusat setiap Node (Lingkaran dalam Hexagon)
  for r := 0 to FRowCount - 1 do
  begin
    for c := 0 to FColCount - 1 do
    begin
      Pt := GetHexCenter(c, r);
      Dist := Sqrt(Sqr(X - Pt.X) + Sqr(Y - Pt.Y));
      if Dist < (FHexSize * 0.85) then
      begin
        FoundCol := c;
        FoundRow := r;
        Break; // Ketemu, langsung hentikan loop
      end;
    end;
    if FoundCol <> -1 then Break;
  end;

  if (FHoverCol <> FoundCol) or (FHoverRow <> FoundRow) then
  begin
    FHoverCol := FoundCol;
    FHoverRow := FoundRow;
    Invalidate;
  end;
end;

procedure TCyberHexGrid.MouseLeave;
begin
  inherited MouseLeave;
  if (FHoverCol <> -1) or (FHoverRow <> -1) then
  begin
    FHoverCol := -1;
    FHoverRow := -1;
    Invalidate;
  end;
end;

procedure TCyberHexGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    if (FHoverCol <> -1) and (FHoverRow <> -1) then
    begin
      FSelectedCol := FHoverCol;
      FSelectedRow := FHoverRow;
      // Triger Event jika terhubung ke Engine Logika utama Anda
      if Assigned(FOnNodeClick) then
        FOnNodeClick(Self, FSelectedCol, FSelectedRow);
      Invalidate;
    end;
  end;
end;

procedure TCyberHexGrid.Paint;
var
  r, c: Integer;
  CenterPt, NextPt: TPointF;
  PtsRect: array[0..3] of TPointF;
  NeonColor, NodeColor, FillColor, GlowColor, WireColor: TBGRAPixel;
  IsHover, IsSelect: Boolean;
  NodeText: string;
  TextY: Integer;

  // HELPER ANTI-GAGAL: Menggambar Segi Enam secara manual dengan Sin/Cos
  procedure DrawHexagon(CenterX, CenterY, Size: Single; Clr: TBGRAPixel; LineThick: Single; FillClr: TBGRAPixel; DoFill: Boolean);
  var
    j: Integer;
    HexPts: array[0..5] of TPointF;
    AngleDeg: Single;
  begin
    for j := 0 to 5 do
    begin
      // -30 derajat shift untuk membuat ujung atasnya runcing (Pointy Top)
      AngleDeg := 60 * j - 30;
      HexPts[j] := PointF(CenterX + Size * Cos(DegToRad(AngleDeg)),
                          CenterY + Size * Sin(DegToRad(AngleDeg)));
    end;

    if DoFill then
      FBuffer.FillPolyAntialias(HexPts, FillClr);

    FBuffer.DrawPolyLineAntialias(HexPts, Clr, LineThick, True);
  end;

begin
  // 1. Bersihkan Latar Belakang
  FBuffer.Fill(CyberThemeData.BgDark);

  NeonColor := CyberThemeData.PrimaryNeon;

  // HELPER ANTI-GAGAL: Kalkulasi BlendPixel Manual (Bobot 80/255)
  GlowColor.red := (CyberThemeData.BgDark.red * (255 - 80) + NeonColor.red * 80) div 255;
  GlowColor.green := (CyberThemeData.BgDark.green * (255 - 80) + NeonColor.green * 80) div 255;
  GlowColor.blue := (CyberThemeData.BgDark.blue * (255 - 80) + NeonColor.blue * 80) div 255;
  GlowColor.alpha := 255;

  WireColor := CyberThemeData.BgLighter;
  WireColor.alpha := 100;

  // 2. Gambar Jalur Koneksi Jaringan Latar Belakang (Wireframe)
  for r := 0 to FRowCount - 1 do
  begin
    for c := 0 to FColCount - 1 do
    begin
      CenterPt := GetHexCenter(c, r);

      // Garis menyambung ke Kanan
      if c < FColCount - 1 then
      begin
        NextPt := GetHexCenter(c + 1, r);
        FBuffer.DrawLineAntialias(CenterPt.X, CenterPt.Y, NextPt.X, NextPt.Y, WireColor, 1.0);
      end;

      // Garis menyambung Serong Bawah
      if r < FRowCount - 1 then
      begin
        NextPt := GetHexCenter(c, r + 1);
        FBuffer.DrawLineAntialias(CenterPt.X, CenterPt.Y, NextPt.X, NextPt.Y, WireColor, 1.0);

        if (r mod 2 = 0) and (c > 0) then
        begin
          NextPt := GetHexCenter(c - 1, r + 1);
          FBuffer.DrawLineAntialias(CenterPt.X, CenterPt.Y, NextPt.X, NextPt.Y, WireColor, 1.0);
        end
        else if (r mod 2 <> 0) and (c < FColCount - 1) then
        begin
          NextPt := GetHexCenter(c + 1, r + 1);
          FBuffer.DrawLineAntialias(CenterPt.X, CenterPt.Y, NextPt.X, NextPt.Y, WireColor, 1.0);
        end;
      end;
    end;
  end;

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  // 3. Render Setiap Node Segi Enam
  for r := 0 to FRowCount - 1 do
  begin
    for c := 0 to FColCount - 1 do
    begin
      CenterPt := GetHexCenter(c, r);

      IsHover := (c = FHoverCol) and (r = FHoverRow);
      IsSelect := (c = FSelectedCol) and (r = FSelectedRow);

      if IsSelect then
      begin
        // STATE: Node Dipilih
        FillColor := NeonColor;
        FillColor.alpha := 40;
        DrawHexagon(CenterPt.X, CenterPt.Y, FHexSize, NeonColor, 2.0, FillColor, True);
        DrawHexagon(CenterPt.X, CenterPt.Y, FHexSize + 4, GlowColor, 2.0, FillColor, False); // Glow Outline Luar
        NodeColor := CyberThemeData.TextHighlight;
      end
      else if IsHover then
      begin
        // STATE: Kursor Di Atas Node
        FillColor := GlowColor;
        FillColor.alpha := 30;
        DrawHexagon(CenterPt.X, CenterPt.Y, FHexSize, CyberThemeData.TextHighlight, 1.5, FillColor, True);
        NodeColor := CyberThemeData.TextHighlight;
      end
      else
begin
        // STATE: Standby (Normal)
        DrawHexagon(CenterPt.X, CenterPt.Y, FHexSize, CyberThemeData.SecondaryNeon, 1.0, CyberThemeData.BgDark, True);
        NodeColor := CyberThemeData.TextNormal;
      end;

      // Titik Pusat Node (Inti Data)
      FBuffer.FillRect(Round(CenterPt.X) - 2, Round(CenterPt.Y) - 2,
                       Round(CenterPt.X) + 2, Round(CenterPt.Y) + 2,
                       NodeColor, dmSet);

      // Teks Kordinat Label Node (Misal: 0,1)
      NodeText := IntToStr(c) + ',' + IntToStr(r);

      // HELPER ANTI-GAGAL: Hitung Posisi Y manual tanpa parameter tlCenter
      TextY := Round(CenterPt.Y) - (FBuffer.TextSize(NodeText).cy div 2);

      FBuffer.TextOut(Round(CenterPt.X), TextY + Round(FHexSize * 0.6), NodeText, NodeColor, taCenter);
    end;
  end;

  // 4. Bingkai Luar Komponen (Gunakan PolyLine)
  PtsRect[0] := PointF(0, 0);
  PtsRect[1] := PointF(Width-1, 0);
  PtsRect[2] := PointF(Width-1, Height-1);
  PtsRect[3] := PointF(0, Height-1);
  FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.SecondaryNeon, 1.0, True);

  // 5. Proyeksi ke Canvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
