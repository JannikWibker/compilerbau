import strutils
import std/options

type
  TokenType* = enum
    PLUS
    MINUS
    STAR
    SLASH
    LPAREN
    RPAREN
    NUMBER
    WHITESPACE
    EOF

type
  Token* = object
    kind*: TokenType
    line*: int
    colstart*: int
    colend*: int
    value*: Option[string]

proc `$`(token: Token): string =
  return "kind: $1, value: \"$2\", line: $3, col: $4-$5" % [$token.kind, $token.value, $(token.line+1), $token.colstart, $token.colend]

type
  Lexer* = ref object
    source*: seq[string]
    line*: int
    col*: int

# this mirrors the finite state machine on slide 33 (the assignment incorrectly states this as being on slide 35, additionally state 2 should also be an accepting state)
proc tokenize_float(lex: Lexer): Token =
  var start_position = lex.col
  var parsed = ""
  var state = 0

  while true:
    var character = lex.source[lex.line][lex.col]
    echo "state: $1, char: '$2'" % [$state, $character]
    case state
      of 0:
        case character
          of '.':
            parsed.add('.')
            lex.col += 1
            state = 1
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 2
          else:
            echo "Invalid character: $1" % [$character]
            return Token(kind: TokenType.EOF, line: lex.line, colstart: start_position, colend: start_position, value: none(string))
      of 1:
        case character
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 3
          else:
            echo "Invalid character: $1" % [$character]
            return Token(kind: TokenType.EOF, line: lex.line, colstart: start_position, colend: start_position, value: none(string))
      of 2:
        case character
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 2
          of '.':
            parsed.add(character)
            lex.col += 1
            state = 3
          else:
            return Token(kind: TokenType.NUMBER, line: lex.line, colstart: start_position, colend: lex.col, value: some(parsed))
      of 3:
        case character
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 3
          of 'e', 'E':
            parsed.add(character)
            lex.col += 1
            state = 4
          of 'f', 'F', 'l', 'L':
            parsed.add(character)
            lex.col += 1
            state = 7
          else:
            return Token(kind: TokenType.NUMBER, line: lex.line, colstart: start_position, colend: lex.col, value: some(parsed))
      of 4:
        case character
          of '+', '-':
            parsed.add(character)
            lex.col += 1
            state = 5
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 6
          else:
            echo "Invalid character: $1" % [$character]
            return Token(kind: TokenType.EOF, line: lex.line, colstart: start_position, colend: start_position, value: none(string))
      of 5:
        case character
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 6
          else:
            echo "Invalid character: $1" % [$character]
            return Token(kind: TokenType.EOF, line: lex.line, colstart: start_position, colend: start_position, value: none(string))
      of 6:
        case character
          of '0'..'9':
            parsed.add(character)
            lex.col += 1
            state = 6
          of 'f', 'F', 'l', 'L':
            parsed.add(character)
            lex.col += 1
            state = 7
          else:
            return Token(kind: TokenType.NUMBER, line: lex.line, colstart: start_position, colend: lex.col, value: some(parsed))
      of 7:
        return Token(kind: TokenType.NUMBER, line: lex.line, colstart: start_position, colend: lex.col, value: some(parsed))
      else:
        echo "Invalid state: $1" % [$state]
        return Token(kind: TokenType.EOF, line: lex.line, colstart: start_position, colend: start_position, value: none(string))


proc has_next*(lex: Lexer): bool =
  # at last line
  if lex.source.len - 1 == lex.line:
    # at last character
    if lex.source[lex.source.len - 1].len == lex.col:
      return false
    else:
      return true
  else:
    echo "true"
    return true

proc next*(lex: Lexer): Token =
  var character = lex.source[lex.line][lex.col]

  case character
    of '+':
      var token = Token(kind: TokenType.PLUS, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some("+"))
      lex.col += 1
      return token
    of '-':
      var token = Token(kind: TokenType.MINUS, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some("-"))
      lex.col += 1
      return token
    of '*':
      var token = Token(kind: TokenType.STAR, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some("*"))
      lex.col += 1
      return token
    of '/':
      var token = Token(kind: TokenType.SLASH, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some("/"))
      lex.col += 1
      return token
    of '(':
      var token = Token(kind: TokenType.LPAREN, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some("("))
      lex.col += 1
      return token
    of ')':
      var token = Token(kind: TokenType.RPAREN, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some(")"))
      lex.col += 1
      return token
    of ' ', '\t', '\n', '\r':
      var token = Token(kind: TokenType.WHITESPACE, line: lex.line, colstart: lex.col, colend: lex.col + 1, value: some($character))
      lex.col += 1
      return token
    of '0'..'9', '.':
      return lex.tokenize_float()
    else:
      return Token(kind: TokenType.EOF, line: lex.line, colstart: lex.col, colend: lex.col, value: none(string));
