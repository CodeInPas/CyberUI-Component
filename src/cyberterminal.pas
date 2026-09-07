unit CyberTerminal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, Types,
  BGRABitmap, BGRABitmapTypes, CyberTheme;

type
  { TCyberTerminal }

  TCyberTerminal = class(TCustomControl)
  private
    FLogs: TStringList;
    FAnimTimer: TTimer;
    FBuffer: TBGRABitmap;
    FMaxLines: Integer;
    FPrefixString: string;

    // State Animasi
    FTypingIndex: Integer;
    FCursorVisible: Boolean;
    FBlinkCounter: Integer;

    procedure OnTimerTick(Sender: TObject);
    procedure SetMaxLines(AValue: Integer);
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Perintah utama untuk menambah log baru
    procedure AddLog(const AMessage: string);
    procedure ClearTerminal;
  published
    property MaxLines: Integer read FMaxLines write SetMaxLines default 100;
    property PrefixString: string read FPrefixString write FPrefixString; // misal: "root@sys:~# "

    property Align;
    property Anchors;
    property Font;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CyberUI', [TCyberTerminal]);
end;

{ TCyberTerminal }

constructor TCyberTerminal.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;

  Width := 400;
  Height := 250;

  FMaxLines := 100;
  FPrefixString := '> ';

  FLogs := TStringList.Create;
  FBuffer := TBGRABitmap.Create(Width, Height);

  // Font wajib Monospace untuk terminal
  Font.Name := 'Courier New';
  Font.Size := 10;
  Font.Style := [fsBold];

  // Setup Timer (Kecepatan update 30ms untuk efek mengetik yang cepat)
  FAnimTimer := TTimer.Create(Self);
  FAnimTimer.Interval := 30;
  FAnimTimer.OnTimer := @OnTimerTick;

  FTypingIndex := 0;
  FCursorVisible := True;
  FBlinkCounter := 0;

  // Jangan jalankan timer di mode desain IDE
  if not (csDesigning in ComponentState) then
    FAnimTimer.Enabled := True;

  ClearTerminal;
end;

destructor TCyberTerminal.Destroy;
begin
  FAnimTimer.Free;
  FLogs.Free;
  FBuffer.Free;
  inherited Destroy;
end;

procedure TCyberTerminal.SetMaxLines(AValue: Integer);
begin
  if FMaxLines = AValue then Exit;
  FMaxLines := AValue;
  if FMaxLines < 10 then FMaxLines := 10;
end;

procedure TCyberTerminal.ClearTerminal;
begin
  FLogs.Clear;
  // Tambahkan baris kosong pertama sebagai prompt awal
  FLogs.Add(FPrefixString);
  FTypingIndex := Length(FLogs[0]);
  Invalidate;
end;

procedure TCyberTerminal.AddLog(const AMessage: string);
begin
  // Jika sedang mengetik baris sebelumnya, paksakan selesai seketika
  if FLogs.Count > 0 then
    FTypingIndex := Length(FLogs[FLogs.Count - 1]);

  // Hapus log terlama jika melampaui batas MaxLines
  if FLogs.Count >= FMaxLines then
    FLogs.Delete(0);

  // Tambahkan pesan baru dengan prefix
  FLogs.Add(FPrefixString + AMessage);

  // Reset index animasi ke panjang prefix, agar prefix langsung muncul,
  // dan sisanya diketik huruf demi huruf
  FTypingIndex := Length(FPrefixString);

  // Nyalakan cursor saat mengetik
  FCursorVisible := True;
  FBlinkCounter := 0;
end;

procedure TCyberTerminal.OnTimerTick(Sender: TObject);
var
  NeedRedraw: Boolean;
  CurrentLineLen: Integer;
begin
  NeedRedraw := False;

  if FLogs.Count = 0 then Exit;

  // 1. Logika Mengetik
  CurrentLineLen := Length(FLogs[FLogs.Count - 1]);
  if FTypingIndex < CurrentLineLen then
  begin
    // Tambah 1 hingga 3 karakter per tick agar terlihat ngebut tapi natural
    FTypingIndex := FTypingIndex + 2;
    if FTypingIndex > CurrentLineLen then
      FTypingIndex := CurrentLineLen;
    NeedRedraw := True;
  end;

  // 2. Logika Blink Cursor (Kedip setiap ~15 tick / 450ms)
  Inc(FBlinkCounter);
  if FBlinkCounter >= 15 then
  begin
    FBlinkCounter := 0;
    FCursorVisible := not FCursorVisible;
    NeedRedraw := True;
  end;

  if NeedRedraw then Invalidate;
end;

procedure TCyberTerminal.Resize;
begin
  inherited Resize;
  if Assigned(FBuffer) then
  begin
    FBuffer.SetSize(Width, Height);
    Invalidate;
  end;
end;

procedure TCyberTerminal.Paint;
var
  i, StartIdx, MaxVisibleLines: Integer;
  LineHeight: Integer;
  DrawX, DrawY: Integer;
  LineStr, PrintStr: string;
  TextSz: TSize;
  NeonColor, BgColor: TBGRAPixel;

  // TAMBAHAN VARIABEL UNTUK PERBAIKAN
  TextGlowColor, ScanlineColor: TBGRAPixel;
  PtsRect: array[0..3] of TPointF;
begin
  // 1. Bersihkan Background
  BgColor := CyberThemeData.BgDark;
  FBuffer.Fill(BgColor);

  FBuffer.FontName := Font.Name;
  FBuffer.FontHeight := Abs(Font.Height);
  FBuffer.FontStyle := Font.Style;

  NeonColor := CyberThemeData.PrimaryNeon;
  LineHeight := FBuffer.TextSize('Wg').cy + 4; // Tinggi 1 baris teks + margin
  MaxVisibleLines := (Height - 10) div LineHeight;

  // PERBAIKAN 1: Hitung manual efek transparansi Glow Teks (Bobot 100/255)
  TextGlowColor.red := (BgColor.red * (255 - 100) + NeonColor.red * 100) div 255;
  TextGlowColor.green := (BgColor.green * (255 - 100) + NeonColor.green * 100) div 255;
  TextGlowColor.blue := (BgColor.blue * (255 - 100) + NeonColor.blue * 100) div 255;
  TextGlowColor.alpha := 255;

  // PERBAIKAN 2: Hitung manual efek Scanline monitor (Bobot 40/255 ke warna Hitam RGB 0,0,0)
  ScanlineColor.red := (BgColor.red * (255 - 40)) div 255;
  ScanlineColor.green := (BgColor.green * (255 - 40)) div 255;
  ScanlineColor.blue := (BgColor.blue * (255 - 40)) div 255;
  ScanlineColor.alpha := 255;

  // Hitung dari baris ke berapa kita mulai menggambar (Scroll otomatis ke bawah)
  StartIdx := FLogs.Count - MaxVisibleLines;
  if StartIdx < 0 then StartIdx := 0;

  DrawX := 10;
  DrawY := 10;

  // 2. Render Teks Log
  for i := StartIdx to FLogs.Count - 1 do
  begin
    LineStr := FLogs[i];

    // Jika ini adalah baris paling bawah, potong teks sesuai animasi mengetik
    if i = FLogs.Count - 1 then
      PrintStr := Copy(LineStr, 1, FTypingIndex)
    else
      PrintStr := LineStr;

    // A. Efek Glow: Gambar teks sedikit transparan & digeser 1 pixel
    // PERBAIKAN 3: Gunakan TextGlowColor manual dan hapus tlTop
    FBuffer.TextOut(DrawX + 1, DrawY + 1, PrintStr, TextGlowColor, taLeftJustify);

    // B. Inti Teks: Gambar teks terang solid (hapus tlTop)
    FBuffer.TextOut(DrawX, DrawY, PrintStr, CyberThemeData.TextNormal, taLeftJustify);

    // Render Kursor di akhir baris yang sedang aktif
    if (i = FLogs.Count - 1) and FCursorVisible then
    begin
      TextSz := FBuffer.TextSize(PrintStr);
      // Gambar kursor blok '█'
      FBuffer.FillRect(DrawX + TextSz.cx + 2, DrawY + 2,
                       DrawX + TextSz.cx + 10, DrawY + LineHeight - 2,
                       CyberThemeData.TextHighlight, dmSet);
    end;

    DrawY := DrawY + LineHeight;
  end;

  // 3. Render Scanlines & Vignette (Efek Monitor Tabung)
  for i := 0 to Height div 4 do
  begin
    // Garis gelap horizontal setiap 4 pixel menggunakan warna Scanline yang dihitung manual
    FBuffer.DrawLineAntialias(0, i * 4, Width, i * 4, ScanlineColor, 1);
  end;

  // PERBAIKAN 4: Ganti DrawRectAntialias dengan DrawPolyLineAntialias
  // Bingkai luar 1 (Bevel Terminal Luar)
  PtsRect[0] := PointF(0, 0);
  PtsRect[1] := PointF(Width-1, 0);
  PtsRect[2] := PointF(Width-1, Height-1);
  PtsRect[3] := PointF(0, Height-1);
  FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.BgLighter, 2.0, True);

  // Bingkai luar 2 (Bevel Terminal Dalam)
  PtsRect[0] := PointF(2, 2);
  PtsRect[1] := PointF(Width-3, 2);
  PtsRect[2] := PointF(Width-3, Height-3);
  PtsRect[3] := PointF(2, Height-3);
  FBuffer.DrawPolyLineAntialias(PtsRect, CyberThemeData.SecondaryNeon, 1.0, True);

  // 4. Proyeksikan ke Canvas
  FBuffer.Draw(Canvas, 0, 0, True);
end;

end.
