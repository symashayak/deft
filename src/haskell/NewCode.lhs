\begin{code}
{-# LANGUAGE PatternGuards #-}

module NewCode (module Statement,
                module Expression,
                defineFunctional )
    where

import Statement
import Expression
import qualified Data.Set as Set

functionCode :: String -> String -> [(String, String)] -> String -> String
functionCode "" "" [] "" = ""
functionCode "" "" (x:xs) "" = if xs == []
                               then fst x ++ " " ++ snd x
                               else fst x ++ " " ++ snd x ++ ", " ++ functionCode "" "" xs ""
functionCode n t a b = t ++ " " ++ n ++ "(" ++ functionCode "" "" a "" ++ ") const {\n" ++ b ++ "}\n"

scalarClass :: Expression Scalar -> [String] -> String -> String
scalarClass e arg n =
  unlines
  ["class " ++ n ++ " : public Functional {",
   "public:",
   "" ++ n ++ codeA arg ++ "  {",
   "}",
   "",
   functionCode "energy" "double" [("const Vector", "&x")]
      (unlines $
       ["\tint sofar = 0;"] ++
       map createInput (inputs e) ++
       [newcodeStatements (fst energy),
       "\treturn " ++ newcode (snd energy) ++ ";\n"]),
   functionCode "energy_per_volume" "double" [("const Vector", "&x")]
      (unlines $
       ["\tint sofar = 0;"] ++
       map createInput (inputs $ makeHomogeneous e) ++
       [newcodeStatements (fst energy_per_volume),
       "\treturn " ++ newcode (snd energy_per_volume) ++ ";\n"]),
   functionCode "denergy_per_volume_dx" "double" [("const Vector", "&x")]
    (newcodeStatements (fst denergy_per_volume_dx) ++
     "\treturn " ++ newcode (snd denergy_per_volume_dx) ++ ";\n"),
   functionCode "grad" "Vector" [("const Vector", "&x")] (evalv grade),
   functionCode "printme" "void" [("const char *", "prefix")]
      (unlines $ map printEnergy (Set.toList (findNamedScalars e))),
   functionCode "createInput" "Vector" (codeInputArgs (inputs e))
      (unlines $ ["\tconst int newsize = " ++
                  xxx (map getsize $ inputs e),
                  "\tVector out(newsize);",
                  "\tint sofar = 0;"] ++
                 map (\x -> concat ["\tout.slice(sofar,", getsize x, ") = ",nameE x,";\n\t",
                                    "sofar += ",getsize x,";"]) (inputs e) ++
                 ["\treturn out;"]),
  "private:",
  ""++ codeArgInit arg ++ codeMutableData (Set.toList $ findNamedScalars e)  ++"}; // End of " ++ n ++ " class",
  "\t// Total " ++ (show $ (countFFT (fst energy) + countFFT (fst grade))) ++ " Fourier transform used.",
  "\t// peak memory used: " ++ (show $ maximum $ map peakMem [fst energy, fst grade])
  ]
    where
      getsize (ES _) = "1"
      getsize ee = nameE ee ++ ".get_size()"
      createInput ee@(E3 _) = "\tVector " ++ nameE ee ++ " = x.slice(sofar,3); sofar += 3;"
      createInput ee@(ES _) = "\tdouble " ++ nameE ee ++ " = x[sofar]; sofar += 1;"
      createInput ee@(ER _) = "\tVector " ++ nameE ee ++ " = x.slice(sofar,Nx*Ny*Nz); sofar += Nx*Ny*Nz;"
      createInput ee = error ("unhandled type in NewCode scalarClass: " ++ show ee)
      inputs x = findOrderedInputs x -- Set.toList $ findInputs x -- 
      maxlen = 1 + maximum (map length $ "total energy" : Set.toList (findNamedScalars e))
      pad nn s | nn <= length s = s
      pad nn s = ' ' : pad (nn-1) s
      printEnergy v = "\tprintf(\"%s" ++ pad maxlen v ++ " =\", prefix);\n" ++
                      "\tprint_double(\"\", " ++ v ++ ");\n" ++
                      "\tprintf(\"\\n\");"
      energy = codex e
      energy_per_volume = codex (makeHomogeneous e)
      denergy_per_volume_dx = codex (derive (s_var "x" :: Expression Scalar) 1 $ makeHomogeneous e)
      grade = codex (grad "n" e)
      evalv (_,0) = unlines["\tVector output(x.get_size());",
                            "\tfor (int i=0;i<x.get_size();i++) {",
                            "\t\toutput[i] = 0;",
                            "\t}",
                            "\treturn output;"]
      evalv (st,ee) = unlines ("\tint sofar = 0;" : map createInput (inputs e) ++
                               [newcodeStatements (st ++ [Initialize (ER $ r_var "output"),
                                                          Assign (ER $ r_var "output") (mkExprn ee)]) ++
                                "\treturn output;"])
      codex :: Type a => Expression a -> ([Statement], Expression a)
      codex x = (init $ reuseVar $ freeVectors $ st ++ [Assign (mkExprn e') (mkExprn e')], e')
        where (st0, e') = simp2 (factorize $ joinFFTs x)
              st = filter (not . isns) st0
              isns (Initialize (ES (Var _ _ s _ Nothing))) = Set.member s ns
              isns _ = False
              ns = findNamedScalars e
      codeA [] = "()"
      codeA a = "(" ++ foldl1 (\x y -> x ++ ", " ++ y ) (map (\x -> "double " ++ x ++ "_arg") a) ++ ") : " ++ foldl1 (\x y -> x ++ ", " ++ y) (map (\x -> x ++ "(" ++ x ++ "_arg)") a)
      codeInputArgs = map (\x -> (newdeclareE x, nameE x))
      codeArgInit a = unlines $ map (\x -> "\tdouble " ++ x ++ ";") a
      codeMutableData a = unlines $ map (\x -> "\tmutable double " ++ x ++ ";") a
      xxx [] = ""
      xxx iii = foldl1 (\x y -> x ++ " + " ++ y) iii ++";"

defineFunctional :: Expression Scalar -> [String] -> String -> String
defineFunctional e arg n =
  unlines ["// -*- mode: C++; -*-",
           "",
           "#include \"new/Functional.h\"",
           "#include \"utilities.h\"",
           "#include \"handymath.h\"",
           "",
           "",
           scalarClass e arg n]
\end{code}