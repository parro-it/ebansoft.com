{{ useLayout("./.layout") }}
{{ title("How to build a shell tokenizer in GO.") }}
{{ subtitle("This post is the first of a series where I explains how to implements in Go a tokenizer for `gash`, a shell language I'm building.") }}
{{ draft(false) }}
{{ published("2021-01-16") }}
{{ categories(["gash", "posts"]) }}
{{ tags(["gash", "golang", "packages"]) }}
{{ heading("person holding shell facing sea","https://source.unsplash.com/-iXjUZlCsd0/800x250") }}


# {{ meta.title }}

![{{ meta.headingCaption }}]({{ meta.headingFigure }})

{{ meta.subtitle }}

`gash` is a console shell with a very focused scope:
I will use it to run commands provided by `virtual-server`,
a Go library that allows to in&shy;teract with local and 
remote SSH server in very high level way.

`virtual-server` is closed source, but [gash](https://github.com/parro-it/gash) 
is MIT licensed, so you can go give it a star at the end of the tutorial if you like it.


## The posts series

* Introduction to `gash` and tokenization of strings (this one).
* Tokenization of operators and command terminators. 
* Tokenization of numbers and comments.
* String interpolation.
* Implementing a tokenization cli.
* Discerning commands at tokenization time to parse them concurrently.
* Final consideration on `gash` tokenizer.

This series of posts only explains how to build the tokenizer for
the lan&shy;gua&shy;ge. If there is some interests in the series, 
I will eventually wrote another one that explains how to build the 
parser for the language and the runtime.

I will complete `gash` anyway, because it will greatly simplify
my life at my daytime work.

## The language 

Since this is the first post of the series, I will give a brief, informal
 intro&shy;duc&shy;tion to the `gash` language.

### Introduction

The language that will be used by the shell will be a very 
simplified version of the posix standard shell language.

To make it simple, it will only implement the `Simple Command`
gram&shy;mar rule from the standard, in a very loose way.

### Some snippets of `gash`

Here below are some brief examples of what you can expect the language to be, 
just to give you a taste of what we will tokenizing in these posts...

#### Commands

Commands are separated by a `;`

Command names and arguments are separated by spaces, tabs or newlines.

```bash
cmd1; cmd2; cmd3 arg1 arg2 arg3;
cmd3 arg1 
	arg2 arg3;
```

#### Operators

There are various kind of operators.
Operators always break other tokens 
(note the `>` below) as if they are
 a whitespace.

```bash
exists remote:/usr/local && 
	ls remote:/usr/local>local:result
cp local:/tmp/afile remote:/usr/local/afile&
```

#### Verbatim strings and interpolation

TODO: write chapter with example of Verbatim strings and interpolation

#### Comments

TODO: write chapter with example of comments

#### Data types 

There are two types of data: `integers`
and `strings`.

```bash
echo "some words" 22 > somefile.txt;
	
any sequence of charachters is a string
even if not quoted in any way

all this text will be parsed as a long command
named any with a multitude of arguments

digits within words are parts of the word and 
not tokenized as integers 
this is a single w1o2r34d word;

this is a digit 42;
```

TODO: Complete chapter "This posts series" and move

## Tokenization of strings
TODO: rename chapter "Tokenization of strings" as "project scaffolding"
Create a new directory where you prefer,
and initialize a new Go module:

```bash
$ mkdir gash && cd gash
$ go mod init github.com/<your user name>/gash
```

Otherwise, you can get the complete source code
of the `gash` tokenizer as it should be at the end 
of this post:

```bash
$ mkdir gash && cd gash
$ git clone https://github.com/parro-it/gash/strings-tokenization
```

## Source files skeleton

TODO: merge chapter "Source files skeleton" with "project scaffolding"

We will use a `tokenizer` sub-module for the
tokenizer. We will write the source code
in a `tokenizer/tokenizer.go` file, and unit tests in
file `tokenizer/tokenizer_test.go`.

Create a skeleton of the two files with an 
always failing test, and check it effectively fail:

__tokenizer/tokenizer.go__
```go
package tokenizer

```

_tokenizer/tokenizer_test.go_
```go
package tokenizer

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestTokenizer(t *testing.T) {
	t.Run("always fail", func(t *testing.T) {
		assert.Fail(t, "it always fail")
	})
}		
```

## Tokenizer struct

The tokenizer struct will be the main data
structure the user of our API will use. 

It will contains a single public field
`Tokens` of `chan Token` type that will emit every token found in source code.

It will also have a private err `error` field,
that we will use to keep any er&shy;rors that 
eventually make the tokenization operation
fail.

```go
// Tokenizer can be used to find all
// tokens in an `io.Reader` source.
type Tokenizer struct {
	// Tokens emits all tokens found in `source`
	Tokens chan Token
	// contains the error that eventually caused
	// the tokenize operation to fails.
	err error
}
```

The module also has a public `New` function,
that initialize and return a new Tokenizer
instance:

```go
// New creates a new tokenizer that
// read tokens from `source` arguement
func New(source io.Reader) *Tokenizer {
	tkn := Tokenizer{
		Tokens: make(chan Token),
	}
	return &tkn
}
```

So, go on and add these two snippet of codes 
to `tokenizer.go`.

You can also test the New function
adding the snippet of code above in file `tokenizer_test.go`. 

Remember to remove the initial fake test if you
want to see the test suc&shy;ceed:

```go
func TestNew(t *testing.T) {
	source := strings.NewReader(`some code`)
	tokenizer := New(source)

	t.Run("return a pointer to a new Tokenizer", func(t *testing.T) {
		assert.NotNil(t, tokenizer)
	})

	t.Run("creates a new channel", func(t *testing.T) {
		assert.NotNil(t, tokenizer.Tokens)
	})

	// there's no way that the tokenizer 
	// could be in an error state by now, 
	// but we check it just in case...

	t.Run("has no error", func(t *testing.T) {
		assert.NoError(t, tokenizer.err)
	})
}
```

You can verify that the code is running using :

```bash
$ go test ./...
OUTPUT >> ok	  github.com/parro-it/gash/tokenizer   0.002s
```

Well, I hope you get the test passing, the 
`Tokenizer` is not doing any&shy;thing by now. In order to 
actually do the parsing, we will need a function in a 
separated goroutine that somehow read code from the input reader, 
and write tokens into the channel.

Let's write an initial version of the function that 
read from `source` one rune at the time, and print 
them on stdout:

```go

// find all tokens in `source` and write them in
// `tkn` channel. This function is called in a goroutine
// by `New` function.
func (tkn *Tokenizer) tokenize(source io.Reader) {
	// we need to close the tokens channel
	// when we finish with source
	defer close(tkn.Tokens)
	// we use a `bufio` reader to speed
	// things up when we will read source code from 
	// files or network.
	reader := bufio.NewReader(source)
	
	for {
		r, _, err := reader.ReadRune()
		if err == io.EOF {
			// when err is EOF, exit with
			// no errors
			return
		}
		if err != nil {
			// when err is not EOF, we store 
			// it in the tokenizer
			tkn.err = err
			return
		}
		// if no errors, print the
		// rune
		fmt.Println(r)
	}
}

```

This new tokenize function should be run in its goroutine
adding this line in `New` function before `return`:

```go
go tkn.tokenize(source)
```

You should now be able to check this piece of code by
running the exixstig test again and looking at the printed runes.

Moreover, now that we are properly closing the
`Tokens` channel, we can check that an empty string
does not caus the emission of any Token. Add this code to the test file:

```go
func TestTokens(t *testing.T) {
	t.Run("read empty reader source", func(t *testing.T) {
		source := strings.NewReader(``)
		tokenizer := New(source)
		for range tokenizer.Tokens {
			assert.Fail(t, "no tokens should be emit")
		}
	})
})
```

_if we would had tested this before, the test itself would have halted, because the channel would have been hanging open, without nobody caring_...

## The `Token` struct

But we don't want to print runes to console,
we want to write `Token` instances to the `Tokens`
channel.

`Token` is a simple struct with a string `Content`
field that contains the text of the token, and a `Type` 
field which is an enum identifying the type of token.

Since in this post, we'll only produce string tokens,
the enum will only have a `String` value, plus an `Empty`
values that will be used for empty tokens.

Add this code to `tokenizer/tokenizer.go`:

```go

// Token represents a single token
type Token struct {
	// Type is the type of the token
	Type TokenType
	// Content is the text representation of the token
	Content string
}

// TokenType is an enum of all kinds of tokens.
type TokenType int

const (
	// Empty is the kind of an empty token (the default)
	Empty TokenType = iota
	// String is the kind of a token that represents
	// a sequence of arbitrary runes.
	String
)

```

Having defined the `Token` struct, we can
improve the `tokenize` fun&shy;ction in order to 
emit our first token. 

We will use a `bytes.Buffer` to acc&shy;um&shy;ulate all
runes until we get an `EOF` error, and only then we 
will emit a new `Token` with content of the buffer.

```go

func (tkn *Tokenizer) tokenize(source io.Reader) {
	defer close(tkn.Tokens)
	reader := bufio.NewReader(source)
	buf := bytes.Buffer{}

	for {
		r, _, err := reader.ReadRune()
		if err == io.EOF {
			tkn.Tokens <- Token{
				Content: buf.String(),
				Type:	String,
			}
			return
		}
		if err != nil {
			tkn.err = err
			return
		}
		buf.WriteRune(r)
		
	}
}

```

To test this change, add this new test 
inside `TestTokens`:

```go

t.Run("read a single string token", func(t *testing.T) {
	source := strings.NewReader(`echo`)
	tokenizer := New(source)
	assert.NotNil(t, tokenizer)
	w, ok := <-tokenizer.Tokens
	assert.True(t, ok)
	assert.Equal(t, "echo", w.String())
	// there should be no more tokens
	empty, ok := <-tokenizer.Tokens
	assert.False(t, ok)
	assert.Equal(t, Empty, empty.Type)
	assert.Equal(t, "", empty.String())
})
		
```

## Tokenizing multiple tokens

We actually want to tokenize multiple strings, 
while by now the tokenize func only emit one
token containing all the source code. Not
really useful! 

If you remember something of the `gash` 
language unformal definition I gave you before, 
strings will be separated by operators or whitespaces.
In this post we will cover only whitespaces, we'll handles
operators in a future post.

Essentially, any time we found a whitespace rune,
if our `buf` con&shy;ta&shy;ins some&shy;thing we emit a token
with the content, empty the buf, and continue with 
the next rune. If the rune is not a space, we 
accumulate it as before.

At the end we emit the Token as before, but only if 
it contains something.

```go

func (tkn *Tokenizer) tokenize(source io.Reader) {
	defer close(tkn.Tokens)
	reader := bufio.NewReader(source)
	buf := bytes.Buffer{}

	for {
		r, _, err := reader.ReadRune()
		if err == io.EOF {
			if buf.Len() > 0 {
				tkn.Tokens <- Token{
					Content: buf.String(),
					Type:	String,
				}
			}
			return
		}
		if err != nil {
			tkn.err = err
			return
		}
		switch true {
		case r == ' ' || r == '\t':
			if buf.Len() > 0 {
				tkn.Tokens <- Token{
					Content: buf.String(),
					Type:	String,
				}
			}
			continue
		default:
			buf.WriteRune(r)
		}
		
	}
}

```

Let's refactor an `emitString` method that 
abstract the repeated code bl&shy;ock used to
emit the token:

```go

// emit a token of String type and reset the buffer
func (tkn *Tokenizer) emitString(buf *bytes.Buffer) {
	if buf.Len() == 0 {
		// we don't want to emi empty tokens!
		return
	}

	tkn.Tokens <- Token{
		Content: buf.String(),
		Type:	String,
	}

	// reset the buffer to reuse it
	buf.Reset()
}

```

The tokenize function is now decisively leaner:

```go

func (tkn *Tokenizer) tokenize(source io.Reader) {
	defer close(tkn.Tokens)
	reader := bufio.NewReader(source)
	buf := bytes.Buffer{}

	for {
		r, _, err := reader.ReadRune()
		if err == io.EOF {
			tkn.emitString(&buf)
			return
		}
		if err != nil {
			tkn.err = err
			return
		}
		switch true {
		case r == ' ' || r == '\t':
			tkn.emitString(&buf)
			continue
		default:
			buf.WriteRune(r)
		}
	}

}

```

We can now test with some more realistic source code in order to get mul&shy;tiple tokens.

Add this code to the test file, inside `TestTokens`:

```go

t.Run("read multiple tokens", func(t *testing.T) {
	source := strings.NewReader(`echo multiple strings`)
	tokenizer := New(source)
	assert.NotNil(t, tokenizer)
	expected := make(chan Token, 3)
	expected <- Token{
		Content: "echo",
		Type:	String,
	}
	expected <- Token{
		Content: "multiple",
		Type:	String,
	}
	expected <- Token{
		Content: "strings",
		Type:	String,
	}

	for tk := range tokenizer.Tokens {
		tkExpected := <-expected
		assert.Equal(t, tkExpected.Type, tk.Type)
		assert.Equal(t, tkExpected.Content, tk.Content)
	}

	_, ok := <-tokenizer.Tokens
	assert.False(t, ok)

})

```

Whoo! Multiple tokens produced, good work! Keep going 💪 

Since I feel strong and I think we'll have to test a lot of tokens in the future, let's go clever and extract a simple 
type that will simplify the test of future tokens:

```go


// ExpectedTokens simplify testing of
// Tokenizer by storing a set of tokens,
// that can be later easily compared with the
// tokens emitted by an actual channel using
// AssertEquals
type ExpectedTokens []Token

// AssertEquals compare the tokens emitted by
// `actual` with the expected ones previously stored
// in the slice. If the two sets differ the test is failed
// accordingly.
func (tokens ExpectedTokens) AssertEquals(
	t *testing.T, 
	actual chan Token,
) {
	tkCount := 0

	failDiffLen := func() {
		assert.Failf(
			t, "", 
			"%d tokens expected, but %d found", 
			len(tokens), tkCount
		)
	}

	for _, expectedToken := range tokens {
		select {
		case <-time.After(500 * time.Millisecond):
			failDiffLen()
		case actualToken := <-actual:
			assert.Equal(
				t, 
				actualToken.Type, 
				expectedToken.Type
			)
			assert.Equal(
				t, 
				actualToken.Content, 
				expectedToken.Content
			)
			tkCount++
		}

	}

	// there should be no other tokens left at this point
	_, ok := <-actual
	if ok {
		failDiffLen()
	}
}

```

The `ExpectedTokens` type refine `[]Token` to add
an `AssertEquals` me&shy;thod.

`AssertEquals` takes in input the channel of tokens 
to test. It compares the tokens emitted by the channel 
with the ones in the slice, both for size and content 
of the tokens.

The test code is now greatly simplified: 

```go

expectedStrings := ExpectedTokens{
	{Content: "echo", Type: String},
	{Content: "multiple", Type: String},
	{Content: "strings", Type: String},
}

t.Run("read multiple tokens", func(t *testing.T) {
	source := strings.NewReader(`echo multiple strings`)
	tokenizer := New(source)
	assert.NotNil(t, tokenizer)
	expectedStrings.AssertEquals(t, tokenizer.Tokens)
	_, ok := <-tokenizer.Tokens
	assert.False(t, ok)
})

```

and you can see how we can now use `expectedStrings`
in multiple tests, provided that the expected results 
it's the same.

## Final conclusion

If you follow all the steps, you should now have a functioning
tokenizer that split a string in multiple word tokens.

That's all for now. I hope you enjoied the turial. I enjoied writing it.

In the next post of the series, we will improve the tokenizer by adding
to it the capacity to tokenize operators and command termination characters 
(`;`) 




## Credits

* <span>Photo by <a href="https://unsplash.com/@valentinsteph?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Stéphan Valentin</a> on <a href="https://unsplash.com/s/photos/shells-beach?utm_source=unsplash&amp;utm_medium=referral&amp;utm_content=creditCopyText">Unsplash</a></span>

[[TOC]]

TODO: Improve golang code colors
TODO: CSS - implements adaptive size page

<br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br>
<br><br><br><br><br><br><br><br><br><br><br><br><br><br>