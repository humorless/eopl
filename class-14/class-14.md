---
marp: true
theme: default
paginate: true
style: |
  h1 {
    border-bottom: 2px solid #4a90d9;
    padding-bottom: 6px;
    color: #1a1a2e;
  }
  blockquote {
    border-left: 4px solid #4a90d9;
    padding-left: 16px;
    color: #444;
    background: none;
  }
  table {
    font-size: 20px;
  }
  pre {
    font-size: 20px;
  }
  section.lead h1 {
    border-bottom: none;
    font-size: 48px;
    color: #1a1a2e;
  }
  section.small {
    font-size: 23px;
  }
  section.small pre {
    font-size: 17px;
  }
  section.small table {
    font-size: 17px;
  }
  section img {
    display: block;
    margin: 0 auto;
  }
---

<!-- _class: lead -->

# 程式語言
## Programming Languages — Class 14

政大資碩 115-1　陳家宏

---

# 今天三堂課

| 時段 | 內容 |
|---|---|
| 第 1 堂 | CHECKED 的標註、新文法、有標註的 proc 規則（pp.240–241） |
| 第 2 堂 | letrec 的兩個 tenv 與 letrec 規則；`check-equal-type!`（pp.241–243） |
| 第 3 堂 | §7.3.1 The Checker：Figures 7.1–7.3；Exercise 7.7；習題 7.5–7.11；HW6（pp.243–248） |

<!-- 講者備註：
第 1 堂：概念 5 個（proc 的 value-of 與 type-of 對照、CHECKED 的標註要求、結果型別與 procedure 的型別、新文法、有標註的 proc 規則與 run 不看標註）、停下來想 1 處（第 10 張）、約 33 分鐘；時間有剩，可以接著講第 2 堂開頭的第 14–16 張（letrec 的形狀與 tres）
第 2 堂：概念 8 個（letrec 的形狀、tres 的動機（我的解讀）、兩個 tenv、letrec 規則、與 extend-env-rec 對照、tres 宣告錯時被點名的位置、check-equal-type! 與要怪罪的運算式、type-to-external-form 與 for effect）、停下來想 3 處（第 15、20、23 張）、約 48 分鐘
第 3 堂：概念 9 個（規則轉寫成程式、init-tenv、if 的兩個 check、call 的兩種錯誤、letrec 的程式、type-of 與 value-of 並排、Exercise 7.7 的錯誤順序、習題地圖（含 emptylist 與 void）、HW6 的 soundness 反例；另有 type hint 1 張課外補充）、停下來想 2 處（第 34、37 張）、約 50 分鐘，偏緊；超時先刪第 44 張，再刪第 41 張
每張的分鐘數是我的假設，沒有實測。
CHECKED 的程式都在 mwand/eopl3 的 chapter7/checked 下跑過（Racket v8.10）；第 36 張的 value-of 對照 chapter3/letrec-lang；第 41 張在 chapter4/explicit-refs 跑過。第 38 張的 Exercise 7.7 版本，是我把 checker.scm 複製一份、改 if-exp 分支後跑的。
Clojure 用 clojure 1.12.0 的 jar（java -cp ... clojure.main）跑過；clj-kondo v2024.08.01 用執行檔跑過。
課綱原本把 §7.3 分在 week 14、15；這次在 week 14 講完，HW6 提前到今天發布，week 15 做期末複習。 -->

---

# 上週停在哪一條規則？（p.240）

```
     (type-of body [var=t1]tenv) = t2
---------------------------------------------
(type-of (proc-exp var body) tenv) = (t1 → t2)
```

p.240（改寫）：

* 規則的由來：若 `proc (var) body` 的型別是 `(t1 → t2)`，它預期被一個型別 t1 的引數呼叫；求值 body 時，var 會綁到一個型別 t1 的值
* 這條規則是 sound 的：若 `type-of` 對 body 的預測正確，它對 `(proc-exp var body)` 的預測也正確
* 但要計算 `(type-of (proc-exp var body) tenv)` 時，要上哪找 var 的型別 t1 呢？課本說：在程式裡找不到
* 兩種標準設計：**Type Checking**（程式設計師補上型別）、**Type Inference**（checker 依變數的用法推出型別）

---

<!-- _class: small -->

# proc 的 `value-of` 與 `type-of` 怎麼對照？

`value-of`（p.76）分兩步：

```
;; step 1: when the proc expression is evaluated
(value-of (proc-exp var body) ρ)
  = (proc-val (procedure var body ρ))

;; step 2: when the procedure is called (val comes from the call site)
(apply-procedure (procedure var body ρ) val)
  = (value-of body [var=val]ρ)
```

`type-of`（p.240）只有一步：

```
     (type-of body [var=t1]tenv) = t2
---------------------------------------------
(type-of (proc-exp var body) tenv) = (t1 → t2)
```

| | `value-of` | `type-of` |
|---|---|---|
| 遇到 proc 時 | 不碰 body，連同 ρ 打包成 closure | 處理 body |
| body 在哪裡算 | `[var=val]ρ` | `[var=t1]tenv` |
| var 綁到的 | val，一個值 | t1，一個型別 |
| 從哪來 | 呼叫時，由 call-exp 的 rand 算出，交給 `apply-procedure` | 規則沒有交代 |

我的解讀：`value-of` 要到呼叫時才算 body，那時呼叫端已經帶來 val；`type-of` 在定義處就檢查 body，那個位置沒有呼叫端可以提供 t1。

<!-- 講者備註：p.76 的兩條等式是 class-06 教過的 PROC 規格，class-13 第 12 張回顧過。 -->

---

# CHECKED 要程式設計師多寫什麼？（p.240）

p.240（改寫）：CHECKED 與 LETREC 相同，只是程式設計師要寫出每個綁定變數的型別；letrec 綁定的變數，還要寫出 procedure 的結果型別。

| 語言 | proc | letrec |
|---|---|---|
| LETREC | `proc (x) -(x,1)` | `letrec double (x) = ...` |
| CHECKED | `proc (x : int) -(x,1)` | `letrec int double (x : int) = ...` |

`x : int` 補上的，就是 proc 規則缺的 t1。

---

<!-- _class: small -->

# p.241 的三個範例，`check` 給出什麼型別？

```
proc (x : int) -(x,1)

letrec
  int double (x : int) = if zero?(x)
                         then 0
                         else -((double -(x,1)), -2)
in double

proc (f : (bool -> int)) proc (n : int) (f zero?(n))
```

在 chapter7/checked 跑 `check`：

```
> (check "proc (x : int) -(x,1)")
'(int -> int)
> (check "letrec int double (x : int) = if zero?(x) then 0 else -((double -(x,1)), -2) in double")
'(int -> int)
> (check "proc (f : (bool -> int)) proc (n : int) (f zero?(n))")
'((bool -> int) -> (int -> int))
```

---

# `double` 的結果型別和 `double` 的型別，差在哪？（p.241）

```
letrec int double (x : int) = ... in double
       ^^^         ^^^^^^^
       結果型別     參數型別
```

p.241（改寫）：`double` 的結果型別是 `int`；`double` 本身的型別是 `(int -> int)`，因為它是一個給整數、回傳整數的 procedure。

| 寫在程式裡的 | 型別 |
|---|---|
| `int`（`double` 前面） | `double` 的結果型別 |
| `x : int` | 參數 `x` 的型別 |
| `double` 本身 | `(int -> int)` |

---

<!-- _class: small -->

# 文法改了哪兩條 production？（p.241）

```
Expression ::= proc (Identifier : Type) Expression
               proc-exp (var ty body)

Expression ::= letrec
                 Type Identifier (Identifier : Type) = Expression
               in Expression
               letrec-exp
                 (p-result-type p-name b-var b-var-type p-body letrec-body)
```

`Type` 就是上週 p.235 的文法：`int`、`bool`、`(Type -> Type)`。

對照 chapter7/checked 的 `lang.scm`，第 43–45 行與第 51–55 行：

```scheme
(expression
 ("proc" "(" identifier ":" type ")" expression)
 proc-exp)

(expression
  ("letrec"
    type identifier "(" identifier ":" type ")" "=" expression
     "in" expression)
  letrec-exp)
```

---

# 加上標註的 proc 規則長什麼樣？（p.241）

p.240 的版本：

```
     (type-of body [var=t1]tenv) = t2
---------------------------------------------
(type-of (proc-exp var body) tenv) = (t1 → t2)
```

p.241 的版本：

```
       (type-of body [var=tvar]tenv) = tres
----------------------------------------------------
(type-of (proc-exp var tvar body) tenv) = (tvar → tres)
```

| | p.240 | p.241 |
|---|---|---|
| 參數的型別 | t1，規則沒說從哪來 | tvar，就是語法樹裡的 `ty` 欄位 |
| 結果的型別 | t2，由 body 算出 | tres，由 body 算出 |

---

# 停下來想：同一個 body，三種標註

```
proc (x : int) x
proc (x : bool) x
proc (x : (int -> int)) x
```

1. 依第 9 張的 p.241 規則，各推出什麼型別？
2. 推出的型別裡，哪一部分來自標註？

**停下來想**（3 分鐘）。

---

# 對答案：標註寫錯了，`check` 和 `run` 各會怎樣？

```
> (check "proc (x : int) x")
'(int -> int)
> (check "proc (x : bool) x")
'(bool -> bool)
> (check "proc (x : (int -> int)) x")
'((int -> int) -> (int -> int))
```

參數的型別就是標註，結果的型別由 body 算出。標註寫錯的話：

```
> (check "(proc (x : bool) -(x,1) 5)")
; check-equal-type!: Types didn't match: bool != int in
; #(struct:var-exp x)
> (run "(proc (x : bool) -(x,1) 5)")
(num-val 4)
```

`run` 不看標註。chapter7/checked 的 `interp.scm` 第 56–58 行：

```scheme
(proc-exp (bvar ty body)
  (proc-val
    (procedure bvar body env)))
```

`ty` 從語法樹取出來之後，沒有被用到；letrec 分支（第 65–67 行）的 `ty1`、`ty2` 也一樣。

<!-- 講者備註：(proc (x : bool) -(x,1) 5) 不在課本裡，是我加的。它執行時沒有 type error，check 拒絕：落在 class-13 文氏圖的藍色環狀區。把標註改成 x : int，check 得 'int。錯誤訊息省略了結尾的 [,bt for context]。 -->

---

<!-- _class: small -->

# 第 1 堂回顧

1. **proc 規則的缺口**：t1 在程式裡找不到；補 t1 有 type checking 與 type inference 兩種設計（p.240，第 3 張）
2. **對照 `value-of`**：`value-of` 呼叫時才算 body，val 由呼叫端帶來；`type-of` 在定義處檢查 body，沒有呼叫端提供 t1。這是我的解讀（p.76，第 4 張）
3. **CHECKED 的標註**：每個綁定變數寫型別；letrec 另外寫結果型別（p.240，第 5 張）
4. **結果型別與 procedure 的型別**：`double` 的結果型別是 `int`，`double` 的型別是 `(int -> int)`（p.241，第 7 張）
5. **新文法**：proc 多一個參數型別，letrec 多兩個型別（p.241，第 8 張）
6. **有標註的 proc 規則**：tvar 來自語法樹；`run` 不看標註（p.241，第 9–11 張）

---

<!-- _class: lead -->

# 第 2 堂
## letrec 規則與 `check-equal-type!`（pp.241–243）

---

# 典型的 letrec 長什麼樣？（pp.241–242）

```
letrec
  tres p (var : tvar) = eproc-body
in eletrec-body
```

p.242（改寫）：這個運算式宣告一個名為 p 的 procedure，參數 var 的型別是 tvar，body 是 eproc-body。所以 p 的型別應該是 `tvar → tres`。

| 名稱 | `double` 的例子（p.241） |
|---|---|
| tres | `int` |
| p | `double` |
| var : tvar | `x : int` |
| eproc-body | `if zero?(x) then 0 else -((double -(x,1)), -2)` |
| eletrec-body | `double` |

---

# 停下來想：letrec 為什麼還要寫 `tres`？

把 `double` 的結果型別拿掉：

```
letrec double (x : int) = if zero?(x)
                          then 0
                          else -((double -(x,1)), -2)
in double
```

試著從 eproc-body 的子運算式開始推型別。

1. 推到 `(double -(x,1))` 時，需要哪個型別？
2. 這個型別從哪裡拿？

**停下來想**（4 分鐘）。

---

# 對答案：遞迴呼叫的型別從哪裡來？

| 步驟 | 需要 | 來源 |
|---|---|---|
| 推 `(double -(x,1))` | `double` 的型別 `(int → ?)` | 要先知道結果型別 |
| 推出結果型別 | eproc-body 的型別 | 要先推完 `(double -(x,1))` |

為什麼要在意（我的解讀）：推 eproc-body 時就要用到 `double` 的型別，而 `double` 的結果型別要等 eproc-body 推完才知道，兩件事互相等待。p.240 只寫了 CHECKED 要求結果型別，沒有寫理由。寫出 `tres`，推 body 之前 `double` 的型別就有了：`(int → int)`。

---

# 兩個 tenv 各放了什麼？（p.242）

p.242（改寫）：eproc-body 和 eletrec-body 都要在「每個變數都有正確型別」的 type environment 裡檢查；哪些變數在 scope 裡，由 scoping rules 決定。

```
tenv_letrec-body = [p = (tvar → tres)]tenv
tenv_proc-body   = [var = tvar]tenv_letrec-body
                 = [var = tvar][p = (tvar → tres)]tenv
```

p.242：在 tenv_proc-body 裡，eproc-body 的型別必須是 tres。

| tenv | 多出的綁定 | 檢查誰 | `double` 的例子 |
|---|---|---|---|
| tenv_letrec-body | `p` | eletrec-body | `[double = (int → int)]tenv` |
| tenv_proc-body | `var`、`p` | eproc-body，結果要是 tres | `[x = int][double = (int → int)]tenv` |

---

<!-- _class: small -->

# letrec 規則的兩個前提各在檢查什麼？（p.242）

```
(type-of eproc-body [var=tvar][p=(tvar → tres)]tenv) = tres
(type-of eletrec-body [p=(tvar → tres)]tenv) = t
------------------------------------------------------------------------
(type-of letrec tres p (var : tvar) = eproc-body in eletrec-body tenv) = t
```

| 前提 | 在哪個 tenv | 要求 |
|---|---|---|
| 第一個 | tenv_proc-body | eproc-body 的型別等於**宣告的** tres |
| 第二個 | tenv_letrec-body | eletrec-body 有型別 t；t 就是這個 letrec 運算式的型別 |

p.242（改寫）：寫下這條規則，規則就寫完了，可以實作 CHECKED 的 type checker。

---

<!-- _class: small -->

# tenv 和 `extend-env-rec` 怎麼對照？（p.83、p.242）

`value-of`（p.83）：

```
(value-of (letrec-exp proc-name bound-var proc-body letrec-body) ρ)
  = (value-of letrec-body (extend-env-rec proc-name bound-var proc-body ρ))
```

p.83（改寫）：記 ρ1 為 `extend-env-rec` 產生的 environment。在 ρ1 裡查 proc-name，得到 `(proc-val (procedure bound-var proc-body ρ1))`；查其他變數，結果和在 ρ 裡查相同。

| | `value-of`（p.83、p.76） | `type-of`（p.242） |
|---|---|---|
| letrec-body | 在 ρ1 裡求值 | 在 `[p=(tvar → tres)]tenv` 裡檢查 |
| 在裡面查 p | 一個 closure，它的 environment 是 ρ1 | `(tvar → tres)` |
| proc-body | 呼叫時，在 `[var=val]ρ1` 裡求值 | 在 `[var=tvar][p=(tvar → tres)]tenv` 裡檢查 |

我的解讀：proc-body 執行時看得到 var、p 與外層的變數；檢查時的 tenv 依同樣的順序放進這些變數。

<!-- 講者備註：proc-body 在 [var=val]ρ1 裡求值，依據是 p.76 的 apply-procedure 規格（class-13 第 12 張回顧過）加上 p.83：closure 裡存的 environment 是 ρ1。 -->

---

# 停下來想：寫出 `double` 的推導

```
letrec int double (x : int) = if zero?(x)
                              then 0
                              else -((double -(x,1)), -2)
in double
```

記號沿用 class-13 第 39 張：`e : t` 是 `(type-of e tenv) = t` 的縮寫。

- `tenv1 = [double=(int → int)]tenv0`
- `tenv2 = [x=int]tenv1`

**停下來想**（6 分鐘）：樹太寬，可以寫成編號的判斷，每一條註明用了哪一條規則、哪幾條前面的判斷。

---

<!-- _class: small -->

# 對答案：`double` 的推導

| # | 判斷 | 規則與依據 |
|---|---|---|
| 1 | `x : int`（tenv2） | var，`tenv2(x)` |
| 2 | `zero?(x) : bool`（tenv2） | zero?，(1) |
| 3 | `0 : int` | const |
| 4 | `double : (int → int)`（tenv2） | var，`tenv2(double)`，就是宣告的型別 |
| 5 | `-(x,1) : int`（tenv2） | diff，(1) 與 `1 : int` |
| 6 | `(double -(x,1)) : int`（tenv2） | call，(4)(5) |
| 7 | `-2 : int` | const |
| 8 | `-((double -(x,1)), -2) : int`（tenv2） | diff，(6)(7) |
| 9 | `if ... : int`（tenv2） | if，(2)(3)(8) |
| 10 | (9) 的 `int` 等於宣告的 tres `int` | letrec 第一個前提 |
| 11 | `double : (int → int)`（tenv1） | var，letrec 第二個前提 |
| 12 | 這個 letrec 運算式 `: (int → int)`（tenv0） | letrec，(10)(11) |

---

# `tres` 宣告錯了，`check` 點名誰？

把結果型別寫成 `bool`：

```
> (check "letrec bool double (x : int) = if zero?(x) then 0 else -((double -(x,1)), -2) in (double 3)")
; check-equal-type!: Types didn't match: bool != int in
; #(struct:call-exp #(struct:var-exp double) #(struct:diff-exp #(struct:var-exp
;   x) #(struct:const-exp 1)))
> (run "letrec bool double (x : int) = if zero?(x) then 0 else -((double -(x,1)), -2) in (double 3)")
(num-val 6)
```

| 第 21 張的步驟 | 宣告 `bool` 之後 |
|---|---|
| (4) `double` 的型別 | `(int → bool)` |
| (6) `(double -(x,1))` | `bool` |
| (8) diff 要求 `int` | 不成立，推導在這裡停下 |

被點名的是遞迴呼叫。宣告的 tres 在推 body 之前就放進 tenv，推導還沒走到第一個前提的比對，就先停下來了。

<!-- 講者備註：錯誤訊息照 REPL 的實際輸出，省略結尾的 [,bt for context]。 -->

---

# 停下來想：`letrec int f (x : int) = zero?(x) in (f 0)`

```
> (run "letrec int f (x : int) = zero?(x) in (f 0)")
(bool-val #t)
```

執行時沒有 type error。

1. `check` 會接受還是拒絕？
2. 如果拒絕，是第 18 張的哪一個前提不成立？
3. 被點名的會是哪一個子運算式？

**停下來想**（3 分鐘）。

---

# 對答案：第一個前提不成立

```
> (check "letrec int f (x : int) = zero?(x) in (f 0)")
; check-equal-type!: Types didn't match: bool != int in
; #(struct:zero?-exp #(struct:var-exp x))
```

| 前提 | 推出 | 要求 | 成立？ |
|---|---|---|---|
| 第一個 | `zero?(x) : bool` | 等於宣告的 tres `int` | 否 |
| 第二個 | `(f 0) : int` | 有型別 | 是 |

被點名的是 eproc-body `zero?(x)`。第 22 張被點名的是 body 裡的遞迴呼叫；這張的 body 沒有遞迴呼叫，推導走完，停在比對 tres 那一步。

---

<!-- _class: small -->

# `check-equal-type!` 的第三個引數做什麼？（p.242）

p.242（改寫）：比較兩個型別是否相等，用 `check-equal-type!`；不相等就報錯。第三個引數是型別不相等時要**怪罪 (blame)** 的運算式。

```
check-equal-type! : Type × Type × Exp → Unspecified

(define check-equal-type!
  (lambda (ty1 ty2 exp)
    (if (not (equal? ty1 ty2))
        (report-unequal-types ty1 ty2 exp))))
```

為什麼要在意：今天每一個拒絕，訊息的 `in` 後面就是這個引數。

| 程式 | 被怪罪的運算式 |
|---|---|
| `(proc (x : bool) -(x,1) 5)`（第 11 張） | `x` |
| `letrec bool double ...`（第 22 張） | `(double -(x,1))` |
| `letrec int f (x : int) = zero?(x) ...`（第 24 張） | `zero?(x)` |

<!-- 講者備註：repo 的 checker.scm 第 10–13 行用 when 取代 if，行為相同。 -->

---

<!-- _class: small -->

# 錯誤訊息怎麼印出型別？（p.243）

```
(define report-unequal-types
  (lambda (ty1 ty2 exp)
    (eopl:error 'check-equal-type!
      "Types didn't match: ~s != ~a in~%~a"
      (type-to-external-form ty1)
      (type-to-external-form ty2)
      exp)))

(define type-to-external-form
  (lambda (ty)
    (cases type ty
      (int-type () 'int)
      (bool-type () 'bool)
      (proc-type (arg-type result-type)
        (list (type-to-external-form arg-type) '-> (type-to-external-form result-type))))))
```

- p.243（改寫）：`type-to-external-form` 把型別轉回容易閱讀的 list。為什麼要在意：`check` 回傳的 `'(int -> int)`，就是它的輸出；沒有它，看到的會是 `#(struct:proc-type ...)`
- p.243（改寫）：`check-equal-type!` 的值從來不被使用，呼叫它只為了 effect，就像 §4.2.2 的 `setref`（p.109：`setref` 回傳 23，這個值不被使用）

<!-- 講者備註：repo 的 type-to-external-form 在 lang.scm 第 86 行起，report-unequal-types 在 checker.scm 第 17–23 行。 -->

---

<!-- _class: small -->

# 第 2 堂回顧

1. **letrec 的形狀**：`letrec tres p (var : tvar) = eproc-body in eletrec-body`，p 的型別是 `tvar → tres`（pp.241–242，第 14 張）
2. **為什麼要寫 tres**：推 eproc-body 時就要用到 p 的型別。這是我的解讀，課本只寫了要求（第 15、16 張）
3. **兩個 tenv**：eletrec-body 看得到 p；eproc-body 看得到 var 與 p（p.242，第 17 張）
4. **letrec 規則**：第一個前提檢查 body 的型別等於宣告的 tres；第二個前提給出這個 letrec 運算式的型別（p.242，第 18 張）
5. **和 `extend-env-rec` 對照**：檢查時的 tenv 與執行時的 environment，放進變數的順序相同。這是我的解讀（p.83、p.242，第 19 張）
6. **tres 宣告錯時**：被點名的可能是遞迴呼叫，也可能是 body 本身（第 22–24 張）
7. **`check-equal-type!`**：第三個引數是要怪罪的運算式；呼叫它只為了 effect（pp.242–243，第 25、26 張）

---

<!-- _class: lead -->

# 第 3 堂
## §7.3.1 The Checker（pp.243–248）

---

<!-- _class: small -->

# const、var、diff、zero? 怎麼寫成程式？（Figure 7.1，p.244）

p.243（改寫）：把規則轉寫成程式，就像第 3 章寫直譯器一樣，結果在 Figures 7.1–7.3。

```scheme
(const-exp (num) (int-type))
(var-exp (var) (apply-tenv tenv var))
(diff-exp (exp1 exp2)
  (let ((ty1 (type-of exp1 tenv))
        (ty2 (type-of exp2 tenv)))
    (check-equal-type! ty1 (int-type) exp1)     ; hypothesis 1
    (check-equal-type! ty2 (int-type) exp2)     ; hypothesis 2
    (int-type)))                                ; conclusion
(zero?-exp (exp1)
  (let ((ty1 (type-of exp1 tenv)))
    (check-equal-type! ty1 (int-type) exp1)
    (bool-type)))
```

規則的每個前提，變成一行 `check-equal-type!`；結論的型別，變成回傳值。

`type-of-program` 從 `(init-tenv)` 開始（p.244）。repo 的 `init-tenv` 讓 `x`、`v`、`i` 都是 `int`（checker.scm 第 138–143 行），和 `init-env` 的 10、5、1 對得上：

```
> (check "-(x,v)")
'int
> (run "-(x,v)")
(num-val 5)
```

<!-- 講者備註：為什麼要在意 init-tenv（我的解讀）：tenv 要預測執行時每個變數的值的型別；init-tenv 若寫 x : bool，而 init-env 的 x 是 10，checker 的預測就不成立。 -->

---

# if 的規則變成哪兩個 `check-equal-type!`？（Figure 7.1，p.244）

```scheme
(if-exp (exp1 exp2 exp3)
  (let ((ty1 (type-of exp1 tenv))
        (ty2 (type-of exp2 tenv))
        (ty3 (type-of exp3 tenv)))
    (check-equal-type! ty1 (bool-type) exp1)
    (check-equal-type! ty2 ty3 exp)
    ty2))
```

| 前提 | 程式 | 怪罪 |
|---|---|---|
| `(type-of e1 tenv) = bool` | 第一個 check | `exp1` |
| `e2`、`e3` 的型別都是 t | 第二個 check：`ty2` 等於 `ty3` | `exp`，也就是 if 運算式本身 |

```
> (check "if zero?(0) then 1 else zero?(1)")
; check-equal-type!: Types didn't match: int != bool in
; #(struct:if-exp #(struct:zero?-exp #(struct:const-exp 0)) ...)
```

---

<!-- _class: small -->

# let 與 proc 的程式（Figure 7.2，p.245）

```scheme
(let-exp (var exp1 body)
  (let ((exp1-type (type-of exp1 tenv)))
    (type-of body
      (extend-tenv var exp1-type tenv))))

(proc-exp (var var-type body)
  (let ((result-type
          (type-of body
            (extend-tenv var var-type tenv))))
    (proc-type var-type result-type)))
```

| 規則裡的 | 程式裡的 |
|---|---|
| `[var=t1]tenv`（let） | `(extend-tenv var exp1-type tenv)`，t1 由 `exp1` 算出 |
| `[var=tvar]tenv`（proc） | `(extend-tenv var var-type tenv)`，tvar 來自語法樹 |
| `(tvar → tres)` | `(proc-type var-type result-type)` |

p.240 說 t1 在程式裡找不到；CHECKED 的 proc 分支，直接拿語法樹裡的 `var-type`。

---

<!-- _class: small -->

# call-exp 會報哪兩種錯？（Figure 7.2，p.245）

```scheme
(call-exp (rator rand)
  (let ((rator-type (type-of rator tenv))
        (rand-type (type-of rand tenv)))
    (cases type rator-type
      (proc-type (arg-type result-type)
        (begin
          (check-equal-type! arg-type rand-type rand)
          result-type))
      (else
        (report-rator-not-a-proc-type rator-type rator)))))
```

| 規則的要求 | 不成立時 |
|---|---|
| rator 的型別是 `(t1 → t2)` 的形狀 | `report-rator-not-a-proc-type` |
| rand 的型別等於 t1 | `check-equal-type!`，怪罪 `rand` |

```
> (check "(3 4)")
; type-of-expression: Rator not a proc type:
; #(struct:const-exp 3)
; had rator type int
> (check "(proc (x : int) x zero?(0))")
; check-equal-type!: Types didn't match: int != bool in
; #(struct:zero?-exp #(struct:const-exp 0))
> (run "(proc (x : int) x zero?(0))")
(bool-val #t)
```

---

<!-- _class: small -->

# letrec 的程式（Figure 7.3，p.246）

checker.scm 第 95–107 行：

```scheme
 95  (letrec-exp (p-result-type p-name b-var b-var-type p-body
 96                letrec-body)
 97    (let ((tenv-for-letrec-body
 98            (extend-tenv p-name
 99              (proc-type b-var-type p-result-type)
100              tenv)))
101      (let ((p-body-type
102              (type-of p-body
103                (extend-tenv b-var b-var-type
104                  tenv-for-letrec-body))))
105        (check-equal-type!
106          p-body-type p-result-type p-body)
107        (type-of letrec-body tenv-for-letrec-body))))
```

`tenv-for-letrec-body` 就是第 17 張的 tenv_letrec-body；第 103–104 行建出的，就是 tenv_proc-body。

---

<!-- _class: small -->

# 停下來想：letrec 規則的每一部分在第幾行？

```
(type-of eproc-body [var=tvar][p=(tvar → tres)]tenv) = tres
(type-of eletrec-body [p=(tvar → tres)]tenv) = t
------------------------------------------------------------------------
(type-of letrec tres p (var : tvar) = eproc-body in eletrec-body tenv) = t
```

對照第 33 張，填出行號：

| 規則裡的 | checker.scm 第幾行 |
|---|---|
| `[p=(tvar → tres)]tenv` | ？ |
| `[var=tvar][p=(tvar → tres)]tenv` | ？ |
| 第一個前提的 `type-of eproc-body ...` | ？ |
| 第一個前提的 `= tres` | ？ |
| 第二個前提 | ？ |
| 結論的 t | ？ |

**停下來想**（4 分鐘）。

---

<!-- _class: small -->

# 對答案：letrec 規則與程式的行號

| 規則裡的 | checker.scm 第幾行 | 程式 |
|---|---|---|
| `[p=(tvar → tres)]tenv` | 97–100 | `tenv-for-letrec-body` |
| `[var=tvar][p=(tvar → tres)]tenv` | 103–104 | `(extend-tenv b-var b-var-type tenv-for-letrec-body)` |
| 第一個前提的 `type-of eproc-body ...` | 101–104 | `p-body-type` |
| 第一個前提的 `= tres` | 105–106 | `(check-equal-type! p-body-type p-result-type p-body)` |
| 第二個前提 | 107 | `(type-of letrec-body tenv-for-letrec-body)` |
| 結論的 t | 107 | 同一行的回傳值 |

---

<!-- _class: small -->

# `type-of` 和 `value-of` 並排

| 分支 | `value-of`（chapter3/letrec-lang/interp.scm） | `type-of`（chapter7/checked/checker.scm） |
|---|---|---|
| if | 第 54–58 行：先算 `exp1`，只算一個分支 | 第 61–67 行：三個子運算式都算 |
| let | 第 61–64 行：`extend-env` | 第 70–73 行：`extend-tenv` |
| proc | 第 66–67 行：打包成 closure，不碰 body | 第 76–80 行：在 `extend-tenv` 裡檢查 body |
| call | 第 69–72 行：`apply-procedure` 執行 body | 第 83–92 行：只看 rator 的型別，不進 body |
| letrec | 第 74–76 行：`extend-env-rec` | 第 95–107 行：`extend-tenv` 兩次 |

我的解讀：`type-of` 對每個子運算式只走一次。proc 的 body 在定義處檢查一次，呼叫時不再檢查；所以程式不終止，檢查仍會結束：

```
> (check "letrec int f (x : int) = (f -(x,-1)) in (f 1)")
'int
```

這個程式就是 class-13 第 9 張的第 11 個程式，加上標註；`run` 它不會結束。

---

# 停下來想：Exercise 7.7 [★]（p.243）

p.243（改寫）：修改檢查 if-exp 的程式，讓測試式不是 boolean 時，不檢查另外兩個運算式。舉一個運算式，新版的 checker 和舊版行為不同。

```scheme
(if-exp (exp1 exp2 exp3)
  (let ((ty1 (type-of exp1 tenv))
        (ty2 (type-of exp2 tenv))
        (ty3 (type-of exp3 tenv)))
    (check-equal-type! ty1 (bool-type) exp1)
    (check-equal-type! ty2 ty3 exp)
    ty2))
```

**停下來想**（5 分鐘）：

1. 改哪幾行？
2. 什麼樣的運算式會讓兩版行為不同？有沒有一個程式，一版接受、另一版拒絕？

---

<!-- _class: small -->

# 對答案：Exercise 7.7（我的解答）

```scheme
(if-exp (exp1 exp2 exp3)
  (let ((ty1 (type-of exp1 tenv)))
    (check-equal-type! ty1 (bool-type) exp1)
    (let ((ty2 (type-of exp2 tenv))
          (ty3 (type-of exp3 tenv)))
      (check-equal-type! ty2 ty3 exp)
      ty2)))
```

| 運算式 | 舊版 `check` | 新版 `check` |
|---|---|---|
| `if 1 then y else 2` | `apply-tenv: Unbound variable y` | 怪罪 `1`：`int != bool` |
| `if 1 then -(zero?(0),1) else 2` | 怪罪 `zero?(0)`：`bool != int` | 怪罪 `1`：`int != bool` |
| `if zero?(0) then 1 else zero?(1)` | 怪罪 if 運算式本身 | 怪罪 if 運算式本身 |

我的解讀：兩版接受的程式相同。測試式是 bool 時，兩版都檢查三個子運算式；不是 bool 時，兩版都拒絕。行為不同的地方，在先報哪一個錯。

<!-- 講者備註：這份解答是我的，課本沒有附答案。表格是把 checker.scm 複製一份、照上面改完後實際跑的結果。 -->

---

<!-- _class: small -->

# 習題 7.5–7.11 各要擴充什麼？（pp.243–248）

| 題號 | 難度 | 頁碼 | 內容 | 用到 |
|---|---|---|---|---|
| 7.5 | ★★ | p.243 | 多個 let 宣告、多參數 procedure、多個 letrec 宣告；新增型別 `(t1 * t2 * ... * tn -> t)` | — |
| 7.6 | ★ | p.243 | 處理 assignment | §4.3 |
| 7.7 | ★ | p.243 | if 的測試式不是 boolean 時，不檢查其他運算式 | 第 37、38 張 |
| 7.8 | ★★ | pp.243、246 | 加入 `pairof` 型別、`newpair`、`unpair`，規則在 p.246 | Exercise 3.18 的 unpair |
| 7.9 | ★★ | p.247 | 加入 `listof` 型別、`list`、`cons`、`null?`、`emptylist`；自己寫 `car`、`cdr` 的規則 | Exercise 3.9 |
| 7.10 | ★★ | p.248 | 處理 EXPLICIT-REFS：`refto t`、`void`；寫出 `newref`、`deref`、`setref` 的規則 | §4.2 |
| 7.11 | ★★ | p.248 | 處理 MUTABLE-PAIRS | §4.4 |

---

# Exercise 7.9 的兩個問題（p.247）

p.247（改寫）：`car`、`cdr` 的規則要保證它們作用在 list 上，但不要保證 list 非空。

```
(type-of emptylist[t] tenv) = listof t
```

課本的兩個問題：

1. 為什麼要求規則保證 list 非空，是不合理的？
2. `emptylist` 為什麼需要型別參數？

這兩題是 HW6 的第 2 題。想第 1 題時，可以回去看 class-13 第 7 張：p.234 把哪些失敗排除在 safety 之外？

---

<!-- _class: small -->

# Exercise 7.10 的 `void` 在保護什麼？（p.248）

p.248（改寫）：`void` 是 `setref` 回傳值的型別。對 `void` 的值不能做任何運算，所以 `setref` 回傳什麼都沒有關係。課本說，這是型別當作資訊隱藏 (information-hiding) 機制的一個例子。

在 chapter4/explicit-refs 跑：

```
> (run "let r = newref(1) in -(setref(r,2), 1)")
(num-val 22)
```

p.109：`setref` 回傳 23，這是任意的選擇。

| | `-(setref(r,2), 1)` |
|---|---|
| EXPLICIT-REFS（沒有型別） | 得到 22，程式用到了 23 這個任意的值 |
| 加上 Exercise 7.10 的型別（我的解讀） | `setref(r,2) : void`，diff 規則要求 `int`，拒絕 |

為什麼要在意（我的解讀）：程式拿不到 23，實作就可以改回傳別的值，不影響任何被接受的程式。

---

<!-- _class: small -->

# HW6：兩題課本習題與一題自訂題

| 題號 | 難度 | 頁碼 | 內容 |
|---|---|---|---|
| 7.8 | ★★ | pp.243、246 | 實作 `pairof`、`newpair`、`unpair`：checker 與直譯器都要改 |
| 7.9 的兩個問題 | ★★ | p.247 | 只回答第 40 張的兩個問題，不用實作 |
| 自訂題 | — | — | 找出一份 checker 不健全的地方（下一張） |

**繳交期限：week 16 上課前，上傳 Moodle。**

硬性要求同 HW3（contract、先寫規格、自己補測試）。

- 7.8：以 repo 的 `chapter7/checked` 為底；`type-to-external-form` 對 pair 型別產生 `(pairof t1 t2)`（p.246）；每條新規則至少一個 `check` 接受、一個 `check` 拒絕的測試，接受的那個也要 `run`
- 7.9：每題用一個 CHECKED 程式說明

---

<!-- _class: small -->

# HW6 自訂題：`check` 接受、`run` 卻發生 type error

Moodle 上的 `hw6-checker.scm` 是 chapter7/checked 的 `checker.scm` 改了一處，letrec 分支以外的程式沒有改。用它替換 `checker.scm`。

1. 找出改了哪裡；用 p.242 的記號，寫出這份 checker 實際用的 letrec 規則
2. 寫一個 CHECKED 程式：這份 checker 的 `check` 接受，`run` 發生 type error。附上兩個輸出
3. 修正 checker；說明修正後，這個程式違反規則的哪一個前提
4. 用 `(check-all)` 跑 repo 的 tests.scm，結果是什麼？為什麼這些測試沒有抓到？

| 小題 | 繳交 |
|---|---|
| 1 | 規則（文字） |
| 2 | 程式、`check` 與 `run` 的輸出 |
| 3 | 修正後的 checker.scm、說明 |
| 4 | `check-all` 的輸出、說明 |

拿 repo 的原版做 diff，就找得到第 1 小題的答案；評分看第 2–4 小題。

<!-- 講者備註：hw6-checker.scm 刪掉了第 105–106 行的 (check-equal-type! p-body-type p-result-type p-body)，也就是不比對 tres。我實測：repo 的 (check-all) 與 (run-all) 都印 no bugs found。參考反例：letrec int f (x : int) = zero?(x) in -((f 0),1)，這份 checker 回傳 int，run 報 Looking for a num, found #(struct:bool-val #t)；原版 checker 怪罪 zero?(x)（第 24 張）。第 4 小題連到 class-08：測試只檢查被執行到的分支，tests.scm 也只放了作者想到的程式。 -->

---

<!-- _class: small -->

# 課外補充：Clojure 的 `^String` 算不算標註？

```clojure
;; hint.clj
(set! *warn-on-reflection* true)
(defn len1 [s] (.length s))
(defn len2 [^String s] (.length s))
(println (len1 "abc") (len2 "abc"))
(println (len2 42))
```

```
$ java -cp clojure-1.12.0.jar:... clojure.main hint.clj
Reflection warning, /tmp/clj/hint.clj:2:16 - reference to field length can't be resolved.
3 3
Execution error (ClassCastException) at user/len2 (hint.clj:3).
class java.lang.Long cannot be cast to class java.lang.String ...

$ clj-kondo --lint hint2.clj     ; (defn g [] (len2 42))
hint2.clj:3:18: error: Expected: string or nil, received: positive integer.
```

| 誰讀 `^String` | 做什麼 | 對照 CHECKED |
|---|---|---|
| Clojure compiler | 編譯 `.length` 時不用 reflection | — |
| 執行時 | 傳入 42，丟 ClassCastException | `run` 不看標註（第 11 張） |
| clj-kondo | 不執行，看到 42 不是 string 就報錯 | `check` |

<!-- 講者備註：hint2.clj 的內容是 (ns hint2) (defn len2 [^String s] (.length s)) (defn g [] (len2 42))。java 的 classpath 省略了 spec.alpha-0.5.238.jar 與 core.specs.alpha-0.4.74.jar；ClassCastException 的訊息只節錄前半。clj-kondo 說 "string or nil"：type hint 允許 nil，CHECKED 的型別沒有 nil 這種值。三種讀法的分類是我的解讀。 -->

---

<!-- _class: small -->

# 本日結論

1. **CHECKED 的標註**：proc 規則的 t1 在程式裡找不到，CHECKED 讓程式設計師寫出每個綁定變數的型別；letrec 另外寫結果型別；`run` 不看標註（pp.240–241，第 3–11 張）
2. **letrec 規則**：eletrec-body 看得到 p；eproc-body 看得到 var 與 p；body 的型別要等於宣告的 tres（p.242，第 14–24 張）
3. **`check-equal-type!`**：比較型別，不相等時怪罪第三個引數；呼叫它只為了 effect（pp.242–243，第 25、26 張）
4. **規則轉寫成程式**：每個前提一行 `check-equal-type!`，結論是回傳值；tenv 的擴充對應 `extend-tenv`（pp.243–246，第 29–35 張）
5. **`type-of` 與 `value-of` 同結構**：差在 if 走幾個分支、proc 的 body 何時被處理；程式不終止，檢查仍會結束。這是我的解讀（第 36 張）
6. **Exercise 7.7**：測試式不是 bool 時跳過分支，改變的是先報哪個錯。這是我的解讀（第 37、38 張）
7. **HW6**：Exercise 7.8、7.9 的兩個問題，與一份不健全的 checker（第 42、43 張）

---

# 下週：期末複習

- 複習這學期教過的範圍：Ch1–Ch4、§7.1–7.3
- HW6 有問題，下週上課可以先問

---

<!-- _class: lead -->

# 問題時間

1. Email: laurence@replware.dev
2. Office Hour: 週四下午 1:00~2:00，請先跟我約
3. 助教：邵振皓 (負責改作業、監考)
4. 助教信箱：114971020@nccu.edu.tw
5. 作業一律上傳 Moodle
