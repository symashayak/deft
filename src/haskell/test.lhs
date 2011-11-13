\begin{code}
import CodeGen
import Prelude hiding ((**))
import Test.HUnit

gradTests :: Test
gradTests = TestList [test_grad "foo" (integrate $ foo*foo) (dV*2*foo),
                      test_grad "foo" (integrate $ foo**2) (dV*2*foo),
                      test_grad "x" (integrate $ x * ifft (5*fft s)) (dV*5*s),
                      test_grad "x" (integrate $ ifft (2 * fft x)) (dV*2)]
  where test_grad v e g = TestCase $ assertEqual (show g) g (grad v e)
        foo = r_var "foo"
        dV = s_var "dV"
        x = r_var "x"
        s = s_var "s"

showTests :: Test
showTests = TestList [show_test "x[i]" x,
                      show_test "x[i]*x[i]" (x**2),
                      show_test "x[i]*x[i]*(x[i]*x[i])" (x**4)]
  where show_test str e = TestCase $ assertEqual str str (show e)
        x = r_var "x"

showStatements :: Test
showStatements = TestList [ss "for (int i=0; i<gd.NxNyNz; i++) {    \nx = 5.0;\n}\n" 
                               ("x" := (5 :: Expression RealSpace)),
                           ss "for (int i=0; i<gd.NxNyNz; i++) {    \nx[i] = y[i];\n}\n" 
                               ("x" := y),
                           ss "for (int i=0; i<gd.NxNyNz; i++) {    \nx[i] = y[i];\n}\n\nGrid a(gd);\nfor (int i=0; i<gd.NxNyNz; i++) {    \na[i] := y[i];\n}\n" $ 
                           do "x" := y
                              "a" :?= y]
  where ss str st = TestCase $ assertEqual str str (show st)
        y = r_var "y"

main :: IO ()
main = do c <- runTestTT $ TestList [ gradTests, showTests, showStatements ]
          if failures c > 0
            then fail $ "Failed " ++ show (failures c) ++ " tests."
            else putStrLn "All tests passed!"
\end{code}