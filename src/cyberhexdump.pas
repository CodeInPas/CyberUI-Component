unit CyberHexDump;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  TCyberHexDump = class(TCustomControl)
  private
    FBuffer: TBGRABitmap;
    FTimer: TTimer;
    FIsStreaming: Boolean;
    FHexLines: array of string;
    FScanlineY: Integer;

    procedure SetIsStreaming(AValue: Boolean);
    procedure OnStreamTimer(Sender: TObject);
    function GenerateHexRow(out AddrStr, DataStr: string): Boolean;
    procedure RebuildLineArray;
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property IsStreaming: Boolean read FIsStreaming write SetIsStreaming default True;
    property Align;
    property Anchors;
    property Font;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberHexDump]);
end;

{ TCyberHexDump }

constructor TCyberHexDump.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 350;
  Height := 200;
  FIsStreaming := True;
  FScanlineY := 0;

  FBuffer := TBGRABitmap.Create(Width, Height);

  // Wajib menggunakan font Monospace agar kolom matriks sejajar sempurna
  Font.Name := 'Courier New';
  Font.Size := 9;
  Font.Style := [fsBold];

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 50; // Bergulir sangat cepat (20 Baris per detik)
  FTimer.OnTimer := @OnStreamTimer;
  FTimer.Enabled := FIsStreaming;
end;

destructor TCyberHexDump.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberHexDump.RebuildLineArray;
var
  MaxLines, i: Integer;
  Dum1, Dum2: string;
begin
  if not Assigned(FBuffer) or (Height <= 0) then Exit;

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);

  // Hitung berapa baris yang muat di dalam layar komponen
  MaxLines := (Height div (FBuffer.FontHeight + 2)) + 1;
  SetLength(FHexLines, MaxLines);

  for i := 0 to High(FHexLines) do
  begin
    GenerateHexRow(Dum1, Dum2);
    FHexLines[i] := Dum1 + '|' + Dum2; // Gunakan separator '|' untuk memisahkan Alamat dan Data
  end;
end;

procedure TCyberHexDump.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    RebuildLineArray;
    Invalidate;
  end;
end;

procedure TCyberHexDump.SetIsStreaming(AValue: Boolean);
begin
  if FIsStreaming = AValue then Exit;
  FIsStreaming := AValue;
  FTimer.Enabled := FIsStreaming;
  Invalidate;
end;

function TCyberHexDump.GenerateHexRow(out AddrStr, DataStr: string): Boolean;
var
  i: Integer;
begin
  // Alamat Memori Palsu (Misal: 0x00F8A2B)
  AddrStr := '0x' + IntToHex(Random($FFFFFF), 7) + '  ';

  DataStr := '';
  // Hasilkan 8 pasangan blok Hex (Misal: 4F A2 00 1C ...)
  for i := 1 to 8 do
    DataStr := DataStr + IntToHex(Random(256), 2) + ' ';

  Result := True;
end;

procedure TCyberHexDump.OnStreamTimer(Sender: TObject);
var
  i: Integer;
  NewAddr, NewData: string;
begin
  if Length(FHexLines) = 0 then Exit;

  // Efek Gulir ke Bawah (Scrolling Down)
  // Geser semua elemen array ke indeks yang lebih tinggi
  for i := High(FHexLines) downto 1 do
    FHexLines[i] := FHexLines[i - 1];

  // Sisipkan baris data baru di paling atas [0]
  GenerateHexRow(NewAddr, NewData);
  FHexLines[0] := NewAddr + '|' + NewData;

  // Gerakkan efek Scanline TV Tabung ke bawah
  FScanlineY := FScanlineY + 4;
  if FScanlineY > Height then FScanlineY := -20;

  Invalidate;
end;

procedure TCyberHexDump.Paint;
var
  i: Integer;
  YPos, AddrWidth: Integer;
  AddrStr, DataStr: string;
  SeparatorPos: Integer;
  ScanColor, BgColor: TBGRAPixel;
begin
  // 1. Latar Belakang Hitam Pekat ala Terminal
  BgColor := CyberThemeData.BgDark;
  FBuffer.Fill(BgColor);

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  YPos := 2;

  // 2. Render Baris Data Memori
  for i := 0 to High(FHexLines) do
  begin
    SeparatorPos := Pos('|', FHexLines[i]);
    if SeparatorPos > 0 then
    begin
      AddrStr := Copy(FHexLines[i], 1, SeparatorPos - 1);
      DataStr := Copy(FHexLines[i], SeparatorPos + 1, Length(FHexLines[i]));

      // Hitung lebar teks alamat agar teks data bisa disebelahnya secara persis
      AddrWidth := FBuffer.TextSize(AddrStr).cx;

      // HELPER ANTI-GAGAL: Cetak Teks dengan 5 Parameter (Tanpa TTextLayout)
      // Baris Alamat (Warna Redup/Secondary)
      FBuffer.TextOut(5, YPos, AddrStr, CyberThemeData.SecondaryNeon, taLeftJustify);

      // Baris Data Hex (Warna Terang/Primary)
      FBuffer.TextOut(5 + AddrWidth, YPos, DataStr, CyberThemeData.TextHighlight, taLeftJustify);
    end;

    YPos := YPos + FBuffer.FontHeight + 2;
  end;

  // 3. Efek Scanline CRT (Garis-garis horizontal tipis berulang)
  ScanColor := BGRA(0, 0, 0, 100); // Hitam transparan (Alpha 100)
  for i := 0 to (Height div 3) do
  begin
    // Gunakan DrawLineAntialias karena selalu berhasil di sistem Anda
    FBuffer.DrawLineAntialias(0, i * 3, Width, i * 3, ScanColor, 1.0);
  end;

  // 4. Efek Refresh Rate / V-Sync (Balok Cahaya Lebar Bergerak Cepat)
  ScanColor := CyberThemeData.PrimaryNeon;
  ScanColor.alpha := 15; // Sangat transparan agar teks di belakangnya tetap terbaca

  // dmDraw untuk menumpuk (blending) transparansi di atas teks, BUKAN menggantikannya
  // Gunakan dmDrawWithTransparency agar efek blok cahaya tidak menghapus teks di belakangnya
    FBuffer.FillRect(0, FScanlineY, Width, FScanlineY + 20, ScanColor, dmDrawWithTransparency);
  // 5. Bingkai Tipis
  FBuffer.DrawLineAntialias(0, 0, Width, 0, CyberThemeData.SecondaryNeon, 1.0);
  FBuffer.DrawLineAntialias(0, Height-1, Width, Height-1, CyberThemeData.SecondaryNeon, 1.0);

  // 6. Proyeksi Akhir
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
