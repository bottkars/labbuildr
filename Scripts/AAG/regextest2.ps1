#Here’s the result.  Tidy and (hopefully!) comprehensible :-)

${250-255}=’25[0-5]‘   # Matches 3 digit numbers between 250 and 255
${200-249}=’2[0-4]\d’  # Matches 3 digit numbers between 200 and 249
${0-199}=‘[01]?\d\d?’  # Matches 1, 2 or 3 digit numbers between 0 and 199

$Octet=“( ${250-255} | ${200-249} | ${0-199} )”

$IPv4=@”
(?x) ^

$Octet (\.$Octet){3}

$

“@
