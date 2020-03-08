augroup lightline_languageclient
    au!
    au User LanguageClientStarted call lightline#languageclient#onStarted()
    au User LanguageClientStopped call lightline#languageclient#onStopped()
    au User LanguageClientDiagnosticsChanged call lightline#languageclient#onChanged()
    au BufEnter * call lightline#languageclient#update()
augroup END
