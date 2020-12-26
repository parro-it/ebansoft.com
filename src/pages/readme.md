```njk
{% extends ".layout" %}
{% block post %}
```

## ebansoft.com blog sources.

This page is just an example of the capacity of orgame app.

## Some list of items

* item 1
* item 2
* item 3

1) numbered item
2) numbered item
3) numbered item

## Normal text

This is a normal paragraph of text. 
This is a citation: `HTML` `orgame`

## Task lists

* [ ] - task 1
* [X] - task 2, done!
* [ ] - task 3
* [X] - task 4, done!

## Headers

### third

#### fourth

##### fifth

###### sixth

## Links

Proudly built with [orgame](https://github.com/parro-it/orgame).

This is a bare link: https://github.com/parro-it/ebansoft.com.

This is link without protocol: github.com/parro-it/ebansoft.com.

## Tables

| 1  | A  | B  | C  | D  |
|----|----|----|----|----|
| 2  | a2 | b2 | c2 | d2 |
| 3  | a3 | b3 | c3 | d3 |
| 4  | a4 | b4 | c4 | d4 |

## Quotes

> This page has been written in markdown.
> This is a quote. This page has been written in markdown.
> This is a quote. This page has been written in markdown.
> This is a quote. This page has been written in markdown.
> This is a quote. This page has been written in markdown.
> This is a quote. This page has been written in markdown.

> This is another quote

## Images
[![spoiler](https://github.com/parro-it/libdesktop/workflows/Node.js%20CI/badge.svg)](https://github.com/parro-it/libdesktop)
![example image](head-blog-home.png)
![A WPS video](https://www.youtube.com/watch?v=SSPzfKRTiZY&t=410s)
![a log](https://source.unsplash.com/random)


## Code snippets

### C

```C
/* an example of C code */
int main(int argc, char** argv) {
    return 0;
}
```

### Javascript

```javascript
/* an example of Javascript code */
function main(argc, argv) {
    console.log("ciao");
    return 0;
}
```

### Typescript

```typescript
/* an example of Typescript code */
function main(args: Array<string>): number {
    return 0;
}

export async function* range(start: number, end: number): AsyncIterable<number> {
    for (let i = start; i < end; i++) {
        yield i;
    }
}
```

### HTML

```html
<!-- an example of HTML code -->
<html>
    <body class="visible">Hello world</body>
</html>
```

### CSS
```css
/* an example of CSS code */
body.visible {
    display: block;
}
```

```njk
{% endblock %}
```