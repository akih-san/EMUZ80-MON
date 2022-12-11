unimonの機能拡張を行いました。
合わせて、GRANT's BASIC版のZ80 BASIC Ver 4.7bも搭載してあります。

電脳伝説さんのオリジナルメモリマップでの動作確認と、
PIC18F47Q84でRAMサイズを12Kまで拡張したファームウエアで
動作させています。

RAM12K版のファームウェアは、メモリマップを以下の様に変更してあります。

ROM 0000H - BFFFH (48K)
RAM C000H - EFFFH (12K)
I/O F000H - FFFFH (4K)

(UART)
FF00H	; UART DATA REGISTOR
FF01H	; UART CONTROL REGISTOR

ＣＬＣを8個使い、メモリの読み書きのベクター割り込み処理はデータ転送の最小限の
処理に留めてあります。
アセンブラは使用していませんので、チューニングの余地はあります。
BASICのASCIIARTは、2.5MHZのZ80で1240秒程度でした。


PIC18F47Q84_firmwareのフォルダにRAM8KとRAM12K用のファームとヘキサファイル
があります。オリジナルメモリマップを使用すのであれば、RAM8Kを使用してください。

一応PIC18F47Q43はRev.B03ではサポートしません。ROM、RAMの容量が足らないためです。

Rev.B03では、SBCZ80データパックに収録されている

・GRANT's BASIC
・PALO ALTO TINY BASIC

および、

・GAME80インタプリタ
・GAME80コンパイラ

を搭載しました。モニタプログラムの＃コマンドで、ローンチすることが出来ます。

BASICからは、MONITORコマンドでモニタに戻ります。
TINY BASICからは、BYEコマンドでモニタに戻ります。
GAME80インタプリタからは、>=3でモニタに戻ります。


モニターの操作方法ですが、？コマンドで以下のヘルプが出ます。
詳細は、MoniorDEbugCommand Document.txtを参照してください。

　　? :Command Help
　　#L|<num> :Launch program
　　A[<address>] : Mini Assemble mode
　　B[1|2[,<adr>]] :Set or List Break Point
　　BC[1|2] :Clear Break Point
　　D[<adr>] :Dump Memory
　　DI[<adr>][,s<steps>|<adr>] :Disassemble
　　G[<adr>][,<stop adr>] :Go and Stop
　　L :Load HexFile
　　P[I|S] :Save HexFile(I:Intel,S:Motorola)
　　R[<reg>] :Set or Dump register
　　S[<adr>] :Set Memory
　　T[<adr>][,<steps>|-1] : Trace command
　　TM[I|S] :Trace Option for CALL
　　TP[ON|OFF] :Trace Print Mode

2022.10.15
Rev.B02 リリース
・逆アセンブルコマンド追加

2022.11.28
Rev.B02.2 リリース
・バグ修正と、RAMで動作するミニアセンブラ公開

2022.12.11
Rev.B03 リリース
・アセンブルコマンド追加
・PALO ALTO TINY BASIC
・GAME80インタプリタ
・GAME80コンパイラ
