type file;

app (file final, file err) scrounge (file[] i)
{
    cat @i stdout=@final stderr=@err;
}


// Reduce stage ? TODO: Done manually now.
file tfidf[] <filesys_mapper; location="12_monthly_abstracts-abridged/", suffix=".txt">;
file final <"final.results.out">;
file f_err <"final.errors">;

tracef("Files : %s", @filename(tfidf[0]));
(final, f_err) = scrounge (tfidf);
