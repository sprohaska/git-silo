test_expect_success \
"setup user" \
'
    git config --global user.name "A U Thor" &&
    git config --global user.email "author@example.com"
'
