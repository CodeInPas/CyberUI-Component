unit CyberTabHeader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberTabHeader }

  TCyberTabHeader = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FTabs: TStringList;
    FTabIndex: Integer;
    FTargetNotebook: TNotebook;
    FOnTabChange: TNotifyEvent;
    FHoverIndex: Integer;

    procedure SetTabs(AValue: TStringList);
    procedure SetTabIndex(AValue: Integer);
    procedure SetTargetNotebook(AValue: TNotebook);
    procedure TabsChanged(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Tabs: TStringList read FTabs write SetTabs;
    property TabIndex: Integer read FTabIndex write SetTabIndex default 0;
    property TargetNotebook: TNotebook read FTargetNotebook write SetTargetNotebook;
    property OnTabChange: TNotifyEvent read FOnTabChange write FOnTabChange;

    property Align;
    property Anchors;
    property Font;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberTabHeader]);
end;

{ TCyberTabHeader }

constructor TCyberTabHeader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 400;
  Height := 35; // Tinggi standar untuk barisan Tab

  FTabs := TStringList.Create;
  FTabs.OnChange := @TabsChanged; // Deteksi jika teks tab diubah di Object Inspector

  // Default Tabs
  FTabs.Add('SYSTEM');
  FTabs.Add('INVENTORY');
  FTabs.Add('DATABASE');

  FTabIndex := 0;
  FHoverIndex := -1;

  FBuffer := TBGRABitmap.Create(Width, Height);

  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

destructor TCyberTabHeader.Destroy;
begin
  FTabs.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberTabHeader.TabsChanged(Sender: TObject);
begin
  if FTabIndex >= FTabs.Count then
    FTabIndex := FTabs.Count - 1;
  if FTabIndex < 0 then FTabIndex := 0;
  Invalidate;
end;

procedure TCyberTabHeader.SetTabs(AValue: TStringList);
begin
  FTabs.Assign(AValue);
  Invalidate;
end;

procedure TCyberTabHeader.SetTabIndex(AValue: Integer);
begin
  if (AValue < 0) or (AValue >= FTabs.Count) then Exit;
  if FTabIndex = AValue then Exit;

  FTabIndex := AValue;

  // Otomatis pindahkan halaman TNotebook jika terhubung!
  if Assigned(FTargetNotebook) then
  begin
    if FTargetNotebook.PageCount > FTabIndex then
      FTargetNotebook.PageIndex := FTabIndex;
  end;

  Invalidate;

  if Assigned(FOnTabChange) then
    FOnTabChange(Self);
end;

procedure TCyberTabHeader.SetTargetNotebook(AValue: TNotebook);
begin
  if FTargetNotebook = AValue then Exit;
  FTargetNotebook := AValue;
  // Sinkronkan indeks awal
  if Assigned(FTargetNotebook) and (FTargetNotebook.PageCount > FTabIndex) then
    FTargetNotebook.PageIndex := FTabIndex;
end;

procedure TCyberTabHeader.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  TabWidth, NewHover: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if FTabs.Count = 0 then Exit;

  TabWidth := Width div FTabs.Count;
  NewHover := X div TabWidth;

  if NewHover >= FTabs.Count then NewHover := FTabs.Count - 1;

  if FHoverIndex <> NewHover then
  begin
    FHoverIndex := NewHover;
    Invalidate;
  end;
end;

procedure TCyberTabHeader.MouseLeave;
begin
  inherited MouseLeave;
  FHoverIndex := -1;
  Invalidate;
end;

procedure TCyberTabHeader.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  TabWidth, ClickedIndex: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and (FTabs.Count > 0) then
  begin
    TabWidth := Width div FTabs.Count;
    ClickedIndex := X div TabWidth;
    if ClickedIndex >= FTabs.Count then ClickedIndex := FTabs.Count - 1;

    TabIndex := ClickedIndex; // Ini akan memicu SetTabIndex dan mengganti halaman Notebook
  end;
end;

procedure TCyberTabHeader.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberTabHeader.Paint;
var
  i: Integer;
  TabWidth, StartX, EndX: Integer;
  Pts: array[0..3] of TPointF;
  NeonColor, TxtColor: TBGRAPixel;
  IsActive, IsHovered: Boolean;
  Chamfer: Single;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  TextY: Integer;
begin
  // 1. Latar Belakang Dasar
  FBuffer.Fill(CyberThemeData.BgDark);

  if FTabs.Count = 0 then
  begin
    FBuffer.Draw(Canvas, 0, 0, True);
    Exit;
  end;

  TabWidth := Width div FTabs.Count;
  Chamfer := 10.0; // Kemiringan sudut tab ala Sci-Fi
  NeonColor := CyberThemeData.PrimaryNeon;

  // 2. Gambar Garis Dasar (Baseline) Neon
  // Garis ini akan membentang di bawah, tapi "terputus" di area tab yang sedang aktif
  FBuffer.DrawLineAntialias(0, Height - 1, Width, Height - 1, NeonColor, 2.0);

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  // 3. Render Setiap Tab
  for i := 0 to FTabs.Count - 1 do
  begin
    IsActive := (i = FTabIndex);
    IsHovered := (i = FHoverIndex);

    StartX := i * TabWidth;
    EndX := StartX + TabWidth;

    // Bentuk Poligon Trapesium untuk Tab
    Pts[0] := PointF(StartX, Height - 1);           // Kiri bawah
    Pts[1] := PointF(StartX + Chamfer, 2);          // Kiri atas (miring)
    Pts[2] := PointF(EndX - Chamfer - 2, 2);        // Kanan atas
    Pts[3] := PointF(EndX - 2, Height - 1);         // Kanan bawah (miring)

    if IsActive then
    begin
      // A. Tab Aktif

      // Isi warna neon transparan
      NeonColor.alpha := 60;
      FBuffer.FillPolyAntialias(Pts, NeonColor);

      // Garis border tab (atas, kiri, kanan) bersinar
      NeonColor.alpha := 255;
      FBuffer.DrawPolyLineAntialias(Pts, NeonColor, 2.0, False);

      // Trik: Timpa garis bawah dengan warna background agar menyatu dengan Notebook di bawahnya
      FBuffer.DrawLineAntialias(StartX + 1, Height - 1, EndX - 3, Height - 1, CyberThemeData.BgDark, 3.0);

      TxtColor := CyberThemeData.TextHighlight;
    end
    else
    begin
      // B. Tab Tidak Aktif
      if IsHovered then
      begin
        NeonColor.alpha := 20;
        FBuffer.FillPolyAntialias(Pts, NeonColor);
        TxtColor := CyberThemeData.TextHighlight;
      end
      else
        TxtColor := CyberThemeData.TextNormal;

      // Garis redup
      FBuffer.DrawPolyLineAntialias(Pts, CyberThemeData.BgLighter, 1.0, False);
    end;

    // 4. Render Teks Tab
    // PERBAIKAN ERROR: Hitung posisi Y manual agar tepat di tengah vertikal
    TextY := (Height - FBuffer.TextSize(FTabs[i]).cy) div 2;

    // Gambar teks dengan 5 argumen saja (hapus tlCenter)
    FBuffer.TextOut(StartX + (TabWidth div 2), TextY, FTabs[i], TxtColor, taCenter);
  end;

  // 5. Proyeksikan
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
