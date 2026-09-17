;; class-02 補充投影片「同一個 nil，兩種錯誤訊息」的 REPL 驗證腳本
;;
;; 用法：在 REPL 中逐個 form 求值（不要整檔 load，後半段會丟 exception）
;;   clj  （JVM Clojure 1.12，已內建 clojure.spec）
;;   注意：不要用 babashka (bb)，錯誤訊息與 spec 的行為都不同，會對不上投影片

(ns nil-context
  (:require [clojure.string :as str]
            [clojure.spec.alpha :as s]
            [clojure.spec.test.alpha :as stest]))

;; ---------------------------------------------------------------------------
;; 1. 資料與函式

(def users [{:name "Amy" :email "amy@nccu.edu.tw"}
            {:name "Ben"}                              ; 忘了填 email
            {:name "Cat" :email "cat@gmail.com"}])

(defn domain-of [user] (second (str/split (:email user) #"@")))

;; 正常的資料沒問題
(comment
  (domain-of {:name "Amy" :email "amy@nccu.edu.tw"})
  ;=> "nccu.edu.tw"
  )

;; ---------------------------------------------------------------------------
;; 2. 沒有 spec

(comment
  (frequencies (map domain-of users))
  ;; Execution error (NullPointerException) at java.util.regex.Matcher/getTextLength (Matcher.java:1808).
  ;; Cannot invoke "java.lang.CharSequence.length()" because "this.text" is null

  ;; 對照：不包 frequencies，錯誤延到「印出結果」時才發生
  (map domain-of users)
  ;; Error printing return value (NullPointerException) at java.util.regex.Matcher/getTextLength (Matcher.java:1808).
  ;; Cannot invoke "java.lang.CharSequence.length()" because "this.text" is null
  )

;; ---------------------------------------------------------------------------
;; 3. 加上 spec

(s/def ::email string?)
(s/fdef domain-of :args (s/cat :user (s/keys :req-un [::email])))

(comment
  ;; 必須先 instrument，fdef 的 :args 才會在呼叫時被檢查
  (stest/instrument `domain-of)
  ;=> [nil-context/domain-of]

  (frequencies (map domain-of users))
  ;; Execution error - invalid arguments to nil-context/domain-of at (...).
  ;; {:name "Ben"} - failed: (contains? % :email) at: [:user]

  ;; exception 裡帶的 context 也可以直接取出來
  (-> *e ex-data ::s/problems first (select-keys [:val :path]))
  ;=> {:val {:name "Ben"}, :path [:user]}

  ;; 還原
  (stest/unstrument `domain-of)
  )
