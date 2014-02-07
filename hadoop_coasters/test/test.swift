type file;

app (file o, file e) test (){
    python "-c" "print(\"Hello\")" stdout=@o stderr=@e;
}

app (file o, file e) test2 (file f){
    cat @f stdout=@o stderr=@e;
}

file out <"hi.out">;
file err <"hi.err">;
file out2 <"cat.out">;
file err2 <"cat.err">;

(out, err)   = test();
(out2, err2) = test2(out);
