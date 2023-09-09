(require 'ert)
(require 'transducers)

(ert-deftest transducers-collecting ()
  (should (equal '() (t-transduce #'t-pass #'t-cons '())))
  (should (equal [] (t-transduce #'t-pass #'t-vector [])))
  (should (equal "hello" (t-transduce #'t-pass #'t-string "hello"))))

(ert-deftest transducers-counting ()
  (should (= 0 (t-transduce #'t-pass #'t-count '())))
  (should (= 3 (t-transduce #'t-pass #'t-count '(1 2 3))))
  (should (= 0 (t-transduce #'t-pass #'t-count [])))
  (should (= 3 (t-transduce #'t-pass #'t-count [1 2 3])))
  (should (= 0 (t-transduce #'t-pass #'t-count "")))
  (should (= 3 (t-transduce #'t-pass #'t-count "cat"))))

(ert-deftest transducers-predicates ()
  (should (not (t-transduce #'t-pass (t-anyp #'cl-evenp) '(1 3 5 7 9))))
  (should (t-transduce #'t-pass (t-anyp #'cl-evenp) '(1 3 5 7 9 2)))
  (should (t-transduce #'t-pass (t-allp #'cl-oddp) '(1 3 5 7 9)))
  (should (not (t-transduce #'t-pass (t-allp #'cl-oddp) '(1 3 5 7 9 2)))))

(ert-deftest transducers-first-last ()
  (should (= 7  (t-transduce (t-filter #'cl-oddp) #'t-first '(2 4 6 7 10))))
  (should-error (t-transduce (t-filter #'cl-oddp) #'t-first '(2 4 6 10)))
  (should (= 10 (t-transduce #'t-pass #'t-last '(2 4 6 7 10))))
  (should-error (t-transduce #'t-pass #'t-last '())))

(ert-deftest transducers-folding-finding ()
  (should (= 1000 (t-transduce #'t-pass (t-fold #'max 0) '(1 2 3 4 1000 5 6))))
  (should (= 6    (t-transduce #'t-pass (t-find #'cl-evenp) '(1 3 5 6 9))))
  (should (= 3.5  (t-transduce #'t-pass #'t-average '(1 2 3 4 5 6))))
  (should-error   (t-transduce (t-filter #'cl-evenp) #'t-average '(1 3 5))))

(ert-deftest transducers-map ()
  (should (equal '() (t-transduce (t-map #'1+) #'t-cons '())))
  (should (equal '(2 3 4) (t-transduce (t-map #'1+) #'t-cons '(1 2 3))))
  (should (equal [2 3 4] (t-transduce (t-map #'1+) #'t-vector '(1 2 3))))
  (should (string-equal "HELLO" (t-transduce (t-map #'upcase) #'t-string "hello"))))

;; (ert-deftest transducers-zip ()
;;   (should (equal '(5 7 9)  (t-transduce (t-map #'+) #'t-cons '(1 2 3) '(4 5 6 7))))
;;   (should (equal '(6 8 10) (t-transduce (t-map #'+) #'t-cons '(1 2 3 4) '(5 6 7))))
;;   (should (equal [5 7 9]   (t-transduce (t-map #'+) #'t-vector [1 2 3] [4 5 6 7])))
;;   (should (equal [6 8 10]  (t-transduce (t-map #'+) #'t-vector [1 2 3 4] [5 6 7]))))

(ert-deftest transducers-filter ()
  (should (equal '(2 4)   (t-transduce (t-filter #'cl-evenp) #'t-cons '(1 2 3 4 5))))
  (should (equal '(2 5 8) (t-transduce (t-filter-map #'car) #'t-cons '(() (2 3) () (5 6) () (8 9)))))
  (should (equal '(1 2 3 "abc") (t-transduce #'t-unique #'t-cons '(1 2 1 3 2 1 2 "abc"))))
  (should (equal '(1 2 3 4 3) (t-transduce #'t-dedup #'t-cons '(1 1 1 2 2 2 3 3 3 4 3 3)))))

(ert-deftest transducers-taking-dropping ()
  (should (equal '() (t-transduce (t-drop 100) #'t-cons '(1 2 3 4 5))))
  (should (equal '(4 5) (t-transduce (t-drop 3) #'t-cons '(1 2 3 4 5))))
  (should (equal '(7 8 9) (t-transduce (t-drop-while #'cl-evenp) #'t-cons '(2 4 6 7 8 9))))
  (should (equal '() (t-transduce (t-take 0) #'t-cons '(1 2 3 4 5))))
  (should (equal '(1 2 3) (t-transduce (t-take 3) #'t-cons '(1 2 3 4 5))))
  (should (equal '() (t-transduce (t-take-while #'cl-evenp) #'t-cons '(1))))
  (should (equal '(2 4 6 8) (t-transduce (t-take-while #'cl-evenp) #'t-cons '(2 4 6 8 9 2)))))

(ert-deftest transducers-flattening ()
  (should (equal '(1 2 3 4 5 6 7 8 9)
                 (t-transduce #'t-concatenate #'t-cons '((1 2 3) (4 5 6) (7 8 9)))))
  (should (equal '(1 2 3 0 4 5 6 0 7 8 9 0)
                 (t-transduce #'t-flatten #'t-cons '((1 2 3) 0 (4 (5) 6) 0 (7 8 9) 0)))))

(ert-deftest transducers-pairing ()
  (should (equal '((1 2 3) (4 5))
                 (t-transduce (t-segment 3) #'t-cons '(1 2 3 4 5))))
  (should (equal '((1 2 3) (2 3 4) (3 4 5))
                 (t-transduce (t-window 3) #'t-cons '(1 2 3 4 5))))
  (should (equal '((2 4 6) (7 9 1) (2 4 6) (3))
                 (t-transduce (t-group-by #'cl-evenp) #'t-cons '(2 4 6 7 9 1 2 4 6 3)))))

(ert-deftest transducers-other ()
  (should (equal '(1 3 5 7 9) (t-transduce (t-step 1) #'t-cons '(1 3 5 7 9))))
  (should (equal '(1 3 5 7 9) (t-transduce (t-step 2) #'t-cons '(1 2 3 4 5 6 7 8 9))))
  (should (equal '(1) (t-transduce (t-step 100) #'t-cons '(1 2 3 4 5 6 7 8 9))))
  (should (equal '() (t-transduce (t-intersperse 0) #'t-cons '())))
  (should (equal '(1 0 2 0 3) (t-transduce (t-intersperse 0) #'t-cons '(1 2 3))))
  (should (equal '((0 . "a") (1 . "b") (2 . "c"))
                 (t-transduce #'t-enumerate #'t-cons '("a" "b" "c"))))
  (should (equal '(0 1 3 6 10)
                 (t-transduce (t-scan #'+ 0) #'t-cons '(1 2 3 4))))
  (should (equal '(0 1)
                 (t-transduce (t-comp (t-scan #'+ 0) (t-take 2))
                              #'t-cons '(1 2 3 4))))
  (should (equal '(hi 11 12)
                 (t-transduce (t-comp (t-filter (lambda (n) (> n 10)))
                                      (t-once 'hi)
                                      (t-take 3))
                              #'t-cons (t-ints 1)))))

(ert-deftest transducers-composition ()
  (should (equal '(12 20 30)
                 (t-transduce (t-comp
                                #'t-enumerate
                                (t-map (lambda (pair) (* (car pair) (cdr pair))))
                                (t-filter #'cl-evenp)
                                (t-drop 3)
                                (t-take 3))
                              #'t-cons
                              '(1 2 3 4 5 6 7 8 9 10)))))

(ert-deftest transducers-generators ()
  (should (equal '() (t-transduce (t-take 0) #'t-cons (t-ints 0))))
  (should (equal '(0 1 2 3) (t-transduce (t-take 4) #'t-cons (t-ints 0))))
  (should (equal '(0 -1 -2 -3) (t-transduce (t-take 4) #'t-cons (t-ints 0 :step -1))))
  (should (equal '(1 2 3 1 2 3 1) (t-transduce (t-take 7) #'t-cons (t-cycle '(1 2 3)))))
  (should (equal '(1 2 3 1 2 3 1) (t-transduce (t-take 7) #'t-cons (t-cycle [1 2 3]))))
  (should (equal "hellohe" (t-transduce (t-take 7) #'t-string (t-cycle "hello"))))
  (should (equal '() (t-transduce (t-take 7) #'t-cons (t-cycle '())))))

(ert-deftest transducers-csv ()
  (should (equal '("Name,Age" "Colin,35" "Tamayo,26")
                 (t-transduce (t-comp #'t-from-csv (t-into-csv '("Name" "Age")))
                              #'t-cons '("Name,Age,Hair" "Colin,35,Blond" "Tamayo,26,Black")))))
