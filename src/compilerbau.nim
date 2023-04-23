import strutils
import exercise_01/main

# testing around a bit
var lex: Lexer
lex = Lexer()

lex.source = split("1 + (2 * 3.4)", '\n')
lex.col = 0
lex.line = 0

while lex.has_next():
  echo lex.next()
