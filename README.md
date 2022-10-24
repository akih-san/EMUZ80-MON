# EMUZ80-MON

2022.10.24 Rev.B02.1をリリースしました。

Rev.2.0でGRANT's Basicのキー入力センス機能に不具合が発生してしまいました。


不具合を修正したバージョンRev.B02.1をリリースします。

2022.10.15

Rev.B02 リリース

・逆アセンブルコマンド追加



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

一応PIC18F47Q43_firmwareでRAM4K版も作成しましたが、手元にQ43が無いため、動作

確認は出来ていません。RAM4KをQ84で再構成して動作することは確認していますので、

多分大丈夫だと思います。

BASICは2000H番地から配置されています。Monitorから、Gコマンドでジャンプするか

#コマンドでローンチすることが出来ます。

BASICからは、MONITORコマンドでMonitorに戻ります。

モニターの操作方法ですが、？コマンドで以下のヘルプが出ます。

詳細は、MoniorDEbugCommand Document.txtを参照してください。

　　? :Command Help

　　D[<adr>] :Dump Memory

  　S[<adr>] :Set Memory"

  　R[<reg>] :Set or Dump register

  　G[<adr>][,<stop adr>] :Go and Stop
  
　　L :Load HexFile"

  　P[I|S] :Save HexFile(I:Intel,S:Motorola

　  #L|<num> :Launch program

　  B[1|2[,<adr>]] :Set or List Break Point

 　 BC[1|2] :Clear Break Point

  　T[<adr>][,<steps>|-1] : Trace command

  　TP[ON|OFF] :Trace Print Mode

  　TM[I|S] :Trace Option for CALL

  　DI[<adr>][,s<steps>|<adr>] :Disassemble"

