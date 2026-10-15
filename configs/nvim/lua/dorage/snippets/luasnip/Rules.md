# Luasnip Rules

트리거는 헤딩에서 `` 로 감싼 글자를 위에서부터 이어 붙인 것이다.

- lang 표기
    - typescript: javascript, javascriptreact, typescript, typescriptreact
    - typescript(ts): typescript, typescriptreact 만

## `l`anguage

### `k`eyword

#### `a`sync

```
lka
```

lang: python, typescript

#### a`w`ait

```
lkw
```

lang: python, typescript

#### `b`reak

```
lkb
```

lang: typescript

#### `c`ontinue

```
lkc
```

lang: typescript

### `t`ype

#### `s`tring

```
lts
```

lang: typescript

#### `n`umber

```
ltn
```

lang: typescript

#### `b`oolean

```
ltb
```

lang: typescript

#### `u`ndefined

```
ltu
```

lang: typescript

#### `n`ull

```
ltn
```

lang: typescript

> 주의: number 와 트리거가 겹친다.

### `v`ariable

```
lv
```

lang: python

> python: def 매개변수 괄호 안에서는 `name: type` 으로 펼쳐진다. choice 로 `name: type = default`.

#### `l`et

```
lvl
```

lang: python, typescript

> python: `lv` 와 같다.

#### `c`onst

```
lvc
```

lang: python, typescript

> python: `NAME: Final = value` (`from typing import Final` 필요)

#### `f`unction variable

```
lvf
```

lang: typescript

### `f`unction

```
lf
```

lang: python, typescript

#### `a`rrow function

```
lfa
```

lang: typescript

#### `j`SON

##### `s`tringify

```
lfjs
```

lang: typescript

##### `p`arse

```
lfjp
```

lang: typescript

#### `d`ecorator

```
lfd
```

lang: python

> choice 로 인자를 받는 decorator. `import functools` 필요.

### `o`bject (class)

```
lo
```

lang: python

> choice 로 `class Name(Base):`

### `s`tatement

#### `if`

```
lsif
```

lang: python, typescript

##### `i`f else if

```
lsifi
```

lang: python, typescript

##### `e`lse

```
lsife
```

lang: python, typescript

#### `s`witch

```
lss
```

lang: python, typescript

##### `c`ase

```
lssc
```

lang: python, typescript

##### `d`efault

```
lssd
```

lang: python, typescript

#### `f`or

```
lsf
```

lang: python, typescript

##### for .. `o`f

```
lsfo
```

lang: typescript

##### for .. `i`n

```
lsfi
```

lang: typescript

#### `w`hile

```
lsw
```

lang: python, typescript

#### `w`ith

```
lswi
```

lang: python

#### `t`ry catch

```
lst
```

lang: python, typescript

##### try `d`efault

```
lstd
```

lang: typescript

##### try `e`lse

```
lste
```

lang: python

##### try `f`inally

```
lstf
```

lang: python

#### `r`eturn

```
lsr
```

lang: python, typescript

#### `e`xport

```
lse
```

lang: typescript

#### `i`mport

```
lsi
```

lang: python, typescript

### `c`omment

#### `t`ODO

```
lct
```

lang: python, typescript

#### `w`ARN

```
lcw
```

lang: python, typescript

#### `n`OTE

```
lcn
```

lang: python, typescript

#### te`s`t

```
lcs
```

lang: python, typescript

#### `f`IX

```
lcf
```

lang: python, typescript

#### `a`I

```
lca
```

lang: python, typescript

#### `h`eader

```
lch
```

lang: typescript

#### separator

```
lcf
```

lang: typescript

> 주의: FIX 와 트리거가 겹친다.

#### `m`ultiline

```
lcm
```

lang: python

#### `g`iven-when-then

```
lcg
```

lang: python

### `a`rray

#### `e`mpty array

```
lae
```

lang: typescript

## array method (postfix)

`배열.` 뒤에 붙여서 쓴다. 예: `items.map` → `items.map(...)`

#### `.for`Each

```
.for
```

lang: typescript

#### `.map`

```
.map
```

lang: typescript

#### `.fil`ter

```
.fil
```

lang: typescript

#### `.eve`ry

```
.eve
```

lang: typescript

#### `.som`e

```
.som
```

lang: typescript

#### `.red`uce

```
.red
```

lang: typescript

#### `.sor`t

```
.sor
```

lang: typescript

## 규칙 밖 트리거

### 출력

#### `log`

```
log
```

lang: python(print), typescript(console.log)

#### `log` `o`bject

```
logo
```

lang: typescript

#### `err`or

```
err
```

lang: typescript

#### `d`e`b`u`g`

```
dbg
```

lang: typescript

### 기타

#### `ter`nary

```
ter
```

lang: all

#### template string

```
$
```

lang: typescript

#### `env` variable

```
env
```

lang: typescript

#### `t`ype`s`cript `d`efinition `i`nterface

```
tsdi
```

lang: typescript(ts)

#### `t`ype`s`cript `d`efinition `t`ype

```
tsdt
```

lang: typescript(ts)

### jest

#### `j`es`t` `d`escribe

```
jtd
```

lang: typescript(ts)

#### `j`es`t` `t`est

```
jtt
```

lang: typescript(ts)

#### `j`es`t` `e`xpect

```
jte
```

lang: typescript(ts)

### `l`ua`sn`ip

#### `i`mport

```
lsni
```

lang: lua

#### `s`nippet

```
lsns
```

lang: lua

#### `f`ormatting

```
lsnf
```

lang: lua

#### `l`ocal `v`ariable

```
lv
```

lang: lua

## 계획 (미구현)

- `m` 접두어로 라이브러리 스니펫 묶기
    - React: `re`
    - Tailwind: `c` (display, flex, text)
