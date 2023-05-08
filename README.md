unimonの機能拡張を行いました。<br>
合わせて、GRANT's BASIC版のZ80 BASIC Ver 4.7bも搭載してあります。<br>
<br>
電脳伝説さんのオリジナルメモリマップでの動作確認と、<br>
PIC18F47Q84でRAMサイズを12Kまで拡張したファームウエアで<br>
動作させています。<br>
<br>
RAM12K版のファームウェアは、メモリマップを以下の様に変更してあります。<br>
<br>
ROM 0000H - BFFFH (48K)<br>
RAM C000H - EFFFH (12K)<br>
I/O F000H - FFFFH (4K)<br>
<br>
(UART)<br>
FF00H	; UART DATA REGISTOR<br>
FF01H	; UART CONTROL REGISTOR<br>
<br>
ＣＬＣを8個使い、メモリの読み書きのベクター割り込み処理はデータ転送の最小限の<br>
処理に留めてあります。<br>
アセンブラは使用していませんので、チューニングの余地はあります。<br>
BASICのASCIIARTは、2.5MHZのZ80で1240秒程度でした。<br>
<br>
<br>
Rev.B05.5より、RAM12Kバージョンのみのサポートとしています。<br>
理由は、GAME80コンパイラがまともに動くメモリ環境が最低でも<br>
12Kバイト程度必要なためです。<br>
<br>
#コマンドで、BASICや、GAME80ICをローンチすることが出来ます。<br>
収容されているソフトは、以下の４つです。<br>
<br>
・BASIC<br>
・TINY BASIC<br>
・GAME80IC<br>
・VTLZ80<br>
<br>
#Lコマンドで、収容されているソフトウェアを確認することが出来ます。<br>
<br>
BASICからは、MONITORコマンドでモニタに戻ります。<br>
TINY BASICからは、BYEコマンドでモニタに戻ります。<br>
GAME80インタプリタからは、>=3でモニタに戻ります。<br>
VTLZ80からは、DELキーを押した後に、リターンキーを押すとモニタに戻ります。<br>
<br>
モニターの操作方法ですが、？コマンドで以下のヘルプが出ます。<br>
詳細は、MoniorDEbugCommand Document.txtを参照してください。<br>
<br>
　　? :Command Help<br>
　　#L|(num) :Launch program<br>
　　A[<address>] :Mini Assemble mode<br>
　　B[1|2[,<adr>]] :Set or List Break Point<br>
　　BC[1|2] :Clear Break Point<br>
　　D[<adr>] :Dump Memory<br>
　　DI[<adr>][,s<steps>|<adr>] :Disassemble<br>
　　G[<adr>][,<stop adr>] :Go and Stop<br>
　　L[G|<offset>] :Load HexFile (and GO)<br>
　　P[I|S] :Save HexFile(I:Intel,S:Motorola)<br>
　　R[<reg>] :Set or Dump register<br>
　　S[<adr>] :Set Memory<br>
　　T[<adr>][,<steps>|-1] : Trace command<br>
　　TM[I|S] :Trace Option for CALL<br>
　　TP[ON|OFF] :Trace Print Mode<br>
<br>
2022.10.15<br>
Rev.B02 リリース<br>
・逆アセンブルコマンド追加<br>
<br>
2022.11.28<br>
Rev.B02.2 リリース<br>
・バグ修正と、RAMで動作するミニアセンブラ公開<br>
<br>
2022.12.11<br>
Rev.B03 リリース<br>
・アセンブルコマンド追加<br>
・PALO ALTO TINY BASIC<br>
・GAME80インタプリタ<br>
・GAME80コンパイラ<br>
<br>
2023.1.17<br>
Rev.B04 リリース<br>
<br>
・PICのファームウェアで、XON/XOFFフロー制御を実装しました。<br>
・LG(Load and Go)コマンド追加<br>
<br>
　　ヘキサファイルのロード後、ロードアドレスの先頭にジャンプするコマンドを<br>
　　追加しました。<br>
<br>
・その他、エラー表示の不具合箇所の修正<br>
<br>
2023.3.30<br>
Rev.B05 リリース<br>
<br>
・VTL言語のZ80版、VTLZ80を追加<br>
<br>
2023.5.9<br>
Rev.B05.5 リリース<br>
<br>
・GAME80をCP/M-80用にリリースしたGAME80IC Ver.03仕様に統一<br>

