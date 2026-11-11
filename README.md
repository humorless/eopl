<!-- markdownlint-disable MD013 -->
# EOPL — 程式語言課程講義

以 *Essentials of Programming Languages*（EOPL）為教材的程式語言課程投影片，使用 [Marp](https://marp.app/) 撰寫，範例程式以 Racket 實作。

這份講義對應國立政治大學 115 學年度第 1 學期「程式語言」（Programming Languages）。
課程大綱、評分方式與選課資訊請見[政大課程大綱頁面](https://newdoc.nccu.edu.tw/teaschm/1151/schmPrv.jsp-yy=115&smt=1&num=753795&gop=00&s=1.html)。

## 課程簡介

這不是哪一種程式語言的入門課，修課前需要有程式設計基礎。

課程的核心想法是：直譯器本身也是一支程式。我們用直譯器來說明語言的語意，從歸納資料結構與資料抽象開始，依序實作 LET、PROC、LETREC（綁定、範疇、closure），接著加入狀態（computational effects、store model），最後介紹型別系統。目標是讓學生從「使用語言的人」走向「設計語言的人」，理解每個語言特性背後的設計理由。

## 教材

- Daniel P. Friedman & Mitchell Wand, *Essentials of Programming Languages*, 3rd ed., MIT Press, 2008.
- 實作語言：[Racket](https://racket-lang.org/)（使用 `#lang eopl`）
- 線上影片（數位學習）：Rich Hickey 的 *Simple Made Easy*（期中）與 *The Value of Values*（期末），清單見 [Rich-Hickey-fanclub](https://github.com/tallesl/Rich-Hickey-fanclub)

## 講義目錄

目錄編號對應課程週次。第 9 週與第 16 週為考試週，沒有講義；尚未上到的週次會陸續加入。

| 週次 | 主題 | EOPL 章節 | 講義 |
| ---- | ---- | --------- | ---- |
| 1 | 課程介紹、歸納資料結構 | 1.1–1.2 | [md](class-01/class-01.md) · [pdf](class-01/class-01.pdf) |
| 2 | 歸納資料結構（續）：structural induction | 1.3 | [md](class-02/class-02.md) · [pdf](class-02/class-02.pdf) |
| 3 | 資料抽象：representation independence | 2.1–2.2 | [md](class-03/class-03.md) · [pdf](class-03/class-03.pdf) |
| 4 | `define-datatype`、抽象語法與具體語法 | 2.3–2.5 | [md](class-04/class-04.md) · [pdf](class-04/class-04.pdf) |
| 5 | LET 語言：直譯器架構、環境模型 | 3.1–3.2 | [md](class-05/class-05.md) · [pdf](class-05/class-05.pdf) |
| 6 | PROC 語言：closure、lexical scope | 3.3 | [md](class-06/class-06.md) · [pdf](class-06/class-06.pdf) |
| 7 | LETREC：遞迴程序的環境語意 | 3.4 | [md](class-07/class-07.md) · [pdf](class-07/class-07.pdf) |
| 8 | 範疇與 nameless representation | 3.5–3.7 | [md](class-08/class-08.md) · [pdf](class-08/class-08.pdf) |
| 9 | 期中考（Ch1–Ch3） | | |
| 10 | EXPLICIT-REFS：store model | 4.1–4.2 | [md](class-10/class-10.md) · [pdf](class-10/class-10.pdf) |
| 11 | IMPLICIT-REFS：mutable variables | 4.3 | [md](class-11/class-11.md) · [pdf](class-11/class-11.pdf) |
| 12 | MUTABLE-PAIRS、參數傳遞方式 | 4.4–4.5 | [md](class-12/class-12.md) · [pdf](class-12/class-12.pdf) |
| 13 | 型別系統簡介 | 7.1–7.2 | |
| 14 | CHECKED 語言 | 7.3 | |
| 15 | type checker 實作與複習 | 7.3 | |
| 16 | 期末考（Ch1–Ch7） | | |

## 範例程式

部分講義附有可執行的範例：

- [`class-03/code/`](class-03/code/)：自然數與環境的多種表示法（unary、Scheme number、bignum；association list、data structure、procedure）
- [`class-04/`](class-04/)：`parse.rkt`、`example.rkt`，抽象語法的解析範例
- [`class-02/nil_context.clj`](class-02/nil_context.clj)：課堂討論用的 Clojure 範例

Racket 檔案可以直接執行：

```bash
racket class-04/example.rkt
```

## 目錄結構

```text
class-NN/
├── class-NN.md     # Marp 原始檔
├── class-NN.pdf    # 輸出的 PDF
├── img/            # 圖片
├── mmd/ diagrams/  # 圖表原始碼（Mermaid、Graphviz）
└── *.rkt           # 範例程式
```

## 用 Marp CLI 產生 PDF

### 安裝 Marp CLI

```bash
npm install -g @marp-team/marp-cli
```

### 轉出單一檔案

講義會引用本機圖片並使用 HTML，所以需要加上 `--allow-local-files` 與 `--html`：

```bash
marp class-12/class-12.md --allow-local-files --html --pdf
```

### 轉出全部講義

```bash
for f in class-*/class-*.md; do
  marp "$f" --allow-local-files --html --pdf
done
```

## 相關連結

- [政大課程大綱](https://newdoc.nccu.edu.tw/teaschm/1151/schmPrv.jsp-yy=115&smt=1&num=753795&gop=00&s=1.html)
- [Functional Thursday](https://www.facebook.com/FunctionalThursday)
