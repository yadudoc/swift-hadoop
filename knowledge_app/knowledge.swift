type file;
type script;

app (file tf, file vocab, file err) calculate_tf (script calc_tf, string dir, file monthly)
{
    python @calc_tf dir 1 0 @tf @vocab stderr=@err;
}

app (file o, file err) merger (script merge, file[] monthly)
{
    python_local @merge @o @filenames(monthly) stderr=@err;
}

app (file tfidf, file err) calculate_idf (script calc, file vocab, file tf, string key)
{
    python @calc 1 0 @vocab @tf key stdout=@tfidf stderr=@err;
}

app (file final, file err) scrounge (script s, file[] i)
{
    bash @s @i stdout=@final stderr=@err;
}

string dir = (@arg("data","./12_monthly_abstracts-abridged"));

// First map stage
script calc_tf <"calculate_tf_scores.py">;
file[] all_monthly_docs <filesys_mapper; location=dir, suffix=".txt">;
file[] monthly_tf ;
file[] monthly_vocab ;
tracef("File : %s\n", @filename(all_monthly_docs[1]));
foreach monthly_doc,index in all_monthly_docs {
    tracef("File : %s\n", @filename(monthly_doc));
    file tf    <single_file_mapper; file=@strcat(@monthly_doc, ".tf")>;
    file vocab <single_file_mapper; file=@strcat(@monthly_doc, ".vocab")>;
    file err   <single_file_mapper; file=@strcat(@monthly_doc, ".err")>;
    (tf, vocab, err) = calculate_tf (calc_tf, dir, monthly_doc);
    monthly_tf[index]    = tf;
    monthly_vocab[index] = vocab;
}

// First reduce stage
script merge   <"merge.py">;
file tf_err    <"tf_merge.err">;
file vocab_err <"vocab_merge.err">;
file all_tf    <single_file_mapper; file=@strcat(dir, "/intermediate/TF_all.tf")>;
file all_vocab <single_file_mapper; file=@strcat(dir, "/intermediate/Vocab_all.vocab")>;
(all_tf, tf_err)       = merger (merge, monthly_tf );
(all_vocab, vocab_err) = merger (merge, monthly_vocab );

// Second map stage
file tfidf[];
script calc_idf <"calculate_idf_scores.py">;
foreach monthly_doc, index in all_monthly_docs {
    file tfidf_t <single_file_mapper; file=@strcat(@monthly_doc, ".tfidf")>;
    file err     <single_file_mapper; file=@strcat(@monthly_doc, ".tfidf_err")>;
    (tfidf_t, err) = calculate_idf (calc_idf, all_vocab, all_tf, @filename(monthly_doc));
    tfidf[index] = tfidf_t;
}

// Second and last reduce stage
//tracef("Filenames : %s", @filename(tfidf[0]));
script concat <"concat.sh">;
file final <"final.results">;
file f_err <"final.errors">;
(final, f_err) = scrounge (concat, tfidf);

